---
paths:
  - "dofiles/**/*.do"
  - "templates/**/*.do"
  - "scripts/run_*.sh"
  - "scripts/run_*.bat"
---

# Stata Reproducibility Protocol

**Bottom line:** anyone with this repo and the raw data must reproduce every committed table and figure with **one command**: `bash scripts/run_pipeline.sh`. No interactive editing, no manual ordering.

---

## The Single Entry Point

`dofiles/00_master.do` is the only legitimate way to run the whole pipeline. It:

1. Sets project-wide options (`version`, `clear all`, `set more off`, `set varabbrev off`)
2. Optionally runs the dependency installer (`ssc install reghdfe ftools estout ivreg2 ranktest boottest, replace`) — gated behind a flag so it doesn't reinstall on every run
3. Saves a `creturn list` snapshot to `logs/00_master_environment.log` (Stata flavor, version, OS)
4. Calls each stage's do-files in dependency order, stopping on first error
5. Exits with a non-zero return code if any stage fails

Sub do-files MUST also be **independently runnable** from project root for debugging — never require `master.do` to have been executed first.

---

## Version Pinning

- Top of every do-file: `version 17` (or your fork's pin)
- Top of `master.do`: `version 17` PLUS a comment recording the **patch level** the pipeline was last validated against (e.g., `// Validated on Stata 17.0 (rev. 2024-04-30)`)
- Pin user-written commands by recording installed dates in `logs/00_master_environment.log` via `which reghdfe`, `which esttab`, etc.

If a forker updates Stata, they should re-run `scripts/check_reproducibility.sh` and bump the validation comment.

---

## Randomness

- `set seed YYYYMMDD` exactly **once** per do-file, at the top
- Never inside loops, functions (`program`), or simulations — Stata's RNG state is global; re-seeding mid-stream defeats reproducibility
- For Monte Carlo work, document the bootstrap reps and seed in the do-file header AND in the resulting log

---

## Logging

Every do-file MUST open and close its own log:

```stata
capture log close
log using "logs/<stage>_<name>.log", replace text
... do-file body ...
log close
```

`text` (not `smcl`) makes logs greppable for the `log-validator` agent.

---

## Environment Snapshot

`master.do` writes `logs/00_master_environment.log` containing:

```
* Stata version + flavor
display "Stata version: " c(stata_version)
display "Flavor: " c(flavor)
display "OS: " c(os)
display "Username: " c(username)
display "Date: " c(current_date) " " c(current_time)

* Key user-written commands
which reghdfe
which esttab
which ivreg2
which boottest
```

This log is the single artifact a reviewer needs to know whether your environment matches theirs.

---

## Reproducibility Test

`scripts/check_reproducibility.sh` simulates a fresh-clone reproduction:

1. Snapshot current `output/` tree
2. `git clean -dfx` in a tmp worktree (or copy of repo)
3. Restore `data/raw/` from the user-configured location
4. Run `bash scripts/run_pipeline.sh`
5. Diff new `output/` against the snapshot
6. Report drift as PASS / WARN (cosmetic) / FAIL (numerical)

Run before any release, paper submission, or major refactor merge.

---

## Anti-Patterns

| Anti-Pattern | Why It's Wrong |
|---|---|
| Manual editing of `data/derived/` | breaks the pipeline; intermediate files must be reproducible from raw |
| `cd` to absolute path inside a do-file | runs only on author's machine |
| Running ad-hoc `display r(N)` in console for "the result" | not in any log; not reproducible |
| Editing `output/tables/*.tex` by hand | next pipeline run wipes the edit; put adjustments in the do-file's `esttab` options |
| Calling `master.do` from inside a sub do-file | infinite recursion risk; obscures dependency direction |
