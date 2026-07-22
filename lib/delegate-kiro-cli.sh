#!/bin/bash
# drovr delegate wrapper: kiro-cli
# Runs kiro-cli in non-interactive mode, captures result, sends back to caller pane.
# Usage: delegate-kiro-cli.sh <return-pane-id> <prompt>

set -eu

RETURN_PANE="${1:?Usage: delegate-kiro-cli.sh <return-pane-id> <prompt>}"
shift
PROMPT="$*"

OUTPUT_FILE=$(mktemp /tmp/drovr-delegate-kiro-XXXXXX.txt)
trap "rm -f $OUTPUT_FILE" EXIT

# Run kiro-cli with tee so pane shows progress
kiro-cli chat --no-interactive --trust-all-tools "$PROMPT" 2>&1 | tee "$OUTPUT_FILE"

# Strip ANSI escape codes and zero-width characters
CLEAN=$(perl -pe 's/\e\[[0-9;?]*[a-zA-Z]//g; s/\e\].*?\a//g; s/[\x00-\x08\x0b\x0c\x0e-\x1f]//g; s/\x{200e}//g; s/\x{200b}//g' "$OUTPUT_FILE")

# Filter noise, extract answer
RESULT=$(echo "$CLEAN" \
  | grep -v "^Searching\|^Fetching\|^ ✓\|^ - \|^Not all mcp\|^All tools\|^Agents can\|^Learn more\|^------\|▸ Time:" \
  | grep -v "^$" \
  | sed 's/^> //' \
  | sed '/^[[:space:]]*$/d' \
  | tail -30 \
  | head -c 1500)

# Send result back to caller pane
if [ -n "$RESULT" ] && command -v herdr &>/dev/null; then
  RESULT_ONELINE=$(printf "%s" "$RESULT" | tr '\n\r' '||' | sed 's/||*/|/g' | head -c 1000)
  herdr pane send-text "$RETURN_PANE" "[RETURN:kiro-cli] $RESULT_ONELINE" 2>/dev/null || true
  herdr pane send-keys "$RETURN_PANE" Enter 2>/dev/null || true
fi
