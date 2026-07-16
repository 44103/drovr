#!/bin/bash
# installed by drovr
# Reports agent session and state to herdr on kiro-cli events.
# DROVR_INTEGRATION_VERSION=1

set -eu
HOOK_INPUT=$(cat)

[ "${HERDR_AGENT:-}" ] || exit 0

DROVR="$(command -v drovr 2>/dev/null || echo "")"
[ -z "$DROVR" ] && exit 0

EVENT=$(echo "$HOOK_INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('hook_event_name', data.get('event', 'unknown')))
except:
    print('unknown')
" 2>/dev/null || echo "unknown")

case "$EVENT" in
  SessionStart|session_start)
    SESSION_ID=$(echo "$HOOK_INPUT" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
    print(data.get('session_id', data.get('sessionId', '')))
except:
    print('')
" 2>/dev/null || echo "")
    [ -z "$SESSION_ID" ] && SESSION_ID="kiro-$(date +%s)-$$"
    "$DROVR" agent session "$SESSION_ID" "kiro-cli" 2>/dev/null || true
    "$DROVR" agent report working --message "Session started" 2>/dev/null || true
    ;;
  Stop|session_end)
    "$DROVR" agent report idle --message "Session ended" 2>/dev/null || true
    ;;
esac
exit 0
