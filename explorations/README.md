# Explorations

This folder is a sandbox for experimental and exploratory work. New methods, prototypes, simulations, diagnostics, and teaching demos go here first, not directly into production folders.

## How It Works

1. Create a subfolder for each exploration, for example `explorations/new_estimator/`.
2. Keep it self-contained with its own `README.md`, `dofiles/`, `logs/`, and `output/`.
3. Work freely during exploration, but keep logs and outputs auditable.
4. Decide whether to graduate the work to production, keep exploring, or archive it.

## Required Structure

```text
explorations/
  [active-project]/
    README.md
    dofiles/
    logs/
    output/
      tables/
      figures/
  ARCHIVE/
    completed_[name]/
    abandoned_[name]/
```

## Rules

- Do not leave Stata logs in the repository root.
- Move run logs and console transcripts to the relevant `explorations/<project>/logs/` folder, usually with a `_console.log` suffix for console transcripts.
- Logs remain gitignored. Commit only the exploration README, do-files, small non-PII summary tables, and figure exports when useful.
- If a method is only a simulation or test, keep it here until the user explicitly asks to integrate it into `dofiles/00_master.do`.
- Avoid `/*` inside Stata header comments, including paths like `output/tables/*`; Stata treats it as a block-comment opener.
- Export Stata figures as both PDF and PNG.

## Current Method Examples

- `cox_hazard_ratio_simulation/`: self-contained Cox proportional hazards simulation using `stset`, `stcox, hr`, a proportional-hazards diagnostic, and survival-curve exports.
- `staggered_did_simulation/`: staggered DID simulation and event-study outputs.

See `.claude/rules/exploration-folder-protocol.md` and `.claude/rules/exploration-fast-track.md` for legacy Claude Code reference material.
