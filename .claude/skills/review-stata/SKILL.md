---
name: review-stata
description: Run the stata-reviewer agent on a do-file. Produces a structured code-review report covering reproducibility, logging, naming, magic numbers, table/figure quality, and conformance to project conventions.
disable-model-invocation: true
argument-hint: "[path/to/file.do]"
allowed-tools: ["Read", "Grep", "Glob", "Task"]
---

# Review a Stata Do-File

Delegate to the `stata-reviewer` agent and report the findings.

## Steps

1. **Resolve target** from `$ARGUMENTS`:
   - Full path: use it
   - Filename only: search `dofiles/**/*.do`
   - No argument: list `dofiles/**/*.do` and ask the user which to review

2. **Confirm the file exists** and is non-empty.

3. **Invoke the agent:**

   ```
   Delegate to stata-reviewer:
     "Review dofiles/<stage>/<file>.do.
      Read the do-file, the most recent log at logs/<stage>_<file>.log (if it exists),
      and follow stata-coding-conventions, stata-reproducibility-protocol, and quality-gates.
      Produce the report in the standard format."
   ```

4. **Receive the agent's report** at `quality_reports/<dofile>_stata_review.md`.

5. **Summarize for the user:**
   - Quality score
   - Total issues by severity
   - Top 3 critical/high issues with line references
   - Verdict: ready-to-commit / needs-revision

6. **Offer to apply fixes** for high-confidence single-line issues (per `proofreading-protocol`'s propose-then-apply pattern). Never apply silently.

## Examples

- `/review-stata dofiles/03_analysis/main_regression.do`
  → Full review with score and issue list.

- `/review-stata main_regression`
  → Searches `dofiles/**/main_regression.do`.

- `/review-stata` (no argument)
  → Lists candidates and asks.

## Troubleshooting

- **Agent reports "no log file"** — run the do-file via `/run-stata` first; the reviewer benefits from log context.
- **Score is high but you suspect a substantive issue** — `stata-reviewer` covers code quality, not econometric correctness. Use `econometric-reviewer` (or `/devils-advocate`) for that.
- **Agent disagrees with your style** — adjust `stata-coding-conventions.md` for project-specific overrides; the agent reads that rule.

## Notes

- This skill scores code quality, not result correctness. For result correctness use `/validate-log` (claims) and the `econometric-reviewer` agent (specs).
- The review report lives in `quality_reports/` and persists across sessions; re-running this skill overwrites the previous report for that file.
