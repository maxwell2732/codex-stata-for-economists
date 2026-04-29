# AGENTS.md - Codex Operating Guide

This repository is a Stata empirical-research workflow template. Codex should preserve the existing Stata pipeline behavior while using this file as the primary project instruction source.

## Project Purpose

- Maintain a reproducible Stata workflow for empirical economics research.
- Keep `dofiles/00_master.do` as the single end-to-end pipeline entry point.
- Keep raw data out of version control.
- Produce audit-friendly tables, figures, logs, and Quarto reports.
- Preserve the existing Claude Code assets under `.claude/` as reference material; do not remove them unless the user explicitly asks.

## Repository Map

- `dofiles/00_master.do`: canonical pipeline orchestrator.
- `dofiles/01_clean/`: raw data to cleaned data.
- `dofiles/02_construct/`: variable construction and samples.
- `dofiles/03_analysis/`: estimation, robustness, event studies, IV, DiD, etc.
- `dofiles/04_output/`: table and figure assembly.
- `dofiles/_utils/`: reusable Stata helpers.
- `data/raw/`: raw datasets, gitignored.
- `data/derived/`: intermediate datasets, gitignored.
- `logs/`: Stata logs, gitignored.
- `output/tables/`: committed publication/audit tables.
- `output/figures/`: committed figures.
- `reports/`: Quarto reports.
- `scripts/`: wrappers and quality tooling.
- `explorations/`: self-contained sandbox analyses and teaching demos.
- `templates/`: reusable project templates.
- `.claude/`: legacy Claude Code agents, skills, rules, and hooks. Treat as reference.

## Non-Negotiable Rules

- No numerical research claim without a source in `logs/*.log` or `output/tables/*`.
- Do not fabricate or infer coefficients, standard errors, p-values, sample sizes, or summary statistics.
- Do not commit or expose raw or derived datasets from `data/raw/` or `data/derived/`.
- Do not weaken `.gitignore` data-protection rules without explicit user confirmation.
- Use relative paths in Stata code. Avoid hardcoded machine-specific paths.
- Every substantive `.do` file should have `version`, `set more off`, `set varabbrev off`, logging, and a clear header.
- Write new or modified Stata do-file comments in Chinese unless the user requests another language.
- Keep reports downstream of pipeline outputs. Reports should consume `output/`, not become the primary analysis source.
- Do not edit protected files casually: `dofiles/00_master.do`, `.gitignore`, and bibliography files if added later.

## Commands

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

Score an artifact:

```bash
python scripts/quality_score.py dofiles/03_analysis/main_regression.do
python scripts/quality_score.py reports/analysis_report.qmd
python scripts/quality_score.py scripts/check_data_safety.py
```

Check staged files for data leaks:

```bash
python scripts/check_data_safety.py --staged $(git diff --cached --name-only)
```

## Stata Conventions

- Local Stata is Stata 15: `C:\Program Files (x86)\Stata15\Stata-64.exe`.
- Pin Stata do-files to `version 15` unless the user explicitly changes the project standard.
- Pin the Stata version at the top of each `.do` file.
- Use one project-wide seed unless a task has a documented reason to do otherwise.
- Open and close logs inside runnable do-files.
- Store estimation results with `estimates store` or `est store` when table assembly depends on them.
- Export figures as `.pdf` and `.png`; do not keep `.gph` as a committed artifact.
- Prefer `esttab` outputs as `.tex` plus `.csv` for auditability.
- Cluster standard errors at the most defensible aggregate level and document the choice.

## Local Environment

- Python is Miniconda, not the Microsoft Store Python.
- Miniconda root: `C:\ProgramData\Miniconda3`.
- Conda executable: `C:\ProgramData\Miniconda3\Scripts\conda.exe`.
- Python executable: `C:\ProgramData\Miniconda3\python.exe`.
- Stata executable: `C:\Program Files (x86)\Stata15\Stata-64.exe`.
- Prefer explicit executable paths if `python`, `conda`, or `stata` are not found on `PATH`.

## Log Verification

Before stating a numerical result:

1. Find the current log or output table.
2. Verify the value appears in that artifact.
3. Cite the artifact path and, when practical, the surrounding context or line.
4. If no current artifact exists, say that the do-file must be run first.

Use this response pattern when blocked:

```text
I cannot state that result because no fresh log or output table backs it. I need to run the relevant do-file first, or remove the numerical claim.
```

## Data Protection

Never add these to version control:

- `data/raw/**`, except `.gitkeep` and documentation.
- `data/derived/**`, except `.gitkeep` and documentation.
- Stata logs under `logs/`.
- Stata binary graphs `*.gph`.
- Data files such as `*.dta`, `*.sav`, `*.por`, `*.parquet`, `*.feather`, except whitelisted output/example paths.
- Raw-data-style spreadsheets or CSVs under `data/`.

Allowed committed outputs:

- `output/tables/*.csv`, `*.tex`, and other small non-PII summary tables.
- `output/figures/*.pdf`, `*.png`, `*.svg`.
- Template/example fixtures only when intentionally whitelisted.

## Quality Gates

- `80/100`: acceptable for commit.
- `90/100`: PR-ready.
- `95/100`: excellence target.

Run `python scripts/quality_score.py <file>` before finalizing substantive edits to `.do`, `.qmd`, or user-facing Python scripts.

For `explorations/`, the quality bar is relaxed because these are sandbox or teaching analyses, but they still need to be runnable and honest about limitations.

## Codex Workflow

- Inspect relevant files before editing.
- Prefer small, targeted patches.
- Preserve user changes and do not revert unrelated edits.
- Keep this repository usable by both Codex and Claude Code.
- If changing workflow rules, update `AGENTS.md` and any affected README section together.
- If changing Stata behavior, run the relevant wrapper when Stata is available; otherwise state exactly what was not verified.

## Legacy Claude Code Material

The `.claude/` directory contains richer rule, agent, and skill documentation. Codex should consult it when deeper guidance is needed, especially:

- `.claude/rules/log-verification-protocol.md`
- `.claude/rules/data-protection.md`
- `.claude/rules/quality-gates.md`
- `.claude/rules/stata-coding-conventions.md`
- `.claude/rules/stata-reproducibility-protocol.md`
- `.claude/skills/stata/SKILL.md`

Do not assume Claude-only commands such as `/run-stata` exist in Codex. Use the shell commands documented above.
