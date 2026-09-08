# frozen_string_literal: true

# Compile every Shanks TIME TABLE (data/shanks/*.zic) into a synthetic TZif zone
# under data/shanks/zoneinfo/, using zic -- the reference tzdata compiler that
# IANA itself ships. TzHistory::Zone then resolves the synthetic zone with the
# same TZInfo machinery it uses for real IANA zones. The compiled TZif blobs are
# committed so the gem has no runtime dependency on zic; re-run this whenever a
# .zic source changes:
#
#   rake shanks:build      # or: ruby tasks/build_shanks_zoneinfo.rb

ROOT = File.expand_path("../data/shanks", __dir__)
OUT  = File.join(ROOT, "zoneinfo")
ZIC  = ENV["ZIC"] || "zic"

sources = Dir[File.join(ROOT, "*.zic")]
abort "no .zic sources in #{ROOT}" if sources.empty?

sources.each do |src|
  puts "zic #{File.basename(src)}"
  system(ZIC, "-d", OUT, src) or abort "zic failed for #{src}"
end

compiled = Dir[File.join(OUT, "Shanks", "*")]
puts "built #{compiled.size} synthetic zone(s):"
compiled.each { |f| puts "  Shanks/#{File.basename(f)} (#{File.size(f)} bytes)" }
