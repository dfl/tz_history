# Geographic-separability test for a candidate split county -- testing the ACTUAL zone
# groups a split would create (OVERRIDE-zone towns vs DEFER-zone towns), not just the two
# biggest tables. A valid `split` needs those two groups to occupy distinct regions.
# Usage: ruby analyze_split.rb <state> <defer_tables_csv> <county_num> [<county_num> ...]
#   defer_tables_csv = the tables that DEFER to IANA (everything else is the override
#   zone). e.g. DE: "1" (table 1 = DST/IANA-ok); CO: everything-but-1 defers -> pass the
#   DST tables. Project each town onto the axis joining the two group centroids, threshold
#   at the midpoint, report the fraction correctly classified. >=0.8 & >8km = geographic.
require "json"
st = ARGV[0]
defer = ARGV[1].split(",").map(&:to_i)
cnums = ARGV[2..].map(&:to_i)
idx = JSON.parse(File.read("research/index/#{st}/cities.json"))
cities = idx["cities"]
legend = idx["legend"] || {}

cnums.each do |cn|
  raw = cities.select { |c| c["county_num"] == cn }
  # Reject OCR county#-misassignment outliers: drop towns whose lat/lon is far from the
  # county's MEDIAN center (a few towns get a wrong county# and land in another county).
  med = ->(a) { s = a.sort; s[s.size / 2] }
  mlat = med.call(raw.map { |c| c["lat"] })
  mlon = med.call(raw.map { |c| c["lon"] })
  towns = raw.select { |c| (c["lat"] - mlat).abs < 0.6 && (c["lon"] - mlon).abs < 0.6 }
  dropped = raw.size - towns.size
  next puts("#{st} c#{cn} (#{legend[cn.to_s]}): only #{towns.size} towns") if towns.size < 6

  # Group by the actual split outcome: DEFER-zone (tables in `defer`) vs OVERRIDE-zone.
  gB = towns.select { |c| defer.include?(c["table"]) } # defer
  gA = towns.reject { |c| defer.include?(c["table"]) } # override
  if gA.size < 3 || gB.size < 3
    next puts(format("%s c%-3d %-16s override=%d defer=%d -> not a real split (one side tiny)",
                     st, cn, legend[cn.to_s] || "?", gA.size, gB.size))
  end
  t1 = "OVR"
  t2 = "DEF"
  cA = [gA.sum { |c| c["lat"] } / gA.size, gA.sum { |c| c["lon"] } / gA.size]
  cB = [gB.sum { |c| c["lat"] } / gB.size, gB.sum { |c| c["lon"] } / gB.size]
  # axis A->B; project each town, threshold at midpoint of the two centroids' projections
  ax = [cB[0] - cA[0], cB[1] - cA[1]]
  norm = Math.sqrt((ax[0]**2) + (ax[1]**2))
  next puts("#{st} c#{cn} (#{legend[cn.to_s]}): centroids coincide (not separable)") if norm < 1e-6

  proj = ->(c) { (((c["lat"] - cA[0]) * ax[0]) + ((c["lon"] - cA[1]) * ax[1])) / norm }
  pA = gA.map(&proj)
  pB = gB.map(&proj)
  thr = (pA.sum / pA.size + pB.sum / pB.size) / 2.0
  correct = gA.count { |c| proj.call(c) <= thr } + gB.count { |c| proj.call(c) > thr }
  score = correct.to_f / (gA.size + gB.size)
  sep_km = norm * 111.0 # rough deg->km
  puts format("%s c%-3d %-16s t%s(%d) vs t%s(%d)  sep=%.1fkm  score=%.2f  drop=%d  %s",
              st, cn, legend[cn.to_s] || "?", t1, gA.size, t2, gB.size, sep_km, score, dropped,
              score >= 0.8 && sep_km > 8 ? "<-- GEOGRAPHIC (ship split)" : "interleaved/tight (keep warn)")
end
