#!/bin/bash
# drovr uninstaller
# Removes drovr binary and installed hooks.

set -euo pipefail

INSTALL_DIR="${DROVR_INSTALL_DIR:-$HOME/.local/bin}"

echo "drovr uninstaller"
echo "=================="
echo ""

# --- Remove binary -----------------------------------------------------------

if [[ -f "${INSTALL_DIR}/drovr" ]]; then
  rm -f "${INSTALL_DIR}/drovr"
  echo "Removed: ${INSTALL_DIR}/drovr"
else
  echo "Not found: ${INSTALL_DIR}/drovr (skipped)"
fi

# --- Remove legacy wrappers (from v0.1) --------------------------------------

for wrapper in kiro-cli-sub codex-sub agy-sub drovr-spawn-multi; do
  if [[ -f "${INSTALL_DIR}/${wrapper}" ]]; then
    rm -f "${INSTALL_DIR}/${wrapper}"
    echo "Removed legacy: ${INSTALL_DIR}/${wrapper}"
  fi
done

# --- Remove hooks (kiro-cli) -------------------------------------------------

KIRO_HOOKS_DIR="${HOME}/.kiro/hooks"

for hook_file in live-diff.json; do
  if [[ -f "${KIRO_HOOKS_DIR}/${hook_file}" ]]; then
    rm -f "${KIRO_HOOKS_DIR}/${hook_file}"
    echo "Removed hook: ${KIRO_HOOKS_DIR}/${hook_file}"
  fi
done

echo ""
echo "Uninstallation complete."
