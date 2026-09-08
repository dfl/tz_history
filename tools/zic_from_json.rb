#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/zic_from_json.rb -- turn a VISUAL-VERIFIED transition list into a zic source
# under data/shanks/<ST>_<n>.zic, in the exact shape of the hand-authored KY_69/KY_71
# files (a `Zone Shanks/<ST>_<n>` block with a provenance header comment). Dev-only.
#
#   ruby tools/zic_from_json.rb <spec.json>
#
# Input JSON (one object):
#   {
#     "table": "AL_1",
#     "printed_page": 1, "pdf_page": 13, "table_no": 1,
#     "region": "Alabama statewide (dominant table): CST with a real 1941 summer DST",
#     "cross_check": "visual-verified only" | "IANA:America/Kentucky/Louisville",
#     "lmt": "-5:50:36",                       # optional; omit to start at first std offset
#     "lmt_until": "1883 Nov 18 12:00",        # required iff lmt present
#     "transitions": [
#       {"at_local": "1918-03-31 02:00", "off": -21600, "dst": false, "abbr": "CST"},
#       {"at_local": "1941-07-21 02:00", "off": -21600, "dst": true,  "abbr": "CDT"},
#       ... ,
#       {"off": -21600, "dst": false, "abbr": "CST"}   # final row: no at_local (open-ended)
#     ]
#   }
#
# `off` is the STANDARD offset in seconds; `dst` true means a +1:00 daylight save on
# top of it (zic's RULES column becomes "1:00"), so the observed offset is off+3600.
# This mirrors how the KY files encode CDT/CWT: `-6:00  1:00  CDT`.

require "json"

path = ARGV[0] or abort "usage: zic_from_json.rb <spec.json>"
spec = JSON.parse(File.read(path))

ROOT = File.expand_path("../data/shanks", __dir__)

MONTHS = %w[_ Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec].freeze

# "1941-07-21 02:00" -> "1941 Jul 21  2:00" (zic UNTIL syntax; hour un-padded).
def zic_time(at_local)
  date, time = at_local.split(" ")
  y, m, d = date.split("-").map(&:to_i)
  hh, mm = (time || "2:00").split(":")
  format("%d %s %2d %2d:%s", y, MONTHS[m], d, hh.to_i, mm || "00")
end

def hhmmss(seconds)
  sign = seconds.negative? ? "-" : ""
  s = seconds.abs
  format("%s%d:%02d:%02d", sign, s / 3600, (s % 3600) / 60, s % 60).sub(/:00$/, "")
end

table = spec.fetch("table")
lines = []
lines << "# Shanks American Atlas TIME TABLE, #{spec['region']}."
lines << "# Atlas printed p.#{spec['printed_page']} (PDF p.#{spec['pdf_page']}), table ##{spec['table_no']}."
lines << "# A dated transition list re-expressed as a zic source (the reference tzdata"
lines << "# compiler input). Cross-check: #{spec['cross_check']}."
lines << "# Rebuild the compiled TZif with:  rake shanks:build"

rows = []
# Optional leading LMT segment (pre-1883; irrelevant to births but preserved for parity).
if spec["lmt"]
  rows << [spec["lmt"], "-", "LMT", spec.fetch("lmt_until")]
end
spec.fetch("transitions").each do |t|
  std = hhmmss(t.fetch("off"))
  rule = t.fetch("dst") ? "1:00" : "-"
  until_s = t["at_local"] ? zic_time(t["at_local"]) : nil
  rows << [std, rule, t.fetch("abbr"), until_s]
end

# First row carries the `Zone Shanks/<table>` prefix; the rest are continuation lines
# aligned under it, exactly like the KY_69/KY_71 sources.
head = "Zone Shanks/#{table} "
indent = " " * head.length
rows.each_with_index do |(gmtoff, rule, abbr, until_s), i|
  prefix = i.zero? ? head : indent
  line = format("%s%-8s %-4s %-4s", prefix, gmtoff, rule, abbr)
  line = "#{line} #{until_s}" if until_s
  lines << line.rstrip
end

out = File.join(ROOT, "#{table}.zic")
File.write(out, lines.join("\n") + "\n")
puts "wrote #{out} (#{rows.size} segments)"
puts "next: rake shanks:build"
