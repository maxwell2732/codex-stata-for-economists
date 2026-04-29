---
paths:
  - "dofiles/**"
  - "output/**"
  - "reports/**/*.qmd"
---

# Single Source of Truth: Enforcement Protocol

**`dofiles/00_master.do` is the authoritative source for every analytical artifact in the repo.** Tables, figures, and reports are derived. NEVER edit a derived artifact directly.

---

## The SSOT Chain

```
data/raw/                            (immutable inputs — never edited)
   ↓
dofiles/01_clean/*.do                → data/derived/clean_*.dta
   ↓
dofiles/02_construct/*.do            → data/derived/sample_*.dta
   ↓
dofiles/03_analysis/*.do             → output/tables/*.{tex,csv}
                                        output/figures/*.{pdf,png}
   ↓
dofiles/04_output/*.do               (assembly / extra polishing if needed)
   ↓
reports/*.qmd                        (includes from output/, never re-runs analysis)
   ↓
docs/*.html (rendered)
```

`dofiles/00_master.do` calls each stage in this order.

---

## Hard Rules

1. **Never hand-edit `output/tables/*.tex` or `*.csv`.** The next pipeline run wipes the change. Adjustments go in the do-file's `esttab` options or in a `04_output/` polish do-file.
2. **Never hand-edit `output/figures/`.** Same reason. Adjust the `graph` and `graph export` calls in the source do-file.
3. **Never hand-edit `data/derived/`.** Reproducible from `01_clean` + `02_construct`; manual edits leave the project unreproducible.
4. **Reports include from `output/`, not from `data/derived/`.** The report's job is narrative, not analysis. If you find yourself running a regression inside a `.qmd` chunk, refactor it into `dofiles/03_analysis/`.
5. **Tables and figures referenced in a report must exist in `output/`.** The `verifier` agent enforces this.

---

## Freshness Check (MANDATORY before report render)

Before `quarto render reports/<file>.qmd`:

1. For every `output/tables/X.{tex,csv}` and `output/figures/X.{pdf,png}` referenced in the report:
2. Find the do-file that produces it (grep `output/tables/X` in `dofiles/`)
3. Compare timestamps: if the do-file's mtime is newer than the output's mtime, the output is **stale**
4. Stale output → re-run the producing do-file before rendering

The `/render-report` skill performs this check automatically.

---

## When SSOT Can Bend (Documented Exceptions)

Two narrow cases:

- **Manual figure annotations** that Stata can't produce cleanly (e.g., a hand-drawn callout). In this case: produce the base figure via Stata to `output/figures/_base/`, post-process to `output/figures/`, and document the post-processing step in the producing do-file's header.
- **External tables** (e.g., one cell from another paper). Place in `output/tables/external/` and cite the source in the cell's CSV header.

Both exceptions require documentation. Otherwise, no edits to derived artifacts.

---

## Content-Fidelity Checklist (Before any commit touching reports)

```
[ ] Every table in the report exists in output/tables/
[ ] Every figure in the report exists in output/figures/
[ ] No inline regressions / data computations in .qmd chunks
[ ] All output files are newer than the do-files that produced them
[ ] Every numerical claim cites a logs/ line
[ ] References.bib has every cited key
```
