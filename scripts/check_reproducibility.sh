#!/usr/bin/env bash
#
# check_reproducibility.sh — Fresh-clone simulation for the pipeline.
#
# Snapshots current output/, wipes the working tree (preserving data/raw/),
# re-runs the pipeline, then diffs the new output/ against the snapshot.
# Any drift indicates a reproducibility failure.
#
# Usage:
#   bash scripts/check_reproducibility.sh           # full check
#   bash scripts/check_reproducibility.sh --clean-only   # just wipe; for /check-reproducibility skill
#
# Exit codes:
#   0 — outputs reproduced exactly (or only timestamp metadata differs)
#   1 — usage error
#   2 — pipeline failed during re-run (cannot assess reproducibility)
#   3 — drift detected (numerical or visual differences in output/)

set -euo pipefail

MODE="full"
if [ "${1:-}" = "--clean-only" ]; then
  MODE="clean-only"
fi

# --- 1. Pre-flight ----------------------------------------------------------
if [ ! -d "output" ]; then
  echo "[check_repro] no output/ directory yet; nothing to compare." >&2
  echo "             run 'bash scripts/run_pipeline.sh' first, then re-run this script." >&2
  exit 1
fi

# Working tree must be clean for the diff to be meaningful (skip if --clean-only).
if [ "$MODE" = "full" ] && command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
  if ! git diff --quiet HEAD 2>/dev/null; then
    echo "[check_repro] working tree has uncommitted changes." >&2
    echo "             commit or stash them first; otherwise the diff is meaningless." >&2
    exit 1
  fi
fi

# --- 2. Snapshot ------------------------------------------------------------
SNAP="$(mktemp -d)/output_snapshot"
echo "[check_repro] snapshotting current output/ → $SNAP"
cp -r output "$SNAP"

# --- 3. Clean working tree (preserve data/raw/) -----------------------------
echo "[check_repro] wiping working tree (preserving data/raw/, .claude/state/)"
if command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
  git clean -dfx -e data/raw -e .claude/state -e .claude/settings.local.json
else
  echo "[check_repro] WARNING: git not available; doing a manual cleanup of generated dirs" >&2
  rm -rf logs output/tables output/figures docs/*.html docs/_files
  mkdir -p logs output/tables output/figures
fi

if [ "$MODE" = "clean-only" ]; then
  echo "[check_repro] --clean-only: stopping here. Snapshot at $SNAP."
  echo "  to restore: rm -rf output && mv $SNAP output"
  exit 0
fi

# --- 4. Re-run the pipeline -------------------------------------------------
echo "[check_repro] re-running the pipeline ..."
set +e
bash scripts/run_pipeline.sh
RUN_RC=$?
set -e

if [ "$RUN_RC" -ne 0 ]; then
  echo "[check_repro] pipeline FAILED on re-run (exit $RUN_RC)" >&2
  echo "             reproducibility cannot be assessed." >&2
  echo "             snapshot preserved at $SNAP" >&2
  exit 2
fi

# --- 5. Diff ----------------------------------------------------------------
echo "[check_repro] diffing new output/ against snapshot"
DIFF_RESULT="$(mktemp)"
set +e
diff -r --brief "$SNAP" output > "$DIFF_RESULT"
DIFF_RC=$?
set -e

if [ "$DIFF_RC" -eq 0 ]; then
  echo "[check_repro] PASS — outputs are byte-identical."
  rm -rf "$SNAP"
  exit 0
fi

# Drift detected. Categorize.
TEXT_DRIFT=$(grep -c '\.csv\|\.tex\|\.txt\|\.md' "$DIFF_RESULT" || true)
BINARY_DRIFT=$(grep -c '\.pdf\|\.png\|\.svg\|\.gph' "$DIFF_RESULT" || true)

echo "[check_repro] DRIFT detected:"
echo "  text-format drift (.csv/.tex/.md): $TEXT_DRIFT files"
echo "  binary drift (.pdf/.png/.svg):     $BINARY_DRIFT files"
echo ""
echo "  detailed diff:"
sed 's/^/    /' "$DIFF_RESULT"
echo ""

if [ "$TEXT_DRIFT" -gt 0 ]; then
  echo "[check_repro] FAIL — numerical drift detected in text outputs." >&2
  echo "             investigate: seeded randomness, package versions, sort order." >&2
  echo "             snapshot preserved at $SNAP for inspection." >&2
  exit 3
else
  echo "[check_repro] WARN — only binary drift detected (likely cosmetic)." >&2
  echo "             open both versions to confirm; snapshot at $SNAP." >&2
  exit 3
fi
