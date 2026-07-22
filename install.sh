#!/bin/bash
# drovr installer
# Installs drovr binary and sub-agent wrappers to PATH.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${DROVR_INSTALL_DIR:-$HOME/.local/bin}"

echo "drovr installer"
echo "================"
echo ""

# --- Install binary ----------------------------------------------------------

echo "1. Installing drovr to ${INSTALL_DIR}..."
mkdir -p "$INSTALL_DIR"

cat > "${INSTALL_DIR}/drovr" <<WRAPPER
#!/bin/bash
exec "${SCRIPT_DIR}/bin/drovr" "\$@"
WRAPPER
chmod +x "${INSTALL_DIR}/drovr"
echo "   Done: ${INSTALL_DIR}/drovr"

# --- Install sub-agent wrappers ----------------------------------------------

echo ""
echo "2. Installing sub-agent wrappers..."

for wrapper in kiro-cli-sub codex-sub agy-sub drovr-spawn-multi; do
  if [[ -f "${SCRIPT_DIR}/bin/${wrapper}" ]]; then
    ln -sf "${SCRIPT_DIR}/bin/${wrapper}" "${INSTALL_DIR}/${wrapper}"
    echo "   Done: ${INSTALL_DIR}/${wrapper} -> ${SCRIPT_DIR}/bin/${wrapper}"
  fi
done

# --- Install hooks (kiro-cli) ------------------------------------------------

echo ""
echo "3. Installing kiro-cli hooks..."

KIRO_HOOKS_DIR="${HOME}/.kiro/hooks"
mkdir -p "$KIRO_HOOKS_DIR"

for hook_file in "${SCRIPT_DIR}"/hooks/kiro/*.json; do
  if [[ -f "$hook_file" ]]; then
    local_name="$(basename "$hook_file")"
    cp "$hook_file" "${KIRO_HOOKS_DIR}/${local_name}"
    echo "   Done: ${KIRO_HOOKS_DIR}/${local_name}"
  fi
done

# --- Verify ------------------------------------------------------------------

echo ""
echo "4. Verification..."
if command -v drovr >/dev/null 2>&1; then
  echo "   drovr: $(drovr version)"
else
  echo "   Warning: drovr not found in PATH."
  echo "   Add ${INSTALL_DIR} to your PATH:"
  echo "     export PATH=\"${INSTALL_DIR}:\$PATH\""
fi

echo ""
echo "Installation complete!"
echo ""
echo "Usage:"
echo "  drovr status                    # Check connection"
echo "  drovr pane list                 # List panes"
echo "  drovr agent spawn task1 -- ...  # Spawn agent in new pane"
echo ""
echo "Sub-agent wrappers (auto-return results to caller pane):"
echo "  herdr agent start name --split right -- kiro-cli-sub <pane-id> \"prompt\""
echo "  herdr agent start name --split right -- codex-sub <pane-id> \"prompt\""
echo "  herdr agent start name --split right -- agy-sub <pane-id> \"prompt\""
