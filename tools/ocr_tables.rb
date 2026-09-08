#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/ocr_tables.rb -- OCR the column strips produced by tools/render_state.rb and
# parse them into a rough per-table transition list. This is a DRAFT for triage
# (tools/triage.rb) only; the source of truth is always the rendered crop read by a
# human/subagent (docs/EXTRACTION.md §2 "OCR is a draft, never the source of truth").
#
#   ruby tools/ocr_tables.rb <render_dir>
#   => writes <render_dir>/ocr_tables.json  and prints a summary
#
# Ported from research/historical_zones/parse_timetable.rb (the script that
# transcribed KY #69/#71). A table is numbered (`AL # 1`) and FLOWS DOWN one column,
# CONTINUING at the top of the next column -- not within-column wrap. We track the
# current table across columns so continuation rows land in the right table.
#
# Consumes the render_state.rb crops.json manifest (col*_band* strips): it reads the
# bands of each column top-to-bottom, column by column, so the table flow-down order is
# preserved. Falls back to the legacy col%d.png naming when no manifest is present.

require "json"
require "open3"

render_dir = ARGV[0] or abort "usage: ocr_tables.rb <render_dir>"

# Zone code -> {offset in seconds, dst?}. US#n = federal uniform rules from that date
# (we defer to IANA thereafter, so treat as a marker, not an offset).
ZONES = {
  "LMT" => nil,
  "EST" => [-5 * 3600, false], "EDT" => [-4 * 3600, true], "EWT" => [-4 * 3600, true], "EPT" => [-4 * 3600, true],
  "CST" => [-6 * 3600, false], "CDT" => [-5 * 3600, true], "CWT" => [-5 * 3600, true], "CPT" => [-5 * 3600, true],
  "MST" => [-7 * 3600, false], "MDT" => [-6 * 3600, true], "MWT" => [-6 * 3600, true], "MPT" => [-6 * 3600, true],
  "PST" => [-8 * 3600, false], "PDT" => [-7 * 3600, true], "PWT" => [-7 * 3600, true], "PPT" => [-7 * 3600, true]
}.freeze

DATE  = %r{\b(\d{1,2})/(\d{1,2})/(\d{4})\b}
TIME  = /\b(\d{1,2}):(\d{2})\b/
ZONE  = /\b([ECMP][SDWP]T|US\s*#?\s*\d+|LMT)\b/i
TABLE = /\b([A-Z]{2})\s*#\s*(\d+)\b/i # e.g. "AL # 1", "KY # 69"

def ocr(img)
  Open3.capture2({ "OMP_THREAD_LIMIT" => "1" }, "tesseract", img, "stdout", "--psm", "6",
                 err: File::NULL).first
end

manifest = File.join(render_dir, "crops.json")
crops =
  if File.exist?(manifest)
    JSON.parse(File.read(manifest))["crops"]
      .sort_by { |c| [c["col"], c["band"]] } # column-major, band-minor = table flow order
      .map { |c| File.join(render_dir, c["path"]) }
  else # legacy single-strip-per-column layout
    Dir[File.join(render_dir, "col*.png")].reject { |f| f =~ /_band\d+/ }.sort
  end
crops = crops.select { |f| File.exist?(f) }
abort "no col crops in #{render_dir} -- run render_state.rb first" if crops.empty?

tables = Hash.new { |h, k| h[k] = [] }
cur = nil
crops.each do |crop|
  ocr(crop).each_line do |line|
    # A bare table header line (no date on it) switches the current table.
    if (m = line.match(TABLE)) && line !~ DATE
      cur = "#{m[1].upcase}_#{m[2]}"
      next
    end
    next unless (d = line.match(DATE))

    zc = line.match(ZONE)&.captures&.first&.upcase&.gsub(/\s+/, "")
    next unless zc

    y, mo, dy = d[3].to_i, d[1].to_i, d[2].to_i
    next unless y.between?(1880, 1970) && mo.between?(1, 12) && dy.between?(1, 31)

    t = line.match(TIME)
    hh = t ? t[1].rjust(2, "0") : "02"
    mm = t ? t[2] : "00"
    uniform = zc.start_with?("US")
    off, dst = uniform ? [nil, nil] : (ZONES[zc] || [nil, nil])
    tables[cur || "UNKNOWN"] << {
      at_local: format("%04d-%02d-%02d %s:%s", y, mo, dy, hh, mm),
      abbr: zc, off: off, dst: dst, uniform: uniform
    }
  end
end

# Dedupe per table (OCR repeats rows across overlapping strips) and sort by date.
tables.each_value do |rows|
  rows.uniq! { |r| [r[:at_local][0, 10], r[:abbr]] }
  rows.sort_by! { |r| r[:at_local] }
end

out = File.join(render_dir, "ocr_tables.json")
File.write(out, JSON.pretty_generate(tables))
puts "parsed #{tables.size} tables -> #{out}"
tables.sort_by { |k, _| [k.length, k] }.each do |tbl, rows|
  dst_years = rows.select { |r| r[:dst] }.map { |r| r[:at_local][0, 4] }.uniq
  puts format("  %-8s %2d rows   DST years: %s", tbl, rows.size, dst_years.join(" "))
end
