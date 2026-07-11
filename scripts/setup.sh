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
echo "[1/5] Installing npm devDependencies..."
(cd "$ROOT" && npm install)

# ── 2. Skills configuration ─────────────────────────────────────────────────
echo ""
echo "[2/5] Adding skill sources..."
if [ -n "${1-}" ]; then
    (cd "$ROOT" && npx skills add homeassistant-ai/skills -a "$1" --skill "*")
    (cd "$ROOT" && npx skills add flutter/skills -a "$1" --skill "*")
else
    (cd "$ROOT" && npx skills add homeassistant-ai/skills --skill "*")
    (cd "$ROOT" && npx skills add flutter/skills --skill "*")
fi

# ── 3. OpenSpec: initialise OpenSpec commands and skills ──────────────────────
echo ""
echo "[3/5] Initialising OpenSpec..."
if [ -n "${1-}" ]; then
    (cd "$ROOT" && npx openspec init --tools "$1")
else
    (cd "$ROOT" && npx openspec init)
fi

# ── 4. Home Assistant MCP (project scope) ─────────────────────────────────────
echo ""
echo "[4/5] Configuring Home Assistant MCP..."
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
#	--env HA_URL="$HA_URL" \
#     --env HA_TOKEN="$HA_TOKEN"
#
echo "  (skipped — homeassistant-custom is configured at user level)"

# ── 5. Flutter doctor ─────────────────────────────────────────────────────────
echo ""
echo "[5/5] Checking Flutter environment..."
flutter doctor

echo ""
echo "Setup complete."
echo "Restart your agent (e.g. Claude Code) or IDE to pick up the new /opsx:* slash commands."
