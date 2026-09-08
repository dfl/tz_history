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
    GEOJSON_PATH = File.join(DATA_DIR, "us_historical_zones.geojson")

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
        f = features.select do |feat|
          (feat[:from_date].nil? || iso >= feat[:from_date]) && iso < feat[:until_date] &&
            feat[:bbox].cover?(lon, lat) && point_in_geometry?(lon, lat, feat[:geometry])
        end.min_by { |feat| feat[:priority] }
        f && f[:kind] == "split" ? resolve_split(f, lon, lat) : f
      end

      # A "split" feature covers a county whose towns disagree town-by-town but along
      # a resolvable geographic line (e.g. eastern Custer went Mountain in 1919, the
      # western Salmon-River basin stayed Pacific until Boise's 1923 switch). It embeds
      # the Shanks CITY LISTINGS points; we snap the birth coordinate to the nearest
      # documented town and apply that town's verdict -- an `override` zone, or a
      # `warn` (defer to IANA, keeping the straddle note) when the town matched IANA.
      # This is strictly finer than a whole-county warn and never coarser.
      def resolve_split(f, lon, lat)
        c = nearest_city(f[:cities], lon, lat)
        common = f.merge(kind: nil, zone: nil, shanks: nil, city: c && c[:name])
        if c && c[:zone]
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
                   "follows the Shanks American Atlas, which IANA does not encode here. " \
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
        @features ||= JSON.parse(File.read(GEOJSON_PATH))["features"].map do |f|
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
            note: props["note"],
            from_date: props["from_date"],
            until_date: props["until_date"],
            cities: (props["cities"] || []).map do |c|
              { name: c["name"], lon: c["lon"].to_f, lat: c["lat"].to_f, zone: c["zone"] }
            end,
            geometry: polygons,
            bbox: BoundingBox.new(polygons),
            priority: priority(props["kind"], props["note"])
          }
        end
      end

      # geometry is an array of polygons; each polygon is [outer_ring, *holes].
      def point_in_geometry?(x, y, polygons)
        polygons.any? do |rings|
          in_ring?(x, y, rings.first) && rings.drop(1).none? { |hole| in_ring?(x, y, hole) }
        end
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

      def cover?(x, y)
        x.between?(@minx, @maxx) && y.between?(@miny, @maxy)
      end
    end
  end
end
