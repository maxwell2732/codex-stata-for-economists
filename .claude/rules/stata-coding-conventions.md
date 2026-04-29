---
paths:
  - "dofiles/**/*.do"
  - "templates/**/*.do"
  - "explorations/**/*.do"
---

# Stata Coding Conventions

**Standard:** Top empirical economics replication package. Every do-file must run cleanly from a fresh clone, log its actions, and produce outputs that another researcher can audit without asking the author.

---

## 1. File Header

Every do-file begins with:

```stata
*------------------------------------------------------------------------------
* File:     dofiles/03_analysis/main_regression.do
* Project:  [Your project name]
* Author:   [Your name]
* Purpose:  Estimate the main DiD specification on the analysis sample
* Inputs:   data/derived/sample_main.dta
* Outputs:  output/tables/main_regression.tex
*           output/tables/main_regression.csv
*           output/figures/event_study.pdf
* Log:      logs/03_analysis_main_regression.log
*------------------------------------------------------------------------------
```

## 2. Top-of-File Boilerplate

```stata
version 17                  // pin Stata version (override per fork in CLAUDE.md)
clear all
set more off
set varabbrev off           // disallow variable-name abbreviation (catches typos)
capture log close
log using "logs/03_analysis_main_regression.log", replace text

set seed 20260428           // set ONCE if randomness used (date-style integer)
```

## 3. Paths

- **Relative paths only.** Project root is `pwd` when do-files are launched via `scripts/run_stata.sh` or `master.do`.
- **Never** `cd "C:\Users\..."` or `cd "/home/..."`.
- Use forward slashes in paths (Stata accepts them on Windows too).
- Use `tempfile` for intermediate files within a do-file rather than writing to `data/` mid-script.

## 4. Naming

- Variable names: `snake_case`, descriptive (`treated`, `post_2010`, `log_wage`)
- Locals: `local varlist age educ exper exper2`
- Globals: rare; prefix with project tag (`global PROJECT_ROOT ...`) to avoid collisions
- File names mirror their stage: `01_clean_cps.do`, `02_construct_sample.do`, `03_analysis_main.do`

## 5. Estimation Output Discipline

After every estimation, name and store the result:

```stata
reghdfe log_wage treated##post i.year, absorb(state_id) cluster(state_id)
estimates store m_main
```

Save table-ready CSV alongside `.tex`:

```stata
esttab m_main using "output/tables/main_regression.tex", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) booktabs label
esttab m_main using "output/tables/main_regression.csv", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) plain
```

## 6. Figures

```stata
graph export "output/figures/event_study.pdf", replace
graph export "output/figures/event_study.png", replace width(1600)
```

Set scheme once at the top of a figure-producing do-file:

```stata
set scheme s2color   // or your project's installed scheme
```

## 7. Comment Quality

- Comments explain **WHY** (sample restriction rationale, identification choice), not WHAT
- Section headers as numbered banners:

```stata
*--- 1. Load + restrict sample ---------------------------------------------
*--- 2. Define treatment + outcome -----------------------------------------
*--- 3. Main specification -------------------------------------------------
*--- 4. Robustness ---------------------------------------------------------
*--- 5. Export tables/figures ----------------------------------------------
```

- No commented-out dead code
- No unexplained magic numbers — assign to a `local` with a name and a comment

## 8. Forbidden Patterns

| Forbidden | Why | Use instead |
|---|---|---|
| `cd "C:\..."` | Breaks reproducibility | run from project root |
| `set more off` *inside loops* | masks errors | once at top |
| `clear` mid-script without `tempfile` | risks losing data | `preserve`/`restore` or `tempfile` |
| Multiple `set seed` in one do-file | fakes reproducibility | once at top only |
| `varabbrev on` | typos compile silently | always `set varabbrev off` |
| Hardcoded dates/cutoffs without macro | obscures intent | `local cutoff_year 2010 // ATT cutoff per Section 3` |

## 9. Required User-Written Commands

The pipeline assumes these are installed (recipe in `templates/master-do-template.do`):

- `reghdfe` — high-dimensional FE regression
- `ftools` — required by reghdfe
- `estout` (provides `esttab`) — publication tables
- `ivreg2` + `ranktest` — IV with weak-instrument diagnostics
- `boottest` — wild bootstrap inference

Document any additional dependencies in the do-file header.

## 10. Closing

Every do-file ends with:

```stata
log close
```

— so subsequent runs can be matched to their log files.
