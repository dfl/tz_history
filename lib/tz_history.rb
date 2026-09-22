# frozen_string_literal: true

require "tzinfo"

require_relative "tz_history/version"

module TzHistory
  DATA_DIR = File.expand_path("../data", __dir__)
end

require_relative "tz_history/zone"
require_relative "tz_history/lookup"
require_relative "tz_history/acs"

# Corrects the IANA/Olson timezone for a US birth that predates a documented
# pre-1970 time-zone-boundary shift. IANA only guarantees local observance since
# 1970 and assigns every coordinate its MODERN zone, so a plain geographic lookup
# mis-zones a place that historically kept different clocks -- the astrology-
# standard ACS/Shanks American Atlas records these; IANA deliberately does not.
#
# This is a Rails-free extraction of the harmonic-explorer HistoricalZone service.
# It returns plain TZInfo::Timezone objects (wrap in ActiveSupport::TimeZone in a
# Rails app if you need .parse/.local). See README for provenance and scope.
module TzHistory
  class << self
    # When true (the default), `for`/`zone_id`/`note` resolve through the ACS town-point
    # layer FIRST: for a pre-1970 US birth within range of a documented town, the town's
    # exact history wins wherever it diverges from IANA, and the county-polygon path is
    # consulted only when no ACS town is in range (outside US coverage, or on/after the
    # 1970 cutover). Set false to fall back to the polygon-only behavior (e.g. for
    # non-ACS/pure-Shanks parity, or to compare layers).
    attr_writer :acs_town_layer

    def acs_town_layer
      @acs_town_layer = true if @acs_town_layer.nil?
      @acs_town_layer
    end

    # The historical timezone to substitute, or nil when the coordinate/date has no
    # documented correction (the birth's clock already matches its modern IANA zone, a
    # warn-only region, or no match). Returns a TZInfo::Timezone.
    #
    # With the town layer on (default), an in-range pre-1970 US birth resolves to its
    # nearest documented ACS town: the town's zone when it diverges from IANA, else nil.
    # Out of range it falls through to the county-polygon overrides.
    #
    #   TzHistory.for(lat: 47.2372, lon: -93.53, date: "1955-07-15") # Grand Rapids MN
    #   # => ACS/A0570  (rural-MN CST summer IANA models as CDT)
    def for(lat:, lon:, date:)
      if acs_town_layer && (r = Acs.resolve(lat:, lon:, date:))
        return r[:diverges] ? r[:zone] : nil
      end

      f = Lookup.lookup(lat:, lon:, date:)
      return nil unless f && f[:kind] == "override"
      return Zone.tzinfo(f[:shanks]) if f[:shanks]
      return nil unless f[:zone]

      TZInfo::Timezone.get(f[:zone])
    end

    # The ACS town-layer zone for a birth (nearest documented town), or nil when out
    # of range or on/after the 1970 IANA cutover. Unlike `for`, this returns the town's
    # zone even when it AGREES with IANA -- the raw ACS verdict, not a "differs" signal.
    #
    #   TzHistory.acs(lat: 47.2372, lon: -93.53, date: "1955-07-15") # Grand Rapids MN
    #   # => ACS zone reading CST (no DST) where IANA America/Chicago reads CDT
    def acs(lat:, lon:, date:)
      Acs.zone(lat:, lon:, date:)
    end

    # The zone identifier string ("America/Chicago", "Etc/GMT+6", "Shanks/KY_71",
    # "ACS/A0570") or nil. Convenience for callers that only need the id, not the object.
    def zone_id(lat:, lon:, date:)
      self.for(lat:, lon:, date:)&.identifier
    end

    # A human-readable note when this birth falls in a historical-boundary region
    # (either an applied correction or a flagged-but-uncorrected warn), so a UI can
    # prompt the user to verify the birth record. nil otherwise.
    def note(lat:, lon:, date:)
      if acs_town_layer && (r = Acs.resolve(lat:, lon:, date:))
        return nil unless r[:diverges]

        return "This location's pre-1970 clock history follows the independently-derived " \
               "Shanks American Atlas at the town level, which IANA does not encode here. " \
               "Applied the historical zone -- verify the birth record. " \
               "(Resolved via the nearest documented town, #{r[:city]}.)"
      end

      Lookup.note(lat:, lon:, date:)
    end
  end
end
