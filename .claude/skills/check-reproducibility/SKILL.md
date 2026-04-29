---
name: check-reproducibility
description: Simulate a fresh-clone reproduction of the entire pipeline and diff the new outputs against the committed ones. Catches drift before paper submission or release.
disable-model-invocation: true
argument-hint: ""
allowed-tools: ["Bash", "Read", "Grep", "Glob"]
---

# Check Reproducibility

Run the entire pipeline as if from a fresh clone, then `diff` the new `output/` against the committed `output/`. Any drift is a reproducibility failure.

## When to Use

- Before submitting a paper
- Before tagging a release
- Before merging a major branch
- When onboarding a new collaborator
- After any non-trivial Stata version upgrade

## Steps

1. **Pre-flight checks:**
   - Working tree is clean (`git status` shows no uncommitted changes) — otherwise the diff is meaningless. If dirty, ask the user to commit/stash first.
   - `data/raw/` is non-empty, OR a `RAW_DATA_RESTORE_CMD` is configured (e.g., a `make restore-raw` target or a download URL documented in `data/README.md`).

2. **Snapshot current outputs:**

   ```bash
   cp -r output /tmp/output_snapshot
   ```

3. **Clean the worktree** (preserves `data/raw/` since it's gitignored):

   ```bash
   bash scripts/check_reproducibility.sh --clean-only
   ```

   This wraps `git clean -dfx -e data/raw -e .claude/state` to wipe everything else.

4. **Re-run the pipeline:**

   ```bash
   bash scripts/run_pipeline.sh
   ```

   Capture exit code; if non-zero, the pipeline itself failed → reproducibility cannot be assessed.

5. **Diff:**

   ```bash
   diff -r /tmp/output_snapshot output | head -200
   ```

   For binary files (PDF, PNG), `diff` will report differences but not show them. Compare the `.csv` companions of any flagged tables — those are text and can be diffed cell-by-cell.

6. **Categorize drift:**

   - **Numerical drift** in `.csv` tables → FAIL (the analysis is non-reproducible; investigate seed, sample order, package versions)
   - **Visual drift** in `.pdf`/`.png` figures → typically WARN (could be font rendering, scheme, or an actual difference — open both and compare)
   - **Timestamp metadata only** → PASS (cosmetic; many tools embed timestamps)
   - **No drift** → PASS

7. **Restore snapshot if drift acceptable** (otherwise leave new outputs and investigate):

   ```bash
   rm -rf output && mv /tmp/output_snapshot output
   ```

8. **Report:**
   - Stages that ran + timings
   - Files that differ + diff category
   - Verdict: PASS / WARN / FAIL
   - If FAIL: top suspects (seeded randomness, package version drift, undeclared input)

## Examples

- `/check-reproducibility`
  → Runs the full check on the current working tree.

- `/check-reproducibility` after upgrading Stata to a new version
  → Reveals any version-sensitive results.

## Troubleshooting

- **Pipeline fails on re-run** — most common cause: a do-file references a file that exists locally but was never committed. Add it to git or document in `data/README.md`.
- **Numerical drift on bootstrap-based SE** — bootstrap is reproducible only if `set seed` is at the top, ONCE, and `bootstrap` itself doesn't reseed internally. Check the do-file.
- **Different cluster count from `reghdfe` singleton drop** — singleton drop depends on the order observations were merged in; if `merge` order is not deterministic, this can drift. Add an explicit `sort` before estimation.
- **Working tree dirty** — commit or stash before running this skill.

## Notes

- This skill is destructive: it wipes everything except `data/raw/`. Triple-check that step 3 succeeded with `data/raw/` intact.
- Long-running: full pipeline + diff. Run when you have time, not as a quick check.
- If the pipeline takes hours, consider running stage-by-stage diffs instead (compare `output/tables/<stage>` between runs).
