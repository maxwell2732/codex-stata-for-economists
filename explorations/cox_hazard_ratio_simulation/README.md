# Cox Hazard Ratio Simulation

This exploration is a self-contained Stata simulation for Cox proportional hazards analysis.

## Contents

- `dofiles/07_cox_hazard_ratio.do`: simulates time-to-event data, runs `stset` and `stcox, hr`, exports a hazard-ratio table, runs a proportional-hazards diagnostic, and exports survival curves.
- `output/tables/cox_hazard_ratio_simulation.csv`: audit table with hazard ratios and confidence intervals.
- `output/tables/cox_hazard_ratio_simulation.tex`: LaTeX version of the table.
- `output/figures/cox_survival_curve_simulation.pdf`: survival-curve figure.
- `output/figures/cox_survival_curve_simulation.png`: survival-curve figure.
- `logs/`: Stata logs for this exploration. Logs are ignored by git.

## Run

From the repository root:

```powershell
scripts\run_stata.bat explorations\cox_hazard_ratio_simulation\dofiles\07_cox_hazard_ratio.do
```

Or run Stata directly:

```powershell
& 'D:\stata\StataMP-64.exe' /e do 'explorations\cox_hazard_ratio_simulation\dofiles\07_cox_hazard_ratio.do'
```
