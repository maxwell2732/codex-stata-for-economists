# How to Tailor This Template After Forking

Step-by-step checklist for an economist who has just forked this template and
wants to start a new empirical project.

---

## 0. One-time machine setup (skip if already done)

- [ ] Install Claude Code: `npm install -g @anthropic-ai/claude-code`
- [ ] Install Stata 17+ and confirm `stata-mp` (or your flavor) is on PATH
- [ ] Install Quarto: `https://quarto.org/docs/get-started/`
- [ ] Install the Stata Quarto engine: `pip install nbstata` (or `pip install pystata`)
- [ ] Install Python 3 (any recent version) for the safety / scoring scripts
- [ ] In Stata, install user-written commands once: `ssc install reghdfe ftools estout ivreg2 ranktest boottest, replace`

---

## 1. Fork-time edits (10 minutes)

- [ ] In `CLAUDE.md`, replace placeholders:
  - `[YOUR PROJECT NAME]`
  - `[YOUR NAME] -- [YOUR INSTITUTION]`
  - The Stata version pin if you're not on 17 (e.g., `version 18`)
- [ ] In `dofiles/00_master.do` and `templates/master-do-template.do`, update the same Stata version pin
- [ ] In `references.bib`, drop in your own bibliography (or replace from your reference manager export)
- [ ] In `data/README.md`, replace the placeholder data dictionary with your own datasets
- [ ] In `.claude/WORKFLOW_QUICK_REF.md`, fill in any project-specific non-negotiables (figure DPI, color palette, etc.)
- [ ] In `.claude/rules/knowledge-base-template.md`, populate the registries (estimands, notation, datasets, identification assumptions, anti-patterns)

---

## 2. Wire the data-safety pre-commit hook (1 minute, do not skip)

```bash
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/bash
python scripts/check_data_safety.py --staged $(git diff --cached --name-only)
EOF
chmod +x .git/hooks/pre-commit
```

Test it:

```bash
touch data/raw/test_blocker.dta
git add -f data/raw/test_blocker.dta   # -f because .gitignore blocks it
git commit -m "test"   # should be REJECTED by the hook
git reset HEAD data/raw/test_blocker.dta
rm data/raw/test_blocker.dta
```

---

## 3. Customize the domain reviewer (5 minutes)

Open `.claude/agents/domain-reviewer.md`. The 5 review lenses are templated for
generic empirical economics. Adapt for your sub-field — for example:

| Sub-field | Lens 1 customization |
|---|---|
| Development | parallel trends, spillovers, partial-equilibrium critique |
| Macro | identification scheme (recursive / sign-restriction / external instrument) |
| IO | structural identification (parameter rank, exclusion restrictions) |
| Labor | sample-selection, attrition, Heckman corrections |

Add sub-field-specific known pitfalls to Lens 4 (Code-Theory Alignment).

---

## 4. (Optional) Adjust quality-gate thresholds

Defaults: 80 (commit), 90 (PR), 95 (excellence). Adjust per project in
`.claude/rules/quality-gates.md` and `scripts/quality_score.py` (the `THRESHOLDS`
constant). Keep them in sync.

---

## 5. First commit

```bash
git add CLAUDE.md references.bib data/README.md .claude/rules/knowledge-base-template.md \
        .claude/WORKFLOW_QUICK_REF.md .claude/agents/domain-reviewer.md
git commit -m "Initialize project from claudecode-stata-for-economists template"
```

---

## 6. Start working

Open Claude Code and paste the prompt in `README.md` (or just say "let's start
on [your project]"). Claude will read `CLAUDE.md`, the rules, and the knowledge
base, then propose a first analysis step.

For your first do-file, follow the `/data-analysis [your topic]` skill — it
walks the full Phase 1–6 workflow (setup, EDA, construct, estimate, output, review).

---

## What to keep in your fork (vs. upstream)

| Type | Keep in fork | Pull from upstream |
|---|---|---|
| `CLAUDE.md`, `references.bib`, `data/README.md` | yes (project-specific) | no |
| `.claude/agents/domain-reviewer.md` | yes (customized) | no |
| `dofiles/`, `output/`, `reports/`, `quality_reports/` | yes | no |
| `.claude/rules/`, `.claude/skills/`, `.claude/agents/` (other) | yes (may diverge) | yes (cherry-pick improvements) |
| `scripts/`, `templates/` | yes | yes (cherry-pick improvements) |

If the upstream template improves a generic rule or skill, `git cherry-pick`
the relevant commit into your fork.
