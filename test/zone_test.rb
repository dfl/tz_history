# frozen_string_literal: true

require "test_helper"

# Cross-check harness for the Shanks TZif engine (docs/EXTRACTION.md §5).
#
# Two regression nets keep bulk extraction safe:
#
#   1. TWINS -- a Shanks table that has a genuine IANA counterpart must reproduce its
#      OBSERVED UTC OFFSET every month across the overlap span. A mismatch is an
#      OCR/transcription bug, not new data. America/Kentucky/Louisville (== KY_69) is
#      the seed; every future table with an IANA twin is added to SHANKS_IANA_TWINS
#      and inherits the same parameterized test for free.
#
#   2. HAND ASSERTIONS -- a table with NO IANA twin (the residual sub-state histories
#      IANA omits: northern KY's 1920-26 summers, Alabama's 1941 summer) can't be
#      cross-checked, so the visual-verified DST seasons are pinned by hand here.
#
# We compare the OBSERVED OFFSET (what actually shifts a chart), never the
# abbreviation: Shanks labels war-time daylight CWT where IANA uses CDT, but -05 is -05.
class ZoneTest < Minitest::Test
  include TestHelpers

  # Shanks table id => the IANA zone it must match, and the span they overlap.
  SHANKS_IANA_TWINS = {
    "KY_69" => { iana: "America/Kentucky/Louisville", from: 1884, to: 1969 }
  }.freeze

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

  # Parameterized twin cross-check: every Shanks table with an IANA counterpart must
  # match it, offset-for-offset, on the 1st and 15th of every month across the span.
  def test_shanks_tables_match_their_iana_twins_every_month
    SHANKS_IANA_TWINS.each do |table, spec|
      shanks = TzHistory::Zone.tzinfo(table)
      iana = TZInfo::Timezone.get(spec[:iana])
      mismatches = []
      (spec[:from]..spec[:to]).each do |year|
        (1..12).each do |month|
          [1, 15].each do |day|
            probe = Date.new(year, month, day)
            s = offset_of(shanks, probe)
            i = offset_of(iana, probe)
            mismatches << "#{table} #{probe}: shanks #{s} vs #{spec[:iana]} #{i}" if s != i
          end
        end
      end
      assert_empty mismatches, "offset mismatches vs IANA twin:\n#{mismatches.first(20).join("\n")}"
    end
  end

  def test_ky69_matches_louisville_around_every_transition
    shanks = TzHistory::Zone.tzinfo("KY_69")
    iana = TZInfo::Timezone.get("America/Kentucky/Louisville")
    transitions = %w[
      1918-03-31 1918-10-27 1919-03-30 1919-10-26 1921-05-01 1921-09-01
      1941-04-27 1941-09-28 1942-02-09 1945-09-30 1946-04-28 1946-06-02
      1950-04-30 1950-09-24 1961-04-30 1961-07-23 1968-04-28 1968-10-27
      1969-04-27 1969-10-26
    ]
    transitions.each do |iso|
      d = Date.parse(iso)
      [d - 1, d + 1].each do |probe|
        assert_equal offset_of(iana, probe), offset_of(shanks, probe),
                     "offset differs from IANA at #{probe} (around #{iso})"
      end
    end
  end

  # --- hand assertions for tables with NO IANA twin ---

  def test_ky69_resolves_summer_dst_cases_a_fixed_offset_cannot
    shanks = TzHistory::Zone.tzinfo("KY_69")
    assert_equal(-18_000, offset_of(shanks, "1921-06-15")) # CDT summer
    assert_equal(-18_000, offset_of(shanks, "1941-07-01")) # CDT summer
    assert_equal(-21_600, offset_of(shanks, "1930-01-15")) # CST winter
  end

  def test_ky71_northern_kentucky_summers_1920_to_1926
    shanks = TzHistory::Zone.tzinfo("KY_71")
    assert_equal(-18_000, offset_of(shanks, "1923-07-15")) # CDT summer
    assert_equal(-21_600, offset_of(shanks, "1923-01-15")) # CST winter
    assert_equal(-18_000, offset_of(shanks, "1930-07-15")) # Eastern standard after 1926 switch
  end

  # Alabama AL #1: statewide CST with a REAL 1941 summer DST (Jul 21 - Oct 1) that
  # neither the flat Etc/GMT+6 override nor IANA America/Chicago models. No IANA twin,
  # so the visual-verified seasons are pinned here.
  def test_al1_alabama_1941_summer_dst_and_surrounding_standard_time
    shanks = TzHistory::Zone.tzinfo("AL_1")
    assert_equal(-21_600, offset_of(shanks, "1941-01-15")) # CST winter
    assert_equal(-18_000, offset_of(shanks, "1941-08-15")) # CDT -- the 1941 summer residual
    assert_equal(-18_000, offset_of(shanks, "1941-09-30")) # CDT still on the day before fallback
    assert_equal(-21_600, offset_of(shanks, "1941-10-15")) # CST after Oct 1 fallback
    assert_equal(-21_600, offset_of(shanks, "1930-07-15")) # no DST 1920-1940
    assert_equal(-18_000, offset_of(shanks, "1943-07-01")) # CWT war-time daylight
  end
end
