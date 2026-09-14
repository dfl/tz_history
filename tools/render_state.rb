#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/render_state.rb -- render one atlas page to a high-DPI grayscale PNG plus a set
# of OCR-ready crops: N overlapping COLUMN strips, each optionally tiled into vertical
# BANDS. Writes a crops.json manifest that ocr_tables.rb / extract_cities.rb consume, so
# downstream tools never have to re-guess the layout. Dev-only; not packaged.
#
#   ruby tools/render_state.rb <pdf_page> [flags]
#     --dpi=300           render DPI (300 recovers small-caps N/W + MM'SS coords;
#                         150 loses them -- see docs/OCR_NEAREST_CITY_PLAN.md sec 0)
#     --cols=N            column count. Atlas layout is layout-dependent: CITY LISTINGS
#                         are 3 columns, TIME TABLES ~5-6. A wrong count slices through
#                         mid-entry coords. Default 3 (city listings).
#     --top=0.0 --bot=1.0 vertical region to crop, as page-height fractions. TIME TABLES
#                         are the top ~45% (--top=0 --bot=0.45); CITY LISTINGS are the
#                         rest but continue full-page on following pages, so default is
#                         the whole page (extract_cities keys on the coord pattern and
#                         ignores non-city rows, so full-page is safe).
#     --band-h=2400       vertical band height in px. A full-height 300-dpi column
#                         (~12000px) makes tesseract exit 1 with empty output ("300
#                         chokes"); banding fixes it. Set 0 to disable banding.
#     --band-overlap=200  px each band overlaps the next, so a row split by a band edge
#                         still appears whole in one band (dedup removes the repeat).
#     --colw=1.45         column-strip width as a multiple of a bare column, so the
#                         trailing token (ZONE / LMT seconds) of a row isn't clipped.
#     --out=DIR           output dir. Default: scratchpad ($SCRATCH or /tmp)/shanks_ocr.
#                         ALWAYS a scratchpad, NEVER the repo (atlas is copyrighted) and
#                         NEVER a per-call /tmp under the sandbox (crops written in one
#                         step are unreadable in the next -> silent empty OCR).
#
#   ATLAS_PDF=/path/atlas.pdf ruby tools/render_state.rb 122 --cols=3 --out=/scratch/id
#
# Backward compatible with the old positional form for the TIME-TABLE flow:
#   ruby tools/render_state.rb 13 /tmp/al 6   ==   --out=/tmp/al --cols=6 --top=0 --bot=0.45

require "json"
require "open3"
require "fileutils"
require "tmpdir"

ATLAS_PDF = ENV["ATLAS_PDF"] or abort "set ATLAS_PDF=/path/to/atlas.pdf"
abort "no such ATLAS_PDF: #{ATLAS_PDF}" unless File.exist?(ATLAS_PDF)

pdf_page = Integer(ARGV[0] || "", exception: false) or
  abort "usage: render_state.rb <pdf_page> [--dpi= --cols= --top= --bot= --band-h= --out=]"

flags = ARGV.drop(1).grep(/\A--/).to_h { |a| k, v = a.sub("--", "").split("=", 2); [k, v] }
positional = ARGV.drop(1).reject { |a| a.start_with?("--") }

scratch = ENV["SCRATCH"] || Dir.tmpdir
out_dir = flags["out"] || positional[0] || File.join(scratch, "shanks_ocr", "pg#{pdf_page}")
num_cols = (flags["cols"] || positional[1] || 3).to_i
dpi = (flags["dpi"] || 300).to_i
top_frac = (flags["top"] || 0.0).to_f
bot_frac = (flags["bot"] || 1.0).to_f
band_h = (flags["band-h"] || 2400).to_i
band_overlap = (flags["band-overlap"] || 200).to_i
colw_mult = (flags["colw"] || 1.45).to_f

FileUtils.mkdir_p(out_dir)

# 1. PDF page -> full-page grayscale PNG. pdftoppm zero-pads the page number to the
#    width of the last page, so glob for whatever it produced and normalise the name.
prefix = File.join(out_dir, "page")
ok = system("pdftoppm", "-f", pdf_page.to_s, "-l", pdf_page.to_s,
            "-r", dpi.to_s, "-png", "-gray", ATLAS_PDF, prefix)
abort "pdftoppm failed for page #{pdf_page}" unless ok
produced = Dir[File.join(out_dir, "page-*.png")].max_by { |f| File.mtime(f) }
abort "pdftoppm produced no PNG" unless produced
full = File.join(out_dir, "full.png")
FileUtils.mv(produced, full) unless produced == full

w, h = Open3.capture2("identify", "-format", "%w %h", full).first.split.map(&:to_i)
y0 = (h * top_frac).to_i
region_h = (h * (bot_frac - top_frac)).to_i
abort "empty region (top=#{top_frac} bot=#{bot_frac})" if region_h <= 0

# 2. Column boundaries.
#    Default: even page-thirds, each strip widened by colw_mult to catch the coord tail.
#    --autocols: detect the true inter-column GUTTERS from a vertical ink projection so a
#    strip never starts inside its left neighbour (that clip leaks the neighbour's coord
#    tail as a 1-2 char fragment glued to the name -- "J Horton", "A Arabia"). We collapse
#    the region to a 1px-tall grayscale row, find the (num_cols-1) widest bright valleys in
#    the interior, and split there. Boundaries become [0, g1, .., w]; each strip runs to the
#    NEXT gutter (+overlap) so it holds its column's full coords and stops before the next.
def detect_gutters(full, w, y0, region_h, num_cols)
  # Project the city region (not headers) onto a 1px row: bright = whitespace gutter.
  region = "#{w}x#{region_h}+0+#{y0}"
  raw, ok = Open3.capture2("convert", full, "-crop", region, "+repage",
                           "-colorspace", "Gray", "-resize", "#{w}x1!", "-depth", "8", "gray:-")
  return nil unless ok.success? && raw.bytesize == w

  prof = raw.bytes
  # Candidate gutters: columns brighter than the 92nd percentile (near-empty of ink).
  thresh = prof.sort[(prof.size * 0.92).to_i]
  # Group contiguous bright runs into valleys; keep those in the interior 8%..92% band.
  valleys = []
  run = nil
  prof.each_index do |x|
    if prof[x] >= thresh
      run ||= [x, x]
      run[1] = x
    elsif run
      valleys << run
      run = nil
    end
  end
  valleys << run if run
  lo = (w * 0.08).to_i
  hi = (w * 0.92).to_i
  ranges = valleys.select { |a, b| ((a + b) / 2).between?(lo, hi) }
                  .sort_by { |a, b| -(b - a) }             # widest valleys first
                  .first(num_cols - 1)
                  .sort_by(&:first)
  ranges.size == num_cols - 1 ? ranges : nil
end

gutters = flags.key?("autocols") ? detect_gutters(full, w, y0, region_h, num_cols) : nil
if flags.key?("autocols")
  warn gutters ? "autocols: detected gutters at x=#{gutters.map { |a, b| "#{a}..#{b}" }.join(', ')}" \
               : "autocols: detection failed, falling back to even thirds"
end

# Turn gutter RANGES into [left, right] spans per column. Each column overlaps a little
# into the gutter on BOTH sides -- its left starts at the preceding gutter's LEFT edge (so
# a leading letter is never clipped) and its right ends at the following gutter's RIGHT edge
# (so the coord/LMT tail is fully captured). extract_cities dedups the overlap by name+coord.
spans =
  if gutters
    lefts  = [0, *gutters.map(&:first)]
    rights = [*gutters.map(&:last), w]
    (0...num_cols).map do |c|
      left = lefts[c]
      right = rights[c]
      [left, right - left]
    end
  else
    col_w = w / num_cols
    (0...num_cols).map { |c| [col_w * c, [(col_w * colw_mult).to_i, w].min] }
  end

manifest = []
spans.each_with_index do |(x, cw), c|
  # Band start positions: step by (band_h - overlap); a final short band covers the tail.
  step = band_h.positive? ? [band_h - band_overlap, 1].max : region_h
  bands = band_h.positive? ? (0...region_h).step(step).to_a : [0]
  bands.each_with_index do |by, b|
    bh = band_h.positive? ? [band_h, region_h - by].min : region_h
    next if bh <= 0

    crop = File.join(out_dir, format("col%d_band%d.png", c, b))
    geom = "#{cw}x#{bh}+#{x}+#{y0 + by}"
    system("convert", full, "-crop", geom, "+repage", crop, err: File::NULL) or
      abort "convert failed for col #{c} band #{b}"
    manifest << { "col" => c, "band" => b, "path" => File.basename(crop),
                  "x" => x, "y" => y0 + by, "w" => cw, "h" => bh }
  end
end

File.write(File.join(out_dir, "crops.json"),
           JSON.generate({ "pdf_page" => pdf_page, "dpi" => dpi, "cols" => num_cols,
                           "page_w" => w, "page_h" => h, "crops" => manifest }))

puts "rendered PDF page #{pdf_page} (printed p.#{pdf_page - 12}) @ #{dpi}dpi -> #{out_dir}"
puts "  full page : #{full} (#{w}x#{h})"
puts "  region    : y #{y0}..#{y0 + region_h} (#{(top_frac * 100).round}%..#{(bot_frac * 100).round}%)"
puts "  crops     : #{num_cols} cols x #{manifest.size / num_cols.to_f.ceil} bands = #{manifest.size} (see crops.json)"
puts "\nnext: ruby tools/ocr_tables.rb #{out_dir}   OR   ruby tools/extract_cities.rb #{out_dir}"
