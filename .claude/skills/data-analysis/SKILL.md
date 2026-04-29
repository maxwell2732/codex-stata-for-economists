---
name: data-analysis
description: End-to-end Stata analysis workflow — load, explore, clean, estimate, and produce publication-ready tables and figures with full logging.
disable-model-invocation: true
argument-hint: "[dataset path or analysis goal]"
allowed-tools: ["Read", "Grep", "Glob", "Write", "Edit", "Bash", "Task"]
---

# End-to-End Stata Data Analysis

Run a complete Stata analysis: load → EDA → clean → estimate → publication output. Produces a self-contained do-file (or a small set of stage do-files) with full logs and all artifacts in `output/`.

**Input:** `$ARGUMENTS` — a dataset path (e.g., `data/raw/cps_2010_2020.dta`) or an analysis goal (e.g., "regress wages on education with state and year FE using CPS data").

---

## Constraints

- **Follow `.claude/rules/stata-coding-conventions.md`** — version pin, log, set seed, naming, magic numbers, paths
- **Follow `.claude/rules/econometric-best-practices.md`** — clustering, FE, weights, IV diagnostics
- **Save scripts** to `dofiles/<stage>/` with `<stagenum>_<verb>_<noun>.do` naming
- **Outputs** to `output/tables/` (`.tex` + `.csv`) and `output/figures/` (`.pdf` + `.png`)
- **Run via** `bash scripts/run_stata.sh` — never call Stata directly without the wrapper
- **Run `stata-reviewer` agent** on each new do-file before presenting

---

## Workflow Phases

### Phase 1: Setup + Data Loading (`dofiles/01_clean/`)

1. Read `.claude/rules/stata-coding-conventions.md` for current standards
2. Create do-file with header (title, author, purpose, inputs, outputs, log)
3. Top-of-file boilerplate: `version 17`, `clear all`, `set more off`, `set varabbrev off`, `capture log close` + `log using`, `set seed YYYYMMDD` if needed
4. `use "data/raw/<file>.dta", clear` — confirm load succeeded with `describe` and `count`
5. Save cleaned data to `data/derived/clean_<name>.dta`

### Phase 2: EDA (logged, no figures yet for the report)

In a separate exploration do-file (under `explorations/<name>/dofiles/`):

- `summarize` — distributions, missingness
- `tabulate` — categorical breakdowns
- `corr` — correlation matrix for key continuous vars
- `xtdescribe` if panel
- Group comparisons if treatment / control structure

EDA logs go to `explorations/<name>/logs/`. EDA artifacts are NOT committed to `output/`.

### Phase 3: Construction (`dofiles/02_construct/`)

- Build samples, define treatment/outcome variables, apply restrictions
- LOG sample N at each restriction step (per `econometric-best-practices`)
- Save analysis sample to `data/derived/sample_<name>.dta`

### Phase 4: Estimation (`dofiles/03_analysis/`)

- Choose specification per the research question
- Cluster SEs at the most aggregate plausible level (default), document the choice
- For panel/FE: `reghdfe`; for IV: `ivreg2` + `ranktest`; for DiD with timing variation: prefer heterogeneity-robust estimators
- `est store m_<name>` after every estimation
- Build robustness specs varying one thing at a time
- Multiple-hypothesis correction if ≥ 5 outcomes from the same family

### Phase 5: Tables + Figures (`dofiles/04_output/`)

Tables via `esttab` to BOTH `.tex` and `.csv`:

```stata
esttab m_main m_alt_cluster using "output/tables/<name>.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) booktabs label ///
    stats(N r2_within mean_dep) addnotes("Cluster: <level>")
esttab m_main m_alt_cluster using "output/tables/<name>.csv", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) plain stats(N r2_within mean_dep)
```

Figures via Stata `graph` + `graph export`:

```stata
set scheme s2color
twoway ...
graph export "output/figures/<name>.pdf", replace
graph export "output/figures/<name>.png", replace width(1600)
```

### Phase 6: Review

1. Run the do-file via `/run-stata`
2. Validate the log via `/validate-log`
3. Run the `stata-reviewer` agent (`/review-stata`)
4. Address any Critical / High issues from the review
5. Re-run if anything changed

---

## Do-file Skeleton

```stata
*------------------------------------------------------------------------------
* File:     dofiles/03_analysis/main_regression.do
* Project:  [Project name]
* Author:   [Name]
* Purpose:  Estimate the main DiD specification on the analysis sample
* Inputs:   data/derived/sample_main.dta
* Outputs:  output/tables/main_regression.tex
*           output/tables/main_regression.csv
*           output/figures/event_study.pdf
* Log:      logs/03_analysis_main_regression.log
*------------------------------------------------------------------------------

version 17
clear all
set more off
set varabbrev off
capture log close
log using "logs/03_analysis_main_regression.log", replace text
set seed 20260428

*--- 1. Load sample -----------------------------------------------------------
use "data/derived/sample_main.dta", clear
display "Sample N: " _N

*--- 2. Main spec -------------------------------------------------------------
local controls "age educ exper"
reghdfe log_wage treated##post `controls', absorb(state_id year) cluster(state_id)
estadd ysumm
estimates store m_main

*--- 3. Robustness ------------------------------------------------------------
reghdfe log_wage treated##post `controls', absorb(state_id year) cluster(state_id year)
estadd ysumm
estimates store m_twoway

*--- 4. Export ----------------------------------------------------------------
esttab m_main m_twoway using "output/tables/main_regression.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) booktabs label ///
    stats(N r2_within mean_dep) ///
    addnotes("Standard errors clustered at state (col 1) and state x year (col 2).")
esttab m_main m_twoway using "output/tables/main_regression.csv", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) plain ///
    stats(N r2_within mean_dep)

log close
```

---

## Important

- **Reproduce, don't guess.** If the user specifies a regression, run exactly that.
- **Show your work in the log.** Print sample sizes at each restriction step.
- **Check for issues.** Multicollinearity, perfect prediction, singleton FEs, weak instruments.
- **No hardcoded values.** Cutoffs and thresholds in `local` macros with comments.
- **Log validation.** After every run, `/validate-log` to catch silent failures.
