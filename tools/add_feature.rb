#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/add_feature.rb -- append ONE historical-zone feature to
# data/us_historical_zones.geojson, built from US Census county polygons (the plotly
# geojson-counties-fips public dataset, the same source the existing features use).
# Dev-only.
#
#   ruby tools/add_feature.rb <spec.json> [--dry-run]
#
# Spec JSON:
#   {
#     "fips": ["01001", "01003", ...],   # counties this feature covers
#     "kind": "override",                # or "warn"
#     "shanks": "AL_1",                  # xor "zone": "Etc/GMT+6" xor neither (warn)
#     "from_date": "1919-10-26",         # nullable
#     "until_date": "1942-02-09",
#     "region": "human description of the region + why",
#     "note": null                       # nullable; a warn WITHOUT a note is an exclusion guard
#   }
#
# CRITICAL (docs/RUNBOOK.md non-negotiables): the whole geojson is NEVER
# pretty_generate'd (that explodes coordinates and blows up the diff). We APPEND
# textually, with the new feature's geometry serialized COMPACT on one line -- exactly
# the shape the KY_69/KY_71 features use. The bulk of the file stays byte-for-byte
# untouched.
#
# County polygons are read from a cached copy of the plotly dataset; set
# COUNTIES_GEOJSON to point at it (default: the scratchpad cache).

require "json"

spec_path = ARGV[0] or abort "usage: add_feature.rb <spec.json> [--dry-run]"
dry = ARGV.include?("--dry-run")
spec = JSON.parse(File.read(spec_path))

GEOJSON = File.expand_path("../data/us_historical_zones.geojson", __dir__)
COUNTIES = ENV["COUNTIES_GEOJSON"] ||
           File.join(ENV.fetch("SCRATCH", "/tmp"), "geojson-counties-fips.json")
abort "counties dataset not found at #{COUNTIES} (set COUNTIES_GEOJSON)" unless File.exist?(COUNTIES)

fips = Array(spec.fetch("fips")).map(&:to_s)
abort "spec.fips is empty" if fips.empty?

counties = JSON.parse(File.read(COUNTIES))["features"]
by_id = counties.each_with_object({}) { |f, h| h[f["id"].to_s] = f }

# Collect every polygon (a county is a Polygon or a MultiPolygon) into one flat list,
# so N counties become one MultiPolygon. point_in_geometry? tests polygons.any?, so an
# un-dissolved union is correct for containment -- no geo library needed.
polygons = []
missing = []
fips.each do |id|
  f = by_id[id]
  (missing << id; next) unless f
  case f.dig("geometry", "type")
  when "Polygon" then polygons << f["geometry"]["coordinates"]
  when "MultiPolygon" then polygons.concat(f["geometry"]["coordinates"])
  end
end
abort "FIPS not found in dataset: #{missing.join(', ')}" unless missing.empty?

geometry = { "type" => "MultiPolygon", "coordinates" => polygons }

props = {
  "region" => spec.fetch("region"),
  "kind" => spec.fetch("kind"),
  "zone" => spec["zone"],
  "shanks" => spec["shanks"],
  "from_date" => spec["from_date"],
  "until_date" => spec.fetch("until_date"),
  "note" => spec["note"]
}

# Render the feature the way the file already formats KY: pretty properties, COMPACT
# geometry on a single line.
prop_lines = props.map { |k, v| "        #{JSON.generate(k)}: #{JSON.generate(v)}" }.join(",\n")
feature = <<~FEAT.chomp
      {
        "type": "Feature",
        "properties": {
    #{prop_lines}
        },
        "geometry": #{JSON.generate(geometry)}
      }
FEAT

pts = polygons.sum { |poly| poly.sum { |ring| ring.size } }
summary = "feature: #{fips.size} counties, #{polygons.size} polygons, #{pts} points, " \
          "#{props['shanks'] || props['zone'] || props['kind']} " \
          "#{props['from_date']}..#{props['until_date']}"

if dry
  puts "[dry-run] would append:"
  puts summary
  puts feature.lines.first(6).join
  exit 0
end

# Append textually: find the LAST "]" that closes the features array (the line that is
# just "  ]" before the final "}") and splice ",<feature>" in before it.
text = File.read(GEOJSON)
lines = text.lines
close_idx = lines.rindex { |l| l.rstrip == "  ]" } or
  abort "could not find features-array close (  ]) in #{GEOJSON}"

# The feature before the close must gain a trailing comma.
prev_idx = close_idx - 1
lines[prev_idx] = lines[prev_idx].rstrip + ",\n" unless lines[prev_idx].rstrip.end_with?(",")
lines.insert(close_idx, feature + "\n")
File.write(GEOJSON, lines.join)

# Verify it still parses and the count went up by one.
n = JSON.parse(File.read(GEOJSON))["features"].size
puts "appended #{summary}"
puts "geojson now has #{n} features; still valid JSON."
