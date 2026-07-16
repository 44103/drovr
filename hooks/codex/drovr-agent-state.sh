#!/bin/sh
# installed by drovr
# Reports agent session to herdr on Codex session events.
# DROVR_INTEGRATION_VERSION=1

set -eu
action="${1:-}"
HOOK_INPUT=$(cat)

case "$action" in
  session) ;;
  *) exit 0 ;;
esac

[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_SOCKET_PATH:-}" ] || exit 0

DROVR="$(command -v drovr 2>/dev/null || echo "")"
[ -z "$DROVR" ] && exit 0

SESSION_ID=$(echo "$HOOK_INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('session_id', ''))
except:
    print('')
" 2>/dev/null || echo "")

[ -z "$SESSION_ID" ] && exit 0

"$DROVR" agent session "$SESSION_ID" "codex" 2>/dev/null || true
"$DROVR" agent report working --message "Session started" 2>/dev/null || true
exit 0
