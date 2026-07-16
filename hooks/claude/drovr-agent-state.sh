#!/bin/sh
# installed by drovr
# Reports agent session to herdr on Claude Code session events.
# DROVR_INTEGRATION_VERSION=1

set -eu
HOOK_INPUT=$(cat)

[ "${HERDR_AGENT:-}" ] || exit 0

DROVR="$(command -v drovr 2>/dev/null || echo "")"
[ -z "$DROVR" ] && exit 0

"$DROVR" agent report working --message "Session started" 2>/dev/null || true
exit 0
