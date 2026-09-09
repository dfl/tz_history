#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/ocr_tables.rb -- OCR the atlas TIME TABLES into a per-table transition list, good
# enough to CLASSIFY tables (no-DST vs DST, and the postwar DST-resumption year) which is
# what the town-level layers need. Still a draft; the crop is the source of truth.
#
#   ruby tools/render_state.rb <pg> --cols=1 --top=0 --bot=0.45 --band-h=2400 --out=DIR
#   ruby tools/ocr_tables.rb DIR
#
# OCR backend: Apple Vision (tools/vision_ocr.swift) when available -- on-device (so the
# copyrighted atlas never leaves the machine) and far higher recall on the faint 1978 print
# than tesseract (24 vs 15 of Maryland's 26 tables). Falls back to tesseract otherwise.
#
# Layout handling: the dense N-column tables have no gutter at a fixed w/N, so we DETECT the
# columns from the DATE tokens' x-clusters (wide gaps = separators; the COUNT is discovered,
# not assumed -- Maryland is 5 columns, Idaho 6). Each OCR token (date/time/zone) is a
# separate box; we assign it to a column by x, group a column's tokens into ROWS by y, and
# read columns in flow order (a table flows down a column, continues at the next). Every
# table opens with an 18xx epoch date, which segments them; the "XX # N" header sets the
# number when legible, else it increments.
#
# STATUS (validated on Maryland + Idaho): for the tables it OUTPUTS, the DST classification
# is accurate -- Baltimore's continuous DST, MD #6=1947 / #7=1948 resumptions, Idaho's 1961
# resumers + 1930s pre-war DST. A table whose "XX # N" header is legible is labelled with
# that number (authoritative); otherwise it's "~N" (a positional guess -- crop-verify).
# Higher DPI helps and is supported (--dpi=600); all pixel geometry scales with it.
#
# KNOWN LIMIT: recall is ~50-60% of tables. This is NOT an OCR-recall problem any more --
# Vision sees ~all the "Before 18xx" openers in a raw scan -- it's the token->row->table
# RECONSTRUCTION (column assignment + row grouping) dropping tables. Closing that is a
# pipeline task, not an OCR one. So: trust the DST pattern of an OUTPUT table, treat "~N"
# numbers as hints, and crop-verify before authoring (RUNBOOK: OCR is a draft).

require "json"
require "open3"

render_dir = ARGV[0] or abort "usage: ocr_tables.rb <render_dir>"
manifest = JSON.parse(File.read(File.join(render_dir, "crops.json")))
VISION = File.expand_path("vision_ocr.swift", __dir__)
HAVE_VISION = system("which", "swift", out: File::NULL, err: File::NULL) && File.exist?(VISION)

ZONES = {
  "EST" => [-5 * 3600, false], "EDT" => [-4 * 3600, true], "EWT" => [-4 * 3600, true], "EPT" => [-4 * 3600, true],
  "CST" => [-6 * 3600, false], "CDT" => [-5 * 3600, true], "CWT" => [-5 * 3600, true], "CPT" => [-5 * 3600, true],
  "MST" => [-7 * 3600, false], "MDT" => [-6 * 3600, true], "MWT" => [-6 * 3600, true], "MPT" => [-6 * 3600, true],
  "PST" => [-8 * 3600, false], "PDT" => [-7 * 3600, true], "PWT" => [-7 * 3600, true], "PPT" => [-7 * 3600, true]
}.freeze
DATE  = %r{\A(\d{1,2})/(\d{1,2})/(\d{4})\z}
EPOCH = %r{\A\d{1,2}/\d{1,2}/18\d\d\z}
ZONE  = /\A([ECMP][SDWP]T)\z/
HEADER = /\A[A-Z]{2}\z/

# Per band -> tokens [{x, y (vertical center, page coords), text}]. Vision gives box coords
# (origin top-left); tesseract tsv gives left/top/height.
def tokens(img, y_off)
  if HAVE_VISION
    Open3.capture2("swift", VISION, img).first.each_line.filter_map do |l|
      f = l.chomp.split("\t")
      next if f.size < 5

      { x: f[1].to_i, y: f[2].to_i + (f[4].to_i / 2) + y_off, text: f[0].strip }
    end
  else
    Open3.capture2({ "OMP_THREAD_LIMIT" => "1" }, "tesseract", img, "stdout", "--psm", "6", "tsv",
                   err: File::NULL).first.each_line.drop(1).filter_map do |l|
      f = l.chomp.split("\t")
      next if f.size < 12 || f[11].to_s.strip.empty?

      { x: f[6].to_i, y: f[7].to_i + (f[9].to_i / 2) + y_off, text: f[11].strip }
    end
  end
end

# 1. First pass: locate the columns from date-token x-clusters (gaps > 500px = separators;
#    the COUNT is discovered, not assumed). Boundary sits just BEFORE the next column's
#    first date so a row's ZONE (rightmost field, in the gutter) isn't clipped off.
crops = manifest["crops"].sort_by { |c| c["band"] }
first = crops.flat_map { |c| tokens(File.join(render_dir, c["path"]), c["y"]) }
abort "no OCR tokens" if first.empty?
date_xs = first.select { |t| t[:text] =~ %r{\A\d{1,2}/\d{1,2}/\d{2,4}\z} }.map { |t| t[:x] }.sort
abort "no date tokens -- not a time-tables page?" if date_xs.size < 5
# All pixel geometry scales with DPI (higher DPI => bigger image => bigger gaps), so the
# column-gap threshold, the zone margin, and the row tolerance are all relative to it.
s = (manifest["dpi"] || 300) / 300.0
seps = date_xs.each_cons(2).select { |a, b| b - a > 500 * s }.map { |_a, b| b - (90 * s).to_i }
w = manifest["page_w"]
region_h = (manifest["page_h"] * 0.45).to_i
bounds = ([0] + seps + [w]).each_cons(2).to_a

# 2. CROP each real column (banded -- a full-height 300dpi column degrades OCR at the
#    bottom) and OCR the clean single-column crop. Group its tokens into ROWS by y. A table
#    flows down a column and continues at the next's top, so read columns in order.
line_tol = (24 * s).to_i
band = (2400 * s).to_i
tmp = File.join(render_dir, "_col.png")
lines = []
full = File.join(render_dir, "full.png")
bounds.each do |x0, x1|
  cw = x1 - x0
  (0...region_h).step(band - (200 * s).to_i) do |y0|
    bh = [band, region_h - y0].min
    next if bh <= 0

    system("magick", full, "-crop", "#{cw}x#{bh}+#{x0}+#{y0}", "+repage", tmp, err: File::NULL)
    toks = tokens(tmp, y0).sort_by { |t| [t[:y], t[:x]] }
    cur_y = nil
    row = nil
    toks.each do |t|
      if cur_y.nil? || (t[:y] - cur_y).abs > line_tol
        lines << row if row
        row = []
        cur_y = t[:y]
      end
      row << t[:text]
    end
    lines << row if row
  end
end
File.delete(tmp) if File.exist?(tmp)

# Segment tables at each epoch date; number from a legible header else increment.
tables = []
cur = nil
last_epoch = -99
lines.each_with_index do |toks, i|
  # The "Before 11/18/1883" opener AND the "11/18/1883 12:00 EST" first row both carry the
  # 18xx date (adjacent lines); dedup so each table starts once, not twice.
  if toks.any? { |t| t =~ EPOCH } && i - last_epoch > 2
    last_epoch = i
    hdr = nil
    ((i - 2)..i).each do |j|
      next unless lines[j]

      lines[j].each_index { |k| lines[j][k] =~ HEADER && lines[j][k + 1] =~ /\A\d{1,3}\z/ && (hdr = lines[j][k + 1].to_i) }
    end
    cur = { hdr: (hdr&.positive? ? hdr : nil), rows: [] }
    tables << cur
    next
  end
  next unless cur

  di = toks.index { |t| t =~ DATE } or next
  m = toks[di].match(DATE)
  y, mo, dy = m[3].to_i, m[1].to_i, m[2].to_i
  next unless y.between?(1884, 1970) && mo.between?(1, 12) && dy.between?(1, 31)

  if (zt = toks.find { |t| t =~ ZONE })
    off, dst = ZONES[zt]
    cur[:rows] << { at_local: format("%04d-%02d-%02d", y, mo, dy), abbr: zt, off: off, dst: dst, uniform: false }
  elsif toks.any? { |t| t =~ /\AUS/ }
    cur[:rows] << { at_local: format("%04d-%02d-%02d", y, mo, dy), abbr: "US#", off: nil, dst: nil, uniform: true }
  end
end

# Keep EVERY detected table in detection order (a table flows down a column then continues
# at the next, so this is Shanks order). The legible "XX # N" header gives the authoritative
# number; where it's missing the position is only a hint. Merging by a fabricated sequential
# number was collapsing distinct tables -- don't.
tables.each { |t| t[:rows] = t[:rows].uniq { |r| r[:at_local] }.sort_by { |r| r[:at_local] } }
seq = 0
tables.each { |t| seq = t[:hdr] || (seq + 1); t[:label] = t[:hdr] ? t[:hdr].to_s : "~#{seq}" }
result = tables.map { |t| [t[:label], t[:rows]] }

out = File.join(render_dir, "ocr_tables.json")
File.write(out, JSON.pretty_generate(result.to_h))
headered = tables.count { |t| t[:hdr] }
puts "parsed #{tables.size} tables (#{headered} header-numbered) in #{bounds.size} columns " \
     "via #{HAVE_VISION ? 'Vision' : 'tesseract'} -> #{out}"
tables.each do |t|
  peace = t[:rows].select { |r| r[:dst] }.map { |r| r[:at_local][0, 4].to_i }
                  .reject { |y| (1942..1945).cover?(y) || [1918, 1919].include?(y) }.uniq.sort
  resume = peace.find { |y| y >= 1946 }
  puts format("  %-5s %2d rows  peacetime-DST %-24s %s", t[:label], t[:rows].size, peace.first(8).join(","),
              resume ? "resume #{resume}" : (peace.empty? ? "NO-DST" : ""))
end
