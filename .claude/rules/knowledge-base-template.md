---
paths:
  - "dofiles/**/*.do"
  - "reports/**/*.qmd"
  - "templates/**/*.do"
---

# Project Knowledge Base: [YOUR PROJECT NAME]

<!-- Fill in the tables below with project-specific content. Claude reads
     this before writing any do-file or report so the work matches the
     project's notation, datasets, and identification strategy. -->

## Estimand Registry

| Estimand | Definition | Identifying Assumption | Estimator | Reference |
|---|---|---|---|---|
| ATT | E[Y(1) − Y(0) \| D=1] | Parallel trends + no anticipation | `csdid`, `did_imputation` | Callaway–Sant'Anna (2021) |
| | | | | |

## Notation Registry

| Symbol | Meaning | Used in | Anti-pattern |
|---|---|---|---|
| `Y_{it}` | Outcome for unit i in period t | reports/, dofiles/ | don't use `y_it` (different variable) |
| `D_{it}` | Treatment indicator | reports/ | |
| | | | |

## Variable Naming (Stata)

| Variable | Type | Description | Constructed in |
|---|---|---|---|
| `treated` | byte | 1 if ever-treated unit | `02_construct/sample.do` |
| `post` | byte | 1 if t ≥ treatment year | `02_construct/sample.do` |
| `log_y` | float | log(outcome + 1) | `02_construct/sample.do` |
| | | | |

## Dataset Registry

| Dataset | Source | Vintage | Unit | N | Restrictions | Used in |
|---|---|---|---|---|---|---|
| Main panel | [agency] | [YYYY] | unit-year | [N] | [restrictions] | `03_analysis/*` |
| | | | | | | |

## Identification Assumptions

| Assumption | Where invoked | How tested |
|---|---|---|
| Parallel trends | DiD spec (`03_analysis/main_did.do`) | event-study leads, `honestdid` sensitivity |
| Exogeneity of Z | IV spec (`03_analysis/iv_main.do`) | first-stage F, AR CIs, Hausman |
| | | |

## Sample Restrictions

| Restriction | Rationale | Drops N | Applied in |
|---|---|---|---|
| Drop singletons | `reghdfe` default | logged at runtime | `03_analysis/*` |
| Restrict to balanced panel | for event-study spec | [N] | `02_construct/balanced.do` |
| | | | |

## Empirical Applications (if replication-based)

| Application | Paper | Dataset | Stage | Purpose |
|---|---|---|---|---|
| | | | | |

## Design Principles

| Principle | Evidence | Applied where |
|---|---|---|
| Cluster at most aggregate plausible level | BDM 2004; AAIW 2023 | every `03_analysis/*` |
| Show pre-trends explicitly | best practice in DiD | event-study figures |
| | | |

## Anti-Patterns (Don't Do This)

| Anti-Pattern | What Happened | Correction |
|---|---|---|
| Used `xtreg fe` with `vce(robust)` | within-cluster correlation ignored | switched to `reghdfe ... cluster(id)` |
| | | |

## Stata Pitfalls (Project-Specific)

| Pitfall | Impact | Fix |
|---|---|---|
| `merge m:1 ... id` without checking `_merge` | silent dropped rows | always tabulate `_merge` and document drops |
| | | |

## Tolerance Thresholds (Project-Specific Override)

If your project needs tighter or looser tolerances than `quality-gates.md` defaults, document them here.

| Quantity | Tolerance | Rationale |
|---|---|---|
| | | |
