#!/usr/bin/env bash
# Sets up all agent tooling for ha-flutter on Linux / macOS.
# Run once after cloning, and any time slash commands or skills appear missing.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> ha-flutter agent setup (Linux/macOS)"

# ── 1. Node dependencies (OpenSpec + future agent tools) ──────────────────────
echo ""
echo "[1/4] Installing npm devDependencies..."
(cd "$ROOT" && npm install)

# ── 2. OpenSpec: initialise Claude Code commands and skills ───────────────────
echo ""
echo "[2/4] Initialising OpenSpec for Claude Code..."
(cd "$ROOT" && npx openspec init --tools claude)

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
