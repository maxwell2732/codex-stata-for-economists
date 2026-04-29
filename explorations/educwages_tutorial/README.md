# Exploration: Returns to Schooling Tutorial (educwages.dta)

A beginner-friendly, end-to-end Stata workflow for someone new to the language.
Walks through summary statistics, two basic plots, an OLS regression of wages
on education, an instrumental-variables (IV) regression that uses father's
education as the instrument for own education, and a one-way / two-way ANOVA
of wages by education tier and union status.

The dataset is `data/raw/educwages.dta`: 1,000 simulated workers with wages,
education in years, union membership, and parents' education in years.

## Goal

Show a Stata beginner:

1. How to load a dataset and inspect its structure (`use`, `describe`, `summarize`).
2. How to compute summary statistics — overall and by group — and export them.
3. How to draw a histogram of education years (`histogram`).
4. How to draw a scatter plot of education vs wages with a fitted regression
   line (`twoway scatter ... lfit`).
5. How to run an OLS regression (`regress`) and interpret the slope.
6. How to run a 2SLS instrumental-variables regression (`ivregress 2sls`)
   using father's education as an instrument for own education, and how to
   read the first-stage F statistic.
7. How to put OLS and IV side-by-side in a publication-style table (`esttab`).
8. How to run one-way and two-way ANOVA (`anova`), and why ANOVA is just OLS
   regression with categorical predictors (`regress wages i.edu_cat`).

## How to replicate

From the project root:

```bash
bash scripts/run_stata.sh explorations/educwages_tutorial/dofiles/01_tutorial.do
```

If Stata is not on your `PATH` (Chen's machine: Stata 15 lives at
`C:\Program Files (x86)\Stata15\`), add it first for this session:

```bash
export PATH="/c/Program Files (x86)/Stata15:$PATH"
```

Or, from inside an interactive Stata session:

```stata
do explorations/educwages_tutorial/dofiles/01_tutorial.do
```

## Outputs

After a successful run:

| Path | What it contains |
|---|---|
| `logs/01_tutorial.log` | Full session transcript: every command, every number |
| `output/figures/edu_histogram.pdf` (and `.png`) | Histogram of education years |
| `output/figures/edu_wage_scatter.pdf` (and `.png`) | Scatter of education vs wages with linear fit |
| `output/tables/summary_stats.csv` | `summarize` output for the analysis sample |
| `output/tables/ols_vs_iv.csv` (and `.rtf`) | Side-by-side OLS and IV regression of wages on education |

Every coefficient, standard error, and first-stage F statistic appears
verbatim in `logs/01_tutorial.log`.

## Files

```
explorations/educwages_tutorial/
├── README.md                    # this file
├── dofiles/
│   └── 01_tutorial.do           # the teaching script (beginner-friendly)
├── logs/
│   └── 01_tutorial.log          # full run output (gitignored)
└── output/
    ├── figures/
    │   ├── edu_histogram.pdf / .png
    │   └── edu_wage_scatter.pdf / .png
    └── tables/
        ├── summary_stats.csv
        └── ols_vs_iv.csv  /  .rtf
```

## Status

This is an **exploration** (per `.claude/rules/exploration-fast-track.md`).
The do-file is teaching code: heavily commented, intentionally pedagogical,
not production research code. Quality threshold: 60/100.

## A note on the IV exclusion restriction

Father's education is a *classic textbook* instrument for own education, but
it is not a clean IV in modern research because father's education is
correlated with family income, social networks, and parenting environment —
all of which can plausibly affect wages directly, not only through one's own
education. The IV result here should be read as a teaching exercise about
**how** to run 2SLS in Stata, not as a credible causal estimate of the
return to schooling. Real applications would prefer instruments like
compulsory-schooling-law variation (Angrist & Krueger 1991), distance to
college (Card 1995), or twin differences (Ashenfelter & Krueger 1994).
