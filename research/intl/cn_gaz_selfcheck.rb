#!/usr/bin/env ruby
# frozen_string_literal: true

# research/intl/cn_gaz_selfcheck.rb -- Tier-2 self-consistency audit of the Apple Vision
# China gazetteer OCR (cn_gazetteer.tsv). Two independent OCR-error detectors that need no
# re-read to RUN -- they tell us whether the 26k-record OCR has a mis-zoning problem worth
# chasing before we spend any agent fan-out.
#
#   CHECK A  LMT-vs-longitude: each row carries BOTH a printed LMT (-8:39:16) and a lon
#            (129E49). True LMT = lon_degrees * 240s. A disagreement means the coord OR the
#            LMT token was OCR-mangled. Big disagreements can also flip which zone a city
#            reads into.
#   CHECK B  Division-majority OFFSET outliers: within an administrative division nearly all
#            cities share one base offset. A city whose TT# maps to a different offset than
#            its division's dominant offset is a candidate misread digit (the intl analog of
#            the US table#-bleed mis-zoning bug). Cross-referenced against CHECK A and against
#            longitude plausibility so we separate "real zone split" from "OCR noise".
#
#   ruby research/intl/cn_gaz_selfcheck.rb [cn_gazetteer.tsv]

DIVS = {
  1 => "Anhui", 2 => "Beijing", 3 => "Fujian", 4 => "Gansu", 5 => "Guangdong",
  6 => "Guangxi", 7 => "Guizhou", 8 => "Hebei", 9 => "Heilongjiang", 10 => "Henan",
  11 => "Hubei", 12 => "Hunan", 13 => "Jiangsu", 14 => "Jiangxi", 15 => "Jilin",
  16 => "Liaoning", 17 => "Inner Mongolia", 18 => "Ningxia", 19 => "Qinghai",
  20 => "Shaanxi", 21 => "Shandong", 22 => "Shanghai", 23 => "Shanxi", 24 => "Sichuan",
  25 => "Taiwan", 26 => "Tianjin", 27 => "Xinjiang", 28 => "Xizang(Tibet)", 29 => "Yunnan",
  30 => "Zhejiang", 31 => "Hong Kong", 32 => "Macau"
}.freeze

# TT# -> base offset. TT#1-6 and #10 are all +8 (they differ only in DST history, not base
# zone), so we collapse them to a single "+8" for the offset-outlier check.
OFF = { 1 => "+8", 2 => "+8", 3 => "+8", 4 => "+8", 5 => "+8", 6 => "+8", 10 => "+8",
        9 => "+7", 8 => "+6", 7 => "+5:30", 11 => "+8:30", 12 => "+8:30" }.freeze

def lon_to_deg(tok)
  m = tok.to_s.match(/(\d{1,3})\s*[EeWw]\s*(\d{1,2})/)
  return nil unless m

  d = m[1].to_i + (m[2].to_i / 60.0)
  m[1].to_s =~ /[Ww]/ || tok =~ /[Ww]/ ? -d : d
end

def lmt_to_sec(tok)
  m = tok.to_s.match(/(-?)(\d{1,2}):(\d{2}):(\d{2})/)
  return nil unless m

  (m[2].to_i * 3600) + (m[3].to_i * 60) + m[4].to_i # magnitude only
end

path = ARGV[0] || "research/intl/cn_gazetteer.tsv"
rows = File.readlines(path).map.with_index do |l, i|
  f = l.chomp.split("\t")
  { line: i + 1, name: f[0], div: f[1].to_i, tt: f[2].to_i,
    lat: f[3], lon: f[4], lmt: f[5], page: f[6], col: f[7],
    lon_deg: lon_to_deg(f[4]), lmt_sec: lmt_to_sec(f[5]) }
end

total = rows.size
puts "China gazetteer self-check: #{total} rows\n"

# ---- CHECK A: LMT vs longitude -------------------------------------------------------
checkable = rows.select { |r| r[:lon_deg] && r[:lmt_sec] }
a_bad = checkable.map do |r|
  expected = (r[:lon_deg].abs * 240).round
  diff = (expected - r[:lmt_sec]).abs
  r.merge(exp_sec: expected, diff_sec: diff)
end.select { |r| r[:diff_sec] > 120 } # >2 min disagreement
a_bad.sort_by! { |r| -r[:diff_sec] }

puts "=" * 90
puts "CHECK A  LMT vs longitude (expected = lon_deg * 240s)"
puts "  checkable rows (have both lon+lmt): #{checkable.size}"
puts "  DISAGREE > 2 min: #{a_bad.size}  (#{format('%.2f', 100.0 * a_bad.size / checkable.size)}%)"
puts "-" * 90
buckets = a_bad.group_by { |r| r[:diff_sec] > 1800 ? ">30m" : r[:diff_sec] > 600 ? "10-30m" : "2-10m" }
%w[>30m 10-30m 2-10m].each { |b| puts format("  %-7s %d", b, (buckets[b] || []).size) }
puts "\n  worst 25:"
puts format("  %-20s %-4s %-3s %-7s %-9s %-9s %8s", "name", "div", "tt", "lat", "lon", "lmt", "off_by")
a_bad.first(25).each do |r|
  off = r[:diff_sec]
  offs = off >= 3600 ? format("%dh%02dm", off / 3600, (off % 3600) / 60) : format("%dm%02ds", off / 60, off % 60)
  puts format("  %-20s %-4s %-3s %-7s %-9s %-9s %8s L%d",
              r[:name].to_s[0, 20], r[:div], r[:tt], r[:lat], r[:lon], r[:lmt], offs, r[:line])
end

# ---- CHECK B: division-majority offset outliers --------------------------------------
valid = rows.select { |r| DIVS.key?(r[:div]) && OFF.key?(r[:tt]) }
by_div = valid.group_by { |r| r[:div] }
puts "\n" + ("=" * 90)
puts "CHECK B  Division-majority OFFSET outliers"
puts "  rows with valid div+tt: #{valid.size}"
puts "-" * 90
puts format("  %-4s %-16s %6s  %-26s %s", "div", "province", "n", "offset histogram", "outliers")
b_outliers = []
by_div.sort_by { |d, _| d }.each do |div, rs|
  hist = rs.each_with_object(Hash.new(0)) { |r, h| h[OFF[r[:tt]]] += 1 }
  dom = hist.max_by { |_, n| n }.first
  outs = rs.reject { |r| OFF[r[:tt]] == dom }
  # A "real split" province (Xinjiang, Tibet, ...) legitimately has a minority offset. We
  # only surface outliers whose share is small enough to look like noise (< 8%).
  minority_share = outs.size.to_f / rs.size
  hstr = hist.sort_by { |_, n| -n }.map { |o, n| "#{o}:#{n}" }.join("  ")
  flag = minority_share < 0.08 && !outs.empty? ? "#{outs.size} (#{format('%.1f', minority_share * 100)}%)" : ""
  b_outliers.concat(outs.map { |r| r.merge(dom: dom) }) if minority_share < 0.08
  puts format("  %-4s %-16s %6d  %-26s %s", div, DIVS[div], rs.size, hstr, flag)
end

puts "\n  suspected misread rows (division-minority offset, share<8%):"
puts format("  %-20s %-16s %-3s %-5s %-9s %-9s %s", "name", "province", "tt", "->off", "lon", "lmt", "dom")
b_outliers.sort_by { |r| [r[:div], r[:tt]] }.first(40).each do |r|
  puts format("  %-20s %-16s %-3s %-5s %-9s %-9s %s L%d",
              r[:name].to_s[0, 20], DIVS[r[:div]], r[:tt], OFF[r[:tt]], r[:lon], r[:lmt], r[:dom], r[:line])
end
puts "  ... (#{b_outliers.size} total)" if b_outliers.size > 40

# ---- overlap: rows failing BOTH checks are the highest-confidence OCR errors ----------
a_lines = a_bad.map { |r| r[:line] }.to_set
both = b_outliers.select { |r| a_lines.include?(r[:line]) }
puts "\n" + ("=" * 90)
puts "OVERLAP  rows failing BOTH A and B (highest-confidence OCR errors): #{both.size}"
both.sort_by { |r| r[:line] }.each do |r|
  puts format("  %-20s %-16s tt=%s ->%s lon=%s lmt=%s  L%d",
              r[:name].to_s[0, 20], DIVS[r[:div]], r[:tt], OFF[r[:tt]], r[:lon], r[:lmt], r[:line])
end
