#!/usr/bin/env python3
"""
Quality Scoring System for the Stata Research Pipeline (Template)

Calculates objective quality scores (0-100) for Stata do-files, Quarto reports,
and ancillary Python scripts. Enforces quality gates: 80 (commit), 90 (PR),
95 (excellence) — per `.claude/rules/quality-gates.md`.

Usage:
    python scripts/quality_score.py dofiles/03_analysis/main_regression.do
    python scripts/quality_score.py reports/analysis_report.qmd
    python scripts/quality_score.py dofiles/**/*.do --summary
    python scripts/quality_score.py --json scripts/check_data_safety.py

Design notes:
- Lightweight static checks only. The full review is done by agents
  (stata-reviewer, econometric-reviewer, log-validator).
- The do-file rubric mirrors the deductions in .claude/rules/quality-gates.md
  exactly. If you change the rubric there, change it here too.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import List

# =============================================================================
# Thresholds — quality-gates.md
# =============================================================================

THRESHOLDS = {"commit": 80, "pr": 90, "excellence": 95}


# =============================================================================
# Data classes
# =============================================================================

@dataclass
class Issue:
    severity: str   # "critical" | "major" | "minor"
    category: str
    line: int
    message: str
    deduction: int


@dataclass
class Score:
    file: str
    kind: str                      # "do" | "qmd" | "py" | "unknown"
    issues: List[Issue] = field(default_factory=list)

    @property
    def total_deduction(self) -> int:
        return sum(i.deduction for i in self.issues)

    @property
    def points(self) -> int:
        return max(0, 100 - self.total_deduction)

    @property
    def gate(self) -> str:
        p = self.points
        if p >= THRESHOLDS["excellence"]:
            return "EXCELLENCE"
        if p >= THRESHOLDS["pr"]:
            return "PR-READY"
        if p >= THRESHOLDS["commit"]:
            return "COMMIT-OK"
        return "BLOCKED"

    def to_dict(self) -> dict:
        return {
            "file": self.file,
            "kind": self.kind,
            "score": self.points,
            "gate": self.gate,
            "issues": [
                {
                    "severity": i.severity,
                    "category": i.category,
                    "line": i.line,
                    "message": i.message,
                    "deduction": i.deduction,
                }
                for i in self.issues
            ],
        }


# =============================================================================
# Stata do-file rubric
# =============================================================================
# Mirrors .claude/rules/quality-gates.md § "Stata `.do` Files".

class DoFileChecker:
    ABS_PATH_RE = re.compile(
        r'(?:cd\s+["\']?(?:[A-Za-z]:[\\/]|/(?:home|Users|root|tmp)/))'
        r'|(?:use\s+["\'][A-Za-z]:[\\/])'
        r'|(?:use\s+["\']/(?:home|Users|root|tmp)/)',
        re.IGNORECASE,
    )
    LOG_USING_RE = re.compile(r"\blog\s+using\b", re.IGNORECASE)
    VERSION_RE = re.compile(r"^\s*version\s+\d", re.IGNORECASE | re.MULTILINE)
    SET_SEED_RE = re.compile(r"^\s*set\s+seed\s+\d", re.IGNORECASE | re.MULTILINE)
    VARABBREV_OFF_RE = re.compile(r"set\s+varabbrev\s+off", re.IGNORECASE)
    RANDOM_USE_RE = re.compile(
        r"\b(?:bootstrap|simulate|permute|rnormal|runiform|rbinomial|rpoisson|"
        r"rchi2|rt\(|sample|generate\s+\w+\s*=\s*runi|generate\s+\w+\s*=\s*rno)",
        re.IGNORECASE,
    )
    MORE_OFF_INSIDE_LOOP_RE = re.compile(
        r"foreach[^\n]*\{[^}]*set\s+more\s+off|forvalues[^\n]*\{[^}]*set\s+more\s+off",
        re.IGNORECASE | re.DOTALL,
    )
    EST_STORE_RE = re.compile(r"\best(?:imates)?\s+store\b", re.IGNORECASE)
    ESTIMATION_RE = re.compile(
        r"^\s*(?:reghdfe|regress|reg\b|areg|xtreg|ivreg2|ivreg|csdid|"
        r"didregress|probit|logit|tobit|poisson|nbreg)\b",
        re.IGNORECASE | re.MULTILINE,
    )
    HEADER_FIELDS = ("File:", "Project:", "Author:", "Purpose:", "Inputs:", "Outputs:", "Log:")
    SECTION_BANNER_RE = re.compile(r"^\s*\*[-*=]{3,}", re.MULTILINE)
    DEAD_CODE_RE = re.compile(r"^\s*\*\s*(?:reg|reghdfe|use|gen|generate)\b", re.MULTILINE)
    MAGIC_NUMBER_RE = re.compile(
        r"\b(?:reghdfe|regress|reg|areg|xtreg|csdid)\b[^\n]*\b\d{4,}\b",
        re.IGNORECASE,
    )

    def __init__(self, path: Path):
        self.path = path
        self.text = path.read_text(encoding="utf-8", errors="replace")
        self.lines = self.text.splitlines()
        self.score = Score(file=str(path), kind="do")

    def add(self, severity: str, category: str, line: int, msg: str, ded: int):
        self.score.issues.append(Issue(severity, category, line, msg, ded))

    # --- individual checks --------------------------------------------------

    def check_header(self):
        head = "\n".join(self.lines[:25])
        missing = [f for f in self.HEADER_FIELDS if f not in head]
        if len(missing) == len(self.HEADER_FIELDS):
            self.add("major", "Header", 1, "Missing file header block entirely", 8)
        elif missing:
            self.add(
                "major", "Header", 1,
                f"Header missing fields: {', '.join(missing)}",
                min(8, 2 * len(missing)),
            )

    def check_version(self):
        if not self.VERSION_RE.search(self.text):
            self.add("critical", "Boilerplate", 1,
                     "No `version` pin (e.g., `version 17`)", 15)

    def check_log(self):
        if not self.LOG_USING_RE.search(self.text):
            self.add("critical", "Logging", 1,
                     "No `log using` — do-file produces no log; reproducibility broken", 15)

    def check_seed(self):
        if self.RANDOM_USE_RE.search(self.text) and not self.SET_SEED_RE.search(self.text):
            self.add("major", "Reproducibility", 1,
                     "Randomness used but no `set seed`", 10)

    def check_varabbrev(self):
        if not self.VARABBREV_OFF_RE.search(self.text):
            self.add("major", "Boilerplate", 1,
                     "Missing `set varabbrev off` (typos compile silently)", 5)

    def check_more_off_in_loop(self):
        if self.MORE_OFF_INSIDE_LOOP_RE.search(self.text):
            self.add("major", "Boilerplate", 0,
                     "`set more off` inside a loop (move it to the top of the file)", 5)

    def check_abs_paths(self):
        for i, line in enumerate(self.lines, 1):
            if self.ABS_PATH_RE.search(line):
                self.add("critical", "Paths", i,
                         f"Hardcoded absolute path: `{line.strip()[:80]}`", 25)

    def check_est_store(self):
        # If there's at least one estimation but no `est store`, flag.
        n_est = len(self.ESTIMATION_RE.findall(self.text))
        n_store = len(self.EST_STORE_RE.findall(self.text))
        if n_est >= 1 and n_store == 0:
            self.add("major", "Estimation", 0,
                     f"{n_est} estimation(s) but no `est store` "
                     "(table assembly via esttab will fail)", 5)

    def check_section_banners(self):
        # We expect at least 3 section banners in a substantive do-file.
        if len(self.lines) >= 50 and len(self.SECTION_BANNER_RE.findall(self.text)) < 3:
            self.add("minor", "Comments", 0,
                     "Few or no section banners (numbered `*--- N. ... ---`)", 2)

    def check_dead_code(self):
        hits = self.DEAD_CODE_RE.findall(self.text)
        if hits:
            self.add("minor", "Comments", 0,
                     f"{len(hits)} commented-out estimation/data line(s) — dead code",
                     min(8, 2 * len(hits)))

    def check_magic_numbers(self):
        hits = self.MAGIC_NUMBER_RE.findall(self.text)
        if hits:
            self.add("major", "Magic", 0,
                     f"{len(hits)} estimation line(s) contain a 4+ digit literal "
                     "(use a named local with a comment)",
                     min(15, 3 * len(hits)))

    def check_long_lines(self):
        offenders = 0
        for i, line in enumerate(self.lines, 1):
            stripped = line.rstrip()
            # Stata line continuations end with `///`.
            if len(stripped) > 100 and not stripped.rstrip().endswith("///"):
                offenders += 1
        if offenders:
            self.add("minor", "Polish", 0,
                     f"{offenders} line(s) over 100 chars (without `///` continuation)",
                     min(10, offenders))

    # --- run all ------------------------------------------------------------

    def run(self) -> Score:
        self.check_header()
        self.check_version()
        self.check_log()
        self.check_seed()
        self.check_varabbrev()
        self.check_more_off_in_loop()
        self.check_abs_paths()
        self.check_est_store()
        self.check_section_banners()
        self.check_dead_code()
        self.check_magic_numbers()
        self.check_long_lines()
        return self.score


# =============================================================================
# Quarto report rubric (lightweight)
# =============================================================================

class QmdReportChecker:
    INLINE_ANALYSIS_RE = re.compile(
        r"```\{stata\}[^`]*?\b(?:reghdfe|regress|reg|areg|xtreg|ivreg|csdid)\b",
        re.IGNORECASE | re.DOTALL,
    )
    CITE_RE = re.compile(r"@([A-Za-z][\w-]*\d{2,4}[a-z]?)")
    CHUNK_RE = re.compile(r"```\{[^}]+\}", re.DOTALL)

    def __init__(self, path: Path):
        self.path = path
        self.text = path.read_text(encoding="utf-8", errors="replace")
        self.score = Score(file=str(path), kind="qmd")

    def add(self, *a, **kw):
        self.score.issues.append(Issue(*a, **kw))

    def check_inline_analysis(self):
        if self.INLINE_ANALYSIS_RE.search(self.text):
            self.add("critical", "Architecture", 0,
                     "Report contains an analysis command (regress / reghdfe / ivreg / csdid) "
                     "inside a code chunk. Analysis must live in dofiles/, not in reports.", 30)

    def check_citations(self):
        keys = set(self.CITE_RE.findall(self.text))
        bib_path = Path("references.bib")
        if not bib_path.exists():
            if keys:
                self.add("critical", "Citations", 0,
                         f"references.bib not found but {len(keys)} citation key(s) used", 15)
            return
        bib_text = bib_path.read_text(encoding="utf-8", errors="replace")
        bib_keys = set(re.findall(r"@\w+\{([^,]+),", bib_text))
        missing = keys - bib_keys
        for k in sorted(missing):
            self.add("critical", "Citations", 0,
                     f"Citation @{k} not found in references.bib", 15)

    def check_required_sections(self):
        # Accept either a Markdown # heading OR a YAML frontmatter title:.
        has_h1 = any(line.startswith("# ") for line in self.text.splitlines())
        has_yaml_title = bool(re.search(r"^title:\s*\S", self.text, re.MULTILINE))
        if not (has_h1 or has_yaml_title):
            self.add("critical", "Structure", 0,
                     "Report has no top-level title (neither YAML title: nor # heading)", 10)

    def run(self) -> Score:
        self.check_inline_analysis()
        self.check_citations()
        self.check_required_sections()
        return self.score


# =============================================================================
# Python script rubric (very light)
# =============================================================================

class PyChecker:
    ABS_PATH_RE = re.compile(r'["\'](?:[A-Z]:[\\/]|/(?:home|Users|root|tmp)/)')

    def __init__(self, path: Path):
        self.path = path
        self.text = path.read_text(encoding="utf-8", errors="replace")
        self.lines = self.text.splitlines()
        self.score = Score(file=str(path), kind="py")

    def add(self, *a, **kw):
        self.score.issues.append(Issue(*a, **kw))

    def check_syntax(self):
        try:
            compile(self.text, str(self.path), "exec")
        except SyntaxError as e:
            self.add("critical", "Syntax", e.lineno or 1,
                     f"SyntaxError: {e.msg}", 100)

    def check_module_docstring(self):
        # First non-blank, non-import line should be a string for a docstring,
        # OR the file starts with a """..."""
        stripped = self.text.lstrip()
        if not (stripped.startswith('"""') or stripped.startswith("'''")):
            # tolerate shebang
            after_shebang = self.text.split("\n", 1)[1] if self.text.startswith("#!") else self.text
            if not (after_shebang.lstrip().startswith('"""') or after_shebang.lstrip().startswith("'''")):
                self.add("major", "Docs", 1, "Missing module docstring", 5)

    def check_abs_paths(self):
        for i, line in enumerate(self.lines, 1):
            # Ignore comments
            code = line.split("#", 1)[0]
            if self.ABS_PATH_RE.search(code):
                self.add("critical", "Paths", i, f"Hardcoded absolute path: `{line.strip()[:80]}`", 25)

    def check_long_lines(self):
        offenders = sum(1 for ln in self.lines if len(ln.rstrip()) > 100)
        if offenders:
            self.add("minor", "Polish", 0,
                     f"{offenders} line(s) over 100 chars",
                     min(10, offenders))

    def run(self) -> Score:
        self.check_syntax()
        # If syntax failed, don't bother with the rest.
        if any(i.severity == "critical" and i.category == "Syntax" for i in self.score.issues):
            return self.score
        self.check_module_docstring()
        self.check_abs_paths()
        self.check_long_lines()
        return self.score


# =============================================================================
# Dispatcher
# =============================================================================

def score_file(path: Path) -> Score:
    suffix = path.suffix.lower()
    if suffix == ".do":
        return DoFileChecker(path).run()
    if suffix == ".qmd":
        return QmdReportChecker(path).run()
    if suffix == ".py":
        return PyChecker(path).run()
    s = Score(file=str(path), kind="unknown")
    s.issues.append(
        Issue("major", "Unknown", 0, f"No rubric for {suffix} files", 0)
    )
    return s


# =============================================================================
# Reporting
# =============================================================================

def render_text(s: Score, summary: bool = False) -> str:
    out = []
    out.append("=" * 72)
    out.append(f"File:  {s.file}")
    out.append(f"Kind:  {s.kind}")
    out.append(f"Score: {s.points}/100   Gate: {s.gate}")
    out.append("=" * 72)
    if summary:
        return "\n".join(out)

    # Group by severity for readability
    for sev in ("critical", "major", "minor"):
        sev_issues = [i for i in s.issues if i.severity == sev]
        if not sev_issues:
            continue
        out.append(f"\n[{sev.upper()}] {len(sev_issues)} issue(s)")
        for i in sev_issues:
            line_str = f"L{i.line:>4}" if i.line else "  -- "
            out.append(f"  {line_str}  -{i.deduction:>3}  {i.category:<14} {i.message}")

    if not s.issues:
        out.append("\n[OK] No issues detected.")
    return "\n".join(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    parser.add_argument("files", nargs="+", help="Files to score")
    parser.add_argument("--summary", action="store_true", help="One line per file")
    parser.add_argument("--json", action="store_true", help="JSON output")
    args = parser.parse_args()

    scores = [score_file(Path(f)) for f in args.files]

    if args.json:
        print(json.dumps([s.to_dict() for s in scores], indent=2))
    else:
        for s in scores:
            print(render_text(s, summary=args.summary))

    # Exit non-zero if any file is below commit threshold.
    return 0 if all(s.points >= THRESHOLDS["commit"] for s in scores) else 2


if __name__ == "__main__":
    sys.exit(main())
