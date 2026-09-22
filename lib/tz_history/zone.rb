# frozen_string_literal: true

module TzHistory
  # Loads a synthetic Shanks TIME TABLE zone -- a pre-1970 US sub-state clock
  # history the IANA/Olson database deliberately omits -- as a TZInfo::Timezone.
  #
  # The hard part is done offline: each Shanks table is compiled into a real TZif
  # file (the on-disk format IANA ships) by zic, the reference tzdata compiler --
  # see tasks/build_shanks_zoneinfo.rb -- and committed under data/shanks/zoneinfo/
  # Shanks/. Here we merely read that TZif with TZInfo's own zoneinfo reader, so
  # wall-clock resolution (spring-forward gaps, fall-back overlaps, DST
  # alternation) runs through the exact same battle-tested code path as every real
  # IANA zone. Unlike a flat Etc/GMT+N offset, a transition list can hold a real
  # seasonal DST alternation (e.g. northern KY's 1920-1926 daylight summers).
  module Zone
    ZONEINFO_DIR = File.join(DATA_DIR, "shanks", "zoneinfo")

    class << self
      # `table` is a Shanks table id like "KY_71". Returns a memoized
      # TZInfo::Timezone named "Shanks/KY_71", or nil if no such table.
      def tzinfo(table)
        cache.fetch("Shanks/#{table}") { cache["Shanks/#{table}"] = build(ZONEINFO_DIR, "Shanks/#{table}") }
      end

      # Build (memoized) a TZInfo::Timezone for any synthetic zone we compile with
      # zic, given the zoneinfo root and the "<Namespace>/<id>" identifier (the
      # relative TZif path under that root). Used by the ACS town layer, which ships
      # its own zoneinfo tree under data/acs/zoneinfo/ACS/. Returns nil if absent.
      def from(zoneinfo_dir, identifier)
        cache.fetch(identifier) { cache[identifier] = build(zoneinfo_dir, identifier) }
      end

      private

      def cache
        @cache ||= {}
      end

      def build(zoneinfo_dir, identifier)
        path = File.join(zoneinfo_dir, identifier)
        return nil unless File.exist?(path)

        zoneinfo = reader.read(path)
        info = if zoneinfo.is_a?(TZInfo::TimezoneOffset)
                 data_sources.const_get(:ConstantOffsetDataTimezoneInfo).new(identifier, zoneinfo)
               else
                 data_sources.const_get(:TransitionsDataTimezoneInfo).new(identifier, zoneinfo)
               end
        TZInfo::DataTimezone.new(info)
      end

      # A single reusable low-level TZif reader. These TZInfo classes are internal
      # (the public ZoneinfoDataSource insists on a full zoneinfo directory with
      # iso3166.tab/zone1970.tab, which we don't ship), so we drive the reader
      # directly -- the same object ZoneinfoDataSource uses under the hood.
      def reader
        @reader ||= begin
          deduper = TZInfo.const_get(:StringDeduper).new
          parser = data_sources.const_get(:PosixTimeZoneParser).new(deduper)
          data_sources.const_get(:ZoneinfoReader).new(parser, deduper)
        end
      end

      def data_sources
        TZInfo::DataSources
      end
    end
  end
end
