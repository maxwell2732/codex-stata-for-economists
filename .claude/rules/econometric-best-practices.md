---
paths:
  - "dofiles/03_analysis/**/*.do"
  - "dofiles/04_output/**/*.do"
  - "templates/**/*.do"
  - "explorations/**/*.do"
---

# Econometric Best Practices

A set of defaults aligned with current top empirical economics practice. Every do-file may deviate, but every deviation must be **deliberate and documented**.

---

## 1. Standard Errors

**Default: cluster at the most aggregate plausible level.**

| Setting | Default cluster | Rationale |
|---|---|---|
| Panel data | unit (e.g., firm, individual) | within-unit serial correlation |
| DiD with state-level treatment | state | within-state correlation; per Bertrand–Duflo–Mullainathan (2004) |
| Unit-of-treatment varies | level of treatment assignment | per Abadie–Athey–Imbens–Wooldridge (2023) |
| Clustered with few clusters (G < ~30) | wild bootstrap (`boottest`) | t-distribution unreliable |
| IV / 2SLS | same cluster as OLS counterpart | consistency |

`robust` (heteroskedasticity-robust without clustering) is the **wrong default** when within-unit correlation is plausible. If using `robust`, the do-file must comment why clustering is unnecessary.

---

## 2. Fixed Effects

- Use `reghdfe` for high-dimensional FE absorption; document `absorb()` choice in a comment
- Drop singletons (`dropsingleton` is default in `reghdfe`) and report N before/after in the log
- Two-way clustering is `reghdfe ..., cluster(unit time)` — declare both
- For event studies, prefer `eventdd` or hand-coded leads/lags; explicitly avoid the canonical TWFE estimator when treatment timing varies (use Callaway–Sant'Anna, de Chaisemartin–D'Haultfœuille, Sun–Abraham, or Borusyak–Jaravel–Spiess instead)

---

## 3. Sample Selection

Every analysis do-file logs:

```stata
display "Sample N before restrictions: " _N
keep if <condition_1>
display "After restriction 1 (<rationale>): " _N
keep if <condition_2>
display "After restriction 2 (<rationale>): " _N
```

So a reviewer can reconstruct the funnel from the log alone.

---

## 4. Weights

| Stata weight | When to use |
|---|---|
| `pweight` | Sampling weights (population inference) — almost always for survey data |
| `aweight` | Analytic weights (cell-mean variance) — when dependent var is a mean over groups |
| `fweight` | Frequency weights — when the row literally represents N observations |
| `iweight` | Importance weights — rare; specific commands only |

**Never** use `pweight` and `cluster()` together without confirming the command supports it (some don't).

---

## 5. Instrumental Variables

- Report **first-stage F** for every IV spec. Use `weakivtest` (Olea–Pflueger) when single endogenous + single instrument
- For multiple instruments, use `ivreg2` + `ranktest` and report Kleibergen–Paap rk Wald F
- F < 10 is a red flag; F < ~24 (Lee et al. 2022) requires reporting Anderson–Rubin CIs
- `boottest` for inference with few clusters in IV

---

## 6. Multiple Hypothesis Testing

If the do-file estimates ≥ 5 coefficients on the same family of outcomes, report:
- **Raw p-values**, AND
- **Adjusted p-values**: Bonferroni (conservative), Holm (less conservative), or Romano–Wolf (`rwolf` package)

Document in the table notes which adjustment is used.

---

## 7. DiD-Specific

- **Show pre-trends** explicitly (event-study leads non-significant)
- **Visualize**: event-study plot of leads + lags with 95% CIs
- **Robustness**: at minimum, both TWFE and one heterogeneity-robust estimator (Callaway–Sant'Anna `csdid`, de Chaisemartin–D'Haultfœuille `did_multiplegt`, Sun–Abraham `eventstudyinteract`)
- **Honest DiD** sensitivity (`honestdid`) when the parallel-trends assumption is plausibly violated

---

## 8. Bootstrap & Simulation

- Reps ≥ 999 for production (use 99 or 199 for development; document in code)
- Wild cluster bootstrap (`boottest`) when G < ~30
- Set seed once at top of the do-file, never inside the bootstrap loop
- Save the bootstrap distribution (`saving()`) so reviewers can audit

---

## 9. Reporting

Every regression table includes:
- N (always)
- R² (when meaningful — not for fixed-effects-absorbed regressions; report within R² instead)
- Mean of dep var
- Cluster level + count
- FE included
- Control set indicator

Use `esttab` `stats(N r2_within mean_dep)` and `addnotes(...)`.

---

## 10. Robustness Section

Every paper-ready do-file produces a robustness section that varies one thing at a time:
- Alternative outcome definition
- Alternative sample restriction
- Alternative cluster level
- Alternative SE method (boot / robust)
- Alternative FE specification
- Drop influential observations / winsorize

Pre-commit, the `econometric-reviewer` agent verifies these are present.
