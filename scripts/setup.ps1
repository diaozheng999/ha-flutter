#Requires -Version 5.1
<#
.SYNOPSIS
    Sets up all agent tooling for ha-flutter on Windows.
    Run this once after cloning, and any time slash commands or skills appear missing.
.PARAMETER Tools
    A comma-separated list of EXTRA OpenSpec tools to configure (e.g. "cursor,opencode")
    or "all". "claude" is always included — the generated Claude commands are the
    source for the universal skill bridge. Pass "none" to skip OpenSpec init and
    the bridge entirely.
#>
param(
    [string]$Tools
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot

Write-Host "==> ha-flutter agent setup (Windows)" -ForegroundColor Cyan

# -- 1. Node dependencies -------------------------------------------------------
Write-Host "`n[1/7] Installing npm devDependencies..." -ForegroundColor Yellow
Push-Location $Root
try {
    npm install
} finally {
    Pop-Location
}

# -- 2. Global OpenSpec CLI -----------------------------------------------------
# The generated slash commands/skills invoke bare `openspec`, which must be on
# PATH. The local devDependency pins the version used by this script via npx.
Write-Host "`n[2/7] Installing global OpenSpec CLI..." -ForegroundColor Yellow
npm install -g @fission-ai/openspec@latest

# -- 3. Restore skills from skills-lock.json ------------------------------------
# Lockfile-driven for reproducibility: `npx skills add` would re-resolve latest.
# To add a NEW skill: npx skills add <source> --skill <name>, then commit the
# updated skills-lock.json (see AGENTS.md).
Write-Host "`n[3/7] Restoring skills from skills-lock.json..." -ForegroundColor Yellow
Push-Location $Root
try {
    npx skills experimental_install
} finally {
    Pop-Location
}

# -- 4. OpenSpec init -----------------------------------------------------------
Write-Host "`n[4/7] Initialising OpenSpec..." -ForegroundColor Yellow
if ($Tools -eq "none") {
    Write-Host "  (skipped - Tools=none)" -ForegroundColor DarkGray
} else {
    $hasBridge = @(
        Get-ChildItem -Path (Join-Path $Root ".agents\skills") -Directory -Filter "opsx-*" -ErrorAction SilentlyContinue
    ).Count -gt 0
    if (-not $Tools -and $hasBridge) {
        Write-Host "  (skipped - existing universal opsx skills preserve project configuration)" -ForegroundColor DarkGray
    } else {
    if (-not $Tools) {
        $EffectiveTools = "claude"
    } elseif ($Tools -eq "all") {
        $EffectiveTools = "all"
    } elseif (($Tools -split ",") -contains "claude") {
        $EffectiveTools = $Tools
    } else {
        $EffectiveTools = "claude,$Tools"
    }
    Push-Location $Root
    try {
        npx openspec init --tools $EffectiveTools
    } finally {
        Pop-Location
    }
    }
}

# -- 5. Bridge OpenSpec commands to universal skills -----------------------------
# Moves .claude/commands/opsx/*.md -> .agents/skills/opsx-*/SKILL.md and renames
# /opsx:xxx -> /opsx-xxx, so agents unsupported by OpenSpec (but reading the
# universal .agents/skills dir) get the workflow too.
Write-Host "`n[5/7] Bridging OpenSpec commands to .agents/skills..." -ForegroundColor Yellow
if ($Tools -eq "none") {
    Write-Host "  (skipped - Tools=none)" -ForegroundColor DarkGray
} else {
    Push-Location $Root
    try {
        node scripts/generate-opsx-skills.mjs
        if ($LASTEXITCODE -ne 0) { throw "generate-opsx-skills.mjs failed" }
    } finally {
        Pop-Location
    }
}

# -- 6. Sanity checks -------------------------------------------------------------
Write-Host "`n[6/7] Checking OpenSpec configuration..." -ForegroundColor Yellow
$configPath = Join-Path $Root "openspec/config.yaml"
if (-not (Select-String -Path $configPath -Pattern '^schema: spec-driven-decisions' -Quiet)) {
    Write-Error ("openspec/config.yaml no longer selects 'spec-driven-decisions'. " +
        "openspec init may have overwritten it - restore via git.")
}
Push-Location $Root
try {
    npx openspec schema validate spec-driven-decisions
} finally {
    Pop-Location
}

# -- 7. Flutter doctor ------------------------------------------------------------
Write-Host "`n[7/7] Checking Flutter environment..." -ForegroundColor Yellow
flutter doctor

Write-Host "`nSetup complete." -ForegroundColor Green
Write-Host "Restart your agent runtime to pick up the /opsx-* skills." -ForegroundColor Cyan
