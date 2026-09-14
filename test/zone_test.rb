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

  # Netherlands NL #1 (Amsterdam / whole country) -- the first INTERNATIONAL Atlas table.
  # Amsterdam Mean Time = +0:19:32 (meridian 4E53), the sub-hour offset a flat Etc/GMT
  # zone cannot hold, redefined to exactly +0:20 (meridian 5E00) on 1937-07-01. The
  # DEFAULT IANA Europe/Amsterdam is merely a Link to Europe/Brussels (WET/+0:00) pre-1940,
  # so a plain geographic lookup is wrong for EVERY pre-1940 Dutch birth. IANA keeps the
  # real history only in the opt-in `backzone` file; Shanks/NL_1 reproduces that backzone
  # zone to the second (575/575 mid-months 1892-1940 -- reproduce via research/intl/), but
  # backzone is not in the system tzdata, so the offsets are pinned here by hand.
  def test_nl1_netherlands_amsterdam_mean_time
    shanks = TzHistory::Zone.tzinfo("NL_1")
    assert_equal(1172, offset_of(shanks, "1910-07-15")) # AMT +0:19:32, no summer time yet
    assert_equal(1172, offset_of(shanks, "1900-01-15")) # AMT winter
    assert_equal(4772, offset_of(shanks, "1925-07-15")) # NST = AMT + 1:00 summer (+1:19:32)
    assert_equal(1172, offset_of(shanks, "1935-01-15")) # AMT winter
    assert_equal(4800, offset_of(shanks, "1938-07-15")) # summer on the +0:20 base (+1:20:00)
    assert_equal(1200, offset_of(shanks, "1939-01-15")) # Dutch Time +0:20 exactly
  end

  # Iceland IS #1 (whole country) -- Iceland stood 1 HOUR BEHIND GMT (meridian 15W,
  # -1:00) from 1908, summer time raising the clock to GMT (+00), until permanent GMT
  # in 1968. Before 1908: Reykjavik mean solar time, -1:28. The DEFAULT IANA build LINKS
  # Atlantic/Reykjavik -> Africa/Abidjan (GMT +0), off by a full hour every 1908-1968
  # winter; the real history is Almanak-sourced but only in the opt-in `backzone`.
  # Shanks p.195 is the primary; three Shanks gaps (omitted 1939/1940 summer time,
  # spurious July 1941/1942 fall-backs) are corrected from the sourced Almanak -- the
  # 1940 and 1941 summer assertions below are the regression guards for those fixes.
  def test_is1_iceland_one_hour_behind_gmt
    shanks = TzHistory::Zone.tzinfo("IS_1")
    assert_equal(-5280, offset_of(shanks, "1900-01-15")) # Reykjavik MST -1:28 (pre-1908)
    assert_equal(-3600, offset_of(shanks, "1910-07-15")) # std -1:00, no summer time yet
    assert_equal(-3600, offset_of(shanks, "1925-07-15")) # std -1:00 (no DST 1922-1938)
    assert_equal(0,     offset_of(shanks, "1940-07-15")) # summer +00 (Shanks omitted 1940 DST; Almanak-sourced)
    assert_equal(0,     offset_of(shanks, "1941-08-15")) # summer +00 (Shanks fell back 2/Jul; Almanak keeps it to autumn)
    assert_equal(-3600, offset_of(shanks, "1965-01-15")) # winter std -1:00
    assert_equal(0,     offset_of(shanks, "1965-07-15")) # summer +00
    assert_equal(0,     offset_of(shanks, "1968-07-15")) # permanent GMT from 1968-04-07
  end

  # Luxembourg LU #1 (whole country) -- Luxembourg kept CENTRAL European Time (+1:00,
  # summer +2:00) from 1904, switched to WESTERN European Time (0:00, summer +1:00) in
  # 1918, then back to CET at the 1940 occupation. The DEFAULT IANA build LINKS
  # Europe/Luxembourg -> Europe/Brussels (WET), so it is a full hour low across 1904-1918.
  def test_lu1_luxembourg_cet_then_wet
    shanks = TzHistory::Zone.tzinfo("LU_1")
    assert_equal(3600, offset_of(shanks, "1910-01-15")) # CET +1:00 (default Brussels would say 0)
    assert_equal(7200, offset_of(shanks, "1916-07-15")) # CEST +2:00 (WWI summer time)
    assert_equal(0,    offset_of(shanks, "1925-01-15")) # WET 0:00 (switched 1918)
    assert_equal(3600, offset_of(shanks, "1925-07-15")) # WEST +1:00 summer
    assert_equal(7200, offset_of(shanks, "1941-07-15")) # occupation CEST +2:00 (continuous 1940-1942)
  end

  # Norway NO #1 (whole country) -- uniform CET (+1:00) from 1895, with summer time ONLY
  # in 1916, 1940-1945 and 1959-1965. The DEFAULT IANA build LINKS Europe/Oslo ->
  # Europe/Berlin, whose DST years differ, so it is an hour off in 1917-1918/1945-1949/
  # 1959-1965. The 1917 (no DST) and 1960 (DST) assertions are the divergence guards.
  def test_no1_norway_uniform_cet
    shanks = TzHistory::Zone.tzinfo("NO_1")
    assert_equal(3600, offset_of(shanks, "1910-01-15")) # CET +1:00
    assert_equal(7200, offset_of(shanks, "1916-07-15")) # CEST +2:00 (Norway's 1916 summer time)
    assert_equal(3600, offset_of(shanks, "1917-07-15")) # CET -- NO summer 1917 (Berlin would be +2:00)
    assert_equal(7200, offset_of(shanks, "1943-07-15")) # occupation CEST +2:00
    assert_equal(3600, offset_of(shanks, "1950-07-15")) # CET -- no DST 1946-1958
    assert_equal(7200, offset_of(shanks, "1960-07-15")) # CEST +2:00 (1959-1965 summer time)
  end
end
