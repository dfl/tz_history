# frozen_string_literal: true

require "minitest/autorun"
require "date"
require "tz_history"

module TestHelpers
  # Observed UTC offset (seconds) a TZInfo::Timezone applies to a noon wall-clock
  # birth on `date` -- works for flat and transition-list zones alike.
  def offset_of(tz, date)
    d = date.is_a?(String) ? Date.parse(date) : date
    tz&.period_for_local(Time.utc(d.year, d.month, d.day, 12))&.observed_utc_offset
  end
end
