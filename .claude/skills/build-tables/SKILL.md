---
name: build-tables
description: Combine saved Stata estimates into publication-ready tables via esttab. Produces both .tex (for paper) and .csv (for audit) with consistent formatting.
disable-model-invocation: true
argument-hint: "[table-name or estimates-list]"
allowed-tools: ["Bash", "Read", "Edit", "Write", "Grep", "Glob"]
---

# Build Publication-Ready Tables

Take a set of saved estimates and produce a single table in `.tex` (for the paper) and `.csv` (for audit / sharing) with the project's standard formatting.

## When to Use

- After running `dofiles/03_analysis/*.do` that produces `est store m_<name>` results
- When assembling a multi-spec table (main + alt outcome + alt cluster + alt FE)
- Before rendering the report — tables must exist in `output/tables/` first

## Steps

1. **Identify the estimates** in `$ARGUMENTS`:
   - If a table name (e.g., `main_regression`): search `dofiles/03_analysis/` for `est store m_main*` and assemble
   - If an explicit estimates list (e.g., `m_ols m_iv m_did`): use those
   - If empty: ask the user which table to build

2. **Locate the producing do-file** that has the `est store` calls. The do-file should also do the `esttab` export. If it doesn't, write a helper do-file in `dofiles/04_output/<table>_assemble.do`.

3. **Compose the `esttab` call** with project conventions:

   ```stata
   estimates restore m_main
   estimates restore m_alt_cluster
   estimates restore m_alt_fe

   esttab m_main m_alt_cluster m_alt_fe ///
       using "output/tables/<name>.tex", replace ///
       se star(* 0.10 ** 0.05 *** 0.01) ///
       booktabs label collabels(none) ///
       stats(N r2_within mean_dep, ///
             labels("Observations" "Within R-sq" "Mean of dep var") ///
             fmt(%9.0fc %9.3f %9.3f)) ///
       drop(_cons) ///
       title("<table title>") ///
       addnotes("Standard errors clustered at <level>." ///
                "Significance: * p<0.10, ** p<0.05, *** p<0.01.")

   esttab m_main m_alt_cluster m_alt_fe ///
       using "output/tables/<name>.csv", replace ///
       se star(* 0.10 ** 0.05 *** 0.01) plain ///
       stats(N r2_within mean_dep)
   ```

4. **Run the do-file** via `/run-stata`.

5. **Verify outputs:**
   - Both `.tex` and `.csv` exist in `output/tables/`
   - Read the `.csv` and spot-check coefficients are sensible
   - Confirm the `.tex` includes N, R², mean dep var, cluster info, significance stars

6. **Report:** path of new `.tex` and `.csv`, the spec each column represents, a one-line summary of the headline coefficient.

## Examples

- `/build-tables main_regression` → assembles `output/tables/main_regression.{tex,csv}` from `m_main`-prefixed estimates.
- `/build-tables m_ols m_iv m_did` → assembles a 3-column table from those specific saved estimates.

## Troubleshooting

- **"estimates ... not found"** — `est store m_<name>` was never run. Re-run the producing do-file.
- **Missing `mean_dep`** — add `estadd ysumm` after each `reghdfe` call in the producing do-file.
- **`esttab` not installed** — `ssc install estout, replace`.
- **Long table names break LaTeX** — use the `label` option and define short labels via `label var`.

## Notes

- Tables ALWAYS go to BOTH `.tex` and `.csv` — `.tex` is for the paper, `.csv` is for reviewers / coauthors who don't speak LaTeX.
- Never hand-edit the produced `.tex`; the next pipeline run will overwrite it. Adjust `esttab` options instead.
- Significance stars: `* p<0.10, ** p<0.05, *** p<0.01` is the project default. Override only if the journal requires different.
