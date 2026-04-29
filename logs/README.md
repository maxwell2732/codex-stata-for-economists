# Logs Directory

Stata logs from every do-file run land here, named to mirror the do-file path.

> **Not committed:** `*.log` and `*.smcl` are in `.gitignore`. Only this README and `.gitkeep` reach GitHub. Logs may contain raw-data echo and so are treated as private.

## Naming convention

A do-file at `dofiles/03_analysis/main_regression.do` writes its log to:

```
logs/03_analysis_main_regression.log
```

The wrapper `scripts/run_stata.sh` derives the log path automatically.

## Why logs matter

Every numerical result claimed in a report or commit message must trace to a log line. The `log-validator` agent enforces this before any commit. If a number does not appear in a log file, it does not get reported.

See `.claude/rules/log-verification-protocol.md`.
