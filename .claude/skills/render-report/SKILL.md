---
name: render-report
description: Render a Quarto report (Stata engine) to HTML / PDF / DOCX. Performs freshness check on included tables/figures, verifies the Stata Quarto engine, and validates numerical claims before rendering.
disable-model-invocation: true
argument-hint: "[reports/file.qmd]"
allowed-tools: ["Bash", "Read", "Grep", "Glob", "Task"]
---

# Render a Quarto + Stata Report

Render a `.qmd` report that uses the Stata Quarto engine (or pure-Markdown Stata code blocks). Pre-flight checks ensure the report is **complete**, **fresh**, and **honest** (no unverified numerical claims).

## When to Use

- After completing an analysis, to assemble the writeup
- Before sharing with coauthors / advisors
- Before a paper-submission deadline

## Steps

### 1. Resolve the file

From `$ARGUMENTS` find the `.qmd`. If just a basename, search `reports/`. If empty, list `reports/*.qmd` and ask.

### 2. Pre-flight checks

a) **Quarto + Stata engine available:**

   ```bash
   quarto check
   ```

   Confirm "Stata: OK" (or equivalent). If missing, emit a clear setup instruction:

   > "Quarto's Stata engine is not installed. Install with: `pip install nbstata` (or `pip install pystata`), then re-run."

   Do NOT attempt to render without the engine — it will fail confusingly.

b) **No inline analysis** — grep the `.qmd` for analysis commands inside Stata code chunks:

   ```bash
   grep -n -E "regress|reghdfe|ivreg|areg|xtreg|csdid" reports/<file>.qmd
   ```

   If found inside ```{stata}``` chunks → flag and refuse to render. Analysis lives in `dofiles/`, not in reports.

c) **Freshness check** for every included artifact (per `single-source-of-truth`):

   - For each `output/tables/X` or `output/figures/X` referenced in the `.qmd`
   - Find the producing do-file (grep for the path in `dofiles/`)
   - If do-file mtime > artifact mtime → STALE → re-run via `/run-stata` BEFORE rendering

d) **Citation completeness:**

   - Extract every `@key` from the `.qmd`
   - Confirm each appears in `references.bib`

e) **Numerical-claim validation:**

   - Identify text claims with numbers (regex on the Markdown narrative outside code chunks)
   - Delegate each to the `log-validator` agent against the relevant `logs/*.log`
   - If any claim is `UNVERIFIED` → refuse to render until either the do-file re-runs or the claim is removed

### 3. Render

```bash
quarto render reports/<file>.qmd
```

By default, produces HTML in `docs/` (or report-local `_files/`). For PDF or DOCX, the `.qmd` needs the `format` block to declare them.

### 4. Post-render verification

- Confirm output exists and is non-empty
- Open the rendered HTML and confirm figures and tables display (read the rendered file's image references)
- No "Could not render" placeholders

### 5. Report to user

- Path of rendered output
- Freshness verdict
- Numerical-claim verdict (N verified, 0 unverified)
- Citation completeness (N keys, 0 missing)
- Next step (commit / share / revise)

## Examples

- `/render-report reports/analysis_report.qmd`
  → Full pre-flight + render.

- `/render-report analysis_report` → resolves to `reports/analysis_report.qmd`.

## Troubleshooting

- **"No engine for stata"** — install `nbstata` or `pystata`; see Quarto Stata engine docs.
- **Render hangs** — typically the Stata engine launching a long computation. Reports should NOT do analysis; refactor into `dofiles/`.
- **Broken figure path** — the `.qmd` references `output/figures/X.pdf` but the file doesn't exist. Re-run the producing do-file.
- **`Bibliography file not found`** — the `_quarto.yml` should point to `bibliography: ../references.bib` (relative from `reports/`).

## Notes

- Reports are output, not source. They should NOT contain analysis logic. If a result is ad-hoc, put it in a do-file first, then `include` from there.
- Numerical-claim validation is a HARD GATE. If a claim cannot be verified, the report does not render. This is per `log-verification-protocol`.
- Output goes to `docs/` for GitHub Pages compatibility (set in `_quarto.yml`).
