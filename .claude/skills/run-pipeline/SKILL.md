---
name: run-pipeline
description: Execute the full Stata pipeline via dofiles/00_master.do. Runs every stage in dependency order, aborts on first error, prints stage timings, and reports final output tree.
disable-model-invocation: true
argument-hint: ""
allowed-tools: ["Bash", "Read", "Grep", "Glob"]
---

# Run the Full Pipeline

Execute `dofiles/00_master.do` end-to-end via `scripts/run_pipeline.sh`. This is the canonical "rebuild everything" command.

## Steps

1. **Pre-flight checks:**
   - Confirm `dofiles/00_master.do` exists
   - Confirm `data/raw/` is non-empty (otherwise the cleaning stage will fail with no inputs)
   - Confirm Stata is on PATH (`which stata` or `which stata-mp`)

2. **Run the pipeline:**

   ```bash
   bash scripts/run_pipeline.sh
   ```

   The wrapper:
   - Records start time
   - Runs `dofiles/00_master.do` in batch mode
   - Streams stage timings as each `do dofiles/XX/...` call completes
   - Aborts on first non-zero exit code
   - Prints total wall time at the end

3. **Inspect the environment snapshot:** `logs/00_master_environment.log` should contain Stata version, flavor, OS, and `which` of key user-written commands.

4. **Validate stage logs:**
   For each `logs/<stage>_*.log` produced, grep for errors:

   ```bash
   for L in logs/*.log; do
     N=$(grep -c -E "^r\(\d+\);|invalid syntax|not found" "$L")
     [ "$N" -gt 0 ] && echo "$L: $N error matches"
   done
   ```

5. **Verify expected outputs:**
   - `output/tables/` and `output/figures/` populated
   - Spot-check that key tables/figures referenced in `reports/*.qmd` exist and are newer than the producing do-files (freshness check from `single-source-of-truth`)

6. **Report:**
   - Total runtime
   - Per-stage timings (from wrapper output)
   - Logs produced + any errors
   - Output files created
   - Next step (re-run a single stage, render report, commit)

## Examples

- `/run-pipeline`
  → Builds the entire pipeline; reports timing + outputs.

- After data refresh: `/run-pipeline` then `/render-report reports/analysis_report.qmd`.

## Troubleshooting

- **Pipeline aborts at stage 02_construct** — check the log of the LAST do-file in stage 01_clean; merge errors are common when raw data shape changes.
- **`reghdfe` not found** — run `ssc install reghdfe ftools, replace` once. Or run `dofiles/00_master.do` with the `INSTALL_DEPS = 1` flag (see master.do header).
- **Stata not found** — see `/run-stata` troubleshooting; the same `command -v` chain applies.
- **Permission denied** — `chmod +x scripts/run_pipeline.sh`.

## Notes

- This skill is destructive: it overwrites everything in `output/`. Commit any in-progress work before running.
- Long-running: for typical empirical work, expect minutes to tens of minutes. The wrapper does not background — run it and wait.
- For partial re-runs (one stage), use `/run-stata` instead.
