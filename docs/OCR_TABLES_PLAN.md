# TIME-TABLES OCR reconstruction — DONE (2026-09)

`tools/ocr_tables.rb` + `tools/vision_ocr.swift` classify the atlas TIME TABLES (no-DST vs
DST, postwar DST-resumption year) to drive the town-level layers (Maine/Maryland shipped
this way). Recall went from **13/28 → 28/28 tables on Maryland and 18/18 on Idaho**, correctly
numbered and classified. This doc records what the bottleneck actually was (the original
diagnosis was wrong) and the design that fixed it.

## What the bottleneck actually was (measured on the crop, not guessed)

The original plan blamed the token→row→table *reconstruction* and proposed dropping the
second OCR pass. Both premises were **wrong**. Measured on Maryland (crop-verified 28 tables):

1. **Hard-coded content region.** `ocr_tables.rb` re-cropped `full.png` at a HARD-CODED
   `region_h = page_h * 0.45`, regardless of what `render_state.rb --bot` produced. The MD
   tables reach ~80% of the page (the block runs down to the COUNTIES divider), so the
   bottom table of every column was silently clipped. This alone accounted for ~half the loss.
2. **Full-width bands garble the DENSE middle columns.** A full-width band hands Vision the
   crowded interior at low effective resolution; it reads ~1 date in a middle-column band
   where a NARROW single-column crop of the same region reads ~19. So the "single-pass over
   full-width tokens" idea (plan Phase 2) actually *destroyed* the middle columns — the
   opposite of the plan's expectation. **The two-pass re-crop was load-bearing all along**;
   the real bug was just the 0.45 clip sitting on top of it.
3. **Epoch-only opener was fragile.** Segmenting tables on the `11/18/18xx` date token alone
   missed openers (Vision read 3 of 5 in one column) and double-counted in others.
4. **Column wrap.** When a table's `XX # N` header lands at a column's floor, its body wraps
   to the top of the NEXT column — an empty header-only table + a headerless body table.

## The design that fixed it

- **Render the whole block** (`--bot=0.88`) and drive the content region from the actual
  rendered bands, never a hard-coded fraction. `--debug` warns if openers reach the floor.
- **Two passes, both load-bearing.** Pass 1 (full-width bands) finds the column x-gaps + the
  header abbr — all it can do reliably. Pass 2 re-crops each column NARROW + banded and OCRs
  it cleanly; this recovers the middle columns.
- **Union opener.** A table opener = the cluster of {header, "Before", LMT, 18xx date}. Any
  one signal firing detects the table; clustering (gap > ~350px·dpi) collapses them into one.
  Robust to a faint header failing to OCR, and it still numbers from the header when legible.
- **Per-band row grouping.** Rows are grouped WITHIN a band (each band's read is internally
  y-consistent); a fragmented overlap read fails the date+zone test, and a duplicated clean
  read is dropped by the per-table date-dedup. Grouping ACROSS bands split date from zone.
- **Wrap-merge.** An empty header-only table immediately followed (column-major) by a
  headerless table-with-rows is one table: the number moves onto the body, the empty is dropped.
- **Numbering.** Legible `XX # N` header → authoritative; else positional `~N` (a hint —
  crop-verify). On MD, 25/28 are header-numbered; the 3 `~N` all resolve to the correct number.

## Validation (crop-verified ground truth)

- **Maryland (PDF 239): 28/28 tables**, numbered 1-28. Only MD#1 (greater Baltimore) shows
  pre-war peacetime DST (1920-30) — matches the page's own intro and the shipped town layer.
  MD#6=1947, MD#7=1948 resumptions confirmed; MD#16 EDT every year 1947-53 then US#3 1954.
- **Idaho (PDF 122): 18/18 tables**, numbered 1-18. ID#2 resume 1964 (north panhandle
  dominant), ID#1 resume 1961 (Coeur d'Alene), 1930s pre-war DST in ID#3/8/10/11 — all match
  the shipped Idaho analysis.
- **Maine (PDF 229): ~35/38 tables**, numbering mostly correct (`1 … 38` with a few `~N`
  positional + one stray). Maine is the HARDEST page: its tables cite another table's zone as
  a tight `ME#N` token (like `US#N`), which the header regex first mistook for a table number.
  Fixed by requiring the header to be SPACED (`ME # N`) and on a line with no time/date/zone
  token. Rows that reference `ME#N` as their zone are still dropped (a cross-table chain we
  don't resolve) — so Maine classification is a rougher draft; crop-verify boundary tables.

## Non-goals / residual

- Still a DRAFT: the crop remains the source of truth for a shipped override's boundary
  tables (RUNBOOK gate). This raises recall + numbering to the point where the bulk is
  automatic and only the boundary calls need eyeballing.
- The CITY-INDEX cross-check (original plan Phase 3) is now UNNEEDED for numbering — the
  header OCR + positional fill already pins all 28. Keep it in reserve for a state whose
  headers are too faint to reach ~90% header-numbered.
- Pass 2 re-crops N_cols × N_bands (~25 crops on a dense page) → ~50s/page. Fine for the
  state-by-state sweep; parallelize per column if it ever needs to be faster.
