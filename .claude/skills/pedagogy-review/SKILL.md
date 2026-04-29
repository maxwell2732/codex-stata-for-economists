---
name: pedagogy-review
description: Run a holistic narrative review on a Quarto report or Markdown document. Checks reader prerequisites, worked examples, notation clarity, structural arc, and pacing.
disable-model-invocation: true
argument-hint: "[QMD or MD filename]"
allowed-tools: ["Read", "Grep", "Glob", "Write", "Task"]
---

# Pedagogical Review of a Report or Document

Perform a holistic narrative review of a Quarto report (`reports/*.qmd`), a replication report (`quality_reports/*.md`), or any document where pedagogical clarity matters (audience comprehension, motivation, worked examples, notation discipline).

## Steps

1. **Identify the file** specified in `$ARGUMENTS`
   - If no argument, ask the user which file to review
   - If just a name, look in `reports/`, then `quality_reports/`, then repo root

2. **Launch the pedagogy-reviewer agent** with the full file path
   - The agent checks the standard pedagogical patterns (motivation, prerequisites, worked examples, notation consistency, narrative arc, pacing)
   - For an analysis report: also verifies that econometric assumptions and identification claims are stated clearly enough for a non-coauthor reader

3. **The agent produces a report** saved to:
   `quality_reports/[FILENAME_WITHOUT_EXT]_pedagogy_report.md`

4. **Present a summary to the user:**
   - Patterns followed vs. violated
   - Document-level assessments (arc, pacing, notation)
   - Top 3–5 critical recommendations

## Important Notes

- This is a **read-only review** — no files are edited
- For econometric specification correctness, use the `econometric-reviewer` agent (or `/review-stata`) instead
- For grammar/typos, use `/proofread` instead
