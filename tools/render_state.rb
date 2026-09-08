#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/render_state.rb -- render one atlas TIME TABLES page to a 150dpi grayscale
# PNG plus N overlapping column-strip crops, ready for OCR (tools/ocr_tables.rb) and
# for visual-verify (a subagent reads the crops). Dev-only; not packaged.
#
#   ruby tools/render_state.rb <pdf_page> [out_dir] [num_columns=6]
#   ATLAS_PDF=/path/to/atlas.pdf ruby tools/render_state.rb 13 /tmp/al 6
#
# Notes (learned from the KY spike, see docs/EXTRACTION.md §2):
# - Atlas is alphabetical; PRINTED page = PDF page - 12; OCR filenames use PDF page.
# - TIME TABLES occupy the top ~45% of the page (6 monospaced `date time ZONE` cols);
#   CITY LISTINGS are below. We render the whole page (city listings needed later for
#   county mapping) but crop the top region into column strips for the table OCR.
# - Render at 150 DPI: 300 makes tesseract choke. `-gray` sharpens the mono text.
# - Column crops OVERLAP into the next column (x1.45) so the trailing ZONE token of a
#   row isn't clipped -- the exact recipe parse_timetable.rb proved on Kentucky.

require "open3"

ATLAS_PDF = ENV["ATLAS_PDF"] or abort "set ATLAS_PDF=/path/to/atlas.pdf"
abort "no such ATLAS_PDF: #{ATLAS_PDF}" unless File.exist?(ATLAS_PDF)

pdf_page = Integer(ARGV[0] || "", exception: false) or
  abort "usage: render_state.rb <pdf_page> [out_dir] [num_columns=6]"
out_dir  = ARGV[1] || File.join(Dir.tmpdir, "shanks_render", "pg#{pdf_page}")
num_cols = (ARGV[2] || 6).to_i

require "tmpdir"
require "fileutils"
FileUtils.mkdir_p(out_dir)

# 1. PDF page -> full-page 150dpi gray PNG. pdftoppm names it <prefix>-<page>.png,
#    zero-padded to the width of the last page number, so glob for the result.
prefix = File.join(out_dir, "page")
ok = system("pdftoppm", "-f", pdf_page.to_s, "-l", pdf_page.to_s,
            "-r", "150", "-png", "-gray", ATLAS_PDF, prefix)
abort "pdftoppm failed for page #{pdf_page}" unless ok
full = Dir[File.join(out_dir, "page-*.png")].max_by { |f| File.mtime(f) }
abort "pdftoppm produced no PNG" unless full
FileUtils.mv(full, (full = File.join(out_dir, "full.png"))) unless File.basename(full) == "full.png"

w, h = Open3.capture2("identify", "-format", "%w %h", full).first.split.map(&:to_i)
table_h = (h * 0.45).to_i # TIME TABLES region; city listings are below it

# 2. Column strips over the table region. Each strip is 1.45 column-widths wide so
#    the ZONE token at the right edge of a column is never clipped.
col_w = w / num_cols
crop_w = (col_w * 1.45).to_i
crops = (0...num_cols).map do |c|
  x = col_w * c
  crop = File.join(out_dir, format("col%d.png", c))
  system("convert", full, "-crop", "#{crop_w}x#{table_h}+#{x}+0", "+repage", crop, err: File::NULL) or
    abort "convert failed for column #{c}"
  crop
end

puts "rendered PDF page #{pdf_page} (printed p.#{pdf_page - 12}) -> #{out_dir}"
puts "  full page : #{full} (#{w}x#{h})"
puts "  table region height: #{table_h}px (top 45%)"
puts "  #{crops.size} column strips: #{crops.map { |f| File.basename(f) }.join(', ')}"
puts "\nnext: ruby tools/ocr_tables.rb #{out_dir}"
