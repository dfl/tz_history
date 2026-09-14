# frozen_string_literal: true

require "json"

module TzHistory
  # Point-in-polygon resolution of a (lat, lon, date) against the county-polygon
  # dataset. US zone boundaries follow COUNTY lines and neighbouring regions
  # interleave along irregular borders (East Tennessee ran Central until 1946-1949
  # while the West North Carolina counties abutting it were always Eastern), so a
  # bounding box cannot separate them -- we ray-cast against the actual polygons.
  #
  # data/us_historical_zones.geojson is a FeatureCollection of county polygons
  # (public-domain US Census boundaries). A feature is one of two kinds:
  # "override" carries the historical zone the county actually observed (a flat
  # IANA `zone`, or a `shanks` transition-list table id); "warn" carries only a
  # note for a contested boundary we deliberately do NOT correct (flag, don't
  # silently guess -- the Olson/Terran-Atlas principle).
  module Lookup
    # US county-polygon corpus plus the international country-polygon corpus (Shanks
    # International Atlas). Features share one schema and one lookup path; the two
    # datasets are geographically disjoint, so concatenation order is immaterial.
    GEOJSON_PATHS = [
      File.join(DATA_DIR, "us_historical_zones.geojson"),
      File.join(DATA_DIR, "intl_historical_zones.geojson")
    ].freeze

    # Coastline tolerance (degrees, ~2.8 km) for the INTERNATIONAL country-polygon
    # overrides ONLY. Exact ray-cast point-in-polygon against Natural Earth's coastline
    # drops cities that sit a km or two seaward of the drawn line -- Copenhagen falls
    # 1.24 km outside even the 10m coast, Luleaa 1.2 km. Because open sea separates these
    # countries, we accept a point that is strictly inside OR within this tolerance of the
    # polygon edge. The US county corpus tiles continuously (no sea gaps, borders shared
    # by two different-zone counties), so it keeps tol = 0 -- an exact test, unchanged.
    # Cost: only a few-km rural strip can leak across a LAND border to a neighbour that
    # itself defers to IANA (e.g. Denmark's short Jutland border with Germany); documented
    # in docs/INTL_COVERAGE.md. Islands farther out (Tromso 3.8 km) still defer -> Phase 2.
    INTL_COAST_TOL = 0.025

    # Friendly labels for the US zones we substitute.
    ZONE_LABELS = {
      "America/Chicago" => "Central", "America/New_York" => "Eastern",
      "America/Denver" => "Mountain", "America/Los_Angeles" => "Pacific"
    }.freeze

    class << self
      # The matching feature (override or warn), or nil. When a point+date matches
      # more than one feature, an EXCLUSION GUARD (a note-less warn over an area
      # IANA already models) always wins (tier 0); among all other features array
      # order is the editorial tie-break (tier 1). `min_by` returns the first
      # feature of the lowest tier, so array order is preserved within a tier.
      def lookup(lat:, lon:, date:)
        return nil unless lat && lon && date

        iso = date.is_a?(String) ? date : date.strftime("%Y-%m-%d")
        lon = lon.to_f
        lat = lat.to_f
        coslat = Math.cos(lat * Math::PI / 180)
        f = features.select do |feat|
          (feat[:from_date].nil? || iso >= feat[:from_date]) && iso < feat[:until_date] &&
            feat[:bbox].cover?(lon, lat, feat[:tol]) &&
            point_in_geometry?(lon, lat, feat[:geometry], feat[:tol], coslat)
        end.min_by { |feat| feat[:priority] }
        f && f[:kind] == "split" ? resolve_split(f, lon, lat, iso) : f
      end

      # A "split" feature covers a county whose towns disagree town-by-town but along
      # a resolvable geographic line (e.g. eastern Custer went Mountain in 1919, the
      # western Salmon-River basin stayed Pacific until Boise's 1923 switch). It embeds
      # the Shanks CITY LISTINGS points; we snap the birth coordinate to the nearest
      # documented town and apply that town's verdict. A town carries ONE OF: a `sched`
      # (a list of [from, until, zone] segments -- a per-town date-ranged schedule, for
      # cohort-nest states where a town kept standard time only in certain year spans; the
      # segment covering the birth date wins, else defer); a flat `zone` (a fixed offset,
      # e.g. Etc/GMT+7); a `shanks` transition-table id (a full zic history); or none of
      # these, meaning it matched IANA and we `warn`/defer. This is how city-specific
      # overrides complement IANA town by town where a county-majority override can't.
      def resolve_split(f, lon, lat, iso = nil)
        c = nearest_city(f[:cities], lon, lat)
        common = f.merge(kind: nil, zone: nil, shanks: nil, city: c && c[:name])
        seg = iso && c && c[:sched]&.find { |s| (s[0].nil? || iso >= s[0]) && iso < s[1] }
        if seg
          common.merge(kind: "override", zone: seg[2])
        elsif c && c[:shanks]
          common.merge(kind: "override", shanks: c[:shanks])
        elsif c && c[:zone]
          common.merge(kind: "override", zone: c[:zone])
        else
          common.merge(kind: "warn") # nearest town matched IANA -> defer, keep the note
        end
      end

      # Nearest by equirectangular distance (cos-lat corrected); fine at county scale.
      def nearest_city(cities, lon, lat)
        return nil unless cities&.any?

        k = Math.cos(lat * Math::PI / 180)
        cities.min_by { |c| ((lat - c[:lat])**2) + (((lon - c[:lon]) * k)**2) }
      end

      # A human-readable verify prompt for the matched region, or nil.
      def note(lat:, lon:, date:)
        f = lookup(lat:, lon:, date:)
        return nil unless f
        return f[:note] unless f[:kind] == "override"

        base = if f[:shanks]
                 "This location's early clock history (through ~#{f[:until_date][0, 4]}) " \
                   "follows the Shanks #{f[:atlas]} Atlas, which IANA does not encode here. " \
                   "Applied the historical zone -- verify the birth record."
               elsif f[:from_date]
                 "This location kept standard time (no daylight saving) around " \
                   "#{f[:from_date][0, 4]}-#{f[:until_date][0, 4]}, which IANA does not encode here. " \
                   "Applied historical standard time -- verify the birth record."
               else
                 label = ZONE_LABELS[f[:zone]] || f[:zone]
                 "This location observed #{label} time before ~#{f[:until_date][0, 4]}, which IANA " \
                   "does not encode (it uses the modern zone). Applied the historical zone -- " \
                   "verify the birth record."
               end
        base = "#{base} #{f[:note]}" if f[:note] && !f[:note].empty?
        f[:city] ? "#{base} (Resolved via the nearest documented town, #{f[:city]}.)" : base
      end

      # An exclusion guard is a `warn` with no note: it exists only to block an
      # overlapping override where IANA is already correct. Guards win outright
      # (tier 0); everything else defers to array order (tier 1).
      def priority(kind, note)
        kind == "warn" && (note.nil? || note.empty?) ? 0 : 1
      end

      # Parsed once. Each feature precompiles to its rings plus a bounding box for
      # a cheap first-pass reject.
      def features
        @features ||= GEOJSON_PATHS.select { |p| File.exist?(p) }.flat_map do |path|
          JSON.parse(File.read(path))["features"]
        end.map do |f|
          polygons = case f.dig("geometry", "type")
                     when "Polygon" then [f["geometry"]["coordinates"]]
                     when "MultiPolygon" then f["geometry"]["coordinates"]
                     else []
                     end
          props = f["properties"]
          {
            kind: props["kind"],
            zone: props["zone"],
            shanks: props["shanks"],
            atlas: props["atlas"] || "American",
            note: props["note"],
            from_date: props["from_date"],
            until_date: props["until_date"],
            cities: (props["cities"] || []).map do |c|
              { name: c["name"], lon: c["lon"].to_f, lat: c["lat"].to_f,
                zone: c["zone"], shanks: c["shanks"], sched: c["sched"] }
            end,
            geometry: polygons,
            bbox: BoundingBox.new(polygons),
            priority: priority(props["kind"], props["note"]),
            # International Atlas country overrides get a coastline tolerance; the US
            # county corpus (atlas "American") stays exact.
            tol: (props["atlas"] == "International" ? INTL_COAST_TOL : 0.0)
          }
        end
      end

      # geometry is an array of polygons; each polygon is [outer_ring, *holes]. `tol`
      # (>0 only for intl overrides) accepts a point within `tol` degrees of the outer
      # ring -- see INTL_COAST_TOL. `coslat` corrects longitude degrees to ~equal metres.
      def point_in_geometry?(x, y, polygons, tol = 0.0, coslat = 1.0)
        strict = polygons.any? do |rings|
          in_ring?(x, y, rings.first) && rings.drop(1).none? { |hole| in_ring?(x, y, hole) }
        end
        return true if strict
        return false unless tol.positive?

        tol2 = tol * tol
        polygons.any? { |rings| min_edge_dist2(x, y, rings.first, coslat) <= tol2 }
      end

      # Squared distance (in cos-lat-corrected degrees) from (x,y) to the nearest edge
      # of a ring -- how far a just-offshore point sits from the drawn coastline.
      def min_edge_dist2(x, y, ring, coslat)
        best = Float::INFINITY
        j = ring.length - 1
        ring.each_index do |i|
          d = seg_dist2(x, y, ring[i], ring[j], coslat)
          best = d if d < best
          j = i
        end
        best
      end

      # Squared point-to-segment distance, longitude scaled by coslat so degrees are
      # ~isometric in metres at this latitude.
      def seg_dist2(px, py, a, b, k)
        ax = a[0] * k; ay = a[1]
        bx = b[0] * k; by = b[1]
        qx = px * k; qy = py
        dx = bx - ax; dy = by - ay
        return ((qx - ax)**2) + ((qy - ay)**2) if dx.zero? && dy.zero?

        t = (((qx - ax) * dx) + ((qy - ay) * dy)) / ((dx * dx) + (dy * dy))
        t = 0.0 if t < 0
        t = 1.0 if t > 1
        ((qx - (ax + t * dx))**2) + ((qy - (ay + t * dy))**2)
      end

      # Ray-casting point-in-polygon on a ring of [lon, lat] pairs.
      def in_ring?(x, y, ring)
        inside = false
        j = ring.length - 1
        ring.each_index do |i|
          xi, yi = ring[i]
          xj, yj = ring[j]
          inside = !inside if (yi > y) != (yj > y) && x < ((xj - xi) * (y - yi) / (yj - yi)) + xi
          j = i
        end
        inside
      end
    end

    class BoundingBox
      def initialize(polygons)
        pts = polygons.flat_map(&:first)
        xs = pts.map(&:first)
        ys = pts.map(&:last)
        @minx, @maxx = xs.minmax
        @miny, @maxy = ys.minmax
      end

      # `margin` (degrees) widens the box so a point within the coastline tolerance of
      # an edge still passes this cheap first-pass reject (intl overrides pass tol > 0).
      def cover?(x, y, margin = 0.0)
        x.between?(@minx - margin, @maxx + margin) && y.between?(@miny - margin, @maxy + margin)
      end
    end
  end
end
