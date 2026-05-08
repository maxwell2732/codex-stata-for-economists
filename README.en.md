<p align="center">
  <a href="https://doi.org/10.5281/zenodo.19902598">
    <img src="https://zenodo.org/badge/DOI/10.5281/zenodo.19902598.svg" alt="DOI">
  </a>
  <a href="README.md">
    <img src="https://img.shields.io/badge/语言-中文-blue" alt="中文">
  </a>
  <a href="README.en.md">
    <img src="https://img.shields.io/badge/Language-English-green" alt="English">
  </a>
</p>

# Codex Stata for Economists

**Author:** Chen Zhu | China Agricultural University (CAU)

**Last updated:** 2026-05-08

**Acknowledgment:** [@shy7890](https://github.com/shy7890) for bug fixes.

Codex Stata for Economists is a reproducible Stata research workflow template for empirical economics, management, business-school research, and applied social science.

It gives researchers a clean project structure for raw data, derived data, do-files, logs, tables, figures, Quarto reports, and exploratory analyses. The repository is designed for AI-assisted empirical work with Codex while keeping the key research rule explicit:

> No numerical claim without a log or output table to verify it.

## Why This Repo Exists

Empirical projects often become hard to audit because data cleaning, variable construction, model estimation, table generation, and reporting drift into separate scripts or ad hoc notebooks. This template keeps the research workflow explicit and reproducible:

- one canonical pipeline entry point;
- raw and derived data protected from git by default;
- Stata logs for verification;
- small committed tables and figures for review;
- Quarto reports downstream of generated outputs;
- a sandbox for method demos and one-off experiments.

The repository is **Codex-first** and **Claude Code compatible**. Codex should read `AGENTS.md` as the primary operating guide. The existing `.claude/` and `CLAUDE.md` files are retained as compatibility and reference material.

## What It Helps You Do

- Build reproducible Stata pipelines around `dofiles/00_master.do`.
- Keep `data/raw/` and `data/derived/` out of version control.
- Generate audit-friendly regression tables, summary tables, and figures.
- Run common empirical workflows including descriptive statistics, OLS, fixed effects, IV, event studies, DID, DDML, and sandbox Cox hazard-ratio simulations.
- Store exploratory work in `explorations/` before promoting it into the production pipeline.
- Maintain the project with Codex under explicit rules for data safety, log verification, and graph output.

## Example Outputs

<p align="center">
  <img src="explorations/mroz_tutorial/output/figures/mroz_faminc_histogram.png" width="45%">
  <img src="explorations/mroz_tutorial/output/figures/mroz_wage_educ_scatter.png" width="45%">
</p>

<p align="center">
  <img src="explorations/cox_hazard_ratio_simulation/output/figures/cox_survival_curve_simulation.png" width="45%">
  <img src="explorations/staggered_did_simulation/output/figures/csdid_event_study.png" width="45%">
</p>

<p align="center">
  <img src="master_supporting_docs/supporting_papers/codeexample1.png" width="45%">
  <img src="master_supporting_docs/supporting_papers/codeexample2.png" width="45%">
</p>

## Quick Start

Prerequisites:

- Codex
- Stata
- Python 3 or Miniconda
- Git and a GitHub account
- Quarto, recommended for reports

Fork and clone:

```bash
git clone https://github.com/YOUR_USERNAME/codex-stata-for-economists.git my-codex-stata-for-economists
cd my-codex-stata-for-economists
```

Start Codex from the repository root:

```bash
codex
```

Place your research data in `data/raw/`, then ask Codex to read `AGENTS.md` and build the Stata analysis you need. For example:

```text
I put [DATA NAME.dta] in data/raw/. Please read AGENTS.md and the repository configuration, then help me run a reproducible Stata analysis. Generate descriptive statistics, figures, and regression results as needed. Save the code as a do-file with clear comments, and save outputs under output/.
```

## Repository Structure

```text
.
├── AGENTS.md                       # Primary Codex operating guide
├── CLAUDE.md                       # Claude Code compatibility notes
├── dofiles/
│   ├── 00_master.do                # Canonical pipeline entry point
│   ├── 01_clean/                   # Raw data to cleaned data
│   ├── 02_construct/               # Samples and variables
│   ├── 03_analysis/                # Estimation
│   ├── 04_output/                  # Table and figure assembly
│   └── _utils/                     # Reusable Stata helpers
├── data/
│   ├── raw/                        # Raw data, gitignored
│   └── derived/                    # Intermediate data, gitignored
├── logs/                           # Production Stata logs, gitignored
├── output/
│   ├── tables/                     # Committed summary tables
│   └── figures/                    # Committed figures
├── reports/                        # Quarto reports
├── scripts/                        # Wrappers and quality checks
├── explorations/                   # Sandbox analyses and teaching demos
└── templates/                      # Reusable project templates
```

## Supported Workflows

The production pipeline supports common Stata empirical workflows:

- descriptive statistics and publication tables;
- graphs exported as both PDF and PNG;
- OLS and fixed-effects regressions;
- IV regressions;
- event studies;
- DID, including TWFE and staggered DID templates;
- DDML templates using `ddml` and `rlasso`;
- Cox hazard-ratio / survival-analysis examples using `stset`, `stcox, hr`, proportional-hazards diagnostics, and survival-curve exports under `explorations/cox_hazard_ratio_simulation/`;
- Quarto reports downstream of output files.

Method tests and simulations should start under `explorations/`. Current examples include:

- `explorations/hsb2_teaching_demo/`
- `explorations/educwages_tutorial/`
- `explorations/staggered_did_simulation/`
- `explorations/cox_hazard_ratio_simulation/`

## Core Rules

- Do not commit raw or derived data.
- Do not fabricate coefficients, standard errors, p-values, sample sizes, or summary statistics.
- Do not report numerical research claims unless they are backed by `logs/*.log` or `output/tables/*`.
- Keep `dofiles/00_master.do` as the single end-to-end entry point.
- Put simulations and method experiments in `explorations/<project>/` first.
- Export Stata figures as both `.pdf` and `.png`.
- Keep logs in the appropriate `logs/` folder; do not leave root-level Stata logs.

## Common Commands

Run a single do-file:

```bash
bash scripts/run_stata.sh dofiles/03_analysis/main_regression.do
```

Run the full pipeline:

```bash
bash scripts/run_pipeline.sh
```

Render the report:

```bash
quarto render reports/analysis_report.qmd
```

Check staged files for data leaks:

```bash
python scripts/check_data_safety.py --staged $(git diff --cached --name-only)
```

Score a do-file or script:

```bash
python scripts/quality_score.py dofiles/03_analysis/main_regression.do
```

## Local Environment Notes

This template is currently configured around Stata 15 on Windows:

```text
C:\Program Files (x86)\Stata15\Stata-64.exe
```

Python is expected to be Miniconda:

```text
C:\ProgramData\Miniconda3\python.exe
```

Forks can update these paths in their local setup, but do-files should use relative project paths.

## Short Description for Sharing

> A Codex-first Stata workflow template for empirical economists: reproducible pipelines, protected data folders, log-verified results, publication-ready tables and figures, Quarto reports, and sandbox method demos.

## License

MIT.
