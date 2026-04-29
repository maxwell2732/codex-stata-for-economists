---
paths:
  - "data/**"
  - ".gitignore"
  - "scripts/check_data_safety.py"
  - "dofiles/**/*.do"
---

# Data Protection Protocol

**Hard rule:** raw and derived datasets are NEVER committed to GitHub. Period. Treat this as on par with secrets management. A leak is not a "minor cleanup commit" — it persists in git history forever.

---

## What is Protected

| Path | Status | Notes |
|---|---|---|
| `data/raw/**` | NEVER COMMIT | Only `.gitkeep` and `README.md` allowed |
| `data/derived/**` | NEVER COMMIT | Intermediate `.dta`; reproducible from raw |
| `*.dta` (anywhere) | BLOCKED by default | Whitelisted: `output/tables/`, `templates/examples/`, `explorations/**/output/` |
| `*.csv` under `data/` | BLOCKED | Source data — same treatment as `.dta` |
| `*.xlsx`, `*.xls` | BLOCKED | Whitelisted under `output/tables/` only |
| `*.sav`, `*.por`, `*.parquet`, `*.feather` | BLOCKED | Same logic |
| `logs/*.log` / `logs/*.smcl` | NEVER COMMIT | May echo raw data |
| `*.gph` | NEVER COMMIT | Stata graph binaries — export to `.pdf`/`.png` instead |

The `.gitignore` enforces all of the above. The `protect-files.sh` hook protects `.gitignore` itself from accidental edits that would weaken these rules.

---

## What Is Allowed

- `output/tables/*.tex`, `*.csv`, `*.dta` (small, numeric, non-PII summary tables — committed for reviewer audit)
- `output/figures/*.pdf`, `*.png`, `*.svg` — published figures
- `data/README.md` — the data dictionary (no actual data, just metadata)
- `data/raw/.gitkeep`, `data/derived/.gitkeep` — empty marker files

If a forker has aggregated data with no privacy concerns and explicitly wants to commit it, they whitelist it via `!output/tables/<file>.dta` in `.gitignore` — a deliberate one-line opt-in.

---

## Pre-Commit Enforcement

`scripts/check_data_safety.py` is the second line of defense (after `.gitignore`). It accepts `--staged <files>` and exits non-zero if any staged path:

- Lives under `data/raw/` or `data/derived/` (other than `.gitkeep` / README)
- Has a binary data extension (`.dta`, `.sav`, `.por`, `.parquet`, `.feather`) outside whitelisted dirs
- Has a `.csv` extension under `data/`
- Is a Stata log (`.log`, `.smcl`) outside `quality_reports/`

Forkers wire this as a git pre-commit hook with one line in `.git/hooks/pre-commit`:

```bash
#!/bin/bash
python scripts/check_data_safety.py --staged $(git diff --cached --name-only)
```

The README documents this install step.

---

## Claude Behavior Rules

When Claude is operating on this repo:

1. **Never `git add` anything under `data/raw/` or `data/derived/`.** Even if the user appears to ask for it, refuse and explain why (privacy / leak risk).
2. **Never weaken `.gitignore`.** If a forker requests removal of a `data/**` block, ask them to confirm and document the reason in a commit message.
3. **Never paste raw-data values into commit messages, plan files, or session logs.** Aggregate statistics only.
4. **Never store data outside `data/`** to evade the rules (e.g., dropping a `.dta` in `dofiles/` or `output/figures/`).
5. **If a do-file `save`s to a non-`data/derived/` location**, flag it during code review.

---

## If a Leak Already Happened

If a raw dataset has been committed to git history:

1. **Stop pushing to remote** immediately if it has not been pushed yet
2. Use `git filter-repo` or BFG to scrub the file from history (not `git rm` — that leaves it in history)
3. Force-push the scrubbed history (coordinate with collaborators — destructive)
4. Treat the data as compromised: rotate any access tokens, notify the data provider if required
5. Add a postmortem entry to `quality_reports/incidents/` (not under `quality_reports/`'s normal cadence — these are special)

This is a destructive operation. The user must explicitly authorize it; do NOT run filter-repo autonomously.
