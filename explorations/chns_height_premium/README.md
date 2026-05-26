# CHNS Height Premium

This exploration studies the height premium in CHNS using the largest available
cross-section selected by complete OLS sample size.

Run from the project root:

```bash
C:\ProgramData\Miniconda3\python.exe explorations\chns_height_premium\scripts\build_height_core.py
bash scripts/run_stata.sh explorations/chns_height_premium/dofiles/01_height_premium.do
```

Outputs:

- `logs/01_height_premium.log`
- `output/tables/wave_sample_counts.csv`
- `output/tables/summary_stats.csv`
- `output/tables/ols_iv_height_premium.csv`
- `data/derived/chns_height_premium_merged_person_wave.dta`
- `data/derived/chns_height_premium_analysis.dta`
- `output/figures/height_distribution.pdf`
- `output/figures/height_distribution.png`
- `output/figures/height_wage_scatter.pdf`
- `output/figures/height_wage_scatter.png`

The Python helper streams selected columns from the large CHNS wide panel and
aggregates job-level wages to person-year. It writes gitignored files under
`data/derived/`, avoiding full wide-table loading in Stata.

The final analysis-ready Stata dataset is
`data/derived/chns_height_premium_analysis.dta`. It is not committed because it
contains person-level derived data.

The IV specification uses average parental height as an instrument for own
height. This is useful as a first pass because it is likely relevant, but the
exclusion restriction is substantively weak: parental height may proxy family
background, childhood nutrition, local conditions, and genetic traits that can
affect wages through channels other than own adult height.
