# Provenance, sourcing, and copyright posture

`tz_history` re-expresses historical **timezone facts** as its own data. It references the
Shanks *American Atlas* (Thomas G. Shanks, ACS Publications) to derive those facts but does
**not** redistribute the atlas or any verbatim transcription of it. This document records the
reasoning so it survives independently of any one maintainer.

## The legal backbone: facts aren't copyrightable

Under **_Feist Publications v. Rural Telephone_ (499 U.S. 340, 1991)**, individual facts are
not protected by copyright, and a compilation of facts is protected only to the extent its
**selection, coordination, or arrangement** is original. What offset a place observed on a
given date, a town's name, and its latitude/longitude are **facts** — you may copy facts out
of a copyrighted compilation; you may not copy its original expression or arrangement.

## The directly-relevant precedent-shaped event: _Astrolabe v. Olson_

In **_Astrolabe, Inc. v. Olson & Eggert_** (D. Mass. No. 1:11-cv-11725, filed Sept 30, 2011),
Astrolabe — holder of the ACS rights to the Shanks atlases — sued the maintainers of the
**IANA/Olson tz database**, claiming its historical data infringed those atlases. The EFF
defended; in **February 2012 Astrolabe voluntarily dismissed** the suit and withdrew. The tz
database subsequently moved under ICANN/IANA stewardship.

The rights-holder to the very atlases this project references tried exactly this claim against
exactly this activity — deriving timezone facts from Shanks — and backed down. Two caveats: it
was **dismissed, not adjudicated** (the binding principle is _Feist_, not Astrolabe), and the
tz database survived precisely because it *referenced* Shanks for facts and never republished
the atlas tables verbatim. The case is no license to copy expression.

## Defensive hygiene we mirror from the tz database

- **Reference, don't redistribute.** The atlas PDF and any verbatim OCR of it stay out of the
  repo; the atlas path is supplied at extraction time via `ENV["ATLAS_PDF"]`.
- **Cross-check against the public-domain IANA database** wherever the two overlap (e.g. the
  Kentucky #69 gold-standard equivalence test).
- **Visual crop-verify** each shipped zone against the atlas page it came from, so every fact
  has an auditable derivation rather than a bulk copy.
- **Ship facts + our own re-expression** — TZif compiled by `zic`, GeoJSON we author — not the
  source tables.

None of this is legal advice; it documents the project's reasoning and risk posture. For any
larger-scale redistribution decision, obtain a professional opinion.
