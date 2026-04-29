# CLAUDE.md — Stata Research Pipeline for Economists (Template)

> Codex note: use `AGENTS.md` as the primary instruction file. This file is retained for Claude Code compatibility.

<!-- HOW TO USE: Replace [BRACKETED PLACEHOLDERS] when forking this template.
     Keep this file under ~150 lines — Claude loads it every session.
     See README.md for setup instructions. -->

**Project:** [YOUR PROJECT NAME] — Stata Research Pipeline (forked from `claudecode-stata-for-economists`)
**Maintainer:** [YOUR NAME] — [YOUR INSTITUTION]
**Template author:** Chen Zhu — China Agricultural University (CAU)
**Branch:** main

---

## Core Principles

- **Plan first** — enter plan mode before non-trivial tasks; save plans to `quality_reports/plans/`
- **Verify after** — run the do-file, inspect the log, confirm output exists at the end of every task
- **Single source of truth** — `dofiles/00_master.do` is authoritative; reports include only outputs it produces
- **Log-verified results** — every numerical claim must trace to a `logs/*.log` line or `output/tables/*.csv` cell. **No log, no claim.**
- **Data privacy** — nothing under `data/raw/` or `data/derived/` is ever committed. Pre-commit safety check enforced.
- **Reproducibility** — `version` pinned, `set seed YYYYMMDD` once, `.do` files runnable from a fresh clone
- **Quality gates** — nothing ships below 80/100
- **[LEARN] tags** — when corrected, save `[LEARN:category] wrong → right` to MEMORY.md

---

## Folder Structure

```
[YOUR-PROJECT]/
├── CLAUDE.md                       # This file
├── .claude/                        # Rules, skills, agents, hooks
├── references.bib                  # Centralized bibliography
├── dofiles/
│   ├── 00_master.do                # Pipeline orchestrator (PROTECTED)
│   ├── 01_clean/                   # Raw → clean .dta
│   ├── 02_construct/               # Variable construction, samples
│   ├── 03_analysis/                # Regressions, IV, DiD, event studies
│   ├── 04_output/                  # esttab tables + graph exports
│   └── _utils/                     # Reusable helpers (programs, ado-style)
├── data/
│   ├── raw/                        # GITIGNORED — raw datasets (never committed)
│   ├── derived/                    # GITIGNORED — intermediate .dta
│   └── README.md                   # Data dictionary + provenance
├── logs/                           # GITIGNORED — *.log/*.smcl per do-file run
├── output/
│   ├── tables/                     # esttab .tex/.csv (committed)
│   └── figures/                    # graph export .pdf/.png/.svg (committed)
├── reports/
│   ├── analysis_report.qmd         # Quarto + Stata engine
│   └── _quarto.yml
├── docs/                           # Rendered HTML reports (GitHub Pages)
├── scripts/                        # run_stata.sh, quality_score.py, …
├── quality_reports/                # Plans, session logs, merge reports
├── explorations/                   # Sandbox (see exploration rules)
├── templates/                      # master.do, replication-targets, …
└── master_supporting_docs/         # Reference papers
```

---

## Commands

```bash
# Run a single do-file (creates logs/<name>.log, returns Stata exit code)
bash scripts/run_stata.sh dofiles/03_analysis/main_regression.do

# Run the full pipeline (calls dofiles/00_master.do, aborts on first error)
bash scripts/run_pipeline.sh

# Render the Markdown/PDF report (Quarto + Stata engine)
quarto render reports/analysis_report.qmd

# Pre-commit data-safety check (recommended as git pre-commit hook)
python scripts/check_data_safety.py --staged $(git diff --cached --name-only)

# Quality score for a do-file (0–100)
python scripts/quality_score.py dofiles/03_analysis/main_regression.do
```

---

## Stata Conventions (Non-Negotiable)

- **Stata version on this machine:** Stata 15 (`C:\Program Files (x86)\Stata15\Stata-64.exe`).
  Added to PATH via `~/.bashrc` so `scripts/run_stata.sh` resolves it.
  **Do NOT use Stata 18** even though it is installed — version mismatches break reproducibility.
- **Python on this machine:** Miniconda at `C:\ProgramData\Miniconda3\python.exe`.
  Conda is at `C:\ProgramData\Miniconda3\Scripts\conda.exe`.
- **Pin Stata version** at top of every do-file: `version 15`
- **Required user-written commands:** `reghdfe`, `ftools`, `estout`, `ivreg2`, `boottest`. See `templates/master-do-template.do` for `ssc install` recipe.
- **Per-do-file logging:** `capture log close` then `log using logs/<name>.log, replace text`
- **Reproducible randomness:** `set seed YYYYMMDD` at the top, never inside loops
- **Relative paths only** — never `cd` to absolute paths; always reference from project root
- **Cluster SEs** at the most aggregate plausible level by default; document the choice

---

## Quality Thresholds

| Score | Gate | Meaning |
|-------|------|---------|
| 80 | Commit | Good enough to save |
| 90 | PR | Ready for deployment |
| 95 | Excellence | Aspirational |

---

## Skills Quick Reference

| Command | What It Does |
|---------|-------------|
| `/run-stata [file.do]` | Execute do-file in batch mode + tail log |
| `/run-pipeline` | Run `dofiles/00_master.do` end-to-end |
| `/build-tables` | Combine `est store` results into publication esttab output |
| `/validate-log [file.log]` | Scan log for errors; cross-check claimed results |
| `/replicate [paper]` | Replication protocol against a paper's reported results |
| `/render-report [report.qmd]` | Render Quarto report (Stata engine) |
| `/check-reproducibility` | Fresh-clone simulation: run pipeline + diff outputs |
| `/review-stata [file.do]` | Stata code-quality review |
| `/data-analysis [topic]` | End-to-end Stata analysis workflow |
| `stata` (auto-loaded) | Comprehensive Stata reference: 38 core topic guides + 20 community-package guides (vendored from `dylantmoore/stata-skill`). Loads automatically when writing/debugging Stata code. |
| `/proofread [file]` | Grammar / typo / consistency review |
| `/validate-bib` | Cross-reference citations against `references.bib` |
| `/devils-advocate` | Challenge analytical decisions before committing |
| `/lit-review [topic]` | Literature search + synthesis |
| `/research-ideation [topic]` | Research questions + empirical strategies |
| `/interview-me [topic]` | Interactive research interview |
| `/review-paper [file]` | Manuscript review |
| `/pedagogy-review [file]` | Narrative + notation review (for reports) |
| `/commit [msg]` | Stage, commit, PR, merge |

---

## Pipeline Stages

| # | Stage Folder | Inputs | Outputs |
|---|--------------|--------|---------|
| 1 | `dofiles/01_clean/` | `data/raw/*` | `data/derived/clean_*.dta` |
| 2 | `dofiles/02_construct/` | `data/derived/clean_*.dta` | `data/derived/sample_*.dta` |
| 3 | `dofiles/03_analysis/` | `data/derived/sample_*.dta` | `output/tables/*.tex`, `output/figures/*.pdf`, saved estimates |
| 4 | `dofiles/04_output/` | `output/tables/*`, `output/figures/*` | rendered `reports/analysis_report.qmd` → `docs/*.html` |

---

## Protected Files (do not edit without intent)

`dofiles/00_master.do`, `references.bib`, `.gitignore` are guarded by a PreToolUse hook (`.claude/hooks/protect-files.sh`). Edit manually if you must, or relax the protection list there.
