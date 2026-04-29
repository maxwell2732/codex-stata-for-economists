# Quality Report: Merge to Main -- [Date]

## Summary
[1-2 sentences: what was merged and why]

## Files Modified

| File | Type | Quality Score |
|------|------|---|
| `dofiles/path/file.do` | Stata do-file | [N]/100 |
| `reports/file.qmd` | Quarto report | [N]/100 |
| `scripts/file.py` | Python helper | [N]/100 |

## Verification Checklist

- [ ] Pipeline runs end-to-end (`bash scripts/run_pipeline.sh` exits 0)
- [ ] All do-file logs free of `r(<n>)` errors
- [ ] All output files in `output/tables/` and `output/figures/` newer than producing do-files
- [ ] Numerical claims in any modified report trace to log lines (`log-validator` PASS)
- [ ] Replication targets (if applicable) within tolerance
- [ ] Quality scores >= 80
- [ ] Data-safety check passes (`python scripts/check_data_safety.py --staged $(git diff --cached --name-only)`)

## Status

MERGED

## Notes

[Any learnings, unresolved discrepancies, or follow-ups for the next merge.]
