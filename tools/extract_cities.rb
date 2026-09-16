#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/extract_cities.rb -- extract the Shanks CITY LISTINGS index (name, county#,
# table#, lat, lon) from the banded column crops produced by tools/render_state.rb.
# This is the coordinate source that feeds the nearest-city `split` feature
# (Lookup#resolve_split) and cross-checks tools/map_counties.rb. Dev-only.
#
#   ruby tools/extract_cities.rb <render_dir> [more_dirs...] [--out=cities.json] [--legend]
#
# Each CITY LISTINGS row is:   Name  county#  table#  LAT  LON  LMT
#   e.g.  "Bayhorse 19 18 44n23'52 114w18'39 7:37:15"
#         -> {name:"Bayhorse", county_num:19, table:18, lat:44.398, lon:-114.311}
# where LAT = DD[N]MM['SS], LON = DDD[W]MM['SS], and the trailing LMT = H:MM:SS is the
# local-mean-time offset = longitude x 240s -- a built-in cross-check we use to repair a
# mangled longitude (LMT digits OCR far more reliably than the fused DDD w MM'SS token).
#
# Two OCR realities the parser must survive (docs/OCR_NEAREST_CITY_PLAN.md sec 0):
#  - WRAP: a long name pushes its coords onto the NEXT line ("Aberdeen Junction 6" then
#    "16 43N13'23 112w28'12"). We walk a flat TOKEN STREAM per column, not lines, so a
#    line break is just whitespace and a record spanning two lines still parses.
#  - BLEED: the 1.45x-wide column strip captures the neighbouring column's left edge, so
#    a fragmentary record (a name with clipped coords) trails each real one. It lacks a
#    full LAT+LON pair, so it never forms a record; and its own column parses it whole.
#
# OCR coordinate fusions handled: l->1, O->0, S->5, B->8 inside digits; N/n and W/w/S
# hemispheres; apostrophe present/absent; a fused 4-digit MMSS minute+second token.

require "json"
require "open3"

# OCR backend: Apple Vision (tools/vision_ocr.swift) when --vision is passed -- on-device
# (so the copyrighted atlas never leaves the machine) and far higher recall on the faint
# 1978 print than tesseract, which systematically misreads 2-digit table numbers as "1".
# Default (no --vision) stays tesseract, unchanged. Mirrors ocr_tables.rb's HAVE_VISION guard.
VISION = File.expand_path("vision_ocr.swift", __dir__)
HAVE_VISION = system("which", "swift", out: File::NULL, err: File::NULL) && File.exist?(VISION)

dirs = ARGV.reject { |a| a.start_with?("--") }
abort "usage: extract_cities.rb <render_dir> [more_dirs...] [--out=] [--legend] [--max-table=N] [--counties=FIPS.json]" if dirs.empty?
flags = ARGV.grep(/\A--/).to_h { |a| k, v = a.sub("--", "").split("=", 2); [k, v || true] }
want_legend = flags.key?("legend")

# --- County# repair (majority-learned) --------------------------------------------------
# The per-city county# OCRs less reliably than the coordinates (which are 300-dpi + repaired
# from the LMT column). A stray digit misread ("39" for "9") or a whole-column bleed can land
# an impossible county#. When a county-FIPS geojson is supplied (--counties, or COUNTIES_GEOJSON),
# we repair the OUTLIERS as follows: (1) point-in-polygon each town to its true county FIPS;
# (2) LEARN this state's Shanks numbering from the data -- for each real county, the county# the
# MAJORITY of its towns carry IS that county's number; (3) repair only the minority towns whose
# county# disagrees with their county's majority. This learns the atlas's own numbering (so it
# is correct for independent-city / renamed-county states like NV/VA/MD/MO, where a naive
# alphabetical rank would be wrong) and never shifts a correctly-numbered majority.
def in_ring?(x, y, ring)
  inside = false
  j = ring.length - 1
  ring.each_index do |i|
    xi, yi = ring[i]; xj, yj = ring[j]
    inside = !inside if (yi > y) != (yj > y) && x < ((xj - xi) * (y - yi) / (yj - yi)) + xi
    j = i
  end
  inside
end

def load_county_polys(path)
  polys = {}; bboxes = {}
  JSON.parse(File.read(path)).fetch("features").each do |f|
    fips = f["id"].to_s
    g = f["geometry"]
    pl = g["type"] == "Polygon" ? [g["coordinates"]] : g["coordinates"]
    polys[fips] = pl
    pts = pl.flat_map(&:first)
    xs = pts.map(&:first); ys = pts.map(&:last)
    bboxes[fips] = [xs.min, ys.min, xs.max, ys.max]
  end
  [polys, bboxes]
end

def fips_for(lon, lat, polys, bboxes)
  bboxes.each do |fips, (minx, miny, maxx, maxy)|
    next unless lon.between?(minx, maxx) && lat.between?(miny, maxy)

    return fips if polys[fips].any? { |rings| in_ring?(lon, lat, rings.first) && rings.drop(1).none? { |h| in_ring?(lon, lat, h) } }
  end
  nil
end

# Repair county# outliers in-place over a rows array, learning per-county numbering from the
# majority. Returns [repaired_count, unresolved_count].
def repair_county_nums!(rows, polys, bboxes)
  rows.each { |r| r["_fips"] = (r["lat"] && r["lon"]) ? fips_for(r["lon"].to_f, r["lat"].to_f, polys, bboxes) : nil }
  fips_to_num = {}
  rows.group_by { |r| r["_fips"] }.each do |fips, ts|
    next unless fips

    num, support = ts.map { |r| r["county_num"] }.tally.max_by { |_n, s| s }
    fips_to_num[fips] = num if support >= 2 # need >=2 agreeing towns to trust a county's number
  end
  repaired = 0; unresolved = 0
  rows.each do |r|
    fips = r.delete("_fips")
    if fips.nil? then unresolved += 1; next end

    target = fips_to_num[fips]
    if target && target != r["county_num"]
      r["county_num"] = target
      repaired += 1
    end
  end
  [repaired, unresolved]
end

counties_path = flags["counties"] || (flags.key?("counties") ? nil : ENV["COUNTIES_GEOJSON"])
$county_polys = $county_bboxes = nil
if counties_path && File.exist?(counties_path)
  $county_polys, $county_bboxes = load_county_polys(counties_path)
  warn "county# repair: loaded #{$county_polys.size} county polygons from #{counties_path}"
end
# The per-city table# is captured by looking back from the LAT+LON pair. When a bled
# fragment from the neighbouring column shifts the token stream, that look-back can grab
# the LATITUDE's degree (Maine towns are 43-47N -> spurious table# 44/45/47) instead of
# the real table#. A state has only so many tables; --max-table=N rejects any record
# whose table# exceeds N as a bleed misparse (0 = no cap, unchanged for other states).
$max_table = (flags["max-table"] || 0).to_i

# --vision routes OCR through Apple Vision instead of tesseract. Vision returns positioned
# tokens ("text\tx\ty\tw\th", origin TOP-left) rather than joined lines, so we reconstruct
# line-oriented text the parser expects: cluster observations into rows by similar y (row
# gap ~ token height), sort each row left-to-right by x, join with spaces, rows top-to-bottom.
$use_vision = flags.key?("vision")
abort "--vision requested but swift/vision_ocr.swift unavailable" if $use_vision && !HAVE_VISION

# BLEED clip (vision only): the colw>1 strip captures the neighbouring column's left edge, so
# each row picks up a faint name-only fragment of the next column at the far right ("Altamor"
# after Abanaka's LMT). Tesseract barely reads that sliver, but Vision reads it cleanly and the
# fragment then prepends to the NEXT town's name (a spurious 2-word name that dodges dedup) or
# shifts the table# look-back. A city column's rightmost REAL content is its coord/LMT tokens;
# the bleed sits in the gutter beyond them. So clip per crop at the right edge of the rightmost
# coord/LMT observation (+margin): bleed name-fragments carry no coord pattern and always land
# further right, so this drops them without touching any real token.
COORDISH = /\d:\d\d:\d\d|\d[wWnNsS]\d|\d[wWnNsS]['`’]/

def ocr_vision(img)
  obs = Open3.capture2("swift", VISION, img).first.each_line.filter_map do |l|
    f = l.chomp.split("\t")
    next if f.size < 5

    { text: f[0].strip, x: f[1].to_i, y: f[2].to_i, w: f[3].to_i, h: f[4].to_i }
  end
  return "" if obs.empty?

  coordish = obs.select { |o| o[:text] =~ COORDISH }
  unless coordish.empty?
    clip_x = coordish.map { |o| o[:x] + o[:w] }.max + 60
    obs.reject! { |o| o[:x] >= clip_x } # drop neighbour-column bleed fragments in the gutter
  end
  return "" if obs.empty?

  # Cluster into rows: sort by y, start a new row when the vertical gap exceeds half the
  # local token height (rows are ~1 line apart; tokens within a row share a baseline).
  obs.sort_by! { |o| o[:y] }
  rows = []
  cur = []
  cur_y = nil
  obs.each do |o|
    tol = [o[:h] / 2, 8].max
    if cur_y && (o[:y] - cur_y).abs > tol
      rows << cur
      cur = []
    end
    cur << o
    cur_y = o[:y]
  end
  rows << cur unless cur.empty?
  rows.map { |r| r.sort_by { |o| o[:x] }.map { |o| o[:text] }.join(" ") }.join("\n")
end

def ocr(img)
  return ocr_vision(img) if $use_vision

  Open3.capture2({ "OMP_THREAD_LIMIT" => "1" }, "tesseract", img, "stdout", "--psm", "6",
                 err: File::NULL).first
end

# Fix the digit-lookalikes OCR emits inside a numeric field.
def digits(str)
  str.tr("lLoOsSBIiZ|", "110055881120")
end

# A latitude token "42n27'21" / "38Nn36" / "44N04" -> decimal degrees (North +).
LAT_RE = /\A(\d{1,2})[NnMm]+([\d'`’o ]*)\z/
# A longitude token "112w34'03" / "85wl19" / "116w52'26" -> decimal degrees (West -).
LON_RE = /\A(\d{1,3})[WwSs]+([\d'`’o ]*)\z/

# Parse the minute[/second] tail after the hemisphere letter into fractional degrees.
# The tail is one of: "" , "MM" , "MM'SS" , "MMSS" (fused), with OCR punctuation noise.
def frac(tail)
  t = digits(tail).gsub(/[^\d']/, "")
  return 0.0 if t.empty?

  if t.include?("'")
    mm, ss = t.split("'", 2)
    m = mm.to_i
    s = ss.to_s[0, 2].to_i
  elsif t.length <= 2
    m = t.to_i
    s = 0
  else # fused MMSS (or MMS) with the apostrophe dropped
    m = t[0, 2].to_i
    s = t[2, 2].to_i
  end
  return nil if m > 59 || s > 59

  (m + s / 60.0) / 60.0
end

def parse_lat(tok)
  m = tok.match(LAT_RE) or return nil
  f = frac(m[2]) or return nil
  d = m[1].to_i
  return nil unless d.between?(24, 50) # CONUS latitudes

  d + f
end

def parse_lon(tok)
  m = tok.match(LON_RE) or return nil
  f = frac(m[2]) or return nil
  d = m[1].to_i
  return nil unless d.between?(66, 125) # CONUS longitudes

  -(d + f)
end

# LMT "7:30:16" -> longitude degrees (West, negative). 1 deg = 240s. Very reliable.
def lon_from_lmt(tok)
  m = tok.match(/\A(\d{1,2}):(\d{2}):(\d{2})\z/) or return nil
  secs = (m[1].to_i * 3600) + (m[2].to_i * 60) + m[3].to_i
  return nil unless secs.between?(60 * 240, 125 * 240)

  -(secs / 240.0)
end

# Walk a flat token stream, emitting one record per LAT+LON pair. Around the pair:
#   [ name-words... ] county# table# LAT LON [LMT]
def parse_stream(tokens)
  rows = []
  i = 0
  while i < tokens.length - 1
    lat = parse_lat(tokens[i])
    lon = parse_lon(tokens[i + 1])
    unless lat && lon
      i += 1
      next
    end
    # Look back for the integer column(s) before the lat. Two layouts:
    #   multi-table states:  Name county# table# LAT LON   ("Arbon 39 18 42n27'21 ..")
    #   single-table states: Name county#        LAT LON   ("Hunt 64 34n57 ..") -- when a
    #     state has ONE table the atlas drops the per-city table# column, so only county#
    #     precedes the lat and the table is implicitly 1.
    int1 = tokens[i - 1]&.match(/\A\d{1,3}\z/) && tokens[i - 1].to_i
    int2 = tokens[i - 2]&.match(/\A\d{1,3}\z/) && tokens[i - 2].to_i
    if int1&.positive? && int2&.positive? # county# table#
      cnum = int2
      tnum = int1
      name_end = i - 3
    elsif int1&.positive? # county# only -> single-table state, table = 1
      cnum = int1
      tnum = 1
      name_end = i - 2
    else
      i += 2
      next
    end
    # Reject a bleed misparse: a table# above the state's real table count is the
    # latitude degree that leaked into the table slot (see $max_table). Drop the record
    # -- the real town is captured cleanly in its own column.
    if $max_table.positive? && tnum > $max_table
      i += 3
      next
    end
    # Most Shanks town names are 1-2 words ("American Falls", "Arbon PO"); cap the
    # walk-back at 2 so a stray bled name-token from the neighbouring column can't
    # prepend itself to the real name.
    name_toks = []
    j = name_end
    while j >= 0 && name_toks.size < 2 && tokens[j] !~ /\A\d/ && tokens[j] =~ /[A-Za-z]/
      name_toks.unshift(tokens[j].gsub(/[^A-Za-z.'()\-]/, ""))
      j -= 1
    end
    # Strip a leading bleed fragment: when a neighbouring column's coord tail clips into the
    # strip it OCRs as a junk token ("J", "et", "-lOVUO") that prepends to the real name.
    # With correct gutters (render_state --autocols) this is rare, but catch the residue:
    # drop a leading token that is a single letter, or starts lowercase / non-letter, ONLY
    # when a real Capitalized name-word follows -- never touch legit 2-char caps (Le/La/Mc/
    # Mt/St) or a lone single-word name.
    if name_toks.size == 2 && name_toks[1] =~ /\A[A-Z][a-z]/ &&
       name_toks[0] !~ /\A(?:Le|La|Mc|Mac|Mt|St|De|Du|El|Van|New|Old|Big|Ft|Fort|Port)\z/ &&
       (name_toks[0].length <= 2 || name_toks[0] =~ /\A[^A-Z]/ || name_toks[0] =~ /[A-Z][a-z]*[A-Z]/)
      name_toks.shift
    end
    name = name_toks.join(" ").strip
    # Title-case an all-lowercase name: OCR sometimes lowercases a real town's initial
    # ("springfield" -> "Springfield", "troy" -> "Troy"). Mixed-case names are left alone.
    name = name.split.map { |wd| wd =~ /\A[a-z]+\z/ ? wd.capitalize : wd }.join(" ") if name == name.downcase
    # Drop the one unambiguous OCR-garble shape: a lone-letter "name" ("J", "f") left by a
    # coord-tail bleed. Everything else is kept -- real names carry legitimate internal caps
    # (McArthur, DeForest, La Rue) that no case/vowel heuristic can tell from garble, and the
    # residual multi-letter blobs ("hs die") are harmless deferred nearest-town points.
    garble = name =~ /\A[A-Za-z]\z/
    # Repair longitude from the highly-reliable LMT column when they disagree.
    lmt_lon = lon_from_lmt(tokens[i + 2].to_s)
    conf = "ok"
    if lmt_lon
      if (lmt_lon - lon).abs > 0.05
        lon = lmt_lon
        conf = "lon<-lmt"
      end
    else
      conf = "no-lmt"
    end
    rows << { "name" => name, "county_num" => cnum, "table" => tnum,
              "lat" => lat.round(4), "lon" => lon.round(4), "conf" => conf } unless name.empty? || garble
    i += 3
  end
  rows
end

# The COUNTY# -> name legend (on the TIME TABLES page, below the tables) is rows of
# "<num> <Name>" pairs, often two per line: "6 Bingham 17 Clark". Grab every
# num+CapWord(s) pair. Skip CITY-LISTINGS lines (they carry a coord token and are long)
# so running this over a page that also holds city rows can't pollute the legend.
LEGEND_PAIR = /(\d{1,3})\s+([A-Z][A-Za-z.'\-]+(?:\s[A-Z][A-Za-z.'\-]+)?)/
COORD_TOKEN = /\d[NnWwSs]\d|\d[NnWwSs]['`’]/

def parse_legend(text)
  legend = {}
  text.each_line do |line|
    next if line =~ COORD_TOKEN || line.split.size > 8 # a city row, not a legend row

    line.scan(LEGEND_PAIR) do |num, name|
      n = num.to_i
      legend[n] ||= name.strip if n.between?(1, 300) && name.split.size <= 3
    end
  end
  legend
end

# --dump-text=FILE preserves the raw per-crop OCR (a facts-derived artifact, no atlas image)
# so the parse can be re-run/audited without re-rendering from the copyrighted PDF. Same
# "===CROP <path>===" section format as research/index/<ST>/tt_ocr_cols.txt.
dump_path = flags["dump-text"]
dump = [] if dump_path

# Cache OCR per crop so a --dump-text run OCRs each crop exactly once (the same call also
# feeds the parser below).
ocr_cache = {}
ocr_once = lambda do |f|
  ocr_cache[f] ||= ocr(f).tap do |txt|
    dump << "===CROP #{File.basename(File.dirname(f))}/#{File.basename(f)}===\n#{txt}" if dump
  end
end

all_rows = []
legend = {}
dirs.each do |dir|
  manifest_path = File.join(dir, "crops.json")
  crops = if File.exist?(manifest_path)
            m = JSON.parse(File.read(manifest_path))
            m["crops"].sort_by { |c| [c["col"], c["band"]] }.map { |c| File.join(dir, c["path"]) }
          else
            Dir[File.join(dir, "col*_band*.png")].sort
          end
  abort "no crops in #{dir} (run render_state.rb first)" if crops.empty?

  # Group crops by column; walk each column's bands as one token stream so a record that
  # straddles a band boundary still parses (the ~200px band overlap guarantees it appears
  # whole in at least one band; cross-band dedup by name+coord removes the repeat).
  by_col = crops.group_by { |f| File.basename(f)[/col(\d+)/, 1].to_i }
  by_col.each_value do |col_crops|
    text = col_crops.map { |f| ocr_once.call(f) }.join("\n")
    legend = legend.merge(parse_legend(text)) { |_k, a, _b| a } if want_legend
    tokens = text.split(/\s+/)
    all_rows.concat(parse_stream(tokens))
  end
end

if dump_path
  File.write(dump_path, dump.join("\n"))
  warn "dump-text: wrote #{dump.size} crop OCR sections -> #{dump_path}"
end

# Repair county# outliers (majority-learned) when a county-FIPS geojson was supplied.
# Runs before dedup so the dedup key uses the corrected county#.
if $county_polys
  repaired, unresolved = repair_county_nums!(all_rows, $county_polys, $county_bboxes)
  warn "county# repair: corrected #{repaired} outlier(s) of #{all_rows.size} rows " \
       "(#{unresolved} coords outside any county polygon)"
end

# Dedup: same town listed once. OCR + band overlap repeat rows; keep the highest-conf
# copy (an LMT-agreeing longitude beats a repaired or LMT-less one).
CONF_RANK = { "ok" => 0, "lon<-lmt" => 1, "no-lmt" => 2 }.freeze
best = {}
all_rows.each do |r|
  key = [r["name"].downcase, r["county_num"], r["table"]]
  cur = best[key]
  best[key] = r if cur.nil? || CONF_RANK[r["conf"]] < CONF_RANK[cur["conf"]]
end
rows = best.values.sort_by { |r| r["name"].downcase }

out = flags["out"] || File.join(dirs.first, "cities.json")
payload = { "cities" => rows }
payload["legend"] = legend if want_legend
File.write(out, JSON.generate(payload))

by_conf = rows.group_by { |r| r["conf"] }.transform_values(&:size)
puts "extracted #{rows.size} cities from #{dirs.size} page(s) -> #{out}"
puts "  confidence: #{by_conf.map { |k, v| "#{k}=#{v}" }.join('  ')}"
puts "  legend entries: #{legend.size}" if want_legend
puts "  sample:"
rows.first(6).each { |r| puts format("    %-22s c%-3d t%-3d %8.4f %9.4f  [%s]", r["name"], r["county_num"], r["table"], r["lat"], r["lon"], r["conf"]) }
