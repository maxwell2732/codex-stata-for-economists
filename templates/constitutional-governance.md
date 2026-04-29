# Constitutional Governance Template

**Define your immutable principles vs. user preferences.**

---

## Why Constitutional Governance?

As projects grow, some decisions become non-negotiable (to maintain quality, reproducibility, or collaboration standards). Others remain flexible based on context.

Making this distinction explicit prevents:
- Repeated debates on settled issues
- Inconsistent application of standards
- Uncertainty about when to ask vs. decide

---

## How to Use This Template

1. Copy this file to `.claude/rules/constitutional-governance.md`
2. Replace bracketed examples with YOUR non-negotiables
3. Delete articles that don't apply to your workflow
4. Add new articles as patterns emerge
5. Keep it to 3-7 articles (more signals insufficient abstraction)

---

## Example Articles (Customize for Your Domain)

### Article I: [Your Primary Artifact Principle]

**Example (Stata pipeline):** `dofiles/00_master.do` is authoritative; tables/figures/reports derive from it. Reports never re-run analysis.

**Example (LaTeX workflows):** Beamer `.tex` is authoritative; Quarto `.qmd` derives from it.

**Example (R workflows):** Analysis scripts are authoritative; reports derive from them.

**Example (Jupyter workflows):** Notebooks are authoritative; exported HTML derives from them.

**Example (multi-format):** Source documents (`.qmd`, `.Rmd`) are authoritative; all outputs (HTML, PDF, Word) derive from them.

**Why this matters:** Prevents circular dependencies and merge conflicts.

**Your version:**
[Replace with your primary artifact principle]

---

### Article II: Plan-First Threshold

Enter plan mode for tasks requiring [YOUR THRESHOLD: e.g., >3 files, >30 minutes, multi-step workflows].

**Why this matters:** Prevents mid-implementation pivots and wasted effort.

**Your exceptions:** [e.g., exploration folder allows fast-track, quick fixes skip planning, documented emergencies]

**Your version:**
[Replace with your threshold and exceptions]

---

### Article III: Quality Gate

Nothing commits below [YOUR THRESHOLD: e.g., 80/100, all tests passing, peer review approval].

**Why this matters:** Technical debt accumulates exponentially below quality thresholds.

**Your exceptions:** [e.g., WIP branches explicitly marked, exploratory work in sandbox folder, draft commits tagged as such]

**Your version:**
[Replace with your quality threshold and exceptions]

---

### Article IV: Verification Standard

All artifacts must [YOUR STANDARD: e.g., compile successfully, pass tests, render without errors, meet accessibility standards] before commit.

**Why this matters:** Broken builds block downstream work and collaboration.

**Your exceptions:** [e.g., known issues documented in README, external dependencies unavailable, explicit --skip-verify flag with justification]

**Your version:**
[Replace with your verification standard and exceptions]

---

### Article V: [Your File Organization Principle]

**Example (structured projects):** Never scatter analysis docs; use `quality_reports/session_logs/` for all session documentation.

**Example (notebook users):** One notebook per analysis; no code duplication across notebooks; shared functions go in modules.

**Example (multi-language):** Language-specific subdirectories (`R/`, `python/`, `julia/`); no mixed-language files.

**Example (literate programming):** All code lives in `.qmd` or `.Rmd` files; extracted `.R` scripts are derived artifacts.

**Why this matters:** Consistent structure enables navigation, collaboration, and automated tooling.

**Your exceptions:** [e.g., quick prototypes in `scratch/`, legacy files in `_archive/`, temporary explorations]

**Your version:**
[Replace with your file organization principle]

---

## User Preferences (Override Anytime)

List patterns that ARE flexible and can vary by context:

- [e.g., File naming conventions (snake_case vs camelCase vs kebab-case)]
- [e.g., Tolerance thresholds for numerical comparisons (1e-6 vs 1e-8)]
- [e.g., Review agent priority order (pedagogy-first vs code-quality-first)]
- [e.g., Comment verbosity (minimal vs detailed)]
- [e.g., Plot color schemes (institutional vs publication-ready vs colorblind-safe)]
- [e.g., Citation style (APA vs Chicago vs domain-specific)]

---

## Requesting Amendment

When a user asks to deviate from an article, ask:

> "Are you **amending Article X** (permanent change) or **overriding for this task** (one-time exception)?"

This preserves institutional memory while allowing flexibility.

**Amendment process:**
1. User proposes amendment with rationale
2. Discuss implications (what breaks? what improves?)
3. Update this file if amendment approved
4. Document the change in session log with [CONSTITUTIONAL AMENDMENT] tag

---

## When NOT to Use Articles

Don't create articles for:

- **Personal preferences** that don't affect collaboration or reproducibility
- **One-off decisions** unlikely to recur
- **Patterns still evolving** (wait until they stabilize across 3+ uses)
- **External constraints** (imposed by journals, funders, collaborators)

---

## Examples from Different Domains

### Economics/Econometrics

1. **Replication-First:** All empirical claims must have accompanying R/Stata scripts
2. **Data Provenance:** All datasets documented with source, date, and processing steps
3. **Robust Standard Errors:** Default to clustered SEs; justify if not used

### Biology/Wet Lab

1. **Lab Notebook Primacy:** Physical lab notebook is authoritative; digital is backup
2. **Sample Tracking:** All biological samples get unique IDs before processing
3. **Protocol Versioning:** Protocol changes documented; old versions archived

### Computer Science/ML

1. **Reproducible Seeds:** All stochastic code uses documented random seeds
2. **Environment Specification:** `requirements.txt` / `environment.yml` always up to date
3. **Benchmark Baselines:** New methods compared against published baselines

### Mathematics/Proofs

1. **Proof-Before-Claim:** No theorems stated without accompanying proof or citation
2. **Notation Dictionary:** All non-standard notation defined in preamble
3. **Lemma Independence:** Each lemma self-contained with dependencies explicit

---

## Maintenance

**Review cadence:** Quarterly (or after every 10 sessions)

**Review questions:**
- Are all articles still relevant?
- Are any being violated repeatedly? (If yes, amend or delete)
- Are any new patterns emerging? (If yes, consider promoting to article)
- Are articles enabling or obstructing work?

---

## Template Checklist

Before finalizing your constitutional governance:

- [ ] 3-7 articles (not more)
- [ ] Each article has: principle, why it matters, your version, exceptions
- [ ] User preferences section populated with flexible patterns
- [ ] Amendment process understood
- [ ] Review cadence scheduled
- [ ] File saved to `.claude/rules/constitutional-governance.md`
