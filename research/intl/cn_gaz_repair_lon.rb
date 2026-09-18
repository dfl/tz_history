#!/usr/bin/env ruby
# frozen_string_literal: true

# research/intl/cn_gaz_repair_lon.rb -- repair the ~600 dropped-leading-digit longitude
# tokens in the China gazetteer OCR (found by cn_gaz_selfcheck.rb CHECK A). The co-located
# LMT is the authoritative offset Shanks printed, and true lon = LMT/240s. When the printed
# lon disagrees with the LMT by >2 min it's a dropped degree digit (`121E12` OCR'd `1E12`);
# we recompute lon from LMT and rewrite the token.
#
# CONSERVATIVE guard -- we only rewrite when BOTH hold, so we never "fix" a row whose LMT is
# itself mangled:
#   1. the recomputed arc-minute matches the printed arc-minute (+/-2')  -> same coordinate
#   2. the printed degrees are a digit-suffix of the recomputed degrees  -> pure digit-drop
# Rows that fail the guard are left untouched and listed as AMBIGUOUS.
#
#   ruby research/intl/cn_gaz_repair_lon.rb [cn_gazetteer.tsv]   # rewrites in place, .bak kept

path = ARGV[0] || "research/intl/cn_gazetteer.tsv"

def parse_lon(tok)
  m = tok.to_s.match(/\A(\d{1,3})\s*([EeWw])\s*(\d{1,2})/)
  return nil unless m

  { deg: m[1].to_i, hemi: m[2].upcase, min: m[3].to_i, degstr: m[1] }
end

def parse_lmt_sec(tok)
  m = tok.to_s.match(/(-?)(\d{1,2}):(\d{2}):(\d{2})/)
  return nil unless m

  (m[2].to_i * 3600) + (m[3].to_i * 60) + m[4].to_i
end

repaired = []
ambiguous = []

lines = File.readlines(path)
out = lines.map do |l|
  f = l.chomp.split("\t")
  lon = parse_lon(f[4])
  lmt_sec = parse_lmt_sec(f[5])
  next l unless lon && lmt_sec

  expected_deg = lmt_sec / 240.0
  printed_deg = lon[:deg] + (lon[:min] / 60.0)
  next l if (expected_deg - printed_deg).abs <= 2.0 / 60.0 # <=2 arc-min: fine as-is

  rdeg = expected_deg.floor
  rmin = ((expected_deg - rdeg) * 60).round
  if rmin == 60
    rdeg += 1
    rmin = 0
  end
  min_ok = (rmin - lon[:min]).abs <= 2
  suffix_ok = rdeg.to_s.end_with?(lon[:degstr])

  if min_ok && suffix_ok
    new_tok = format("%d%s%02d", rdeg, lon[:hemi], rmin)
    repaired << { name: f[0], old: f[4], new: new_tok, lmt: f[5], line: lines.index(l) }
    f[4] = new_tok
    next f.join("\t") + "\n"
  else
    ambiguous << { name: f[0], lon: f[4], lmt: f[5], rdeg: rdeg, rmin: rmin,
                   min_ok: min_ok, suffix_ok: suffix_ok }
    next l
  end
end

File.rename(path, "#{path}.bak")
File.write(path, out.join)

puts "repaired #{repaired.size} lon tokens; #{ambiguous.size} left as AMBIGUOUS (guard failed)"
puts "backup: #{path}.bak\n\n"
puts "=== sample repairs (first 20) ==="
puts format("  %-20s %-9s -> %-9s  (lmt %s)", "name", "old", "new", "")
repaired.first(20).each do |r|
  puts format("  %-20s %-9s -> %-9s  (lmt %s)", r[:name].to_s[0, 20], r[:old], r[:new], r[:lmt])
end
unless ambiguous.empty?
  puts "\n=== AMBIGUOUS (left untouched -- LMT and lon disagree in min, not a clean digit-drop) ==="
  puts format("  %-20s %-9s %-9s  %-14s min_ok suffix_ok", "name", "lon", "lmt", "recomputed")
  ambiguous.first(30).each do |a|
    puts format("  %-20s %-9s %-9s  %3dE%02d          %-6s %s",
                a[:name].to_s[0, 20], a[:lon], a[:lmt], a[:rdeg], a[:rmin], a[:min_ok], a[:suffix_ok])
  end
  puts "  ... (#{ambiguous.size} total)" if ambiguous.size > 30
end
