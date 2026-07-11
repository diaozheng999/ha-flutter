#!/usr/bin/env bash
# Sets up all agent tooling for ha-flutter on Linux / macOS.
# Run once after cloning, and any time slash commands or skills appear missing.
# Usage: ./scripts/setup.sh [tools]
#   [tools] is a comma-separated list of EXTRA OpenSpec tools to configure
#   (e.g., "cursor,opencode") or "all". "claude" is always included — the
#   generated Claude commands are the source for the universal skill bridge.
#   Pass "none" to skip OpenSpec init and the bridge entirely.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="${1-}"

echo "==> ha-flutter agent setup (Linux/macOS)"

# ── 1. Node dependencies ──────────────────────────────────────────────────────
echo ""
echo "[1/7] Installing npm devDependencies..."
(cd "$ROOT" && npm install)

# ── 2. Global OpenSpec CLI ────────────────────────────────────────────────────
# The generated slash commands/skills invoke bare `openspec`, which must be on
# PATH. The local devDependency pins the version used by this script via npx.
echo ""
echo "[2/7] Installing global OpenSpec CLI..."
npm install -g @fission-ai/openspec@latest

# ── 3. Restore skills from skills-lock.json ──────────────────────────────────
# Lockfile-driven for reproducibility: `npx skills add` would re-resolve
# latest. To add a NEW skill: npx skills add <source> --skill <name>, then
# commit the updated skills-lock.json (see AGENTS.md).
echo ""
echo "[3/7] Restoring skills from skills-lock.json..."
(cd "$ROOT" && npx skills experimental_install)

# ── 4. OpenSpec init ──────────────────────────────────────────────────────────
echo ""
echo "[4/7] Initialising OpenSpec..."
if [ "$TOOLS" = "none" ]; then
    echo "  (skipped — tools=none)"
else
    case ",$TOOLS," in
        ,,|*,claude,*) EFFECTIVE_TOOLS="${TOOLS:-claude}" ;;
        ,all,)         EFFECTIVE_TOOLS="all" ;;
        *)             EFFECTIVE_TOOLS="claude,$TOOLS" ;;
    esac
    (cd "$ROOT" && npx openspec init --tools "$EFFECTIVE_TOOLS")
fi

# ── 5. Bridge OpenSpec commands to universal skills ──────────────────────────
# Moves .claude/commands/opsx/*.md -> .agents/skills/opsx-*/SKILL.md and
# renames /opsx:xxx -> /opsx-xxx, so agents unsupported by OpenSpec (but
# reading the universal .agents/skills dir) get the workflow too.
echo ""
echo "[5/7] Bridging OpenSpec commands to .agents/skills..."
if [ "$TOOLS" = "none" ]; then
    echo "  (skipped — tools=none)"
else
    (cd "$ROOT" && node scripts/generate-opsx-skills.mjs)
fi

# ── 6. Sanity checks ──────────────────────────────────────────────────────────
echo ""
echo "[6/7] Checking OpenSpec configuration..."
if ! grep -q '^schema: spec-driven-decisions' "$ROOT/openspec/config.yaml"; then
    echo "WARNING: openspec/config.yaml no longer selects 'spec-driven-decisions'." >&2
    echo "         openspec init may have overwritten it — restore via git." >&2
    exit 1
fi
(cd "$ROOT" && npx openspec schema validate spec-driven-decisions)

# ── 7. Flutter doctor ─────────────────────────────────────────────────────────
echo ""
echo "[7/7] Checking Flutter environment..."
flutter doctor

echo ""
echo "Setup complete."
echo "Restart your agent runtime to pick up the /opsx-* skills."
