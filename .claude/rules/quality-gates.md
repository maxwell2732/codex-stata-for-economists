---
paths:
  - "dofiles/**/*.do"
  - "reports/**/*.qmd"
  - "scripts/**/*.py"
  - "templates/**/*.do"
---

# Quality Gates & Scoring Rubrics

## Thresholds

- **80/100 = Commit** — good enough to save
- **90/100 = PR** — ready for deployment
- **95/100 = Excellence** — aspirational

Run `python scripts/quality_score.py <file>` to score a single artifact.

---

## Stata `.do` Files

| Severity | Issue | Deduction |
|---|---|---|
| Critical | Stata `r(<n>)` error in most recent log | -100 |
| Critical | Hardcoded absolute path (`cd "C:\..."` or `/home/...`) | -25 |
| Critical | Missing `version` pin | -15 |
| Critical | Missing `log using` / no log produced | -15 |
| Major | Missing file header block | -8 |
| Major | Missing `set seed` when randomness used | -10 |
| Major | `varabbrev on` (or no `set varabbrev off`) | -5 |
| Major | `set more off` inside loops | -5 |
| Major | Magic number without macro/local + comment | -3 each (cap -15) |
| Major | Estimation result not `est store`'d | -5 |
| Minor | Section banners missing or inconsistent | -2 |
| Minor | Commented-out dead code | -2 each (cap -8) |
| Minor | Lines > 100 chars (unless `///`-continued) | -1 each (cap -10) |
| Minor | Mixed `*` / `//` comment styles | -1 |

## Quarto Reports (`reports/*.qmd` with Stata engine)

| Severity | Issue | Deduction |
|---|---|---|
| Critical | Render failure | -100 |
| Critical | Numerical claim without log citation (per `log-verification-protocol`) | -30 each |
| Critical | Broken citation key | -15 |
| Critical | Missing required section (Abstract, Data, Method, Results) | -10 each |
| Major | Table not produced from `output/tables/` | -10 |
| Major | Figure inline-rendered (should be pre-built) | -10 |
| Major | Stale output reference (output file older than do-file) | -5 |
| Minor | Long uncommented code block in narrative | -2 |

## Python Scripts (`scripts/*.py`)

| Severity | Issue | Deduction |
|---|---|---|
| Critical | Syntax error | -100 |
| Critical | Hardcoded absolute path | -25 |
| Major | Missing module docstring | -5 |
| Major | No CLI arg parsing in user-facing scripts | -5 |
| Minor | Lines > 100 chars | -1 each |

---

## Tolerance Thresholds (Replication)

| Quantity | Tolerance | Rationale |
|---|---|---|
| Integer counts (N, observations) | exact | no reason for difference |
| Point estimates (coefficients) | < 0.01 absolute, or < 1% relative | rounding in paper display |
| Standard errors | < 0.05 absolute, or < 5% relative | bootstrap / cluster variation |
| p-values | same significance star | exact may differ |
| Percentages reported in text | < 0.1pp | display rounding |
| R² | < 0.005 | display precision |

Document any deviation in `quality_reports/<lecture>_replication_report.md`.

---

## Enforcement

- **Score < 80:** block commit; list blocking issues with file:line references
- **80 ≤ Score < 90:** allow commit, warn user with recommendations
- **Score ≥ 90:** ready for PR
- User may override with documented justification in commit message

## Quality Reports

Generated **only at merge time** (not per commit). Use `templates/quality-report.md`. Save to `quality_reports/merges/YYYY-MM-DD_<branch>.md`.
