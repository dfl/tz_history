# frozen_string_literal: true

require "test_helper"

# Gold-standard equivalence test for the Shanks TZif engine.
# America/Kentucky/Louisville is the one Kentucky locality IANA fully models
# pre-1970, so our hand-authored Shanks table #69 must reproduce it. If a
# synthetic Shanks zone -- compiled by zic and resolved by TZInfo -- returns the
# same observed UTC offset as IANA across every DST season 1884-1969, the whole
# compile-to-TZif approach is validated.
#
# We compare the OBSERVED UTC OFFSET (what actually shifts a chart), not the
# abbreviation: Shanks labels the 1918/1919 and war-time daylight seasons
# CWT/CDT differently from IANA, but the offset is identical.
class ZoneTest < Minitest::Test
  include TestHelpers

  IANA_LOUISVILLE = TZInfo::Timezone.get("America/Kentucky/Louisville")

  def test_returns_a_tzinfo_timezone_named_for_the_table
    z = TzHistory::Zone.tzinfo("KY_69")
    assert_instance_of TZInfo::DataTimezone, z
    assert_equal "Shanks/KY_69", z.identifier
  end

  def test_returns_nil_for_unknown_table
    assert_nil TzHistory::Zone.tzinfo("ZZ_99")
  end

  def test_memoizes
    assert_same TzHistory::Zone.tzinfo("KY_69"), TzHistory::Zone.tzinfo("KY_69")
  end

  def test_ky69_matches_louisville_offset_every_month_1884_to_1969
    shanks = TzHistory::Zone.tzinfo("KY_69")
    mismatches = []
    (1884..1969).each do |year|
      (1..12).each do |month|
        [1, 15].each do |day|
          probe = Date.new(year, month, day)
          s = offset_of(shanks, probe)
          i = offset_of(IANA_LOUISVILLE, probe)
          mismatches << "#{probe}: shanks #{s} vs iana #{i}" if s != i
        end
      end
    end
    assert_empty mismatches, "offset mismatches vs IANA:\n#{mismatches.first(20).join("\n")}"
  end

  def test_ky69_matches_louisville_around_every_transition
    shanks = TzHistory::Zone.tzinfo("KY_69")
    transitions = %w[
      1918-03-31 1918-10-27 1919-03-30 1919-10-26 1921-05-01 1921-09-01
      1941-04-27 1941-09-28 1942-02-09 1945-09-30 1946-04-28 1946-06-02
      1950-04-30 1950-09-24 1961-04-30 1961-07-23 1968-04-28 1968-10-27
      1969-04-27 1969-10-26
    ]
    transitions.each do |iso|
      d = Date.parse(iso)
      [d - 1, d + 1].each do |probe|
        assert_equal offset_of(IANA_LOUISVILLE, probe), offset_of(shanks, probe),
                     "offset differs from IANA at #{probe} (around #{iso})"
      end
    end
  end

  def test_resolves_summer_dst_cases_a_fixed_offset_cannot
    shanks = TzHistory::Zone.tzinfo("KY_69")
    assert_equal(-18_000, offset_of(shanks, "1921-06-15")) # CDT summer
    assert_equal(-18_000, offset_of(shanks, "1941-07-01")) # CDT summer
    assert_equal(-21_600, offset_of(shanks, "1930-01-15")) # CST winter
  end
end
