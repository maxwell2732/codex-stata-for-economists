---
paths:
  - "dofiles/**/*.do"
  - "reports/**/*.qmd"
  - "quality_reports/**"
  - "logs/**"
---

# Log Verification Protocol

**The bedrock rule of this template.** Every numerical claim Claude makes about an analysis MUST be traceable to a `logs/*.log` line or an `output/tables/*.csv`/`*.tex` cell. **No log, no claim.**

This protocol exists because the most damaging failure mode in empirical work is fabricated or hallucinated numbers — a coefficient that "looks about right" but has no provenance. The template forbids it operationally.

---

## When This Rule Triggers

- Claude is summarizing results in a session log, plan, commit message, or report
- Claude is filling in a replication target row
- Claude is responding to "what does the model say about X?"
- Any sentence containing a number Claude attributes to a regression, simulation, or descriptive statistic

---

## How to Comply

For every numerical statement, Claude must:

1. **Identify the source artifact:**
   - A specific log file (`logs/03_analysis_main_regression.log`) and a line number / context
   - OR a specific cell in `output/tables/*.csv` (row + column)
   - OR a value in a saved estimate (`estimates use ...`) — but reading the underlying log is preferred

2. **Quote the relevant line** (or the value with its surrounding context) when first introducing the number

3. **Use the `log-validator` agent** before any commit that adds or changes numerical claims in a report or replication report. The agent reads the claim + the log and confirms (or denies) the match.

4. **If no log exists yet**, refuse to state the result. Say instead: "I would need to run `dofiles/03_analysis/main_regression.do` first; that produces `logs/03_analysis_main_regression.log`."

---

## What Counts as a "Log Line"

Any of:

- `_b[treated]` displayed by Stata after `regress` / `reghdfe` / `ivreg2`
- An `esttab` table written to `.tex` or `.csv`
- A `summarize` table
- A `tabulate` output
- A `display` command's printed value (only when the `display` is explicitly part of the do-file, not interactive)

What does NOT count:

- A number Claude calculated by hand from other reported numbers (unless the calculation is shown and trivial)
- A number from a previous Stata session that no longer has a log
- Anything from a screenshot or pasted output the user shared (treat as input, not as project artifact — request a re-run)

---

## The `log-validator` Agent Workflow

Input to the agent:
- The claim (e.g., "the ATT in the main spec is −1.632 (SE 0.584)")
- The candidate log file path

Agent steps:
1. Read the log file
2. Search for the claimed coefficient and SE within plausible neighborhoods (e.g., output of `reghdfe ... cluster(state_id)`)
3. If found, verify it matches the claim within rounding tolerance documented in `replication-protocol.md`
4. If not found, return `UNVERIFIED — number does not appear in <logfile>`

Agent output:
- `VERIFIED — found at <logfile>:<line>` (with the matching excerpt), OR
- `UNVERIFIED — <reason>` (no match, multiple matches with conflicting values, log file missing)

A `VERIFIED` is required before the commit completes. `UNVERIFIED` blocks the commit until either (a) the do-file is re-run and a new log produced, or (b) the claim is removed.

---

## Commit Message Discipline

Every commit message that mentions a numerical result must cite the log:

```
Update main regression table with clustered SE

ATT estimate: -1.632 (SE 0.584, clustered at state)
Source: logs/03_analysis_main_regression.log (line 412)
```

The `log-validator` agent is invoked from `/commit` when commit messages contain numbers.

---

## What Claude Says When It Cannot Verify

Verbatim template:

> "I cannot state that result. The do-file `dofiles/03_analysis/main_regression.do` has not been run since the last edit (no fresh `logs/03_analysis_main_regression.log` exists), so I have no log line to back the claim. Want me to (a) run the do-file via `bash scripts/run_stata.sh dofiles/03_analysis/main_regression.do`, or (b) drop the numerical claim from the report?"

This phrasing is non-negotiable. Better to ask than to fabricate.
