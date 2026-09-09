#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/ocr_tables.rb -- OCR the atlas TIME TABLES into a per-table transition list, good
# enough to CLASSIFY tables (no-DST vs DST, and the postwar DST-resumption year) which is
# what the town-level layers need. Still a draft; the crop is the source of truth.
#
#   ruby tools/render_state.rb <pg> --cols=1 --top=0 --bot=0.45 --band-h=2400 --out=DIR
#   ruby tools/ocr_tables.rb DIR
#
# The dense N-column layout defeated fixed w/N crops (the columns aren't at w/N -- margins
# shift them -- so crops bleed the neighbour in and headers get lost). The fix: DETECT the
# real columns. A first tsv pass locates the DATE words; their left-x forms tight per-column
# clusters, and the wide gaps between clusters are the column separators (so the column
# COUNT is discovered, not assumed -- Maryland is 5 columns, Idaho 6). We then crop each
# real column cleanly and OCR it as one block. A numbered table FLOWS DOWN a column and
# CONTINUES at the next column's top; every table opens with an 18xx epoch date (which OCRs
# far better than the words "Before"/"LMT"), so that segments them. Columns are cropped to
# just BEFORE the next column's first date so the ZONE (rightmost field) isn't clipped, and
# each column is OCR'd in vertical bands (a full-height 300dpi column degrades tesseract at
# the bottom). The "XX # N" header, when legible, sets the number; otherwise it increments.
#
# STATUS (validated on Maryland + Idaho): a big step up from the old row-merging parser --
# it auto-detects the column count, and for the tables it DETECTS the DST classification is
# accurate (Baltimore's continuous DST, the 1947/1948/1954 resumption years, Idaho's 1961
# resumers + 1930s pre-war DST all come out right). BUT recall is ~50-60% of tables/page:
# some tables' faint epoch line isn't OCR'd, and a missed table shifts the sequential
# numbering. So trust the DST *pattern* of a detected table as a strong triage signal, but
# CROP-VERIFY a table's number + resumption date before authoring (RUNBOOK: OCR is a draft).
# Full recall needs a sharper source render or a better OCR engine -- a further follow-up.

require "json"
require "open3"

render_dir = ARGV[0] or abort "usage: ocr_tables.rb <render_dir>"
manifest = JSON.parse(File.read(File.join(render_dir, "crops.json")))
full = File.join(render_dir, "full.png")
w = manifest["page_w"]
region_h = (manifest["page_h"] * 0.45).to_i

ZONES = {
  "EST" => [-5 * 3600, false], "EDT" => [-4 * 3600, true], "EWT" => [-4 * 3600, true], "EPT" => [-4 * 3600, true],
  "CST" => [-6 * 3600, false], "CDT" => [-5 * 3600, true], "CWT" => [-5 * 3600, true], "CPT" => [-5 * 3600, true],
  "MST" => [-7 * 3600, false], "MDT" => [-6 * 3600, true], "MWT" => [-6 * 3600, true], "MPT" => [-6 * 3600, true],
  "PST" => [-8 * 3600, false], "PDT" => [-7 * 3600, true], "PWT" => [-7 * 3600, true], "PPT" => [-7 * 3600, true]
}.freeze
DATE  = %r{\b(\d{1,2})/(\d{1,2})/(\d{4})\b}
EPOCH = %r{\b\d{1,2}/\d{1,2}/18\d\d\b}          # the "Before 11/18/1883" opener
ZONE  = /\b([ECMP][SDWP]T)\b/
HEADER = /\b([A-Z]{2})\s*[#*XxYy¥]+\s*(\d{1,3})\b/

def tsv_date_xs(img)
  Open3.capture2({ "OMP_THREAD_LIMIT" => "1" }, "tesseract", img, "stdout", "--psm", "6", "tsv",
                 err: File::NULL).first.each_line.drop(1).filter_map do |l|
    f = l.chomp.split("\t")
    f[6].to_i if f.size >= 12 && f[11].to_s =~ %r{\A\d{1,2}/\d{1,2}/\d{2,4}\z}
  end
end

def ocr(img)
  Open3.capture2({ "OMP_THREAD_LIMIT" => "1" }, "tesseract", img, "stdout", "--psm", "6", err: File::NULL).first
end

# 1. Locate columns from the DATE-word x clusters (gaps > 500px = column separators).
xs = manifest["crops"].sort_by { |c| c["band"] }
                      .flat_map { |c| tsv_date_xs(File.join(render_dir, c["path"])) }.sort
abort "no date words -- not a time-tables page?" if xs.size < 5
# A column's row is date..time..ZONE, and the zone reaches almost to the NEXT column's
# date; so the boundary must sit just BEFORE the next column's first date (b - margin),
# not at the gap midpoint -- else the zone (the bit we most need) gets clipped.
seps = xs.each_cons(2).select { |a, b| b - a > 500 }.map { |_a, b| b - 90 }
bounds = [0] + seps + [w]

# 2. Crop each real column and OCR it, VERTICALLY BANDED (a full-height 300dpi column
#    degrades tesseract at the bottom, dropping the last tables in each column), then
#    concatenate in column order (a table flows down a column, so its rows stay together).
tmp = File.join(render_dir, "_col.png")
lines = []
band_h = 2400
band_ov = 200
(bounds.size - 1).times do |c|
  x0 = bounds[c]
  cw = bounds[c + 1] - x0
  step = band_h - band_ov
  prev = nil
  (0...region_h).step(step) do |y0|
    bh = [band_h, region_h - y0].min
    next if bh <= 0

    system("magick", full, "-crop", "#{cw}x#{bh}+#{x0}+#{y0}", "+repage", tmp, err: File::NULL)
    ocr(tmp).each_line do |l|
      l = l.rstrip
      # drop the line repeated across the band overlap
      lines << l unless l.empty? || l == prev
      prev = l
    end
  end
end
File.delete(tmp) if File.exist?(tmp)

# 3. Segment at each epoch date; number from a legible header else increment; parse rows.
tables = []
cur = nil
lines.each_with_index do |line, i|
  if line =~ EPOCH
    hdr = nil
    ((i - 3)..i).each { |j| (m = lines[j]&.match(HEADER)) && m[2].to_i.positive? && (hdr = m[2].to_i) }
    cur = { num: hdr || ((tables.last&.dig(:num) || 0) + 1), rows: [] }
    tables << cur
    next
  end
  next unless cur

  d = line.match(DATE) or next
  y, mo, dy = d[3].to_i, d[1].to_i, d[2].to_i
  next unless y.between?(1884, 1970) && mo.between?(1, 12) && dy.between?(1, 31)

  if line =~ ZONE
    off, dst = ZONES[Regexp.last_match(1)]
    cur[:rows] << { at_local: format("%04d-%02d-%02d", y, mo, dy), abbr: Regexp.last_match(1), off: off, dst: dst, uniform: false }
  elsif line =~ /US\s*[#*]?\s*\d/i
    cur[:rows] << { at_local: format("%04d-%02d-%02d", y, mo, dy), abbr: "US#", off: nil, dst: nil, uniform: true }
  end
end

by_num = {}
tables.each { |t| (by_num[t[:num]] ||= []).concat(t[:rows]) }
result = by_num.transform_values { |rows| rows.uniq { |r| r[:at_local] }.sort_by { |r| r[:at_local] } }

out = File.join(render_dir, "ocr_tables.json")
File.write(out, JSON.pretty_generate(result.transform_keys(&:to_s)))
puts "parsed #{result.size} tables in #{bounds.size - 1} columns -> #{out}"
result.sort.each do |num, rows|
  peace = rows.select { |r| r[:dst] }.map { |r| r[:at_local][0, 4].to_i }
              .reject { |y| (1942..1945).cover?(y) || [1918, 1919].include?(y) }.uniq.sort
  resume = peace.find { |y| y >= 1946 }
  puts format("  #%-3d %2d rows  peacetime-DST %-24s %s", num, rows.size, peace.first(8).join(","),
              resume ? "resume #{resume}" : (peace.empty? ? "NO-DST" : ""))
end
