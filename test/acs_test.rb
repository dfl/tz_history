# frozen_string_literal: true

require "test_helper"

# Town-level ACS layer tests. The layer snaps a birth coordinate to the nearest
# documented ACS town and applies that town's exact pre-1970 clock history (compiled
# to TZif). These exercise the golden cities the town histories were validated against, the
# town-level distinctions county polygons cannot make, and the range/cutover gating.
class AcsTest < Minitest::Test
  include TestHelpers

  # --- golden cities (validated against the published atlas reference) ---

  def test_grand_rapids_mn_keeps_cst_through_summers_the_garland_fix
    # Rural MN (MN #131) ran CST with NO peacetime DST until 1957, while IANA
    # America/Chicago applies CDT every summer -- the canonical 1-hour town-level error.
    tz = TzHistory.acs(lat: 47.2372, lon: -93.53, date: "1955-07-15")
    assert_equal(-6 * 3600, offset_of(tz, "1955-07-15")) # CST, not IANA's CDT
    assert_equal(-6 * 3600, offset_of(tz, "1922-07-15")) # and back in 1922
  end

  def test_chicago_observes_summer_dst
    # A few miles' difference in table: Chicago (IL #1294) DID run continuous DST.
    tz = TzHistory.acs(lat: 41.85, lon: -87.65, date: "1955-07-15")
    assert_equal(-5 * 3600, offset_of(tz, "1955-07-15")) # CDT
    assert_equal(-6 * 3600, offset_of(tz, "1955-01-15")) # CST winter
  end

  def test_knoxville_switches_central_to_eastern_in_1946
    # East Tennessee (zone-table 13658) kept CST until the 1946 base switch to EST --
    # a change of BASE offset, not just DST, that the town's zone-table encodes.
    tz = TzHistory.acs(lat: 35.9606, lon: -83.9208, date: "1941-01-15")
    assert_equal(-6 * 3600, offset_of(tz, "1941-01-15")) # CST before the switch (and pre-war)
    tz2 = TzHistory.acs(lat: 35.9606, lon: -83.9208, date: "1950-01-15")
    assert_equal(-5 * 3600, offset_of(tz2, "1950-01-15")) # EST after
  end

  def test_phoenix_drops_dst_after_1967
    # Arizona (AZ #81) observed the 1967 Uniform-Act DST for one year, then abandoned it.
    tz = TzHistory.acs(lat: 33.4483, lon: -112.0733, date: "1967-07-15")
    assert_equal(-6 * 3600, offset_of(tz, "1967-07-15")) # MDT that one summer
    assert_equal(-7 * 3600, offset_of(tz, "1968-07-15")) # MST -- no more DST (still < cutover)
  end

  def test_cheyenne_mountain_war_time_and_1967
    tz = TzHistory.acs(lat: 41.1333, lon: -104.8167, date: "1943-07-15")
    assert_equal(-6 * 3600, offset_of(tz, "1943-07-15")) # MWT (war time)
    assert_equal(-7 * 3600, offset_of(tz, "1950-07-15")) # MST, no peacetime DST yet
  end

  # --- town-level split: neighbouring towns, different tables ---

  def test_nearest_town_resolution_distinguishes_neighbours
    # The whole point: two coordinates in the same county/IANA zone can resolve to
    # different histories. Grand Rapids MN (no DST) vs Chicago (DST) in summer 1930.
    assert_equal(-6 * 3600, offset_of(TzHistory.acs(lat: 47.2372, lon: -93.53, date: "1930-07-15"), "1930-07-15"))
    assert_equal(-5 * 3600, offset_of(TzHistory.acs(lat: 41.85, lon: -87.65, date: "1930-07-15"), "1930-07-15"))
  end

  def test_phenix_city_keeps_eastern_while_interior_alabama_is_central
    # The sub-county split no county polygon can hold: Phenix City sits on the river
    # across from Columbus GA and kept EASTERN time (its own ACS town record), while
    # Auburn/Opelika ~30km west were CENTRAL. This is exactly why the county-level
    # "East Alabama observes Eastern de facto" warn was left in place and NOT replaced
    # with a flat-CST override -- that override would have wrongly forced Phenix City
    # to Central. The town layer resolves both correctly.
    %w[1950-01-15 1950-07-15 1960-07-15].each do |d|
      assert_equal(-5 * 3600, offset_of(TzHistory.acs(lat: 32.4710, lon: -85.0008, date: d), d),
                   "Phenix City should read Eastern -5 on #{d}")
      assert_equal(-6 * 3600, offset_of(TzHistory.acs(lat: 32.6099, lon: -85.4808, date: d), d),
                   "Auburn should read Central -6 on #{d}")
    end
  end

  # --- resolve metadata + note ---

  def test_resolve_returns_nearest_town_and_distance
    r = TzHistory::Acs.resolve(lat: 47.2372, lon: -93.53, date: "1955-07-15")
    assert_equal "Grand Rapids", r[:city]
    assert_operator r[:km], :<, 5.0
    assert_match(/\AA\d{4}\z/, r[:zone_id])
  end

  # --- gating: range + 1970 cutover ---

  def test_post_1970_defers_to_iana
    # From 1970 IANA is authoritative, so the town layer returns nil (no correction).
    assert_nil TzHistory.acs(lat: 47.2372, lon: -93.53, date: "1970-07-15")
    assert_nil TzHistory.acs(lat: 47.2372, lon: -93.53, date: "1985-07-15")
  end

  def test_far_from_any_town_defers
    # Mid-Atlantic ocean: no ACS town within MAX_KM -> nil.
    assert_nil TzHistory.acs(lat: 30.0, lon: -45.0, date: "1950-07-15")
  end

  def test_nearest_returns_close_town_for_a_us_coordinate
    n = TzHistory::Acs.nearest(41.85, -87.65)
    refute_nil n
    assert_operator n[:km], :<, TzHistory::Acs::MAX_KM
  end

  # --- flag integration into TzHistory.for ---

  def test_for_uses_town_layer_by_default
    # Default on: `for` resolves rural MN via the nearest ACS town, whose CST-no-DST
    # history diverges from IANA's CDT, so it returns an ACS zone (not the polygon override).
    tz = TzHistory.for(lat: 47.2372, lon: -93.53, date: "1955-07-15")
    assert_match(%r{\AACS/A\d{4}\z}, tz.identifier)
    assert_equal(-6 * 3600, offset_of(tz, "1955-07-15"))
  end

  def test_for_falls_back_to_polygon_when_flag_disabled
    prev = TzHistory.acs_town_layer
    TzHistory.acs_town_layer = false
    tz = TzHistory.for(lat: 44.9853, lon: -95.4731, date: "1950-07-15")
    assert_equal "Etc/GMT+6", tz.identifier # county-polygon path, unchanged
  ensure
    TzHistory.acs_town_layer = prev
  end

  def test_for_returns_nil_when_town_agrees_with_iana
    # Chicago ran continuous DST = its modern IANA zone, so the town layer finds no
    # divergence and returns nil (defer to IANA) -- honoring the correction contract.
    assert_nil TzHistory.for(lat: 41.85, lon: -87.65, date: "1955-07-15")
  end

  # --- the divergence gate: correct only where ACS differs from the modern IANA zone ---
  # The Mountain no-DST states (WY/UT/NM) match IANA America/Denver in the peacetime-
  # standard years (Denver kept no DST 1921-1964), so the town layer correctly defers
  # then -- and only corrects the summers where IANA applies MDT the state did not (1920,
  # and 1965-66 before the Uniform Act). This is finer than the old flat Etc/GMT+7 window.

  def test_mountain_states_defer_to_iana_in_the_matching_standard_years
    [[41.14, -104.8202], [40.7608, -111.8910], [35.084, -106.65]].each do |lat, lon| # Cheyenne/SLC/ABQ
      assert_nil TzHistory.for(lat: lat, lon: lon, date: "1930-07-15"),
                 "#{lat},#{lon} matches IANA MST in 1930 -> defer"
    end
  end

  def test_mountain_states_correct_the_1920_and_1965_66_mdt_summers
    # 1920 and 1965-66: IANA America/Denver applies MDT (-6) but the state kept MST (-7).
    %w[1920-07-15 1965-07-15 1966-07-15].each do |d|
      tz = TzHistory.for(lat: 41.14, lon: -104.8202, date: d) # Cheyenne
      refute_nil tz, "Cheyenne should be corrected on #{d}"
      assert_equal(-7 * 3600, offset_of(tz, d)) # MST, not IANA's MDT
    end
  end

  # --- downstate Illinois: the town layer supersedes the polygon over-correction ---
  # The county-polygon layer flattened downstate IL to CST until 1959, but Shanks itself
  # records early-postwar DST tables there (IL#3 1947, IL#6 1946). The town layer resolves
  # per town: a deep-downstate no-DST town stays CST (diverges from IANA), while a town
  # whose table adopted daylight (Peoria, continuous 1946-70) agrees with IANA and defers.

  def test_deep_downstate_illinois_town_stays_cst
    # A town on the full-CST table (no peacetime DST through the 1950s) diverges from
    # IANA America/Chicago's CDT -> corrected to CST.
    tz = TzHistory.for(lat: 39.2833, lon: -88.6333, date: "1950-07-15") # Effingham area (IL full-CST)
    refute_nil tz
    assert_equal(-6 * 3600, offset_of(tz, "1950-07-15")) # CST, not CDT
  end

  def test_peoria_observed_dst_so_defers_to_iana
    # Peoria's table ran continuous DST 1946-1970 (a documented carve-out), matching
    # IANA -> the town layer defers rather than flattening it to CST like the polygon did.
    assert_nil TzHistory.for(lat: 40.6936, lon: -89.5890, date: "1950-07-15")
  end

  # --- note() follows the divergence verdict ---

  def test_note_present_for_a_diverging_town_and_names_the_town
    note = TzHistory.note(lat: 47.2372, lon: -93.53, date: "1955-07-15") # Grand Rapids MN
    assert_match(/Shanks American Atlas/i, note)
    assert_match(/Grand Rapids/, note)
  end

  def test_note_absent_when_town_agrees_with_iana
    assert_nil TzHistory.note(lat: 41.85, lon: -87.65, date: "1955-07-15") # Chicago
  end

  def test_note_after_cutover_defers_to_polygon_layer
    # Post-1970 the town layer is silent; note falls through to the polygon layer (also nil here).
    assert_nil TzHistory.note(lat: 47.2372, lon: -93.53, date: "1975-07-15")
  end
end
