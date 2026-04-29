# Replication Targets: [Paper Author (Year)]

> Use one file per paper being replicated. Save to:
> `quality_reports/<paper_short>_replication_targets.md`

## Bibliographic Information

- **Citation:** [Full bibliographic citation]
- **DOI / URL:** [Where to find the paper]
- **Replication package:** [Where the original code/data live, if available]
- **Original code language:** Stata 15 / R 4.x / Matlab / etc.

## Targets

For each numerical result you want to reproduce, add a row. Mark each as
**MUST** (non-negotiable; replication fails if missed), **SHOULD** (preferred),
or **MAY** (nice-to-have).

| # | Tier  | Target description     | Table/Figure | Paper value | SE / CI | Tolerance | Notes |
|---|-------|------------------------|--------------|-------------|---------|-----------|-------|
| 1 | MUST  | Main ATT               | Tab 2, Col 3 | -1.632      | (0.584) | abs<0.01  | clustered at state |
| 2 | MUST  | First-stage F          | Tab 3, Pn A  | 28.4        |  --     | abs<1.0   | weak-IV diagnostic |
| 3 | SHOULD| Sample size            | Tab 1        | 12,453      |  --     | exact     | after restrictions |
| 4 | SHOULD| Pre-trend coef (lead-2)| Fig 2        |  0.014      | (0.012) | abs<0.005 | placebo test |
| 5 | MAY   | R-squared (within)     | Tab 2, Col 3 |  0.387      |  --     | abs<0.005 | display precision |

## Specifications to Match

- **Sample restrictions:** [list every restriction in order, e.g., "drop missing X; keep if year >= 2000; balanced panel"]
- **Outcome variable:** [exact construction; logs/levels; winsorization]
- **Treatment variable:** [exact construction; binary/continuous; timing]
- **Controls:** [list]
- **Fixed effects:** [unit, year, state-by-year, etc.]
- **Cluster level:** [exact level + how chosen]
- **Weights:** [pweight / aweight / fweight; or unweighted]
- **Standard error method:** [robust / cluster / wild bootstrap / boot reps]

## Known Translation Risks (if cross-language)

[List any Stata-vs-R-vs-Python pitfalls relevant to this replication.
Common ones: cluster df-adjust differences, default link in `glm`/`probit`,
bootstrap implementation differences, missing-value handling.]

## Decision: How Strict?

- [ ] Strict: every MUST target within tolerance, no exceptions
- [ ] Standard: MUST within tolerance; document any near-miss
- [ ] Loose: report differences but don't block (use only for very old papers without replication packages)

## Approval

- **Author:** [Your name]
- **Approved on:** [YYYY-MM-DD]
- **Approver:** [Coauthor / advisor / self]
