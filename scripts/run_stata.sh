#!/usr/bin/env bash
#
# run_stata.sh — Wrapper around `stata -b` for the Stata Research Pipeline.
#
# Usage:
#   bash scripts/run_stata.sh <path/to/file.do> [<log/path.log>]
#
# Behavior:
#   * Runs from project root (whatever directory you invoke it from)
#   * Picks the first available Stata executable from a known list
#   * Derives the log path from the do-file path if not given
#   * Captures Stata's exit code and propagates it
#   * Prints log tail on failure so the error is visible
#
# Exit codes:
#   0  — success
#   1  — usage error
#   2  — Stata not found on PATH
#   3  — do-file not found
#   N  — Stata exit code on failure

set -euo pipefail

# --- 1. Argument parsing ------------------------------------------------------
if [ $# -lt 1 ]; then
  echo "usage: bash scripts/run_stata.sh <path/to/file.do> [<log/path.log>]" >&2
  exit 1
fi

DOFILE="$1"
LOG_PATH="${2:-}"

if [ ! -f "$DOFILE" ]; then
  echo "error: do-file not found: $DOFILE" >&2
  exit 3
fi

# --- 2. Derive log path if not given -----------------------------------------
# dofiles/03_analysis/main_regression.do -> logs/03_analysis_main_regression.log
if [ -z "$LOG_PATH" ]; then
  REL="${DOFILE#dofiles/}"          # strip leading dofiles/
  REL="${REL%.do}"                  # strip trailing .do
  REL="${REL//\//_}"                # replace / with _
  LOG_PATH="logs/${REL}.log"
fi

mkdir -p "$(dirname "$LOG_PATH")"

# --- 3. Locate a Stata executable --------------------------------------------
STATA_CANDIDATES=(stata-mp stata-se stata StataMP-64 StataSE-64 Stata-64)
STATA_BIN=""
for CAND in "${STATA_CANDIDATES[@]}"; do
  if command -v "$CAND" >/dev/null 2>&1; then
    STATA_BIN="$CAND"
    break
  fi
done

if [ -z "$STATA_BIN" ]; then
  echo "error: no Stata executable found on PATH (tried: ${STATA_CANDIDATES[*]})" >&2
  echo "       install Stata or add it to PATH; see CLAUDE.md prerequisites." >&2
  exit 2
fi

# --- 4. Run Stata -------------------------------------------------------------
# We run from project root and let the do-file open its own log.
# We ALSO redirect Stata's transcript via -b -e so that even do-files that
# forget `log using` still produce something to inspect.

STATA_EXTRA_LOG="${LOG_PATH%.log}_stata_console.log"

echo "[run_stata] using:    $STATA_BIN"
echo "[run_stata] do-file:  $DOFILE"
echo "[run_stata] log:      $LOG_PATH"
echo "[run_stata] starting:" "$(date '+%Y-%m-%d %H:%M:%S')"

set +e
"$STATA_BIN" -b -e do "$DOFILE" >"$STATA_EXTRA_LOG" 2>&1
RC=$?
set -e

echo "[run_stata] exit:     $RC"
echo "[run_stata] finished:" "$(date '+%Y-%m-%d %H:%M:%S')"

# --- 5. On failure, tail the logs --------------------------------------------
if [ "$RC" -ne 0 ]; then
  echo "[run_stata] --- last 30 lines of $LOG_PATH ---" >&2
  if [ -f "$LOG_PATH" ]; then
    tail -n 30 "$LOG_PATH" >&2
  else
    echo "[run_stata] (log file not produced; see $STATA_EXTRA_LOG)" >&2
    tail -n 30 "$STATA_EXTRA_LOG" >&2
  fi
fi

exit "$RC"
