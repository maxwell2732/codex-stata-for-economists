# Attribution

The reference material in this skill (`SKILL.md` + `references/` + `packages/`) was vendored from:

> **dylantmoore/stata-skill** — https://github.com/dylantmoore/stata-skill
> Author: Dylan Moore
> Vendored on: 2026-04-28
> Upstream commit: HEAD (shallow clone, see commit history of this repo for the date)

The upstream `LICENSE` is a disclaimer (the author does not claim copyright), reproduced verbatim in `UPSTREAM_DISCLAIMER.txt`. The material is derived from Stata's official documentation and community package documentation. **Stata is a registered trademark of StataCorp LLC**; this project is not affiliated with or endorsed by StataCorp.

## What was vendored

- The `stata` plugin only (37 core reference files + 20 community-package guides)
- Did NOT vendor `stata-c-plugins` (specialized C-extension development) or `stata-skill-contributor` (meta-skill for contributing back upstream)

## Updating from upstream

When upstream improves a reference, re-pull selectively:

```bash
# from a temp clone of dylantmoore/stata-skill
cp plugins/stata/skills/stata/references/<file>.md \
   <this-repo>/.claude/skills/stata/references/<file>.md
```

Or to refresh the whole skill:

```bash
TMP=$(mktemp -d) && gh repo clone dylantmoore/stata-skill "$TMP/up" -- --depth=1 \
  && rm -rf .claude/skills/stata/{SKILL.md,references,packages} \
  && cp -r "$TMP/up/plugins/stata/skills/stata/SKILL.md" \
           "$TMP/up/plugins/stata/skills/stata/references" \
           "$TMP/up/plugins/stata/skills/stata/packages" \
           .claude/skills/stata/ \
  && rm -rf "$TMP"
```

`ATTRIBUTION.md` and `UPSTREAM_DISCLAIMER.txt` should be preserved across upstream refreshes — they are local additions.
