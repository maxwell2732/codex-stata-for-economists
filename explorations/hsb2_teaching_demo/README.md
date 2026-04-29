# Exploration: HSB2 Teaching Demonstration

A compact, end-to-end Stata workflow for an undergraduate audience.
Demonstrates summary statistics, a basic histogram, and an OLS regression
on the UCLA "High School and Beyond" sample (`data/raw/hsb2.dta`, 200 obs).

## Goal

Show students:

1. How to load a dataset and inspect its structure (`describe`, `codebook`).
2. How to compute summary statistics overall and by subgroup
   (`summarize`, `tabulate`, `tabstat`).
3. How to draw a histogram with a normal overlay (`histogram ... normal`).
4. How to run a series of nested OLS regressions, store the results, and
   present them side-by-side (`regress`, `estimates store`, `estimates table`).

## How to replicate

From the project root:

```bash
bash scripts/run_stata.sh explorations/hsb2_teaching_demo/dofiles/01_demo.do
```

If Stata is not on your `PATH`, add it first (Chen's machine: Stata 15 lives at
`C:\Program Files (x86)\Stata15\`; add that to `PATH` either temporarily
(`export PATH="/c/Program Files (x86)/Stata15:$PATH"`) or permanently in
Windows System Environment Variables).

Or, from inside an interactive Stata session:

```stata
do explorations/hsb2_teaching_demo/dofiles/01_demo.do
```

## Outputs

After a successful run:

| Path | What it contains |
|---|---|
| `logs/01_demo.log` | Full session transcript: every command, every number |
| `output/figures/write_histogram.pdf` (and `.png`) | Histogram of writing scores with normal overlay |
| `output/tables/coef_table.csv` | Side-by-side comparison of three OLS specifications |

The headline regression (Spec 3) regresses `write` on `read`, `math`,
`female`, and indicators for `race` and `prog`. Every coefficient,
standard error, and R² appears verbatim in `logs/01_demo.log`.

## Files

```
explorations/hsb2_teaching_demo/
├── README.md                    # this file
├── dofiles/
│   ├── 00_inspect.do            # one-off describe (used to confirm vars)
│   └── 01_demo.do               # the teaching script
├── logs/
│   ├── 00_inspect.log           # describe output
│   └── 01_demo.log              # main run output
└── output/
    ├── figures/
    │   ├── write_histogram.pdf
    │   └── write_histogram.png
    └── tables/
        └── coef_table.csv
```

## Status

This is an **exploration** (per `.claude/rules/exploration-fast-track.md`).
Quality threshold: 60/100. The do-file is teaching code, not production
research code, so some niceties (no `reghdfe`, no clustered SEs, no
robustness section) are deliberately omitted to keep it readable.

## Scope deliberately omitted

- Robust / clustered standard errors (`,robust` or `,vce(cluster ...)`)
- Heteroskedasticity diagnostics (Breusch–Pagan, etc.)
- Outlier checks (DFBETA, Cook's distance)
- Multiple-hypothesis correction
- Causal interpretation of the coefficients

These would be the natural next-week extensions if the course continues.
