#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/triage.rb -- data-driven candidate detection (docs/EXTRACTION.md §4).
#
# A Shanks transition-list zone is only worth authoring for the RESIDUAL case the
# shipped model cannot represent: a table that observed a daylight season IANA does
# NOT model AND the flat override gets wrong. Everything else already resolves
# correctly (flat override for year-round standard time, IANA for the rest), so we do
# NOT transcribe it.
#
# For each table we walk months `--from`..`--to` and compare the table's OBSERVED
# offset against two baselines:
#   (a) the flat override shipped for the state (constant, e.g. CST -6), and
#   (b) the state's modern IANA zone (e.g. America/Chicago).
# A month is a "miss" iff the table differs from BOTH. Contiguous misses collapse to
# year-ranges. Tables with zero misses are provably already correct -- dropped.
#
# Federal seasons (WWI 1918-19, war 1942-45, uniform 1967+) match IANA by
# construction, so they never flag -- the surviving flags are exactly the pre-war
# local-DST pockets (e.g. northern KY 1920-26) that motivate this whole gem.
#
#   ruby tools/triage.rb <ocr_tables.json> --flat=-6 --iana=America/Chicago \
#        [--from=1918] [--to=1966]
#
# Output: a ranked candidate list. Then a HUMAN visual-verifies each flagged table's
# crop before it is transcribed (tools/zic_from_json.rb); OCR alone never authors a
# zone.

require "json"
require "date"
require "tzinfo"

args = {}
files = []
ARGV.each do |a|
  if a =~ /\A--([a-z]+)=(.+)\z/ then args[$1] = $2 else files << a end
end
ocr_path = files[0] or abort "usage: triage.rb <ocr_tables.json> --flat=-6 --iana=Zone"
flat_off = Integer(args.fetch("flat", "-6")) * 3600
iana = TZInfo::Timezone.get(args.fetch("iana", "America/Chicago"))
from_y = (args["from"] || 1918).to_i
to_y   = (args["to"]   || 1966).to_i

tables = JSON.parse(File.read(ocr_path))

# Observed offset (seconds) of a table on a probe date: last transition at/before it.
# `uniform` markers (US#n) hand off to IANA -- from then on we treat the table as
# equal to IANA (no possible miss), which is exactly the semantics we want.
def table_offset(rows, probe)
  seen = nil
  rows.each do |r|
    at = r["at_local"] ? Date.parse(r["at_local"][0, 10]) : nil
    break if at && at > probe

    seen = r
  end
  return :uniform if seen && seen["uniform"]
  return nil unless seen && seen["off"]

  seen["off"] + (seen["dst"] ? 3600 : 0)
end

def iana_offset(zone, probe)
  zone.period_for_local(Time.utc(probe.year, probe.month, probe.day, 12), true).observed_utc_offset
rescue StandardError
  zone.period_for_utc(Time.utc(probe.year, probe.month, probe.day, 12)).observed_utc_offset
end

candidates = []
tables.each do |tbl, rows|
  next if rows.empty?

  misses = [] # [Date, table_off, iana_off]
  (from_y..to_y).each do |y|
    (1..12).each do |mo|
      probe = Date.new(y, mo, 15)
      t = table_offset(rows, probe)
      next if t.nil? || t == :uniform # pre-history or handed to IANA -> can't miss

      i = iana_offset(iana, probe)
      misses << [probe, t, i] if t != flat_off && t != i
    end
  end
  next if misses.empty?

  # Collapse consecutive missed months into year-ranges for a compact report.
  years = misses.map { |m| m[0].year }.uniq.sort
  ranges = years.slice_when { |a, b| b - a > 1 }.map { |g| g.first == g.last ? "#{g.first}" : "#{g.first}-#{g.last}" }
  sample = misses.first
  candidates << {
    table: tbl,
    missed_months: misses.size,
    year_ranges: ranges,
    example: "#{sample[0]}: table #{sample[1] / 3600}h vs flat #{flat_off / 3600}h vs IANA #{sample[2] / 3600}h"
  }
end

candidates.sort_by! { |c| -c[:missed_months] }

if candidates.empty?
  puts "NO CANDIDATES -- every table matches the flat override or IANA. State is flat/IANA-sufficient."
else
  puts "#{candidates.size} candidate table(s) (differ from BOTH flat #{flat_off / 3600}h and IANA #{iana.identifier}):"
  candidates.each do |c|
    puts format("  %-8s  %3d missed months  years %-14s  e.g. %s",
                c[:table], c[:missed_months], c[:year_ranges].join(","), c[:example])
  end
  puts "\nNEXT: visual-verify each flagged table's rendered crop, then tools/zic_from_json.rb."
  puts "Tables NOT listed are provably already correct (flat/IANA) -- leave them."
end
