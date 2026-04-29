---
paths:
  - "dofiles/**/*.do"
  - "reports/**/*.qmd"
  - "output/**"
  - "docs/**"
---

# Task Completion Verification Protocol

**At the end of EVERY task, Claude MUST verify the output works correctly.** This is non-negotiable.

---

## For Stata Do-Files

1. Run via the wrapper: `bash scripts/run_stata.sh dofiles/<stage>/<file>.do`
2. Confirm exit code is 0 (the wrapper exposes Stata's `_rc`)
3. Confirm `logs/<stage>_<file>.log` exists and is non-empty
4. Scan the log tail for `r(<n>)` error indicators (use `grep "^r(" logs/...` or the `/validate-log` skill)
5. Confirm expected output files exist with non-trivial size:
   - `output/tables/<expected>.tex` and `.csv`
   - `output/figures/<expected>.pdf` and `.png`
6. Spot-check estimates for plausible magnitude and sign
7. If the task adds or changes a numerical claim in any committed document, run the `log-validator` agent
8. Report the verification results to the user with paths

## For Quarto Reports (`reports/*.qmd`)

1. Run `quarto render reports/<file>.qmd` (or via `/render-report`)
2. Confirm the rendered HTML/PDF in `docs/` (or report-local `_files/`) has been updated
3. Open / inspect the rendered output for missing figures (broken paths)
4. Confirm every numerical claim in the rendered output traces to a log line
5. Verify no inline analysis: report should `include` from `output/tables/` and `output/figures/`, never re-run regressions

## For Pipeline Runs (`bash scripts/run_pipeline.sh`)

1. Confirm exit code 0
2. Stage-by-stage timings printed
3. `logs/00_master_environment.log` exists with the environment snapshot
4. Final `output/` tree contains the expected artifacts (compare to a manifest if one exists)

## Common Pitfalls

- **Assuming silent success:** always check the wrapper's exit code; Stata can exit 0 even when a do-file errored if `capture` swallowed it. The `validate-log` skill catches this.
- **Stale outputs:** if `output/tables/foo.tex` is older than `dofiles/03_analysis/foo.do`, the table is stale → re-run.
- **Missing logs:** if a do-file ran without `log using`, you have no provenance → forbidden by `stata-coding-conventions`; treat as failure.
- **Quarto render in offline mode:** check that the Stata Quarto engine is installed (`quarto check`); skip cleanly if not, with a documented message.

## Verification Checklist

```
[ ] Stata do-file exit code is 0
[ ] Log file created and non-empty
[ ] No r(<n>) errors in log
[ ] All expected output files exist (tables + figures)
[ ] Output files newer than the do-file
[ ] Numerical claims (if any) cited to log lines
[ ] log-validator agreed (if numerical claims in commit/report)
[ ] Quarto report rendered successfully (if applicable)
[ ] Reported verification results to user with file paths
```
