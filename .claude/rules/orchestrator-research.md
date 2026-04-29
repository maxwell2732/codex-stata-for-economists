---
paths:
  - "dofiles/**/*.do"
  - "explorations/**"
---

# Research Project Orchestrator (Simplified)

**For Stata do-files, simulations, and exploratory data analysis** — use this simplified loop instead of the full multi-agent orchestrator.

## The Simple Loop

```
Plan approved → orchestrator activates
  │
  Step 1: IMPLEMENT — Write/edit the do-file
  │
  Step 2: VERIFY — Run the do-file via scripts/run_stata.sh
  │         • Stata exit code 0
  │         • Log file created and non-empty
  │         • No r(<n>) errors in log (use /validate-log)
  │         • Expected output files exist with sensible size
  │         If verification fails → fix → re-verify (max 2 attempts)
  │
  Step 3: SCORE — Apply quality-gates rubric (python scripts/quality_score.py)
  │
  └── Score >= 80?
        YES → Done (commit when user signals)
        NO  → Fix blocking issues, re-verify, re-score
```

**No 5-round critic-fixer loops here. No multi-agent reviews. Just: write, run, validate log, done.**

For production do-files that ship results in a paper, escalate to the full `orchestrator-protocol` and run `econometric-reviewer` + `log-validator` + `stata-reviewer`.

---

## Verification Checklist

- [ ] Script runs without errors (`_rc == 0`)
- [ ] All packages loaded / pinned at top (`version`, required user-written commands)
- [ ] No hardcoded absolute paths
- [ ] `set seed` once at top if stochastic
- [ ] Log file produced and non-empty
- [ ] Output files created at expected paths
- [ ] Tolerance checks pass (if replication target exists)
- [ ] Quality score ≥ 80
