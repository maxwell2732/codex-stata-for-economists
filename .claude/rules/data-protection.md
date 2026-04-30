---
paths:
  - "data/**"
  - ".gitignore"
  - "scripts/check_data_safety.py"
  - "dofiles/**/*.do"
---

# Data Protection Protocol

**Hard rule:** raw and derived datasets are NEVER committed to GitHub. Treat this as on par with secrets management. A leak persists in git history.

---

## What Is Protected

| Path | Status | Notes |
|---|---|---|
| `data/raw/**` | NEVER COMMIT | Only `.gitkeep` and `README.md` allowed |
| `data/derived/**` | NEVER COMMIT | Intermediate `.dta`; reproducible from raw |
| `*.dta` | BLOCKED by default | Whitelisted only under `output/tables/` and `templates/examples/` |
| `*.csv` | BLOCKED by default | Whitelisted only under table/example output dirs |
| `*.json`, `*.jsonl` | BLOCKED by default | API dumps are data unless explicitly reviewed |
| `*.xlsx`, `*.xls` | BLOCKED by default | Whitelisted only under table/example output dirs |
| `*.sav`, `*.por`, `*.parquet`, `*.feather` | BLOCKED | Same logic |
| `logs/*.log` / `logs/*.smcl` | NEVER COMMIT | May echo raw data |
| `*.gph` | NEVER COMMIT | Stata graph binaries; export to `.pdf`/`.png` instead |

The `.gitignore` enforces these defaults. `scripts/check_data_safety.py` is the second line of defense and must stay at least as strict as `.gitignore`.

---

## What Is Allowed

- `output/tables/*.tex`, `*.csv`, `*.dta` for small, numeric, non-PII summary tables committed for reviewer audit.
- `output/figures/*.pdf`, `*.png`, `*.svg` for published figures.
- `explorations/*/output/tables/*.csv`, `*.xls`, and `*.xlsx` for small non-PII teaching or sandbox summary tables.
- `data/README.md` for the data dictionary, without actual data.
- `data/raw/.gitkeep` and `data/derived/.gitkeep` as empty marker files.

If a forker has aggregated data with no privacy concerns and explicitly wants to commit it, they must add the narrowest possible `.gitignore` exception and document the reason in review. Do not whitelist entire sandbox roots such as `explorations/`.

---

## Pre-Commit Enforcement

`scripts/check_data_safety.py` accepts `--staged <files>` and exits non-zero if any staged path:

- Lives under `data/raw/` or `data/derived/`, other than `.gitkeep` or `README.md`.
- Has a data-like extension (`.dta`, `.sav`, `.por`, `.parquet`, `.feather`, `.csv`, `.json`, `.jsonl`, `.xls`, `.xlsx`) outside narrow whitelisted table/example dirs.
- Is a Stata log or graph binary (`.log`, `.smcl`, `.gph`).

Forkers wire this as a git pre-commit hook:

```bash
#!/bin/bash
python scripts/check_data_safety.py --staged $(git diff --cached --name-only)
```

The README documents this install step.

---

## Claude Behavior Rules

When Claude is operating on this repo:

1. **Never `git add` anything under `data/raw/` or `data/derived/`.** Even if the user appears to ask for it, refuse and explain why.
2. **Never weaken `.gitignore`.** If a forker requests removal of a data block, ask them to confirm and document the reason in a commit message.
3. **Never paste raw-data values into commit messages, plan files, or session logs.** Aggregate statistics only.
4. **Never store data outside `data/`** to evade the rules, such as dropping a `.dta`, `.csv`, or API `.json` dump in `dofiles/`, `explorations/`, or `output/figures/`.
5. **If a do-file `save`s to a non-`data/derived/` location**, flag it during code review.

---

## If a Leak Already Happened

If a raw dataset has been committed to git history:

1. **Stop pushing to remote** immediately if it has not been pushed yet.
2. Use `git filter-repo` or BFG to scrub the file from history, not `git rm`.
3. Force-push the scrubbed history after coordinating with collaborators.
4. Treat the data as compromised: rotate any access tokens and notify the data provider if required.
5. Add a postmortem entry to `quality_reports/incidents/`.

This is a destructive operation. The user must explicitly authorize it; do not run filter-repo autonomously.
