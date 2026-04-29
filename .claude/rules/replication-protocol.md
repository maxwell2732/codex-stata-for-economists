---
paths:
  - "dofiles/**/*.do"
  - "templates/replication-targets.md"
  - "quality_reports/**"
---

# Replication-First Protocol

**Core principle:** replicate the original results to the dot BEFORE extending. No extension makes sense if the baseline is wrong.

---

## Phase 1: Inventory & Baseline

Before writing any do-file:

- [ ] Read the paper's replication README
- [ ] Inventory the replication package: language (Stata / R / Matlab / etc.), data files, scripts, outputs
- [ ] Record gold-standard numbers in `templates/replication-targets.md` → save to `quality_reports/<paper>_replication_targets.md`:

```markdown
## Replication Targets: [Paper Author (Year)]

| Target | Table/Figure | Value | SE/CI | Notes |
|--------|--------------|-------|-------|-------|
| Main ATT | Table 2, Col 3 | -1.632 | (0.584) | Primary specification, clustered at state |
| First-stage F | Table 3, Panel A | 28.4 |  — | Weak-instrument test |
| Sample size | Table 1 | 12,453 |  — | After all restrictions |
```

- [ ] Mark each target MUST / SHOULD / MAY (per `templates/requirements-spec.md` framework)

---

## Phase 2: Translate & Execute

- [ ] Follow `stata-coding-conventions` for all do-files
- [ ] Translate **line-by-line** initially — don't "improve" during replication
- [ ] Match original specification exactly: covariates, sample restrictions, clustering, SE method, weights
- [ ] Save all intermediate results as `.dta` in `data/derived/` (gitignored)

### Common Translation Pitfalls

#### Stata → Stata (different package versions)

| Stata | Trap |
|---|---|
| `xtreg ... fe` vs `reghdfe` | `xtreg` uses different small-sample adjustment than `reghdfe`'s default |
| `cluster()` in old vs new Stata | df adjustment changed; pin command version |
| `bootstrap` vs `boottest` | wild-cluster vs pairs bootstrap give different SEs with few clusters |
| `areg` vs `reghdfe` | demeaning method differs slightly; check `dofadjustments()` option in `reghdfe` |

#### Stata ↔ R

| Stata | R equivalent | Trap |
|---|---|---|
| `reg y x, cluster(id)` | `feols(y ~ x, cluster = ~id)` (`fixest`) | Stata clusters df-adjust differently from `lmtest::coeftest` |
| `areg y x, absorb(id)` | `feols(y ~ x \| id)` | Check demeaning method |
| `probit` for PS | `glm(family = binomial(link = "probit"))` | R default link in some commands is logit |
| `bootstrap, reps(999)` | `boot::boot()` | Match seed, reps, and bootstrap type exactly |

#### Stata ↔ Python

| Stata | Python equivalent | Trap |
|---|---|---|
| `reg y x, robust` | `statsmodels.OLS(...).fit(cov_type="HC1")` | Stata uses HC1; `linearmodels` defaults to HC0 |
| `xtreg ... fe` | `linearmodels.PanelOLS(entity_effects=True)` | df adjustment differences |

---

## Phase 3: Verify Match

Use tolerances from `quality-gates.md`. If outside tolerance:

**Do NOT proceed to extensions.** Isolate which step introduces the difference:

1. Sample size — check `keep`/`drop` ordering and missing-value handling
2. SE computation — check cluster level, df adjustment, weights
3. Default options — many commands have changed defaults across Stata versions
4. Variable definitions — log-of-zero handling, winsorization, top-coding

Document the investigation in the replication report **even if unresolved**. An unreplicated result is informative; a glossed-over discrepancy is fraud.

### Replication Report

Save to `quality_reports/<paper>_replication_report.md` (template in `templates/`):

```markdown
# Replication Report: [Paper Author (Year)]
**Date:** [YYYY-MM-DD]
**Original language:** [Stata 15 / R 4.x / etc.]
**Our implementation:** dofiles/<path>

## Summary
- **Targets checked / Passed / Failed:** N / M / K
- **Overall:** [REPLICATED / PARTIAL / FAILED]

## Results Comparison

| Target | Paper | Ours | Diff | Status |
|--------|-------|------|------|--------|

## Discrepancies (if any)
- **Target:** X
  - **Investigation:** ...
  - **Resolution:** [resolved / unresolved with documented hypothesis]

## Environment
- Stata version + flavor (from `logs/00_master_environment.log`)
- Key user-written commands with versions
- Data source + vintage
```

---

## Phase 4: Only Then Extend

After replication is verified (all MUST targets PASS):

- [ ] Commit the replication: `Replicate <Paper> Tables 2–4: all targets within tolerance`
- [ ] Now extend with project-specific modifications (alternative estimators, new outcomes, robustness)
- [ ] Each extension builds on the verified baseline
- [ ] If an extension's result diverges in spirit from the replication baseline, that's a research finding worth understanding — not a bug to suppress
