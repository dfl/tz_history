#!/usr/bin/env ruby
# frozen_string_literal: true

# research/intl/crosscheck_all.rb -- comprehensive Shanks-vs-backzone residual scan across
# EVERY shipped Shanks table. crosscheck.rb was only ever run ad hoc per-zone; this is the
# all-at-once pass. Instead of parsing the intended twin out of noisy prose, we take the
# candidate twins per country code from iana_divergence.tsv and EMPIRICALLY find which
# backzone zone each Shanks table reproduces best. The real "unexplained divergence" is a
# shipped table that reproduces NO backzone twin for its country exactly.
#
#   TZ_SRC=/tmp/tzsrc ruby research/intl/crosscheck_all.rb

require "tzinfo"
require "tmpdir"

SRC = ENV["TZ_SRC"] || "/tmp/tzsrc"
REGION = %w[africa antarctica asia australasia europe northamerica southamerica etcetera].freeze
BUILD = "research/intl/build_intl.rb"
DIVERGENCE = "research/intl/iana_divergence.tsv"

# candidate twins per CC, from the divergence list (zone<TAB>cc<TAB>...)
cands = Hash.new { |h, k| h[k] = [] }
File.readlines(DIVERGENCE).drop(1).each do |l|
  f = l.chomp.split("\t")
  cands[f[1]] << f[0]
end

# per-table year range from the REGISTRY (this part parses cleanly)
text = File.read(BUILD)
yr = {}
text.split(/(?=\{\s*admin1:)/).each do |b|
  tbl = b[/shanks:\s*"([^"]+)"/, 1] or next
  y0 = b[/from:\s*"(\d{4})/, 1]&.to_i
  y1 = b[/to:\s*"(\d{4})/, 1]&.to_i
  m = (yr[tbl] ||= { y0: nil, y1: nil })
  m[:y0] = [m[:y0], y0].compact.min
  m[:y1] = [m[:y1], y1].compact.max
end

pack = Dir.mktmpdir("xchkall")
system("zic", "-d", pack, *REGION.map { |f| File.join(SRC, f) }, File.join(SRC, "backzone"),
       out: File::NULL, err: File::NULL)

ds = TZInfo::DataSources
deduper = TZInfo.const_get(:StringDeduper).new
parser  = ds.const_get(:PosixTimeZoneParser).new(deduper)
reader  = ds.const_get(:ZoneinfoReader).new(parser, deduper)
def load(reader, path, id)
  zi = reader.read(path) or return nil
  info = zi.is_a?(TZInfo::TimezoneOffset) ?
    TZInfo::DataSources::ConstantOffsetDataTimezoneInfo.new(id, zi) :
    TZInfo::DataSources::TransitionsDataTimezoneInfo.new(id, zi)
  TZInfo::DataTimezone.new(info)
end
OFF = ->(z, t) { z.period_for_utc(t).observed_utc_offset rescue nil }

def ratio(reader, pack, sh, twin, y0, y1)
  bz = load(reader, File.join(pack, twin), twin) or return nil
  match = 0
  total = 0
  worst = 0
  (y0..y1).each do |y|
    (1..12).each do |m|
      t = Time.utc(y, m, 15, 12)
      a = OFF.call(sh, t)
      b = OFF.call(bz, t)
      next if a.nil? || b.nil?

      total += 1
      a == b ? match += 1 : worst = [worst, (a - b).abs].max
    end
  end
  return nil if total.zero?

  { match: match, total: total, worst_s: worst }
end

shipped = Dir.children("data/shanks/zoneinfo/Shanks").sort
puts "Comprehensive Shanks-vs-backzone residual scan (#{shipped.size} shipped tables)\n\n"

clean = []
flagged = []
shipped.each do |tbl|
  cc = tbl.split("_").first
  sh = load(reader, "data/shanks/zoneinfo/Shanks/#{tbl}", "Shanks/#{tbl}")
  unless sh
    flagged << [tbl, "Shanks zic not loadable", nil]
    next
  end
  y0 = yr.dig(tbl, :y0) || 1890
  y1 = yr.dig(tbl, :y1) || 1969
  candidates = cands[cc]
  if candidates.empty?
    flagged << [tbl, "no candidate twin for CC=#{cc} in divergence list (#{y0}-#{y1})", nil]
    next
  end
  scored = candidates.map { |tw| [tw, ratio(reader, pack, sh, tw, y0, y1)] }.reject { |_, r| r.nil? }
  best = scored.max_by { |_, r| r[:match].to_f / r[:total] }
  if best.nil?
    flagged << [tbl, "twins exist but no overlapping years (#{y0}-#{y1}): #{candidates.join(',')}", nil]
    next
  end
  tw, r = best
  if r[:match] == r[:total]
    clean << [tbl, tw, r]
  else
    flagged << [tbl, "BEST twin #{tw}: #{r[:match]}/#{r[:total]} match, worst dz=#{r[:worst_s] / 60}m (#{y0}-#{y1})", scored]
  end
end

puts "CLEAN (reproduces a backzone twin exactly): #{clean.size}"
clean.each { |tbl, tw, r| puts format("  %-7s -> %-24s %d/%d", tbl, tw, r[:match], r[:total]) }
puts "\nFLAGGED: #{flagged.size}"
flagged.each do |tbl, msg, scored|
  puts "  == #{tbl}: #{msg}"
  next unless scored

  scored.sort_by { |_, r| -(r[:match].to_f / r[:total]) }.first(4).each do |tw, r|
    puts format("       %-24s %d/%d  worst dz=%dm", tw, r[:match], r[:total], r[:worst_s] / 60)
  end
end
