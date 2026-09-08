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

  # --- flat EST override where IANA over-applies early-1920s NYC daylight ---
  # Rural/interior Connecticut kept EST year-round through the early-mid 1920s, but
  # IANA America/New_York applies NYC's continuous 1920-1925 summer DST statewide.

  def test_rural_connecticut_summer_1922_is_fixed_est_not_iana_edt
    # Torrington (Litchfield Co.): a flat Etc/GMT+5 corrects IANA's spurious EDT.
    tz = TzHistory.for(lat: 41.8007, lon: -73.1212, date: "1922-07-15")
    assert_equal "Etc/GMT+5", tz.identifier
    assert_equal(-5 * 3600, offset_of(tz, "1922-07-15")) # EST, not EDT
  end

  def test_rural_connecticut_after_1926_defers_to_iana
    # From 1926 Connecticut generally observed DST (matching IANA), so we defer.
    assert_nil TzHistory.for(lat: 41.8007, lon: -73.1212, date: "1930-07-15")
  end

  def test_urban_connecticut_county_is_a_warn_split_not_an_override
    # Bridgeport (Fairfield Co.): the city ran DST from 1920 but surrounding towns did
    # not -- a genuine straddle, so we warn and defer rather than guess.
    assert_nil TzHistory.for(lat: 41.1792, lon: -73.1894, date: "1922-07-15")
    note = TzHistory.note(lat: 41.1792, lon: -73.1894, date: "1922-07-15")
    assert_match(/larger cities/i, note)
  end

  # --- flat MST override where IANA over-applies early-1920s Denver daylight ---
  # Rural/mountain Colorado kept MST year-round in 1920-1921, but IANA America/Denver
  # applies Denver-metro summer DST (1920, spring 1921) statewide.

  def test_rural_colorado_summer_1920_is_fixed_mst_not_iana_mdt
    # Grand Junction (Mesa Co.): flat Etc/GMT+7 corrects IANA's spurious MDT.
    tz = TzHistory.for(lat: 39.0639, lon: -108.5506, date: "1920-07-15")
    assert_equal "Etc/GMT+7", tz.identifier
    assert_equal(-7 * 3600, offset_of(tz, "1920-07-15")) # MST, not MDT
  end

  def test_rural_colorado_after_1921_defers_to_iana
    assert_nil TzHistory.for(lat: 39.0639, lon: -108.5506, date: "1922-07-15")
  end

  def test_denver_kept_its_1920_dst_and_defers_to_iana
    # Denver Co. observed the 1920 DST IANA models, so we defer rather than override.
    assert_nil TzHistory.for(lat: 39.7392, lon: -104.9903, date: "1920-07-15")
  end

  def test_denver_metro_split_county_is_a_warn
    # Adams Co.: Denver suburbs on DST, outlying towns on MST -- a straddle, so warn.
    assert_nil TzHistory.for(lat: 39.9853, lon: -104.8206, date: "1920-07-15")
    note = TzHistory.note(lat: 39.9853, lon: -104.8206, date: "1920-07-15")
    assert_match(/Denver metro/i, note)
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
