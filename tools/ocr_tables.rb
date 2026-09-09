#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/ocr_tables.rb -- OCR the atlas TIME TABLES into a per-table transition list.
# A DRAFT for triage; the rendered crop is still the source of truth. But this draft is
# now reliable enough to CLASSIFY tables (no-DST vs DST, and postwar DST-resumption year),
# which is what the town-level layers need.
#
#   render full-width bands first, then:
#   ruby tools/render_state.rb <pg> --cols=1 --top=0 --bot=0.45 --band-h=2400 --out=DIR
#   ruby tools/ocr_tables.rb DIR [--cols=6]
#
# Why full-width + tsv: the dense 6-column layout has no gutter a fixed w/6 crop can hit
# (margins shift it), so column crops BLEED the neighbour in and the "XX # N" headers land
# mid-line and get lost -- the old parser dropped ~40% of tables. Instead we OCR full-width
# bands with WORD BOXES (tesseract tsv), CLUSTER words into columns by their x-coordinate
# (each column's date/time/zone words share an x-band), rebuild clean per-column lines, and
# read the columns in flow order. A table FLOWS DOWN a column and CONTINUES at the next
# column's top; every table opens with an 18xx epoch date, which segments them reliably.
#
# STATUS: the word-box/column-cluster rewrite parses the tables it DETECTS accurately
# (e.g. it now gets Baltimore's continuous DST and the correct postwar resumption year,
# which the old row-merging parser mangled). But recall on the faint 1978 print is still
# only ~50-80% of tables per page, and a missed epoch shifts the SEQUENTIAL numbering, so
# the per-table NUMBER isn't yet authoritative. Treat the DST *pattern* per detected table
# as a solid triage signal; still crop-verify a table's number + resumption date before
# authoring (docs/RUNBOOK.md: OCR is a draft, the crop is truth). Lifting recall needs
# OCR preprocessing (contrast/deskew) + detected column boundaries -- a focused follow-up.

require "json"
require "open3"

render_dir = ARGV[0] or abort "usage: ocr_tables.rb <render_dir> [--cols=6]"
ncols = (ARGV.grep(/\A--cols=/).first&.split("=")&.last || 6).to_i

ZONES = {
  "EST" => [-5 * 3600, false], "EDT" => [-4 * 3600, true], "EWT" => [-4 * 3600, true], "EPT" => [-4 * 3600, true],
  "CST" => [-6 * 3600, false], "CDT" => [-5 * 3600, true], "CWT" => [-5 * 3600, true], "CPT" => [-5 * 3600, true],
  "MST" => [-7 * 3600, false], "MDT" => [-6 * 3600, true], "MWT" => [-6 * 3600, true], "MPT" => [-6 * 3600, true],
  "PST" => [-8 * 3600, false], "PDT" => [-7 * 3600, true], "PWT" => [-7 * 3600, true], "PPT" => [-7 * 3600, true]
}.freeze
DATE = %r{\A(\d{1,2})/(\d{1,2})/(\d{4})\z}
ZONE = /\A([ECMP][SDWP]T)\z/
HEADER = /\A[A-Z]{2}\z/ # the state code word; the number is a following word
EPOCH_YR = /\A18\d\d\z/  # the 18xx epoch year word on the "Before .. LMT" line

# tsv words for one image: [{x (left), y (top), text}]. y is offset to page coordinates.
def words(img, y_off)
  tsv = Open3.capture2({ "OMP_THREAD_LIMIT" => "1" }, "tesseract", img, "stdout", "--psm", "6", "tsv",
                       err: File::NULL).first
  tsv.each_line.drop(1).filter_map do |l|
    f = l.chomp.split("\t")
    next if f.size < 12
    t = f[11].to_s.strip
    next if t.empty?

    # vertical CENTER (top + height/2): letters and digits have different box tops, so
    # centers group a row's words together far more reliably than tops.
    { x: f[6].to_i, y: f[7].to_i + (f[9].to_i / 2) + y_off, text: t }
  end
end

manifest = JSON.parse(File.read(File.join(render_dir, "crops.json")))
crops = manifest["crops"].sort_by { |c| c["band"] }
all = crops.flat_map { |c| words(File.join(render_dir, c["path"]), c["y"]) }
abort "no words OCR'd in #{render_dir}" if all.empty?

# Column boundaries from the DATE words: their left-x forms `ncols` tight clusters. Take
# the min date-x as the first column edge and the pitch as the span / (ncols-1).
date_xs = all.select { |wd| wd[:text] =~ %r{\A\d{1,2}/\d{1,2}/\d{2,4}\z} }.map { |wd| wd[:x] }.sort
abort "no date words -- not a time-tables page?" if date_xs.size < ncols
lo = date_xs[date_xs.size / 40] # robust min (skip outliers)
hi = date_xs[-date_xs.size / 40 - 1]
pitch = (hi - lo) / (ncols - 1).to_f
# FLOOR, not round: a column's date/time/zone span ~0.7*pitch, so the whole field-group
# must land in one column slot [c*pitch, (c+1)*pitch) -- rounding would kick the zone word
# (rightmost field) up into the next column and shred the rows.
col_of = ->(x) { [[((x - lo) / pitch).floor, 0].max, ncols - 1].min }

# Group each column's words into lines (same y within a tolerance), left-to-right.
LINE_TOL = (pitch * 0.03).clamp(12, 34)
columns = Array.new(ncols) { [] }
all.each { |wd| columns[col_of.call(wd[:x])] << wd }
lines = [] # reading order: column-major, top-to-bottom
columns.each do |cw|
  cw.sort_by! { |wd| [wd[:y], wd[:x]] }
  cur_y = nil
  line = nil
  cw.each do |wd|
    if cur_y.nil? || (wd[:y] - cur_y).abs > LINE_TOL
      lines << line if line
      line = []
      cur_y = wd[:y]
    end
    line << wd[:text]
  end
  lines << line if line
end

# Segment tables at each "Before <18xx> LMT" opener; number sequentially, reconciled with
# any legible "XX # N" header on/just above the opener.
tables = []
cur = nil
lines.each_with_index do |toks, i|
  # An 18xx DATE (the "Before 11/18/1883" opener) marks every table start and appears on
  # no other row -- all transitions are 19xx. This OCRs far more reliably than the word
  # "Before" or "LMT", so key on it.
  is_epoch = toks.any? { |t| t =~ %r{\A\d{1,2}/\d{1,2}/18\d\d\z} }
  if is_epoch
    hdr = nil
    ((i - 2)..i).each do |j|
      next unless lines[j]
      lines[j].each_index { |k| lines[j][k] =~ HEADER && lines[j][k + 1] =~ /\A\d{1,3}\z/ && (hdr = lines[j][k + 1].to_i) }
    end
    cur = { num: (hdr && hdr.positive? ? hdr : (tables.last&.dig(:num) || 0) + 1), rows: [] }
    tables << cur
    next
  end
  next unless cur

  # a row = date word + a zone/US# word somewhere on the line
  di = toks.index { |t| t =~ DATE }
  next unless di

  m = toks[di].match(DATE)
  y, mo, dy = m[3].to_i, m[1].to_i, m[2].to_i
  next unless y.between?(1884, 1970) && mo.between?(1, 12) && dy.between?(1, 31)

  zc = toks.find { |t| t =~ ZONE }
  uni = toks.find { |t| t =~ /\AUS/ } || toks.each_cons(2).find { |a, b| a =~ /US/ && b =~ /\d/ }
  if zc
    off, dst = ZONES[zc]
    cur[:rows] << { at_local: format("%04d-%02d-%02d", y, mo, dy), abbr: zc, off: off, dst: dst, uniform: false }
  elsif uni
    cur[:rows] << { at_local: format("%04d-%02d-%02d", y, mo, dy), abbr: "US#", off: nil, dst: nil, uniform: true }
  end
end

by_num = {}
tables.each { |t| (by_num[t[:num]] ||= []).concat(t[:rows]) }
result = by_num.transform_values { |rows| rows.uniq { |r| r[:at_local] }.sort_by { |r| r[:at_local] } }

out = File.join(render_dir, "ocr_tables.json")
File.write(out, JSON.pretty_generate(result.transform_keys(&:to_s)))
puts "parsed #{result.size} tables (pitch #{pitch.round}px) -> #{out}"
result.sort.each do |num, rows|
  peace = rows.select { |r| r[:dst] }.map { |r| r[:at_local][0, 4].to_i }
              .reject { |y| (1942..1945).cover?(y) || [1918, 1919].include?(y) }.uniq.sort
  resume = peace.find { |y| y >= 1946 }
  puts format("  #%-3d %2d rows  peacetime-DST %-26s %s", num, rows.size, peace.first(9).join(","),
              resume ? "resume #{resume}" : (peace.empty? ? "NO-DST" : ""))
end
