#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# codex-antigravity-worker macOS / Linux Installer
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
SKILLS_DEST="${CODEX_HOME}/skills/antigravity-flash-worker"

echo "=== Codex Antigravity Worker Installation ==="
echo ""

# 1. Check Antigravity CLI (`agy`)
echo "[1/4] Checking Google Antigravity CLI ('agy')..."
if command -v agy >/dev/null 2>&1; then
    AGY_PATH="$(command -v agy)"
    echo "      Found agy at: ${AGY_PATH}"
elif [[ -x "${HOME}/.local/bin/agy" ]]; then
    AGY_PATH="${HOME}/.local/bin/agy"
    echo "      Found agy at: ${AGY_PATH}"
else
    echo "      [!] 'agy' CLI not found in PATH or ~/.local/bin/agy."
    echo "          Please ensure Google Antigravity CLI is installed and authenticated."
fi

# 2. Check `agy-mcp`
echo "[2/4] Checking 'agy-mcp' MCP Server..."
if command -v agy-mcp >/dev/null 2>&1; then
    AGY_MCP_PATH="$(command -v agy-mcp)"
    echo "      Found agy-mcp at: ${AGY_MCP_PATH}"
elif [[ -x "${HOME}/.local/bin/agy-mcp" ]]; then
    AGY_MCP_PATH="${HOME}/.local/bin/agy-mcp"
    echo "      Found agy-mcp at: ${AGY_MCP_PATH}"
else
    echo "      [!] 'agy-mcp' not found."
    echo "          Install upstream agy-mcp via Homebrew or GitHub Releases:"
    echo "          - Homebrew: brew install tphakala/tap/agy-mcp"
    echo "          - Releases: https://github.com/tphakala/agy-mcp/releases"
fi

# 3. Install Codex Skill
echo "[3/4] Installing 'antigravity-flash-worker' Codex Skill..."
mkdir -p "${SKILLS_DEST}"
cp "${REPO_ROOT}/skills/antigravity-flash-worker/SKILL.md" "${SKILLS_DEST}/SKILL.md"
echo "      Installed skill to: ${SKILLS_DEST}/SKILL.md"

# 4. Check Codex Configuration
echo "[4/4] Checking Codex MCP configuration (${CODEX_HOME}/config.toml)..."
CONFIG_FILE="${CODEX_HOME}/config.toml"

if [[ -f "${CONFIG_FILE}" ]] && grep -q '\[mcp_servers\.agy\]' "${CONFIG_FILE}"; then
    echo "      'agy' MCP server is already registered in ${CONFIG_FILE}."
else
    echo "      'agy' MCP server is NOT yet registered in ${CONFIG_FILE}."
    echo ""
    echo "      To register, add the following to ${CONFIG_FILE}:"
    echo "      ------------------------------------------------------"
    cat "${REPO_ROOT}/config/codex-mcp.example.toml"
    echo "      ------------------------------------------------------"
fi

echo ""
echo "=== Installation & Check Complete ==="
echo "You can test the setup by running: ./scripts/smoke-test.sh"
