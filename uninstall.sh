#!/bin/bash
# drovr uninstaller
# Removes drovr binary and hooks from all supported agents.

set -euo pipefail

INSTALL_DIR="${DROVR_INSTALL_DIR:-$HOME/.local/bin}"

echo "drovr uninstaller"
echo "=================="
echo ""

# Remove binary
if [[ -f "${INSTALL_DIR}/drovr" ]]; then
  rm -f "${INSTALL_DIR}/drovr"
  echo "Removed: ${INSTALL_DIR}/drovr"
else
  echo "Not found: ${INSTALL_DIR}/drovr (skipped)"
fi

# Remove kiro-cli hooks
for f in drovr-agent-state.sh drovr-agent-state.json; do
  if [[ -f "${HOME}/.kiro/hooks/${f}" ]]; then
    rm -f "${HOME}/.kiro/hooks/${f}"
    echo "Removed: ~/.kiro/hooks/${f}"
  fi
done

# Remove codex hooks
if [[ -f "${HOME}/.codex/drovr-agent-state.sh" ]]; then
  rm -f "${HOME}/.codex/drovr-agent-state.sh"
  echo "Removed: ~/.codex/drovr-agent-state.sh"
fi

# Remove claude hooks
if [[ -f "${HOME}/.claude/hooks/drovr-agent-state.sh" ]]; then
  rm -f "${HOME}/.claude/hooks/drovr-agent-state.sh"
  echo "Removed: ~/.claude/hooks/drovr-agent-state.sh"
fi

# Remove old kiro-herdr hooks if present
for f in herdr-agent-state.sh herdr-agent-state.json; do
  if [[ -f "${HOME}/.kiro/hooks/${f}" ]]; then
    rm -f "${HOME}/.kiro/hooks/${f}"
    echo "Removed (legacy): ~/.kiro/hooks/${f}"
  fi
done

echo ""
echo "Uninstallation complete."
