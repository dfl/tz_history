#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/locate_states.rb -- find where each state begins in the atlas by OCRing the
# CAPS header at the top of each page. The atlas is alphabetical and every page carries
# the state name in large caps at the top; a state's first page is where its name first
# appears. Cheap: render the top strip at low DPI (the header is huge). Dev-only.
#
#   ATLAS_PDF=... ruby tools/locate_states.rb <first_pdf_page> <last_pdf_page> [flags]
#     --dpi=70     low DPI is plenty for the big header caps (fast: full page ~2000px)
#     --frac=0.10  top fraction of the page to OCR
#     --out=DIR    scratch dir for the throwaway strip renders
#
# Prints, per page, the caps tokens found (the state header + any section subhead like
# "CITY LISTINGS" / "TIME TABLES"), and a compact "state -> first page" summary. Use it
# to fill the unknown "TT pg" cells in docs/COVERAGE.md and to seed the index build.
# (The ledger's printed-page column drifts when a state's county section is long -- e.g.
# Georgia's 159-county listing pushes later states several PDF pages; always confirm the
# header, see the memory's "verified page index".)

require "open3"
require "fileutils"
require "tmpdir"

ATLAS_PDF = ENV["ATLAS_PDF"] or abort "set ATLAS_PDF=/path/to/atlas.pdf"
first = Integer(ARGV[0] || "", exception: false) or abort "usage: locate_states.rb <first> <last> [--dpi= --frac=]"
last  = Integer(ARGV[1] || "", exception: false) or abort "usage: locate_states.rb <first> <last> [--dpi= --frac=]"
flags = ARGV.grep(/\A--/).to_h { |a| k, v = a.sub("--", "").split("=", 2); [k, v] }
dpi = (flags["dpi"] || 70).to_i
frac = (flags["frac"] || 0.10).to_f
scratch = flags["out"] || File.join(ENV["SCRATCH"] || Dir.tmpdir, "shanks_locate")
FileUtils.mkdir_p(scratch)

# The 50 state names (+ DC) as they head their atlas sections, upper-cased for matching.
STATES = %w[ALABAMA ALASKA ARIZONA ARKANSAS CALIFORNIA COLORADO CONNECTICUT DELAWARE
            FLORIDA GEORGIA HAWAII IDAHO ILLINOIS INDIANA IOWA KANSAS KENTUCKY LOUISIANA
            MAINE MARYLAND MASSACHUSETTS MICHIGAN MINNESOTA MISSISSIPPI MISSOURI MONTANA
            NEBRASKA NEVADA OHIO OKLAHOMA OREGON PENNSYLVANIA TENNESSEE TEXAS UTAH VERMONT
            VIRGINIA WASHINGTON WISCONSIN WYOMING].freeze
# Multi-word names need their own matching (OCR keeps the space).
MULTI = ["NEW HAMPSHIRE", "NEW JERSEY", "NEW MEXICO", "NEW YORK", "NORTH CAROLINA",
         "NORTH DAKOTA", "RHODE ISLAND", "SOUTH CAROLINA", "SOUTH DAKOTA",
         "WEST VIRGINIA", "DISTRICT OF COLUMBIA"].freeze

def header_caps(img, frac)
  w, h = Open3.capture2("identify", "-format", "%w %h", img).first.split.map(&:to_i)
  strip = "#{img}.hdr.png"
  system("convert", img, "-crop", "#{w}x#{(h * frac).to_i}+0+0", "+repage", strip, err: File::NULL)
  txt = Open3.capture2({ "OMP_THREAD_LIMIT" => "1" }, "tesseract", strip, "stdout", "--psm", "6",
                       err: File::NULL).first
  File.delete(strip) if File.exist?(strip)
  txt.upcase
end

first_page = {}
(first..last).each do |pg|
  prefix = File.join(scratch, "loc#{pg}")
  system("pdftoppm", "-f", pg.to_s, "-l", pg.to_s, "-r", dpi.to_s, "-png", "-gray",
         ATLAS_PDF, prefix, err: File::NULL)
  img = Dir["#{prefix}-*.png"].first or (warn "  pg#{pg}: no render"; next)
  caps = header_caps(img, frac)
  File.delete(img)

  found = MULTI.select { |s| caps.include?(s) } +
          STATES.select { |s| caps.include?(s) && MULTI.none? { |m| m.include?(s) } }
  found.uniq.each { |s| first_page[s] ||= pg }
  tag = found.empty? ? "" : "  <- #{found.uniq.join(', ')}"
  puts format("  pg %-4d %s%s", pg, caps.split("\n").first.to_s.strip[0, 40], tag)
end

puts "\nstate -> first PDF page (in range #{first}..#{last}):"
first_page.sort_by { |_, p| p }.each { |s, p| puts format("  %-22s %d (printed %d)", s, p, p - 12) }
