#!/usr/bin/env python3
"""
check_data_safety.py — Block accidental commits of raw / derived datasets.

The Stata Research Pipeline template guarantees that raw or derived datasets
are not committed. This script enforces that guarantee at commit time by
blocking protected data directories and data-like file extensions outside
narrow, documented output/example exceptions.

Forkers wire this into their git pre-commit hook. The standard install is
documented in README.md and looks like:

    cat > .git/hooks/pre-commit <<'EOF'
    #!/bin/bash
    python scripts/check_data_safety.py --staged $(git diff --cached --name-only)
    EOF
    chmod +x .git/hooks/pre-commit

Usage:
    python scripts/check_data_safety.py --staged FILE [FILE ...]
    python scripts/check_data_safety.py --scan-tree           # walk repo

Exit codes:
    0 — all checked paths are safe
    1 — usage error
    2 — at least one unsafe path detected (lists offending paths on stderr)
"""

import argparse
import os
import sys
from pathlib import Path

# --- Configuration -----------------------------------------------------------

# Paths whose contents are ALWAYS forbidden (except .gitkeep / README.md).
ALWAYS_FORBIDDEN_PREFIXES = (
    "data/raw/",
    "data/derived/",
)

# Files allowed inside the always-forbidden prefixes (markers + docs).
ALLOWED_INSIDE_FORBIDDEN = {".gitkeep", "README.md"}

# Data-like extensions blocked outside narrow, documented output dirs.
BLOCKED_DATA_EXTS = {
    ".dta",
    ".sav",
    ".por",
    ".parquet",
    ".feather",
    ".csv",
    ".json",
    ".jsonl",
    ".xls",
    ".xlsx",
}

# Stata logs and graph binaries are NEVER committed.
ALWAYS_BLOCKED_EXTS = {".log", ".smcl", ".gph"}

# Directories where committed tabular output is OK (small aggregated outputs,
# example fixtures shipped with the template). Do not whitelist whole sandbox
# roots such as explorations/.
WHITELISTED_TABLE_DIRS = (
    "output/tables/",
    "templates/examples/",
)

# Extensions allowed in normal table-output directories.
TABLE_OUTPUT_EXTS = {".csv", ".xls", ".xlsx"}

# Extensions allowed in explicit template/example fixture directories.
TEMPLATE_EXAMPLE_EXTS = {".dta", ".csv", ".xls", ".xlsx"}

# Official project tables may also include small Stata-format audit artifacts.
PROJECT_TABLE_EXTS = TABLE_OUTPUT_EXTS | {".dta"}


# --- Core check --------------------------------------------------------------

def normalize(p: str) -> str:
    """Use forward slashes so prefix matching works on Windows too."""
    return p.replace("\\", "/")


def is_exploration_table_output(p: str) -> bool:
    """Return True for explorations/<name>/output/tables/... paths."""
    return p.startswith("explorations/") and "/output/tables/" in p


def allowed_data_output(path: str, ext: str) -> bool:
    """Return True only for documented, narrow data-output exceptions."""
    if path.startswith("output/tables/"):
        return ext in PROJECT_TABLE_EXTS
    if path.startswith("templates/examples/"):
        return ext in TEMPLATE_EXAMPLE_EXTS
    if is_exploration_table_output(path):
        return ext in TABLE_OUTPUT_EXTS
    return False


def is_unsafe(path: str) -> str:
    """
    Return an empty string if `path` is safe to commit, or a non-empty
    explanation if it is unsafe.
    """
    p = normalize(path)
    base = os.path.basename(p)
    ext = os.path.splitext(base)[1].lower()

    # 1) Anything under an always-forbidden prefix, unless it's a marker file.
    for prefix in ALWAYS_FORBIDDEN_PREFIXES:
        if p.startswith(prefix):
            if base in ALLOWED_INSIDE_FORBIDDEN:
                return ""
            return f"forbidden directory: {prefix} (only .gitkeep/README.md allowed)"

    # 2) Stata logs / graph binaries are never committed.
    if ext in ALWAYS_BLOCKED_EXTS:
        return f"forbidden extension: {ext} (Stata logs / graph binaries never commit)"

    # 3) Data-like extensions outside narrow whitelisted output dirs.
    if ext in BLOCKED_DATA_EXTS:
        if not allowed_data_output(p, ext):
            return (
                f"forbidden data-like file: {ext} outside whitelisted table/example dirs "
                f"({', '.join(WHITELISTED_TABLE_DIRS)}, explorations/*/output/tables/)"
            )

    return ""


# --- Modes -------------------------------------------------------------------

def check_paths(paths):
    unsafe = []
    for raw in paths:
        if not raw or not raw.strip():
            continue
        reason = is_unsafe(raw.strip())
        if reason:
            unsafe.append((raw.strip(), reason))
    return unsafe


def scan_tree(root: Path):
    """Walk the repo and check every tracked-or-untracked file."""
    paths = []
    for dirpath, dirnames, filenames in os.walk(root):
        # Skip .git
        dirnames[:] = [d for d in dirnames if d not in {".git", ".quarto", "__pycache__"}]
        for f in filenames:
            full = os.path.join(dirpath, f)
            rel = os.path.relpath(full, root)
            paths.append(rel)
    return check_paths(paths)


# --- CLI ---------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Refuse to commit raw / derived datasets."
    )
    parser.add_argument(
        "--staged",
        nargs="*",
        default=None,
        help="Check these paths (typically `git diff --cached --name-only` output)."
    )
    parser.add_argument(
        "--scan-tree",
        action="store_true",
        help="Walk the entire repo and report any tracked-or-untracked unsafe path."
    )
    parser.add_argument(
        "--root",
        default=".",
        help="Project root for --scan-tree (default: cwd)."
    )
    args = parser.parse_args()

    if args.staged is None and not args.scan_tree:
        parser.print_help(sys.stderr)
        return 1

    if args.staged is not None and args.scan_tree:
        print("error: pass either --staged or --scan-tree, not both", file=sys.stderr)
        return 1

    if args.staged is not None:
        unsafe = check_paths(args.staged)
    else:
        unsafe = scan_tree(Path(args.root))

    if not unsafe:
        print("[check_data_safety] OK -- no forbidden paths detected.")
        return 0

    print(
        "[check_data_safety] BLOCKED -- the following paths must not be committed:",
        file=sys.stderr,
    )
    for path, reason in unsafe:
        print(f"  - {path}", file=sys.stderr)
        print(f"      reason: {reason}", file=sys.stderr)
    print("", file=sys.stderr)
    print("To override (after deliberate review): unstage the file with", file=sys.stderr)
    print("  git reset HEAD <file>", file=sys.stderr)
    print("or whitelist its directory in scripts/check_data_safety.py.", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main())
