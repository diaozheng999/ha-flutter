#!/usr/bin/env bash
# Sets up all agent tooling for ha-flutter on Linux / macOS.
# Run once after cloning, and any time slash commands or skills appear missing.
# Usage: ./scripts/setup.sh [tools]
#   [tools] is a comma-separated list of tools to configure (e.g., "claude,cursor") or "all"/"none".
#   If omitted, you will be prompted interactively to select the tools.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> ha-flutter agent setup (Linux/macOS)"

# ── 1. Node dependencies (OpenSpec + future agent tools) ──────────────────────
echo ""
echo "[1/4] Installing npm devDependencies..."
(cd "$ROOT" && npm install)

# ── 2. OpenSpec: initialise OpenSpec commands and skills ──────────────────────
echo ""
echo "[2/4] Initialising OpenSpec..."
if [ -n "${1-}" ]; then
    (cd "$ROOT" && npx openspec init --tools "$1")
else
    (cd "$ROOT" && npx openspec init)
fi

# ── 3. Home Assistant MCP (project scope) ─────────────────────────────────────
echo ""
echo "[3/4] Configuring Home Assistant MCP..."
#
# The homeassistant-custom MCP is typically configured at user level via
# Claude Desktop and should already be available in your session.
#
# If it is NOT available, uncomment and fill in the block below:
#
# : "${HA_URL:?HA_URL env var is not set}"
# : "${HA_TOKEN:?HA_TOKEN env var is not set}"
# claude mcp add --scope project homeassistant-custom \
#     npx @homeassistant-mcp/server \
#     --env HA_URL="$HA_URL" \
#     --env HA_TOKEN="$HA_TOKEN"
#
echo "  (skipped — homeassistant-custom is configured at user level)"

# ── 4. Flutter doctor ─────────────────────────────────────────────────────────
echo ""
echo "[4/4] Checking Flutter environment..."
flutter doctor

echo ""
echo "Setup complete."
echo "Restart Claude Code to pick up the new /opsx:* slash commands."
