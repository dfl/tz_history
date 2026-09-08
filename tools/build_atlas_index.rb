#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/build_atlas_index.rb -- drive tools/build_index.rb across MANY states in
# parallel, deriving each state's CITY-LISTINGS page range from the sorted TIME-TABLE
# page manifest (a state's city pages run from tt+1 to the next state's tt-1). This is
# the full-atlas Phase-1 pass (docs/OCR_NEAREST_CITY_PLAN.md); it shards the mechanical
# render+OCR N-wide. Dev-only.
#
#   ATLAS_PDF=... ruby tools/build_atlas_index.rb [flags]
#     --manifest=tools/atlas_pages.tsv   ST\ttt_page rows (default)
#     --only=ID,IL,IN                    build just these states (default: all in manifest)
#     --jobs=3                           parallel states (default 3; higher IO-contends
#                                        on the ~1GB PDF -- 3-4 is the sweet spot)
#     --max-city-pages=8                 cap a derived range (guards against a bad gap)
#     --dry-run                          print the derived plan, render nothing
#
# The render+OCR is mechanical and parallelises with plain process fan-out -- no LLM
# agents needed here (agents earn their keep at the VISUAL-VERIFY step, one per state,
# which stays a separate gated pass). Output: research/index/<ST>/ (git-ignored).

require "open3"

flags = ARGV.grep(/\A--/).to_h { |a| k, v = a.sub("--", "").split("=", 2); [k, v || true] }
manifest = flags["manifest"] || File.expand_path("atlas_pages.tsv", __dir__)
jobs = (flags["jobs"] || 3).to_i
# Cap a derived city range only as a runaway guard. A real section can be large (PA runs
# ~46 pages, NY ~35), so keep this well above the biggest true section, NOT a tight cap
# (a tight cap silently truncates a state's city listings -- the first-pass bug).
max_city = (flags["max-city-pages"] || 50).to_i
last_page = (flags["last-page"] || 636).to_i # atlas page count; clamp the final state
only = flags["only"] ? flags["only"].split(",").map(&:upcase) : nil
tools = __dir__

# Parse manifest -> [[ST, tt_page], ...] sorted by page, so the next entry's page bounds
# this state's city listings.
entries = File.readlines(manifest)
              .reject { |l| l.strip.empty? || l.start_with?("#") }
              .map { |l| st, pg = l.split(/\s+/); [st.upcase, pg.to_i] }
              .sort_by(&:last)

plan = entries.each_with_index.map do |(st, tt), i|
  next_tt = entries[i + 1]&.last
  first_city = tt + 1
  last_city = next_tt ? next_tt - 1 : tt + max_city
  last_city = [last_city, first_city + max_city - 1].min # cap runaway gaps
  last_city = [last_city, last_page].min                 # never past the atlas end
  { st: st, tt: tt, cities: (first_city..last_city) }
end
plan.select! { |p| only.include?(p[:st]) } if only

# Resumable: skip a state whose index already exists (unless --force), so a re-run after
# an interruption is cheap and doesn't re-render 300-dpi pages it already has.
index_root = File.expand_path("../research/index", __dir__)
unless flags["force"]
  before = plan.size
  plan.reject! { |p| File.exist?(File.join(index_root, p[:st], "cities.json")) }
  skipped = before - plan.size
  puts "skipping #{skipped} already-built state(s) (use --force to rebuild)" if skipped.positive?
end

puts "atlas index plan (#{plan.size} states, #{jobs}-wide):"
plan.each { |p| puts format("  %-3s tt=%-4d cities=%d-%d", p[:st], p[:tt], p[:cities].first, p[:cities].last) }
exit 0 if flags["dry-run"]

# Simple N-wide process pool over build_index.rb (one state each).
require "etc"
queue = plan.dup
running = {}
until queue.empty? && running.empty?
  while running.size < jobs && !queue.empty?
    p = queue.shift
    cmd = ["ruby", File.join(tools, "build_index.rb"), p[:st],
           "--tt=#{p[:tt]}", "--cities=#{p[:cities].first}-#{p[:cities].last}"]
    pid = Process.spawn(*cmd, out: $stdout, err: $stderr)
    running[pid] = p[:st]
    puts ">> started #{p[:st]} (pid #{pid}), #{queue.size} queued"
  end
  pid, status = Process.wait2
  st = running.delete(pid)
  puts "<< finished #{st} (#{status.success? ? 'ok' : 'FAIL'})"
end
puts "atlas index complete: #{plan.size} states -> research/index/"
