# frozen_string_literal: true

require "zlib"

module TzHistory
  # TOWN-LEVEL clock-history resolution from the Shanks American Atlas (independently
  # derived; facts only -- coordinates and
  # clock-change dates are not copyrightable, Feist / Astrolabe v. Olson). Where the
  # county-polygon layer (Lookup) can only assign a county-majority zone, the atlas
  # resolves finer than county: neighbouring towns ~20 km apart routinely carry
  # DIFFERENT time-change tables (downstate Illinois splits 72% of 25 km cells). This
  # layer snaps a birth coordinate to its nearest documented ACS town and applies that
  # town's exact transition history.
  #
  # Each town maps to a synthetic zone id ("A0667") whose full pre-1970 transition
  # sequence was compiled to TZif by zic (see research; data/acs/zoneinfo/ACS/), so it
  # resolves through the same TZInfo machinery as every real IANA zone -- spring-forward
  # gaps, fall-back overlaps and DST alternation all handled. IANA is authoritative from
  # 1970, so this layer only corrects dates BEFORE the cutover.
  module Acs
    POINTS_PATH  = File.join(DATA_DIR, "acs", "points.csv.gz")
    ZONEINFO_DIR = File.join(DATA_DIR, "acs", "zoneinfo")

    # IANA guarantees local observance only since 1970; before it, a coordinate's
    # modern zone can be historically wrong. We correct strictly before this instant.
    CUTOVER = "1970-01-01"

    # ACS time-change tables begin at US railroad standard time (noon 1883-11-18) and
    # carry no local-mean-time era, so zic extends each town's first standard offset
    # back forever. On or before this date defer to IANA, which models LMT.
    STANDARD_TIME = "1883-11-18"

    # Beyond this, the nearest ACS town is too far to speak for the birthplace (open
    # water, offshore, or outside the atlas's US coverage) -- defer to the polygon/IANA
    # path. The atlas is dense (157k towns) so any US mainland birth resolves well under this.
    MAX_KM = 40.0

    EMPTY = [].freeze

    class << self
      # The nearest ACS town to (lat, lon): { name:, lat:, lon:, zone_id:, iana:, km: },
      # or nil if none within MAX_KM. Uses a 1-degree grid so only a handful of candidate
      # towns are distance-tested per query.
      def nearest(lat, lon)
        load!
        best = nil
        best_d2 = Float::INFINITY
        k = Math.cos(lat * Math::PI / 180)
        cell_of(lat.floor, lon.floor).each do |gi, gj|
          (@grid[[gi, gj]] || EMPTY).each do |idx|
            dlat = lat - @lats[idx]
            dlon = (lon - @lons[idx]) * k
            d2 = (dlat * dlat) + (dlon * dlon)
            if d2 < best_d2
              best_d2 = d2
              best = idx
            end
          end
        end
        return nil unless best

        km = Math.sqrt(best_d2) * 111.195
        return nil if km > MAX_KM

        { name: @names[best], lat: @lats[best], lon: @lons[best],
          zone_id: @zone_ids[best], iana: @ianas[best], km: km.round(2) }
      end

      # The town-layer TZInfo::Timezone for a birth, or nil when out of range or on/after
      # the 1970 cutover (where IANA is authoritative). Returns the atlas town's exact
      # historical zone -- correct by construction, so unlike Lookup it does not return
      # nil to mean "IANA is already right": a non-nil result is simply the ACS answer.
      def zone(lat:, lon:, date:)
        r = resolve(lat: lat, lon: lon, date: date)
        r && r[:zone]
      end

      # The town-layer CORRECTION for a birth: the resolution, but ONLY when the town's
      # observed offset differs from its MODERN IANA zone on that date -- i.e. only where
      # IANA (which assigns the modern zone to all history) actually gets this birth
      # wrong. nil when the town agrees with IANA, is out of range, or is on/after the
      # 1970 cutover. This is the drop-in for Lookup's override role: same "nil means IANA
      # is already right" contract, resolved at the town level.
      def correction(lat:, lon:, date:)
        r = resolve(lat: lat, lon: lon, date: date)
        r && r[:diverges] ? r : nil
      end

      # The full resolution for the nearest in-range town, or nil when out of range or
      # on/after the cutover: { zone:, iana_zone:, diverges:, city:, km:, zone_id:, iana:,
      # iso: }. `zone` is the ACS TZInfo::Timezone; `iana_zone` its modern IANA baseline;
      # `diverges` is true when the two observe different offsets on `date`.
      def resolve(lat:, lon:, date:)
        return nil unless lat && lon && date

        iso = date.is_a?(String) ? date : date.strftime("%Y-%m-%d")
        return nil unless iso < CUTOVER && iso > STANDARD_TIME

        n = nearest(lat.to_f, lon.to_f)
        return nil unless n

        tz = Zone.from(ZONEINFO_DIR, "ACS/#{n[:zone_id]}")
        return nil unless tz

        iana = iana_tz(n[:iana])
        { zone: tz, iana_zone: iana, diverges: diverges?(tz, iana, iso), city: n[:name],
          km: n[:km], zone_id: n[:zone_id], iana: n[:iana], iso: iso }
      end

      private

      # Do the ACS zone and its modern IANA baseline observe different offsets at noon
      # on `iso`? (noon avoids spring-forward gap / fall-back overlap ambiguity.)
      def diverges?(acs_zone, iana_zone, iso)
        return false unless iana_zone

        noon = Time.utc(iso[0, 4].to_i, iso[5, 2].to_i, iso[8, 2].to_i, 12)
        acs_zone.period_for_local(noon, true).observed_utc_offset !=
          iana_zone.period_for_local(noon, true).observed_utc_offset
      end

      # Memoized modern IANA baseline zone for a town (its tzao.plist Olson name).
      def iana_tz(name)
        return nil if name.nil? || name.empty?

        (@iana_cache ||= {}).fetch(name) { @iana_cache[name] = TZInfo::Timezone.get(name) }
      end

      # The 3x3 block of grid cells around (gi, gj) -- a town in an adjacent cell can be
      # the nearest one when the query sits near a cell edge.
      def cell_of(gi, gj)
        out = []
        (-1..1).each { |di| (-1..1).each { |dj| out << [gi + di, gj + dj] } }
        out
      end

      def load!
        return if @grid

        names = []
        lats = []
        lons = []
        zone_ids = []
        ianas = []
        grid = Hash.new { |h, key| h[key] = [] }
        # Hand-parsed (no `csv`, which is no longer a Ruby default gem): the five
        # columns are name,lat,lon,zone_id,iana and only the name can contain a comma,
        # so split off the last four fields from the right and keep the rest as the name.
        Zlib::GzipReader.open(POINTS_PATH) do |gz|
          first = true
          gz.each_line do |line|
            if first
              first = false
              next
            end
            rest, iana = line.chomp.rpartition(",").values_at(0, 2)
            rest, zid = rest.rpartition(",").values_at(0, 2)
            rest, lon = rest.rpartition(",").values_at(0, 2)
            name, _, lat = rest.rpartition(",")
            idx = names.length
            latf = lat.to_f
            lonf = lon.to_f
            names << name
            lats << latf
            lons << lonf
            zone_ids << zid
            ianas << iana
            grid[[latf.floor, lonf.floor]] << idx
          end
        end
        @names = names
        @lats = lats
        @lons = lons
        @zone_ids = zone_ids
        @ianas = ianas
        @grid = grid
      end
    end
  end
end
