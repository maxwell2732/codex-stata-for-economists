---
name: run-stata
description: Execute a single Stata do-file in batch mode via the project wrapper. Captures the log, surfaces any r(<n>) errors, and reports exit code and output paths.
disable-model-invocation: true
argument-hint: "[path/to/file.do]"
allowed-tools: ["Bash", "Read", "Grep", "Glob"]
---

# Run a Stata do-file

Execute one do-file end-to-end via `scripts/run_stata.sh` (POSIX) or `scripts/run_stata.bat` (Windows). The wrapper sets working directory to project root, derives the log path automatically, runs Stata in batch mode, and propagates the exit code.

## Steps

1. **Resolve the do-file path** from `$ARGUMENTS`:
   - If a full path: use it
   - If just a filename: search `dofiles/**/<name>.do`
   - If no argument: ask the user which do-file to run

2. **Pre-run checks:**
   - Confirm the file exists
   - Read its header `Inputs:` block — confirm each input file exists
   - Confirm the do-file opens its own log (grep for `log using`)

3. **Run the wrapper:**

   ```bash
   bash scripts/run_stata.sh dofiles/<stage>/<file>.do
   ```

   Capture both the wrapper's exit code and the path of the produced log.

4. **Validate the log** by delegating to `/validate-log` (or running the inline `grep` from the rule):

   ```bash
   grep -E "^r\(\d+\);|invalid syntax|not found|no observations|conformability" logs/<stage>_<file>.log
   ```

5. **Verify outputs** referenced in the do-file's `Outputs:` header block:

   ```bash
   ls -la output/tables/<expected>* output/figures/<expected>*
   ```

6. **Report to user:**

   - Exit code
   - Log path + size
   - Any errors found in log
   - Output files created (with mtimes)
   - Next-step suggestion (e.g., "ready to commit" or "fix log errors first")

## Examples

- `/run-stata dofiles/03_analysis/main_regression.do`
  → Runs main_regression.do; reports `logs/03_analysis_main_regression.log` and `output/tables/main_regression.{tex,csv}` produced.

- `/run-stata main_regression`
  → Searches `dofiles/**/main_regression.do`; runs the unique match.

- `/run-stata` (no argument)
  → Asks user which do-file.

## Troubleshooting

- **"stata: command not found"** — the wrapper tries `stata`, `stata-mp`, `stata-se`, `StataMP-64`, `StataSE-64` in order. If none work, install Stata or add it to PATH.
- **Wrapper exits 0 but log shows errors** — Stata sometimes returns 0 even on `r(<n>)` errors. Always run step 4. The `validate-log` skill catches this.
- **Log file not created** — the do-file is missing `log using`. Add it per `stata-coding-conventions.md`.
- **Permission denied** — `chmod +x scripts/run_stata.sh`.

## Notes

- This skill never runs `dofiles/00_master.do` — use `/run-pipeline` for that.
- Always run from project root; the wrapper enforces this.
