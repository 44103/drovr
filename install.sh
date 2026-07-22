#!/bin/bash
# drovr installer
# Installs drovr binary and agent-specific hooks.

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

# --- Install hooks (kiro-cli) ------------------------------------------------

echo ""
echo "2. Installing kiro-cli hooks..."

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
echo "3. Verification..."
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
echo "  drovr diff start         # Start live diff view"
echo "  drovr delegate --to codex -- \"Review this code\""
echo "  drovr delegate multi \"kiro-cli:task1\" \"codex:task2\""
echo ""
echo "Skills (install separately):"
echo "  gh skill install 44103/drovr"
