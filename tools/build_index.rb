#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/build_index.rb -- build (or refresh) the git-ignored research index for ONE
# state: its TIME-TABLE transition drafts, its CITY LISTINGS coordinate index, and its
# county-number legend. One state per run, so the full-atlas pass shards trivially
# across `xargs -P` or parallel agents (Phase 1 of docs/OCR_NEAREST_CITY_PLAN.md).
#
#   ATLAS_PDF=... ruby tools/build_index.rb <ST> --tt=<pdf_page> --cities=<first>-<last>
#     --out=research/index   (default; git-ignored -- see .gitignore, atlas is copyrighted)
#     --keep-png             keep the heavy renders (default: only the JSON is kept)
#
#   ruby tools/build_index.rb ID --tt=122 --cities=123-127
#
# Outputs research/index/<ST>/:
#   timetables.json  {tables:{ID_2:[...]}, ...}   (from tools/ocr_tables.rb -- a DRAFT)
#   cities.json      {cities:[{name,county_num,table,lat,lon,conf}], legend:{n=>name}}
#   meta.json        provenance: pages, dpi, counts, so a consumer knows what it has
#
# The render PNGs are scratch-only (huge, copyrighted); only the derived JSON persists.
# OCR remains a DRAFT: authoring a zone/feature still passes the visual-verify gate.

require "json"
require "open3"
require "fileutils"
require "tmpdir"

st = ARGV[0]&.upcase
abort "usage: build_index.rb <ST> --tt=<page> --cities=<first>-<last> [--out= --keep-png]" unless st && st =~ /\A[A-Z]{2}\z/
flags = ARGV.grep(/\A--/).to_h { |a| k, v = a.sub("--", "").split("=", 2); [k, v || true] }

root = File.expand_path("..", __dir__)
tools = File.join(root, "tools")
out_root = flags["out"] || File.join(root, "research", "index")
out_dir = File.join(out_root, st)
FileUtils.mkdir_p(out_dir)
scratch = File.join(ENV["SCRATCH"] || Dir.tmpdir, "shanks_index", st)
FileUtils.mkdir_p(scratch)

def run(*cmd)
  out, ok = Open3.capture2e(*cmd)
  warn out unless ok.success?
  [out, ok.success?]
end

meta = { "state" => st, "dpi" => 300, "built_pages" => [] }

# 1. TIME TABLES (top ~45%, ~6 columns) -> ocr_tables draft.
if (tt = flags["tt"])
  dir = File.join(scratch, "tt#{tt}")
  run("ruby", File.join(tools, "render_state.rb"), tt.to_s,
      "--cols=6", "--top=0", "--bot=0.45", "--colw=1.45", "--out=#{dir}")
  run("ruby", File.join(tools, "ocr_tables.rb"), dir)
  tj = File.join(dir, "ocr_tables.json")
  FileUtils.cp(tj, File.join(out_dir, "timetables.json")) if File.exist?(tj)
  meta["tt_page"] = tt.to_i
  meta["built_pages"] << tt.to_i
end

# 2. CITY LISTINGS (full page, 3 columns, tight colw to cut neighbour-column bleed) ->
#    extract_cities over ALL city pages at once (one alphabetical stream).
if (spec = flags["cities"])
  a, b = spec.to_s.split(/[-.]+/).map(&:to_i)
  b ||= a
  city_dirs = (a..b).map do |pg|
    dir = File.join(scratch, "city#{pg}")
    run("ruby", File.join(tools, "render_state.rb"), pg.to_s,
        "--cols=3", "--colw=1.15", "--out=#{dir}")
    meta["built_pages"] << pg
    dir
  end
  run("ruby", File.join(tools, "extract_cities.rb"), *city_dirs,
      "--out=#{File.join(out_dir, 'cities.json')}")
  meta["city_pages"] = (a..b).to_a
end

# The COUNTY# -> name legend sits below the TIME TABLES on the state's first page (the
# --tt page), NOT among the city listings. OCR that page whole (150 dpi is plenty and
# doesn't choke tesseract) single-column: --psm 6 reads each physical legend line across
# both legend columns ("6 Bingham 17 Clark"), which is exactly what parse_legend wants.
if (tt = flags["tt"]) && File.exist?(File.join(out_dir, "cities.json"))
  lp = File.join(scratch, "legend#{tt}")
  FileUtils.mkdir_p(lp)
  system("pdftoppm", "-f", tt.to_s, "-l", tt.to_s, "-r", "150", "-png", "-gray",
         ENV["ATLAS_PDF"], File.join(lp, "p"), err: File::NULL)
  png = Dir[File.join(lp, "p-*.png")].first
  if png
    text = Open3.capture2({ "OMP_THREAD_LIMIT" => "1" }, "tesseract", png, "stdout", "--psm", "6",
                          err: File::NULL).first
    legend = {}
    text.each_line do |line|
      next if line =~ /\d[NnWwSs]\d/ || line.split.size > 8

      line.scan(/(\d{1,3})\s+([A-Z][A-Za-z.'\-]+(?:\s[A-Z][A-Za-z.'\-]+)?)/) do |num, name|
        n = num.to_i
        legend[n] ||= name.strip if n.between?(1, 300) && name.split.size <= 3
      end
    end
    cj = JSON.parse(File.read(File.join(out_dir, "cities.json")))
    cj["legend"] = legend
    File.write(File.join(out_dir, "cities.json"), JSON.generate(cj))
  end
end

# Provenance + quick counts.
if File.exist?(File.join(out_dir, "cities.json"))
  cj = JSON.parse(File.read(File.join(out_dir, "cities.json")))
  meta["city_count"] = cj["cities"].size
  meta["legend_count"] = (cj["legend"] || {}).size
  meta["counties_seen"] = cj["cities"].map { |c| c["county_num"] }.uniq.sort
end
if File.exist?(File.join(out_dir, "timetables.json"))
  meta["table_count"] = JSON.parse(File.read(File.join(out_dir, "timetables.json"))).size
end
File.write(File.join(out_dir, "meta.json"), JSON.pretty_generate(meta))

FileUtils.rm_rf(scratch) unless flags["keep-png"]

puts "index[#{st}] -> #{out_dir}"
puts "  cities: #{meta['city_count']}  legend: #{meta['legend_count']}  " \
     "tables: #{meta['table_count']}  counties: #{meta['counties_seen']&.size}"
