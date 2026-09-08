#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/map_counties.rb -- resolve each county of a state to its Shanks TIME TABLE by
# majority vote of its cities (docs/EXTRACTION.md §7). Dev-only.
#
#   ruby tools/map_counties.rb <dir_of_page_pngs> [--cols=6] [--split=0.75] [--min=3]
#
# The CITY LISTINGS (lower ~55% of each state page, continuing for several pages) are
# rows of `CityName County# Table# lat lon`; a numbered County# -> name legend sits
# just below the TIME TABLES on the first page. We column-crop every page, OCR each
# strip, parse legend + city rows, and for each county report the distribution of
# table numbers its cities cite plus the MAJORITY table.
#
# A county whose majority table has < --split share (or < --min cities) is a genuine
# straddle -> emit `warn`, don't guess (the Olson principle). OCR is noisy, but
# majority vote over many cities is robust; low-vote counties are flagged, not trusted.
#
# Output: JSON {county_num => {name, votes:{table=>n}, majority, share, split?}} to
# <dir>/county_map.json, plus a readable table on stdout.

require "json"
require "open3"

opts = ARGV.grep(/\A--/).to_h { |a| k, v = a.sub("--", "").split("=", 2); [k, v || true] }
dir = ARGV.reject { |a| a.start_with?("--") }[0]
abort "usage: map_counties.rb <dir_of_page_pngs> | --from-cities=cities.json [--split=0.75] [--min=3] [--split-emit --zone-map=T:zone,... [--county=N,N]]" unless dir || opts["from-cities"]
cols = (opts["cols"] || 6).to_i
split_thresh = (opts["split"] || 0.75).to_f
min_votes = (opts["min"] || 3).to_i

# Exclude our own transient column crops (named <page>.col<N>.png) so a re-run after
# an interrupted pass doesn't mistake leftover crops for pages. (Only the legacy OCR
# path needs page PNGs; --from-cities reads a prebuilt index instead.)
pages = []
unless opts["from-cities"]
  pages = Dir[File.join(dir, "*.png")].reject { |f| f =~ /\.col\d+\.png\z/ }.sort
  abort "no page PNGs in #{dir}" if pages.empty?
end

def column_ocr(img, cols)
  w, h = Open3.capture2("identify", "-format", "%w %h", img).first.split.map(&:to_i)
  cw = w / cols
  (0...cols).map do |c|
    x = cw * c
    crop = "#{img}.col#{c}.png"
    system("convert", img, "-crop", "#{(cw * 1.5).to_i}x#{h}+#{x}+0", "+repage", crop, err: File::NULL)
    text = Open3.capture2({ "OMP_THREAD_LIMIT" => "1" }, "tesseract", crop, "stdout", "--psm", "6",
                          err: File::NULL).first
    File.delete(crop) if File.exist?(crop)
    text
  end.join("\n")
end

# Legend: a line that is "<num> <Name>" with nothing after the name (county# -> name).
LEGEND = /\A\s*(\d{1,3})\s+([A-Z][A-Za-z.'\- ]+?)\s*\z/
# City row: "<Name> <county#> <table#> <lat like 41N23>". The lat token (digits then
# N/S) disambiguates which integer is the table number.
CITY = /\A\s*([A-Za-z][A-Za-z.'\- ]*?)\s+(\d{1,3})\s+(\d{1,2})\s+\d{1,3}\s*[NnSs]/

legend = {}
votes = Hash.new { |h, k| h[k] = Hash.new(0) }
# Per-city rows WITH coordinates, kept for --split-emit (only the extract_cities path
# has them; the legacy OCR path has no coords, so split-emit needs --from-cities).
city_rows = Hash.new { |h, k| h[k] = [] }

if opts["from-cities"]
  # Consume tools/extract_cities.rb output: {cities:[{name,county_num,table,lat,lon}],
  # legend:{n=>name}}. Richer than re-OCRing -- and carries the coords split-emit needs.
  data = JSON.parse(File.read(opts["from-cities"]))
  (data["legend"] || {}).each { |n, name| legend[n.to_i] = name }
  data["cities"].each do |c|
    county = c["county_num"].to_i
    table = c["table"].to_i
    next unless county.positive? && table.positive?

    votes[county][table] += 1
    city_rows[county] << c
  end
else
  pages.each do |img|
    column_ocr(img, cols).each_line do |line|
      line = line.rstrip
      if (m = line.match(CITY))
        county = m[2].to_i
        table = m[3].to_i
        votes[county][table] += 1 if county.positive? && table.positive?
      elsif (m = line.match(LEGEND))
        num = m[1].to_i
        name = m[2].strip.squeeze(" ")
        # Legend names are short (a county), not a whole sentence; guard against prose.
        legend[num] ||= name if name.split.size <= 4 && num.between?(1, 300)
      end
    end
  end
end

result = {}
votes.sort.each do |county, tbls|
  total = tbls.values.sum
  majority, top = tbls.max_by { |_, n| n }
  share = top.to_f / total
  split = share < split_thresh || total < min_votes
  result[county] = {
    "name" => legend[county],
    "votes" => tbls.sort_by { |_, n| -n }.to_h,
    "total_cities" => total,
    "majority" => majority,
    "share" => share.round(2),
    "split" => split
  }
end

out = File.join(File.dirname(opts["from-cities"] || File.join(dir, "x")), "county_map.json")
File.write(out, JSON.pretty_generate(result))
puts "counties resolved: #{result.size}  (legend entries: #{legend.size})  -> #{out}"
puts format("%-4s %-16s %-22s %-8s %-6s %s", "#", "county", "table votes", "majority", "share", "flag")
result.each do |num, r|
  flag = r["split"] ? "SPLIT/warn" : ""
  puts format("%-4s %-16s %-22s %-8s %-6s %s",
              num, r["name"] || "?", r["votes"].map { |t, n| "#{t}:#{n}" }.join(" "),
              r["majority"], r["share"], flag)
end

# --split-emit: for the SPLIT counties, emit a per-town {name,lon,lat,zone} list ready
# to paste into an add_feature.rb `split` spec (Phase 2 of OCR_NEAREST_CITY_PLAN.md).
# `zone` comes from --zone-map=<table>:<zone>,...  (a table absent from the map, or
# mapped to empty, means "defer to IANA" -> null zone, i.e. the town matched IANA).
# Needs the coords the --from-cities index carries; the geographic separability of the
# split MUST still be crop-verified before shipping (a non-geographic split stays warn).
if opts["split-emit"]
  abort "--split-emit needs --from-cities (coords)" unless opts["from-cities"]
  zone_map = (opts["zone-map"] || "").split(",").to_h do |kv|
    t, z = kv.split(":", 2)
    [t.to_i, (z && !z.empty? ? z : nil)]
  end
  wanted = opts["county"] ? opts["county"].split(",").map(&:to_i) : result.select { |_, r| r["split"] }.keys
  specs = wanted.map do |cnum|
    cities = city_rows[cnum].map do |c|
      { "name" => c["name"], "lon" => c["lon"], "lat" => c["lat"],
        "zone" => zone_map[c["table"].to_i] }
    end
    { "county_num" => cnum, "county" => legend[cnum], "kind" => "split", "cities" => cities }
  end
  emit = File.join(File.dirname(out), "split_specs.json")
  File.write(emit, JSON.pretty_generate(specs))
  puts "\nsplit-emit: #{specs.size} county spec(s) -> #{emit}"
  specs.each do |s|
    zoned = s["cities"].count { |c| c["zone"] }
    puts "  county #{s['county_num']} #{s['county']}: #{s['cities'].size} towns (#{zoned} zoned, #{s['cities'].size - zoned} defer)"
  end
end
