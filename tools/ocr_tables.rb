#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/ocr_tables.rb -- OCR the atlas TIME TABLES into a per-table transition list, good
# enough to CLASSIFY tables (no-DST vs DST, and the postwar DST-resumption year) which is
# what the town-level layers need. Still a draft; the crop is the source of truth.
#
#   ruby tools/render_state.rb <pg> --cols=1 --top=0 --bot=0.88 --band-h=2400 --out=DIR
#   ruby tools/ocr_tables.rb DIR [--debug]
#
# RENDER THE WHOLE TABLES BLOCK. The tables run from under the "TIME TABLES" rule down to the
# "COUNTIES" divider -- on a dense state (Maryland: 28 tables in 5 columns) that reaches ~80%
# of the page, NOT 45%. Render with --cols=1 (one full-width strip) and --bot generous
# (0.88). Clipping the region is the single biggest recall killer -- a short region silently
# drops the bottom table of every column. The COUNTIES list and CITY LISTINGS below carry no
# m/d/18xx dates, so an over-long region is harmless; --debug warns if openers reach the floor.
#
# OCR backend: Apple Vision (tools/vision_ocr.swift) when available -- on-device (so the
# copyrighted atlas never leaves the machine) and far higher recall on the faint 1978 print
# than tesseract. Falls back to tesseract otherwise.
#
# Layout handling (TWO PASS -- both passes are load-bearing):
#   Pass 1, full-width bands: DETECT the columns from DATE-token x-clusters (wide gaps =
#     separators; the COUNT is discovered, not assumed) + the header abbr. A full-width band
#     garbles the DENSE middle columns (Vision reads the crowded interior poorly), but it
#     still resolves the coarse column gaps and centred headers, which is all pass 1 needs.
#   Pass 2, per-column NARROW re-crops (banded): OCR each single column cleanly -- this is
#     what recovers the middle columns (a narrow crop reads ~19 dates where the full-width
#     band reads ~1). Within a column, tokens group into ROWS by y; rows segment into TABLES
#     at each OPENER (the union of header/"Before"/LMT/18xx signals, clustered -- robust to a
#     faint header failing to OCR); columns read left-to-right (Shanks order). A header at a
#     column's FLOOR wraps its body to the next column's top -- the wrap-merge stitches them.
#
# STATUS (validated Maryland 28/28, Idaho 18/18): the DST classification of an OUTPUT table
# is accurate. A legible "XX # N" header is authoritative; else "~N" (a positional guess).
# Higher DPI helps and is supported (--dpi=600); all pixel geometry scales with it.
#
# The old design collapsed 28 tables to ~13 for TWO reasons, both fixed: a HARD-CODED top-45%
# content region (clipped the bottom table of every column) and a lossy epoch-only opener.
# Trust an OUTPUT table's DST pattern, treat "~N" as a hint, crop-verify before authoring
# (RUNBOOK: OCR is a draft). Pass 2 re-crops N_cols x N_bands, so a dense page takes ~50s.

require "json"
require "open3"

render_dir = ARGV[0] or abort "usage: ocr_tables.rb <render_dir> [--debug]"
debug = ARGV.include?("--debug")
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
DATEISH = %r{\A\d{1,2}/\d{1,2}/\d{2,4}\z}
EPOCH = %r{\A\d{1,2}/\d{1,2}/18\d\d\z}
ZONE  = /\A([ECMP][SDWP]T)\z/
BEFORE = /\ABefore\b/i
LMT   = /\ALMT\z/

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

# 1. PASS 1 -- full-width bands, used ONLY to locate the columns and the header abbr. A
#    full-width band garbles the DENSE middle columns (Vision reads the crowded interior
#    poorly -- ~1 date where a narrow crop finds ~19), but it still resolves the coarse
#    column x-gaps and the centred "XX" headers, which is all pass 1 needs.
s = (manifest["dpi"] || 300) / 300.0
crops = manifest["crops"].sort_by { |c| c["y"] }
fw = crops.flat_map { |c| tokens(File.join(render_dir, c["path"]), c["y"]) }
abort "no OCR tokens" if fw.empty?

# Columns from date-token x-clusters (gaps > 500px = separators; the COUNT is discovered).
# The boundary sits just BEFORE the next column's first date so a row's ZONE (rightmost
# field, near the gutter) isn't flung into the next column. Geometry scales with DPI.
date_xs = fw.select { |t| t[:text] =~ DATEISH }.map { |t| t[:x] }.sort
abort "no date tokens -- not a time-tables page?" if date_xs.size < 5
seps = date_xs.each_cons(2).select { |a, b| b - a > 500 * s }.map { |_a, b| b - (90 * s).to_i }
w = manifest["page_w"]
bounds = ([0] + seps + [w]).each_cons(2).to_a
line_tol = (24 * s).to_i

# STATE abbr = the most common EXACTLY-two-letter uppercase token (or "XX # N" prefix); this
# is the header abbr (MD/ID/ME/...), and is distinct from zone/"US#" tokens.
abbr_counts = Hash.new(0)
fw.each do |t|
  case t[:text]
  when /\A([A-Z]{2})\z/, /\A([A-Z]{2})\s*#\s*\d+\z/ then abbr_counts[Regexp.last_match(1)] += 1
  end
end
state = abbr_counts.max_by { |_k, v| v }&.first
# The header "XX # N" is SPACED; require the space so it isn't confused with a tight zone
# reference like "ME#1" or "US#2" (Maine tables cite another table's zone as "ME#N", which
# would otherwise be read as a header and mis-number the table).
hdr_re = /\A#{state}\s+#?\s*(\d{1,3})\z/

# 2. PASS 2 -- RE-CROP each detected column NARROW (banded, so Vision isn't downsampling a
#    full-height strip) and OCR the clean single-column crop. This is what recovers the
#    middle columns. Keep each band's tokens SEPARATE per column: overlapping bands read a
#    boundary row twice and the two reads disagree (one often fragments into single chars),
#    so rows are grouped WITHIN a band (internally y-consistent); a fragmented read fails the
#    date+zone test and a duplicated clean read is dropped by the per-table date-dedup later.
full = File.join(render_dir, "full.png")
tmp = File.join(render_dir, "_col.png")
col_bands = Array.new(bounds.size) { [] }
col_tokens = Array.new(bounds.size) { [] }
bounds.each_with_index do |(x0, x1), ci|
  cw = x1 - x0
  crops.each do |c|
    system("magick", full, "-crop", "#{cw}x#{c['h']}+#{x0}+#{c['y']}", "+repage", tmp, err: File::NULL)
    bt = tokens(tmp, c["y"])
    col_bands[ci] << bt
    col_tokens[ci].concat(bt)
  end
end
File.delete(tmp) if File.exist?(tmp)

# 3. Assemble transition ROWS per (column, band): within one band group tokens into rows by
#    y, read date + zone/US# from each, tag with column and y.
trans = []
col_bands.each_with_index do |cbs, ci|
  cbs.each do |bt|
    rows = []
    cur_y = nil
    row = nil
    bt.sort_by { |t| [t[:y], t[:x]] }.each do |t|
      if cur_y.nil? || (t[:y] - cur_y).abs > line_tol
        rows << row if row
        row = []
        cur_y = t[:y]
      end
      row << t
    end
    rows << row if row
    rows.each do |r|
      dt = r.find { |t| t[:text] =~ DATE } or next
      m = dt[:text].match(DATE)
      y, mo, dy = m[3].to_i, m[1].to_i, m[2].to_i
      next unless y.between?(1884, 1970) && mo.between?(1, 12) && dy.between?(1, 31)

      at = format("%04d-%02d-%02d", y, mo, dy)
      if (zt = r.find { |t| t[:text] =~ ZONE })
        off, dst = ZONES[zt[:text]]
        trans << { col: ci, y: dt[:y], at_local: at, abbr: zt[:text], off: off, dst: dst, uniform: false }
      elsif r.any? { |t| t[:text] =~ /\AUS/ }
        trans << { col: ci, y: dt[:y], at_local: at, abbr: "US#", off: nil, dst: nil, uniform: true }
      end
    end
  end
end

# 4. Per column, find each table's OPENER, then bin the transitions between openers; columns
#    left-to-right (a table flows down a column and continues at the next -- Shanks order).
#
#    OPENER = a MULTI-signal event. Every table opens with, within a few lines: the "XX # N"
#    header, a "Before 11/18/18xx" line, an "LMT" zone, and two 18xx dates. Each of those
#    signals only ever appears at a table top (data rows are 1918+ dates with real zones), so
#    the UNION of them, clustered by y, marks the openers ROBUSTLY -- if the faint header
#    fails to OCR, "Before"/"LMT"/the 18xx date still fire. A generous cluster gap groups all
#    of one table's signals while keeping adjacent tables apart (the shortest table is ~8 rows
#    ~= 700px; opener signals span only ~300px from the header). The header, when legible,
#    gives the authoritative number; else the number is positional ("~N").
opener_gap = (350 * s).to_i
tables = []
stage = { cols: bounds.size, col_trans: [], col_tables: [] }
bounds.each_index do |ci|
  col = col_tokens[ci].sort_by { |t| [t[:y], t[:x]] }
  # Transitions in this column, top-to-bottom. (Overlapping bands read some rows twice with
  # the SAME date at nearly the same y; those land in one table's bin and the per-table
  # uniq-by-date below drops the repeat. Do NOT dedup by date here -- every table repeats the
  # same 1918/1919 dates, so a column-wide dedup would collapse distinct tables.)
  col_trans = trans.select { |r| r[:col] == ci }.sort_by { |r| r[:y] }
  stage[:col_trans] << col_trans.size
  # A header sits on its OWN line (above the first data row) with nothing but "XX # N". A data
  # row always carries a TIME ("02:00") -- and often a zone reference like Maine's "ME#1",
  # which must NOT be read as a table number. Flag any line bearing a time/date/zone/US-ref as
  # data (via the time token even when the date OCR failed), so only true header lines number.
  data_line = lambda do |y|
    col.any? do |t|
      (t[:y] - y).abs < line_tol &&
        (t[:text] =~ DATEISH || t[:text] =~ /\A\d{1,2}[:.]\d\d\z/ || t[:text] =~ ZONE || t[:text] =~ /\AUS#/)
    end
  end

  sig = col.select do |t|
    t[:text] =~ EPOCH || t[:text] =~ BEFORE || t[:text] =~ LMT || t[:text] =~ hdr_re
  end
  openers = []
  sig.each do |t|
    if openers.empty? || t[:y] - openers.last[:y1] > opener_gap
      openers << { y0: t[:y], y1: t[:y], toks: [t] }
    else
      openers.last[:y1] = t[:y]
      openers.last[:toks] << t
    end
  end
  # Number each opener from its header, which sits on its own line at (or just above) the
  # opener top -- search that band, skipping data-row lines: a combined "XX # N" token, else a
  # bare number just right of a lone "XX" token.
  openers.each do |op|
    hdrs = col.select { |t| t[:y] >= op[:y0] - opener_gap && t[:y] <= op[:y1] && !data_line.call(t[:y]) }
    num = hdrs.filter_map { |t| t[:text][hdr_re, 1]&.to_i }.find(&:positive?)
    if num.nil? && (st = hdrs.find { |t| t[:text] == state })
      n = col.find { |t| (t[:y] - st[:y]).abs < line_tol && t[:x] > st[:x] && t[:text] =~ /\A\d{1,3}\z/ }
      num = n[:text].to_i if n
    end
    op[:num] = num&.positive? ? num : nil
  end
  ys = openers.map { |op| op[:y0] }
  openers.each_with_index do |op, oi|
    hi = ys[oi + 1] || Float::INFINITY
    rows = col_trans.select { |r| r[:y] >= op[:y0] && r[:y] < hi }
    tables << { hdr: op[:num], col: ci, y: op[:y0], rows: rows }
  end
  stage[:col_tables] << openers.size
end

# Keep EVERY detected table in column-major (Shanks) order.
tables.each { |t| t[:rows] = t[:rows].uniq { |r| r[:at_local] }.sort_by { |r| r[:at_local] } }

# COLUMN WRAP: when a table's "XX # N" header lands at the very bottom of a column, its body
# wraps to the TOP of the next column -- so we see an empty header-only table (the header,
# no rows) immediately followed in column-major order by a headerless table WITH rows (the
# wrapped body). They are one table: move the number onto the body and drop the empty header.
merged = []
tables.each do |t|
  prev = merged.last
  if prev && prev[:hdr] && prev[:rows].empty? && t[:hdr].nil? && t[:rows].any?
    t[:hdr] = prev[:hdr]
    merged[-1] = t
  else
    merged << t
  end
end
tables = merged

# The legible "XX # N" header gives the authoritative number; where it's missing the position
# is only a hint ("~N"). (Merging by a fabricated sequential number collapsed distinct tables
# -- don't.)
seq = 0
tables.each { |t| seq = t[:hdr] || (seq + 1); t[:label] = t[:hdr] ? t[:hdr].to_s : "~#{seq}" }
result = tables.map { |t| [t[:label], t[:rows]] }

out = File.join(render_dir, "ocr_tables.json")
File.write(out, JSON.pretty_generate(result.to_h))
headered = tables.count { |t| t[:hdr] }
puts "parsed #{tables.size} tables (#{headered} header-numbered) in #{bounds.size} columns " \
     "via #{HAVE_VISION ? 'Vision' : 'tesseract'} -> #{out}"

if debug
  col_all = col_tokens.flatten
  region_bot = col_all.map { |t| t[:y] }.max || 0
  epoch_ys = col_all.select { |t| t[:text] =~ EPOCH }.map { |t| t[:y] }
  warn "  [debug] pass1 full-width tokens #{fw.size}; pass2 per-column tokens #{col_all.size}; " \
       "transitions #{trans.size}; 18xx openers #{epoch_ys.size}; state #{state.inspect} (#{abbr_counts[state]}x)"
  warn "  [debug] columns #{bounds.size}: #{bounds.map { |x0, x1| "#{x0}..#{x1}" }.join('  ')}"
  bounds.each_index do |ci|
    warn "  [debug]   col#{ci}: #{stage[:col_trans][ci]} transitions -> #{stage[:col_tables][ci]} tables"
  end
  last_opener = epoch_ys.max || 0
  if region_bot - last_opener < (400 * s)
    warn "  [debug] !! last opener (y=#{last_opener}) is near the region floor (y=#{region_bot}) -- " \
         "a table may be clipped; re-render with a larger --bot."
  end
end

tables.each do |t|
  peace = t[:rows].select { |r| r[:dst] }.map { |r| r[:at_local][0, 4].to_i }
                  .reject { |y| (1942..1945).cover?(y) || [1918, 1919].include?(y) }.uniq.sort
  resume = peace.find { |y| y >= 1946 }
  puts format("  %-5s %2d rows  peacetime-DST %-24s %s", t[:label], t[:rows].size, peace.first(8).join(","),
              resume ? "resume #{resume}" : (peace.empty? ? "NO-DST" : ""))
end
