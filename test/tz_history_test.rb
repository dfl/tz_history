# frozen_string_literal: true

require "test_helper"

# Public API tests. These exercise the point-in-polygon lookup and the two kinds
# of correction the gem ships: flat IANA-zone overrides and full Shanks
# transition-list zones. Uses a handful of representative coordinates rather than
# the app's full fixture set (which lives upstream in harmonic-explorer).
class TzHistoryTest < Minitest::Test
  include TestHelpers

  # --- flat-offset overrides (winter/standard exact; summer via substitute zone) ---

  def test_east_tennessee_pre_switch_is_fixed_cst
    tz = TzHistory.for(lat: 35.9606, lon: -83.9207, date: "1946-01-15") # Knoxville
    assert_equal "Etc/GMT+6", tz.identifier
  end

  def test_east_tennessee_post_switch_is_fixed_est
    tz = TzHistory.for(lat: 35.9606, lon: -83.9207, date: "1950-07-01")
    assert_equal "Etc/GMT+5", tz.identifier
  end

  def test_zone_id_convenience
    assert_equal "Etc/GMT+6", TzHistory.zone_id(lat: 35.9606, lon: -83.9207, date: "1946-01-15")
  end

  # --- Shanks transition-list zone (northern KY, table #71) ---

  def test_northern_ky_summer_1923_is_cdt_not_flattened_cst
    # Covington (Kenton Co.): the 1920-1926 daylight summers a flat CST could not hold.
    tz = TzHistory.for(lat: 39.0837, lon: -84.5086, date: "1923-07-15")
    assert_equal "Shanks/KY_71", tz.identifier
    assert_equal(-5 * 3600, offset_of(tz, "1923-07-15")) # CDT
  end

  def test_northern_ky_winter_1923_is_cst
    assert_equal(-6 * 3600, offset_of(TzHistory.for(lat: 39.0837, lon: -84.5086, date: "1923-01-15"), "1923-01-15"))
  end

  def test_northern_ky_after_1926_switch_is_eastern_standard
    assert_equal(-5 * 3600, offset_of(TzHistory.for(lat: 39.0837, lon: -84.5086, date: "1930-07-15"), "1930-07-15"))
  end

  # --- non-matches ---

  def test_returns_nil_outside_any_polygon
    assert_nil TzHistory.for(lat: 51.5074, lon: -0.1278, date: "1946-01-15") # London
  end

  def test_returns_nil_for_a_modern_birth
    assert_nil TzHistory.for(lat: 35.9606, lon: -83.9207, date: "1990-01-15")
  end

  def test_returns_nil_when_date_missing
    assert_nil TzHistory.for(lat: 35.9606, lon: -83.9207, date: nil)
  end

  # Louisville (Jefferson Co.) is an exclusion guard: IANA already models its real
  # 1921/1941 DST, so we defer to IANA (return nil) rather than substitute.
  def test_louisville_defers_to_iana
    assert_nil TzHistory.for(lat: 38.2527, lon: -85.7585, date: "1921-06-15")
  end

  # --- notes ---

  def test_note_prompts_verification_for_a_shanks_region
    note = TzHistory.note(lat: 39.0837, lon: -84.5086, date: "1923-07-15")
    assert_match(/verify the birth record/i, note)
    assert_match(/Shanks/i, note)
  end

  def test_note_is_nil_for_a_modern_birth
    assert_nil TzHistory.note(lat: 35.9606, lon: -83.9207, date: "1990-01-15")
  end
end
