#!/bin/bash
# drovr installer
# Installs drovr binary to PATH and optionally registers hooks for supported agents.

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
echo "1b. Installing sub-agent wrappers..."

for wrapper in kiro-cli-sub codex-sub agy-sub drovr-spawn-multi; do
  if [[ -f "${SCRIPT_DIR}/bin/${wrapper}" ]]; then
    ln -sf "${SCRIPT_DIR}/bin/${wrapper}" "${INSTALL_DIR}/${wrapper}"
    echo "   Done: ${INSTALL_DIR}/${wrapper} -> ${SCRIPT_DIR}/bin/${wrapper}"
  fi
done

echo ""
echo "1c. Installing skills..."

SKILLS_DIR="${HOME}/.kiro/skills"
if [[ -d "${SCRIPT_DIR}/skills" ]]; then
  for skill_dir in "${SCRIPT_DIR}/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    mkdir -p "${SKILLS_DIR}/${skill_name}"
    ln -sf "${skill_dir}SKILL.md" "${SKILLS_DIR}/${skill_name}/SKILL.md" 2>/dev/null || true
    echo "   Skill: ${skill_name}"
  done
fi

# --- Detect and install hooks ------------------------------------------------

echo ""
echo "2. Installing agent hooks..."

install_kiro_hooks() {
  local hooks_dir="${HOME}/.kiro/hooks"
  mkdir -p "$hooks_dir"

  cp "${SCRIPT_DIR}/hooks/kiro/drovr-agent-state.sh" "${hooks_dir}/drovr-agent-state.sh"
  chmod +x "${hooks_dir}/drovr-agent-state.sh"

  cp "${SCRIPT_DIR}/hooks/kiro/drovr-agent-state.json" "${hooks_dir}/drovr-agent-state.json"

  echo "   kiro-cli: ${hooks_dir}/drovr-agent-state.{sh,json}"
}

install_codex_hooks() {
  local hooks_dir="${HOME}/.codex"
  mkdir -p "$hooks_dir"

  cp "${SCRIPT_DIR}/hooks/codex/drovr-agent-state.sh" "${hooks_dir}/drovr-agent-state.sh"
  chmod +x "${hooks_dir}/drovr-agent-state.sh"

  echo "   codex: ${hooks_dir}/drovr-agent-state.sh"
}

install_claude_hooks() {
  local hooks_dir="${HOME}/.claude/hooks"
  mkdir -p "$hooks_dir"

  cp "${SCRIPT_DIR}/hooks/claude/drovr-agent-state.sh" "${hooks_dir}/drovr-agent-state.sh"
  chmod +x "${hooks_dir}/drovr-agent-state.sh"

  echo "   claude: ${hooks_dir}/drovr-agent-state.sh"
}

# Install hooks for detected agents
if command -v kiro-cli >/dev/null 2>&1 || [[ -d "${HOME}/.kiro" ]]; then
  install_kiro_hooks
fi

if command -v codex >/dev/null 2>&1 || [[ -d "${HOME}/.codex" ]]; then
  install_codex_hooks
fi

if command -v claude >/dev/null 2>&1 || [[ -d "${HOME}/.claude" ]]; then
  install_claude_hooks
fi

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
echo "  drovr status                    # Check connection"
echo "  drovr pane list                 # List panes"
echo "  drovr agent spawn task1 -- ...  # Spawn agent in new pane"
echo ""
echo "Sub-agent wrappers (auto-return results to caller pane):"
echo "  herdr agent start name --split right -- kiro-cli-sub <pane-id> \"prompt\""
echo "  herdr agent start name --split right -- codex-sub <pane-id> \"prompt\""
echo "  herdr agent start name --split right -- agy-sub <pane-id> \"prompt\""
echo ""
echo "Hooks will automatically report session state to herdr"
echo "when supported AI agents start and stop."
