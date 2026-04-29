#!/usr/bin/env bash
#
# run_pipeline.sh — Execute the full Stata pipeline via dofiles/00_master.do.
#
# Usage:
#   bash scripts/run_pipeline.sh
#
# Behavior:
#   * Runs from project root
#   * Calls scripts/run_stata.sh on dofiles/00_master.do
#   * Prints total wall time at the end
#   * Aborts on first non-zero exit
#
# Exit codes:
#   0 — pipeline succeeded
#   N — exit code from the failing stage (propagated from run_stata.sh)

set -euo pipefail

MASTER="dofiles/00_master.do"

if [ ! -f "$MASTER" ]; then
  echo "error: $MASTER not found." >&2
  echo "       The pipeline orchestrator is missing. See templates/master-do-template.do." >&2
  exit 3
fi

START_EPOCH=$(date +%s)
echo "============================================================"
echo "  Stata Research Pipeline"
echo "  Master:   $MASTER"
echo "  Started:  $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================================"

set +e
bash scripts/run_stata.sh "$MASTER"
RC=$?
set -e

END_EPOCH=$(date +%s)
ELAPSED=$((END_EPOCH - START_EPOCH))

echo "============================================================"
echo "  Pipeline finished"
echo "  Exit code: $RC"
echo "  Elapsed:   ${ELAPSED}s"
echo "  Logs:      logs/"
echo "============================================================"

if [ "$RC" -ne 0 ]; then
  echo ""
  echo "Pipeline FAILED. Inspect logs/ for the first failing stage." >&2
  echo "  $ ls -lt logs/*.log | head -5" >&2
fi

exit "$RC"
