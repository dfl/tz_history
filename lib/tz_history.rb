# frozen_string_literal: true

require "tzinfo"

require_relative "tz_history/version"

module TzHistory
  DATA_DIR = File.expand_path("../data", __dir__)
end

require_relative "tz_history/zone"
require_relative "tz_history/lookup"

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
    # The historical timezone to substitute, or nil when the coordinate/date has
    # no documented correction (no override, a warn-only region, or no match).
    # Returns a TZInfo::Timezone.
    #
    #   TzHistory.for(lat: 39.0837, lon: -84.5086, date: "1923-07-15")
    #   # => Shanks/KY_71  (northern-KY CDT summer IANA does not model)
    def for(lat:, lon:, date:)
      f = Lookup.lookup(lat:, lon:, date:)
      return nil unless f && f[:kind] == "override"
      return Zone.tzinfo(f[:shanks]) if f[:shanks]
      return nil unless f[:zone]

      TZInfo::Timezone.get(f[:zone])
    end

    # The zone identifier string ("America/Chicago", "Etc/GMT+6", "Shanks/KY_71")
    # or nil. Convenience for callers that only need the id, not the object.
    def zone_id(lat:, lon:, date:)
      self.for(lat:, lon:, date:)&.identifier
    end

    # A human-readable note when this birth falls in a historical-boundary region
    # (either an applied override or a flagged-but-uncorrected warn), so a UI can
    # prompt the user to verify the birth record. nil otherwise.
    def note(lat:, lon:, date:)
      Lookup.note(lat:, lon:, date:)
    end
  end
end
