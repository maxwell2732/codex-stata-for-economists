---
name: validate-bib
description: Validate bibliography entries against citations in Quarto reports and Stata do-files. Find missing entries, unused references, and likely typos.
disable-model-invocation: true
allowed-tools: ["Read", "Grep", "Glob"]
---

# Validate Bibliography

Cross-reference all citations across the project against `references.bib`.

## Steps

1. **Read `references.bib`** and extract all citation keys (lines starting with `@type{key,`).

2. **Scan source files for citation usage:**
   - `reports/**/*.qmd` (Quarto): look for `@key`, `[@key]`, `[@key1; @key2]`, `[-@key]`
   - `dofiles/**/*.do` (Stata): look for explicit `cite{` strings inside `esttab` `notes()` arguments and any inline `// cite: key` comments
   - `*.qmd` and `*.md` at repo root and `quality_reports/` (replication reports may cite)
   - Extract unique citation keys used.

3. **Cross-reference and report:**
   - **Missing entries** (CRITICAL): citation key used in source but absent from `references.bib`
   - **Unused entries** (informational): bib entry never cited
   - **Potential typos**: keys with edit distance ≤ 2 to a defined key (e.g., `chetty2014` vs `chetty2015`)

4. **Check entry quality** for each bib entry:
   - Required fields present: `author`, `title`, `year`, plus `journal`/`booktitle`/`publisher` for type
   - Author field properly formatted (`Last, First` with `and` between authors)
   - Year is a 4-digit integer in a plausible range
   - No malformed braces or unescaped `&` / `%` characters

5. **Report findings** to the user as four ranked sections:
   - Missing entries (block reports from rendering until fixed)
   - Likely typos (likely most actionable)
   - Quality issues
   - Unused entries (often safe to ignore — could be reading list)

## Files scanned

```
references.bib                    (bibliography source of truth)
reports/**/*.qmd                  (Quarto + Stata engine reports)
dofiles/**/*.do                   (look for cite-style strings in notes/comments)
quality_reports/**/*.md           (replication reports, plans)
*.qmd *.md (repo root)            (top-level docs)
```
