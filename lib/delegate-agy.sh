#!/bin/bash
# drovr delegate wrapper: agy (Claude Code)
# Runs agy in print mode, captures result, sends back to caller pane.
# Usage: delegate-agy.sh <return-pane-id> <prompt>

set -eu

RETURN_PANE="${1:?Usage: delegate-agy.sh <return-pane-id> <prompt>}"
shift
PROMPT="$*"

OUTPUT_FILE=$(mktemp /tmp/drovr-delegate-agy-XXXXXX.txt)
trap "rm -f $OUTPUT_FILE" EXIT

# Run agy in print mode (non-interactive), tee for pane display
agy --dangerously-skip-permissions -p "$PROMPT" 2>&1 | tee "$OUTPUT_FILE"

# Strip ANSI escape codes
CLEAN=$(perl -pe 's/\e\[[0-9;?]*[a-zA-Z]//g; s/\e\].*?\a//g; s/[\x00-\x08\x0b\x0c\x0e-\x1f]//g' "$OUTPUT_FILE")

# Filter noise, extract answer
RESULT=$(echo "$CLEAN" \
  | grep -v "^$" \
  | sed '/^[[:space:]]*$/d' \
  | tail -30 \
  | head -c 2000)

# Send result back to caller pane
if [ -n "$RESULT" ] && command -v herdr &>/dev/null; then
  RESULT_ONELINE=$(echo "$RESULT" | tr '\n' '|' | head -c 1500)
  herdr pane send-text "$RETURN_PANE" "[RETURN:agy] $RESULT_ONELINE" 2>/dev/null || true
  herdr pane send-keys "$RETURN_PANE" Enter 2>/dev/null || true
fi
