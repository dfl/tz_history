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

  # --- Shanks transition-list zone (Alabama 1941 summer DST, table AL #1) ---

  def test_alabama_summer_1941_is_shanks_cdt_not_flattened_cst
    # Birmingham (Jefferson Co.): Jul 21 - Oct 1 1941 Alabama observed CDT, which the
    # flat Etc/GMT+6 override skips and IANA America/Chicago (no 1941 DST) also misses.
    tz = TzHistory.for(lat: 33.5207, lon: -86.8025, date: "1941-08-15")
    assert_equal "Shanks/AL_1", tz.identifier
    assert_equal(-5 * 3600, offset_of(tz, "1941-08-15")) # CDT
  end

  def test_alabama_before_the_1941_dst_window_is_the_flat_cst_override
    # A June 1941 birth is before Jul 21, so the flat CST override still applies.
    tz = TzHistory.for(lat: 33.5207, lon: -86.8025, date: "1941-06-15")
    assert_equal "Etc/GMT+6", tz.identifier
  end

  def test_alabama_after_the_1941_dst_window_defers_to_iana
    # After the Oct 1 fallback the state is back on plain CST, which IANA models
    # correctly, so we defer (return nil) rather than substitute.
    assert_nil TzHistory.for(lat: 33.5207, lon: -86.8025, date: "1941-11-15")
  end

  def test_alabama_georgia_line_county_keeps_its_warn_in_summer_1941
    # Auburn (Lee Co.) is one of the east-Alabama Georgia-line counties that keep
    # Eastern de facto -- it stays a warn (defers to IANA), NOT forced onto AL_1.
    assert_nil TzHistory.for(lat: 32.6099, lon: -85.4808, date: "1941-08-15")
    note = TzHistory.note(lat: 32.6099, lon: -85.4808, date: "1941-08-15")
    assert_match(/Georgia line/i, note)
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
