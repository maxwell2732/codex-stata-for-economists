# Do-files

Source code for the Stata pipeline.

## Stages

| Folder | Purpose | Inputs | Outputs |
|---|---|---|---|
| `01_clean/` | Standardize raw data | `data/raw/*` | `data/derived/clean_*.dta` |
| `02_construct/` | Build samples + variables | `data/derived/clean_*.dta` | `data/derived/sample_*.dta` |
| `03_analysis/` | Estimation | `data/derived/sample_*.dta` | `output/tables/*`, `output/figures/*`, saved estimates |
| `04_output/` | Polish + assemble | `output/*` | rendered `reports/*.qmd` → `docs/*.html` |
| `_utils/` | Helpers (programs, ado-style) | n/a | reusable across stages |

## Conventions

- Each do-file opens its own log: `capture log close` then `log using logs/<name>.log, replace text`
- Each do-file is independently runnable from project root (no `cd`, only relative paths)
- `00_master.do` calls every other do-file in dependency order — never bypass it for production runs
- Pin Stata version at top: `version 17` (override in your fork)
- Use `set seed YYYYMMDD` once per do-file when randomness is involved
- Cluster SEs at the most aggregate plausible level by default — document the choice in a comment

See `.claude/rules/stata-coding-conventions.md` and `.claude/rules/stata-reproducibility-protocol.md`.

## Analysis Templates

- `templates/did-analysis-template.do`: copy to `dofiles/03_analysis/05_did.do` for TWFE DID, Callaway-Sant'Anna DID, pre-trend checks, and event-study output.
- `templates/ddml-analysis-template.do`: copy to `dofiles/03_analysis/06_ddml.do` for a DDML partial linear model using `ddml` with `rlasso` learners by default.
- `dofiles/00_master.do` records and optionally installs the extra DID/DDML dependencies when `local INSTALL_DEPS = 1`.
