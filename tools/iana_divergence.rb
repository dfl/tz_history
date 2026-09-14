#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/iana_divergence.rb -- Phase-0 triage for the International Atlas sweep.
#
# IANA models the whole world pre-1970 but distrusts its own pre-1970 data and has
# DEMOTED much of it out of the default build: zones are merged to bare Links (in
# `backward`) and their real pre-1970 history is quarantined in the opt-in `backzone`
# file (compiled only with `make PACKRATDATA=backzone`). Wherever the demoted history
# DIFFERS from what the default build now serves, a plain geographic lookup is wrong
# pre-1970 -- exactly the gap the Shanks International Atlas fills (the Netherlands:
# Europe/Amsterdam is a Link to Brussels, off by +0:19:32 every pre-1940 winter).
#
# This tool compiles the tz database TWO ways with zic and diffs every backzone zone's
# observed offset against the default build, month by month 1890-1969. Zones that
# differ are the ranked worklist; zones that match are already IANA-sufficient.
#
#   ruby tools/iana_divergence.rb /path/to/tzdb-src        # a checkout of eggert/tz
#   TZ_SRC=/path/to/tzdb-src ruby tools/iana_divergence.rb
#
# The tzdb source dir must contain the region files, `backward`, `backzone`,
# `zone.tab`, `zone1970.tab`, `iso3166.tab` (fetch from raw.githubusercontent.com/
# eggert/tz/main). Writes a ranked TSV to research/intl/iana_divergence.tsv.

require "tzinfo"
require "fileutils"
require "tmpdir"

SRC = ARGV[0] || ENV["TZ_SRC"] or abort "usage: iana_divergence.rb <tzdb-src-dir>"
REGION = %w[africa antarctica asia australasia europe northamerica southamerica etcetera].freeze

# --- compile the two builds ---------------------------------------------------
OUT = Dir.mktmpdir("tzdiv")
dflt = File.join(OUT, "DFLT")
pack = File.join(OUT, "PACK")
region_paths = REGION.map { |f| File.join(SRC, f) }
system("zic", "-d", dflt, *region_paths, File.join(SRC, "backward"), out: File::NULL, err: File::NULL)
system("zic", "-d", pack, *region_paths, File.join(SRC, "backzone"), out: File::NULL, err: File::NULL)

# --- low-level TZif reader (as in lib/tz_history/zone.rb) ----------------------
ds = TZInfo::DataSources
deduper = TZInfo.const_get(:StringDeduper).new
parser  = ds.const_get(:PosixTimeZoneParser).new(deduper)
READER  = ds.const_get(:ZoneinfoReader).new(parser, deduper)
def load_zone(path, id)
  zi = READER.read(path)
  return nil unless zi

  info = zi.is_a?(TZInfo::TimezoneOffset) ?
    TZInfo::DataSources::ConstantOffsetDataTimezoneInfo.new(id, zi) :
    TZInfo::DataSources::TransitionsDataTimezoneInfo.new(id, zi)
  TZInfo::DataTimezone.new(info)
rescue StandardError
  nil
end

# --- country-code maps --------------------------------------------------------
cc2name = {}
File.foreach(File.join(SRC, "iso3166.tab")) do |l|
  next if l =~ /^#/

  c, n = l.chomp.split("\t", 2)
  cc2name[c] = n
end
zone2cc = {}
# zone1970.tab first (multi-cc, take the primary), then zone.tab (authoritative single).
File.foreach(File.join(SRC, "zone1970.tab")) do |l|
  next if l =~ /^#/

  ccs, _co, z = l.chomp.split("\t")
  zone2cc[z] ||= ccs.split(",").first
end
File.foreach(File.join(SRC, "zone.tab")) do |l|
  next if l =~ /^#/

  c, _co, z = l.chomp.split("\t")
  zone2cc[z] = c
end
# Alias zones (Asia/Chongqing, Europe/Belfast, ...) aren't in the .tab files; resolve
# them through the backward Link target's country (Chongqing -> Shanghai -> CN).
link_target = {}
File.foreach(File.join(SRC, "backward")) do |l|
  next unless l =~ /^Link/

  _, tgt, name = l.split
  link_target[name] = tgt
end
resolve_cc = lambda do |z, seen = 0|
  zone2cc[z] || (seen < 5 && link_target[z] ? resolve_cc.call(link_target[z], seen + 1) : nil)
end

# --- diff each backzone zone --------------------------------------------------
bz = File.readlines(File.join(SRC, "backzone")).select { |l| l =~ /^Zone/ }.map { |l| l.split[1] }.uniq
rows = []
bz.each do |z|
  # Noise: fictitious acronym zones (no region prefix) and Antarctica research bases
  # are not atlas countries.
  next unless z.include?("/")
  next if z.start_with?("Antarctica/")

  p = load_zone(File.join(pack, z), z)
  d = load_zone(File.join(dflt, z), z)
  next unless p && d

  diff = 0
  maxdelta = 0
  first_delta = nil
  (1890..1969).each do |y|
    [1, 7].each do |m|
      t = Time.utc(y, m, 15, 12)
      op = (p.period_for_utc(t).observed_utc_offset rescue nil)
      od = (d.period_for_utc(t).observed_utc_offset rescue nil)
      next if op.nil? || od.nil? || op == od

      diff += 1
      delta = (op - od).abs
      maxdelta = delta if delta > maxdelta
      first_delta ||= op - od
    end
  end
  next if diff.zero?

  cc = resolve_cc.call(z)
  rows << { zone: z, cc: cc, country: cc2name[cc] || cc || "?", half: diff, maxdelta: maxdelta, delta: first_delta }
end

rows.sort_by! { |r| [-r[:half], -r[:maxdelta]] }

# --- output -------------------------------------------------------------------
tsv = File.expand_path("../research/intl/iana_divergence.tsv", __dir__)
FileUtils.mkdir_p(File.dirname(tsv))
File.open(tsv, "w") do |io|
  io.puts "zone\tcc\tcountry\thalf_years_diff\tmax_delta_s\tfirst_delta_s"
  rows.each { |r| io.puts [r[:zone], r[:cc], r[:country], r[:half], r[:maxdelta], r[:delta]].join("\t") }
end

puts "IANA pre-1970 divergence triage (backzone vs default build, 1890-1969, Jan+Jul samples)"
puts "backzone zones scanned: #{bz.size};  DIVERGENT (worklist): #{rows.size};  " \
     "countries: #{rows.map { |r| r[:country] }.uniq.size}"
puts "wrote #{tsv}"
puts
printf "%-27s %-3s %-24s %5s %8s\n", "zone", "cc", "country", "halfY", "maxDelta"
rows.each do |r|
  printf "%-27s %-3s %-24s %5d %7dm\n", r[:zone], r[:cc] || "?", r[:country][0, 24], r[:half], r[:maxdelta] / 60
end
FileUtils.remove_entry(OUT)
