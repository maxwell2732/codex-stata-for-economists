---
name: validate-log
description: Scan a Stata log file for errors, warnings, suspicious patterns, and silent failures. Cross-check claimed numerical results against log contents.
disable-model-invocation: true
argument-hint: "[path/to/log file] [optional: claim to verify]"
allowed-tools: ["Bash", "Read", "Grep", "Task"]
---

# Validate a Stata Log

Two modes:

**Mode A — log scan**: pass only a log path. The skill greps for known error/warning patterns and reports them.

**Mode B — claim verification**: pass a log path + a numerical claim. The skill delegates to the `log-validator` agent, which confirms (or denies) the claim against the log.

## Mode A: Log Scan

### Steps

1. **Resolve log path** from `$ARGUMENTS` (or list `logs/*.log` if not given and ask).

2. **Run the standard error grep:**

   ```bash
   grep -nE "^r\(\d+\);" logs/<file>.log              # Stata error code lines
   grep -nE "invalid syntax|not found|no observations|conformability error" logs/<file>.log
   grep -nE "no variables defined|file ... already exists" logs/<file>.log
   ```

3. **Check the merge tab** (silent dropped rows are a common bug):

   ```bash
   grep -A 5 "_merge" logs/<file>.log
   ```

   Flag any merge where `_merge == 1` (master only) or `_merge == 2` (using only) is non-zero AND the do-file does not handle it.

4. **Check sample-size funnel** (required by `econometric-best-practices`):

   ```bash
   grep -E "Sample N|after restriction" logs/<file>.log
   ```

   The log should show N at each restriction step.

5. **Check the tail** for the most-recent estimation output, sanity-checking magnitude / sign / SE plausibility.

6. **Report findings** as a structured list:
   - Errors: count + context for each
   - Suspicious patterns: count + context
   - Sample funnel: present / missing
   - Last estimation: spec + headline coef + SE

## Mode B: Claim Verification

If `$ARGUMENTS` includes a claim (any sentence with a number after the log path):

1. Delegate to the `log-validator` agent:

   ```
   Claim: <quoted claim>
   Log: <log path>

   Verify per the log-verification-protocol rule.
   ```

2. Report the agent's verdict (`VERIFIED` / `MISMATCH` / `UNVERIFIED`) verbatim.

## Examples

- `/validate-log logs/03_analysis_main_regression.log`
  → Mode A: scans for errors and reports.

- `/validate-log logs/03_analysis_main_regression.log "ATT = -1.632 (SE 0.584)"`
  → Mode B: confirms the claim is in the log.

- `/validate-log` (no args) → lists `logs/*.log` and asks which to scan.

## Troubleshooting

- **No log files** — either the do-file hasn't run, or it doesn't open a log. Fix per `stata-coding-conventions`.
- **Log exists but is `.smcl`** — convert with `translate <name>.smcl <name>.log` in Stata, or update the do-file to use `log using ..., text`.
- **Grep finds errors but the do-file ran "successfully"** — `capture` likely swallowed an error. Check do-file for `capture` blocks.

## Notes

- This skill is the operational backbone of `log-verification-protocol`. Use it before any commit that adds numerical claims.
- The `log-validator` agent (Mode B) refuses to validate fabricated claims — that's the design.
