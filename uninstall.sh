#!/bin/bash
# drovr uninstaller
# Removes drovr binary and sub-agent wrappers.

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

# Remove sub-agent wrappers
for wrapper in kiro-cli-sub codex-sub agy-sub drovr-spawn-multi; do
  if [[ -f "${INSTALL_DIR}/${wrapper}" ]]; then
    rm -f "${INSTALL_DIR}/${wrapper}"
    echo "Removed: ${INSTALL_DIR}/${wrapper}"
  fi
done

echo ""
echo "Uninstallation complete."
