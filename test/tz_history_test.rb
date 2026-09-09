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

  # --- rural Delaware: EST 1920-1941 where IANA applies continuous Philly/NYC DST ---

  def test_rural_sussex_delaware_summer_1925_is_fixed_est
    tz = TzHistory.for(lat: 38.6901, lon: -75.3855, date: "1925-07-15") # Georgetown
    assert_equal "Etc/GMT+5", tz.identifier
    assert_equal(-5 * 3600, offset_of(tz, "1925-07-15")) # EST, not EDT
  end

  def test_rural_sussex_delaware_after_war_defers_to_iana
    assert_nil TzHistory.for(lat: 38.6901, lon: -75.3855, date: "1948-07-15")
  end

  def test_kent_delaware_is_a_town_by_town_warn_split
    assert_nil TzHistory.for(lat: 39.1582, lon: -75.5244, date: "1925-07-15") # Dover
    note = TzHistory.note(lat: 39.1582, lon: -75.5244, date: "1925-07-15")
    assert_match(/town-by-town/i, note)
  end

  # --- Atlanta local DST 1937-1940 (Shanks GA #21), an exclusion guard ---
  # The city of Atlanta observed summer DST 1937-1940 (EDT), which IANA models
  # correctly but the statewide Georgia EST no-DST override would flatten. A note-less
  # guard over Fulton + DeKalb blocks the override for 1937-1940 so they defer to IANA.

  def test_atlanta_1938_summer_defers_to_iana_for_its_local_dst
    # Fulton Co.: without the guard the statewide no-DST override wins; with it, defer.
    assert_nil TzHistory.for(lat: 33.749, lon: -84.388, date: "1938-07-15")
  end

  def test_dekalb_1939_summer_defers_to_iana_for_its_local_dst
    assert_nil TzHistory.for(lat: 33.7748, lon: -84.2963, date: "1939-07-15") # Decatur
  end

  def test_atlanta_guard_only_covers_the_dst_years
    # Outside 1937-1940 the guard does not apply (Savannah stays on the EST override).
    tz = TzHistory.for(lat: 32.0809, lon: -81.0912, date: "1938-07-15") # Savannah, EST override
    assert_equal "Etc/GMT+5", tz.identifier
  end

  # --- Atlanta-metro Central-set bug fix (was mis-zoned Central 1919-41) ---
  # Fulton (Atlanta) + Cobb/Clayton/Cherokee/Forsyth were wrongly included in the
  # Western-Georgia Central set (Etc/GMT+6), so outside the 1937-40 guard they read
  # Central -- a 1 h error. They are Eastern (like DeKalb): removed from the Central
  # features, they now fall through to the statewide Georgia EST override (Etc/GMT+5).

  def test_atlanta_metro_is_eastern_standard_not_central_1925
    # 1925 is outside the 1937-40 guard; before the fix Fulton resolved Etc/GMT+6.
    %w[fulton cobb clayton cherokee forsyth].zip(
      [[33.749, -84.388], [33.94, -84.57], [33.54, -84.36], [34.24, -84.48], [34.23, -84.13]]
    ).each do |name, (lat, lon)|
      tz = TzHistory.for(lat: lat, lon: lon, date: "1925-06-01")
      assert_equal "Etc/GMT+5", tz.identifier, "#{name} should be Eastern (EST), not Central"
    end
  end

  def test_true_western_georgia_stays_central_1925
    # Columbus (Muscogee) + LaGrange (Troup) are genuinely Central -- unchanged.
    [[32.4610, -84.9877], [33.0362, -85.0319]].each do |lat, lon|
      tz = TzHistory.for(lat: lat, lon: lon, date: "1925-06-01")
      assert_equal "Etc/GMT+6", tz.identifier
    end
  end

  # --- north Idaho panhandle: PST 1946-1960 where IANA applies California DST ---
  # The 10 Pacific-zone counties kept Pacific Standard year-round from the end of war
  # time until DST resumed, but IANA America/Los_Angeles applies California summer DST in
  # 1948 and 1950-1960. The panhandle is now a TOWN-LEVEL split: most towns (Shanks ID #2)
  # kept PST through 1963, but the ID #1 towns -- including Coeur d'Alene -- resumed summer
  # DST in 1961. The correctness invariant is the OFFSET; which zone object serves a point
  # (Etc/GMT+8 vs Shanks/ID_1) depends on the nearest documented town, and both are PST in
  # a no-DST year like 1955/1948.

  def test_north_idaho_summer_1955_is_pst_not_iana_pdt
    # 1955 predates any Idaho DST resumption, so every panhandle town is PST (-8), not
    # IANA's spurious PDT -- whichever town the point snaps to.
    tz = TzHistory.for(lat: 47.6777, lon: -116.7805, date: "1955-07-15") # Coeur d'Alene
    assert_equal(-8 * 3600, offset_of(tz, "1955-07-15")) # PST, not PDT
  end

  def test_north_idaho_summer_1948_is_pst
    # 1948 was California's first post-war DST year; the panhandle kept PST (-8).
    tz = TzHistory.for(lat: 46.4165, lon: -117.0177, date: "1948-07-15")
    assert_equal(-8 * 3600, offset_of(tz, "1948-07-15"))
  end

  def test_coeur_dalene_resumed_summer_dst_1962_via_town_layer
    # Coeur d'Alene is a Shanks ID #1 town: it resumed summer DST in 1961, three years
    # before the ID #2 majority. The old flat override wrongly forced PST 1961-63; the
    # town-level split resolves it to Shanks/ID_1 -> PDT (-7). This is DEFERRED #5, now fixed.
    tz = TzHistory.for(lat: 47.6777, lon: -116.7805, date: "1962-07-15")
    assert_equal "Shanks/ID_1", tz.identifier
    assert_equal(-7 * 3600, offset_of(tz, "1962-07-15")) # PDT, matching IANA (not forced PST)
    assert_equal(-8 * 3600, offset_of(tz, "1962-01-15")) # but PST in winter
  end

  def test_north_idaho_id2_town_still_kept_pst_through_1963
    # An ID #2 town kept PST even in 1962 (no early DST resumption) -- unchanged by the
    # town layer, which corrects only the ID #1 resumers. (The ID #4/7/10/12 resumers are
    # the same pattern and would extend the layer once their tables are transcribed.)
    tz = TzHistory.for(lat: 48.14, lon: -116.75, date: "1962-07-15") # a Shanks ID #2 town
    assert_equal(-8 * 3600, offset_of(tz, "1962-07-15"))
  end

  def test_north_idaho_war_time_defers_to_iana
    # A 1944 birth is before the override window (war time PWT, which IANA models).
    assert_nil TzHistory.for(lat: 47.6777, lon: -116.7805, date: "1944-07-15")
  end

  # (Superseded: the old "Coeur d'Alene kept PST in 1962" test asserted the over-correction
  # bug -- Coeur d'Alene is an ID #1 town that resumed DST in 1961. The ID #2 "kept PST"
  # invariant is now checked with a real ID #2 coordinate above, and the Coeur d'Alene
  # correction by test_coeur_dalene_resumed_summer_dst_1962_via_town_layer.)

  def test_north_idaho_after_1964_dst_resumption_defers_to_iana
    # From spring 1964 the panhandle observed DST (matching America/Los_Angeles), so defer.
    assert_nil TzHistory.for(lat: 47.6777, lon: -116.7805, date: "1964-07-15")
  end

  # --- southern Idaho: MOUNTAIN from 1919 where IANA/Boise stays Pacific until 1923 ---
  # Eastern/central Idaho counties switched to Mountain time in 1919 (Shanks ID #13-16),
  # but IANA America/Boise keeps them Pacific until the official 1923-05-13 boundary move.

  def test_eastern_idaho_1921_is_fixed_mst_not_iana_pst
    # Pocatello (Bannock Co.): flat Etc/GMT+7 corrects Boise's spurious Pacific.
    tz = TzHistory.for(lat: 42.8713, lon: -112.4455, date: "1921-07-15")
    assert_equal "Etc/GMT+7", tz.identifier
    assert_equal(-7 * 3600, offset_of(tz, "1921-07-15")) # MST, not PST
  end

  def test_idaho_falls_1921_winter_is_fixed_mst
    # Idaho Falls (Bonneville Co.), the largest eastern-Idaho city.
    tz = TzHistory.for(lat: 43.4917, lon: -112.0339, date: "1921-01-15")
    assert_equal "Etc/GMT+7", tz.identifier
  end

  def test_eastern_idaho_after_1923_boundary_move_defers_to_iana
    # From 1923-05-13 America/Boise itself is Mountain, so we defer.
    assert_nil TzHistory.for(lat: 42.8713, lon: -112.4455, date: "1924-07-15")
  end

  def test_boise_matches_iana_and_defers
    # Ada Co. (Boise): its cities map to Shanks ID #18, which switched in 1923-05-13 --
    # exactly what America/Boise models -- so there is no residual to correct.
    assert_nil TzHistory.for(lat: 43.615, lon: -116.2023, date: "1921-07-15")
  end

  # --- town-by-town straddle counties resolved by nearest documented Shanks town ---
  # Custer + Power straddle the eastern Mountain-from-1919 bloc and the western
  # Boise-match region. A "split" feature embeds the Shanks CITY LISTINGS points and
  # snaps the birth coordinate to the nearest town, so each sub-region gets its own
  # answer instead of a whole-county warn.

  def test_custer_east_lost_river_resolves_to_mountain_override
    # Mackay (eastern Custer): nearest documented town is Mountain-from-1919 -> Etc/GMT+7.
    tz = TzHistory.for(lat: 43.9115, lon: -113.6103, date: "1921-07-15")
    assert_equal "Etc/GMT+7", tz.identifier
    assert_equal(-7 * 3600, offset_of(tz, "1921-07-15"))
    assert_match(/nearest documented town/i, TzHistory.note(lat: 43.9115, lon: -113.6103, date: "1921-07-15"))
  end

  def test_custer_west_salmon_basin_defers_to_iana
    # Challis / Stanley (western Custer): nearest town matched Boise (Pacific until 1923).
    assert_nil TzHistory.for(lat: 44.2163, lon: -114.9361, date: "1921-07-15") # Stanley
    assert_match(/straddle/i, TzHistory.note(lat: 44.2163, lon: -114.9361, date: "1921-07-15"))
  end

  def test_power_northeast_resolves_to_mountain_override
    # Michaud (NE Power, by American Falls): Mountain-from-1919 -> Etc/GMT+7.
    tz = TzHistory.for(lat: 42.8900, lon: -112.6140, date: "1921-07-15")
    assert_equal "Etc/GMT+7", tz.identifier
  end

  def test_power_arbon_valley_defers_to_iana
    assert_nil TzHistory.for(lat: 42.4560, lon: -112.5680, date: "1921-07-15") # Arbon
  end

  def test_split_county_is_inert_outside_its_window
    # Before 1919-10-26 and after the 1923-05-13 Boise switch, no correction applies.
    assert_nil TzHistory.for(lat: 43.9115, lon: -113.6103, date: "1918-07-15")
    assert_nil TzHistory.for(lat: 43.9115, lon: -113.6103, date: "1924-07-15")
  end

  # --- downstate Illinois: CST where IANA/Chicago bakes in continuous Chicago DST ---
  # Illinois law required birth times recorded in CST until 1959-07-01, and downstate
  # clocks kept CST, but IANA America/Chicago applies Chicago's continuous summer DST.

  def test_downstate_illinois_summer_1930_is_fixed_cst_not_iana_cdt
    # Springfield (Sangamon Co.): flat Etc/GMT+6 corrects IANA's spurious CDT.
    tz = TzHistory.for(lat: 39.7817, lon: -89.6501, date: "1930-07-15")
    assert_equal "Etc/GMT+6", tz.identifier
    assert_equal(-6 * 3600, offset_of(tz, "1930-07-15")) # CST, not CDT
  end

  def test_downstate_illinois_postwar_summer_1950_is_fixed_cst
    # Peoria: still CST after the war, before the 1959 state-law change.
    tz = TzHistory.for(lat: 40.6936, lon: -89.5890, date: "1950-07-15")
    assert_equal "Etc/GMT+6", tz.identifier
  end

  def test_downstate_illinois_wartime_defers_to_iana
    # 1943 is inside the WWII CWT window (IANA models it), between the two CST windows.
    assert_nil TzHistory.for(lat: 39.7817, lon: -89.6501, date: "1943-07-15")
  end

  def test_downstate_illinois_after_1959_law_change_defers_to_iana
    # From 1959-07-01 downstate adopted daylight time (matching IANA), so defer.
    assert_nil TzHistory.for(lat: 39.7817, lon: -89.6501, date: "1960-07-15")
  end

  def test_chicago_metro_defers_to_iana_via_exclusion_guard
    # Cook Co. (Chicago) observed the continuous DST IANA models -- the metro
    # exclusion guard keeps it on IANA rather than the downstate CST override.
    assert_nil TzHistory.for(lat: 41.8781, lon: -87.6298, date: "1930-07-15")
  end

  # --- Indiana: pre-1970 Central/Eastern + DST chaos, flagged not corrected ---
  # Shanks calls Indiana "very complex ... contradictory ... not documented"; IANA's
  # eight America/Indiana/* sub-zones are best-guesses. We flag (warn) and defer rather
  # than assert a clock offset we cannot verify.

  def test_indiana_pre1970_defers_to_iana_with_a_verify_warning
    # Indianapolis (Marion Co.): no override, but a note prompts verification.
    assert_nil TzHistory.for(lat: 39.7684, lon: -86.1581, date: "1950-07-15")
    note = TzHistory.note(lat: 39.7684, lon: -86.1581, date: "1950-07-15")
    assert_match(/complex|contradictory|verify/i, note)
  end

  def test_indiana_after_1970_has_no_warning
    assert_nil TzHistory.note(lat: 39.7684, lon: -86.1581, date: "1975-07-15")
  end

  def test_indiana_chicago_corner_is_not_flagged
    # Gary (Lake Co.): the clean NW Chicago corner (America/Chicago) is excluded.
    assert_nil TzHistory.note(lat: 41.5934, lon: -87.3464, date: "1935-07-15")
  end

  # --- Iowa: CST through 1953 where IANA/Chicago bakes in continuous DST ---
  # Iowa is entirely Central and kept CST (no DST) until the mid-1950s adoption scatter
  # (earliest Shanks postwar DST is IA #8, 1954). Pre-war + 1946-1953 are universal CST.

  def test_iowa_postwar_1950_is_fixed_cst_not_iana_cdt
    tz = TzHistory.for(lat: 41.5868, lon: -93.6250, date: "1950-07-15") # Des Moines
    assert_equal "Etc/GMT+6", tz.identifier
    assert_equal(-6 * 3600, offset_of(tz, "1950-07-15")) # CST, not CDT
  end

  def test_iowa_1953_still_fixed_cst_before_the_1954_scatter
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 41.5868, lon: -93.6250, date: "1953-07-15").identifier
  end

  def test_iowa_from_1954_is_a_patchy_warn_not_an_override
    # From 1954 observance is town-by-town, so we defer to IANA with a verify note.
    assert_nil TzHistory.for(lat: 41.5868, lon: -93.6250, date: "1958-07-15")
    assert_match(/patchy|diversity|verify/i, TzHistory.note(lat: 41.5868, lon: -93.6250, date: "1958-07-15"))
  end

  def test_iowa_wartime_defers_to_iana
    assert_nil TzHistory.for(lat: 41.5868, lon: -93.6250, date: "1943-07-15")
  end

  # --- Kansas: dominant Central kept CST 1920-1966; far-west Mountain deferred ---
  # KS #1 (bulk of the state) is straight CST with no local DST until the 1967 Uniform
  # Time Act, while IANA America/Chicago applies continuous summer CDT.

  def test_central_kansas_summer_1950_is_fixed_cst_not_iana_cdt
    tz = TzHistory.for(lat: 37.6872, lon: -97.3301, date: "1950-07-15") # Wichita
    assert_equal "Etc/GMT+6", tz.identifier
    assert_equal(-6 * 3600, offset_of(tz, "1950-07-15")) # CST, not CDT
  end

  def test_central_kansas_prewar_1930_is_fixed_cst
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 37.6872, lon: -97.3301, date: "1930-07-15").identifier
  end

  def test_kansas_after_1967_uniform_defers_to_iana
    assert_nil TzHistory.for(lat: 37.6872, lon: -97.3301, date: "1968-07-15")
  end

  # --- Louisiana: statewide CST, except New Orleans' one-summer 1946 CDT ---
  # LA #1 (nearly all parishes) is pure CST; LA #2 (Orleans/Jefferson/St. Bernard)
  # differs only by observing CDT in summer 1946, which IANA America/Chicago models.

  def test_new_orleans_summer_1946_defers_to_iana_for_its_cdt
    # Orleans Parish: the exclusion guard blocks the CST override so 1946 CDT resolves.
    assert_nil TzHistory.for(lat: 29.9511, lon: -90.0715, date: "1946-07-15")
  end

  def test_new_orleans_winter_1946_is_the_cst_override
    tz = TzHistory.for(lat: 29.9511, lon: -90.0715, date: "1946-02-15")
    assert_equal "Etc/GMT+6", tz.identifier
  end

  def test_new_orleans_other_years_stay_on_the_cst_override
    # 1950 summer: LA #2 was back on CST (only 1946 had CDT), so override applies.
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 29.9511, lon: -90.0715, date: "1950-07-15").identifier
  end

  def test_rest_of_louisiana_summer_1946_is_fixed_cst
    # Baton Rouge (LA #1): kept CST in 1946; the New Orleans guard does not apply.
    tz = TzHistory.for(lat: 30.4515, lon: -91.1871, date: "1946-07-15")
    assert_equal "Etc/GMT+6", tz.identifier
    assert_equal(-6 * 3600, offset_of(tz, "1946-07-15"))
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
