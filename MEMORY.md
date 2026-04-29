# Project Memory

Corrections and learned facts that persist across sessions.
When a mistake is corrected, append a `[LEARN:category]` entry below.

---

<!-- Append new entries below. Most recent at bottom. -->

## Workflow Patterns

[LEARN:workflow] Requirements specification phase catches ambiguity before planning → reduces rework 30-50%. Use spec-then-plan for complex/ambiguous tasks (>1 hour or >3 files).

[LEARN:workflow] Spec-then-plan protocol: AskUserQuestion (3-5 questions) → create `quality_reports/specs/YYYY-MM-DD_description.md` with MUST/SHOULD/MAY requirements → declare clarity status (CLEAR/ASSUMED/BLOCKED) → get approval → then draft plan.

[LEARN:workflow] Context survival before compression: (1) Update MEMORY.md with [LEARN] entries, (2) Ensure session log current (last 10 min), (3) Active plan saved to disk, (4) Open questions documented. The pre-compact hook displays checklist.

[LEARN:workflow] Plans, specs, and session logs must live on disk (not just in conversation) to survive compression and session boundaries. Quality reports only at merge time.

## Documentation Standards

[LEARN:documentation] When adding new features, update README and any user-facing docs immediately to prevent documentation drift. Stale docs break user trust.

[LEARN:documentation] Always document new templates in README's "What's Included" section with purpose description. Template inventory must be complete and accurate.

[LEARN:documentation] Date fields in frontmatter and README must reflect latest significant changes. Users check dates to assess currency.

## Design Philosophy

[LEARN:design] Framework-oriented > Prescriptive rules. Constitutional governance works as a TEMPLATE with examples users customize to their domain. Same for requirements specs.

[LEARN:design] Forkable templates serve a SPECIFIC primary workflow (here: Stata empirical economics) but keep the underlying governance generic so the lessons transfer. Be opinionated about the workflow, generic about the meta-rules.

## File Organization

[LEARN:files] Specifications go in `quality_reports/specs/YYYY-MM-DD_description.md`, not scattered in root or other directories.

[LEARN:files] Templates belong in `templates/` directory with descriptive names. Stata pipeline ships with: session-log.md, quality-report.md, exploration-readme.md, archive-readme.md, requirements-spec.md, constitutional-governance.md, skill-template.md, master-do-template.do, replication-targets.md, data-dictionary.md, analysis-report.qmd, CONTRIBUTING-FOR-FORKERS.md.

## Constitutional Governance

[LEARN:governance] Constitutional articles distinguish immutable principles (non-negotiable for quality/reproducibility) from flexible user preferences. Keep to 3-7 articles max.

[LEARN:governance] Example articles: Primary Artifact (which file is authoritative — for this template, `dofiles/00_master.do`), Plan-First Threshold (when to plan), Quality Gate (minimum score), Verification Standard (what must pass), File Organization (where files live).

[LEARN:governance] Amendment process: Ask user if deviating from article is "amending Article X (permanent)" or "overriding for this task (one-time exception)". Preserves institutional memory.

## Skill Creation

[LEARN:skills] Effective skill descriptions use trigger phrases users actually say: "run my regression", "build a publication table", "validate this log" → Claude knows when to load skill.

[LEARN:skills] Skills need 3 sections minimum: Instructions (step-by-step), Examples (concrete scenarios), Troubleshooting (common errors) → users can debug independently.

[LEARN:skills] Domain-specific examples beat generic ones: regression formatter (econ), event-study figure builder (causal inference), replication-target tracker (audit) → shows adaptability.

## Memory System

[LEARN:memory] Two-tier memory solves template vs working project tension: MEMORY.md (generic patterns, committed), personal-memory.md (machine-specific, gitignored) → cross-machine sync + local privacy.

[LEARN:memory] Post-merge hooks prompt reflection, don't auto-append → user maintains control while building habit.

## Meta-Governance

[LEARN:meta] Repository dual nature requires explicit governance: what's generic (commit) vs specific (gitignore) → prevents template pollution.

[LEARN:meta] Dogfooding principles must be enforced: plan-first, spec-then-plan, quality gates, session logs → we follow our own rules.

[LEARN:meta] Template development work (building infrastructure, docs) doesn't create session logs in `quality_reports/` → those are for user research work (analysis, replication), not meta-work. Keeps the template clean for forkers.

## Stata Pipeline (this template's domain)

[LEARN:stata] No result without a log. Every numerical claim Claude makes about an analysis MUST trace to a `logs/*.log` line or `output/tables/*.csv` cell. The `log-validator` agent enforces this; refusal to verify is the correct response when no log exists. See `.claude/rules/log-verification-protocol.md`.

[LEARN:stata] `dofiles/00_master.do` is the SINGLE entry point for end-to-end reproduction. Reports include from `output/`, never re-run analysis. See `.claude/rules/single-source-of-truth.md`.

[LEARN:stata] Stata version pin (`version 17`) goes at the top of every do-file AND in `master.do`'s validation comment. User-written commands (`reghdfe`, `ftools`, `estout`, `ivreg2`, `boottest`) are listed in `templates/master-do-template.do` with `ssc install` recipe.

## Data Protection (this template's bedrock)

[LEARN:data] Raw data NEVER commits. `data/raw/` and `data/derived/` are blanket-gitignored; the `scripts/check_data_safety.py` pre-commit script enforces it. Forkers wire it into `.git/hooks/pre-commit` per the README. Whitelist exceptions exist for `output/tables/` and `templates/examples/` only.

[LEARN:data] If a leak happens, treat it like a credential leak: stop pushing, scrub history with `git filter-repo` (NOT `git rm`), force-push (with explicit user authorization), and document in `quality_reports/incidents/`. See `.claude/rules/data-protection.md`.
