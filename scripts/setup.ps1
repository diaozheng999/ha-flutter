#Requires -Version 5.1
<#
.SYNOPSIS
    Sets up all agent tooling for ha-flutter on Windows.
    Run this once after cloning, and any time slash commands or skills appear missing.
.PARAMETER Tools
    A comma-separated list of tools to configure (e.g. "claude,cursor") or "all"/"none".
    If omitted, you will be prompted interactively to select the tools.
#>
param(
    [string]$Tools
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot

Write-Host "==> ha-flutter agent setup (Windows)" -ForegroundColor Cyan

# -- 1. Node dependencies (OpenSpec + future agent tools) ----------------------
Write-Host "`n[1/5] Installing npm devDependencies..." -ForegroundColor Yellow
Push-Location $Root
try {
    npm install
} finally {
    Pop-Location
}

# -- 2. Skills configuration ---------------------------------------------------
Write-Host "`n[2/5] Adding skill sources..." -ForegroundColor Yellow
Push-Location $Root
try {
    if ($Tools) {
        npx skills add homeassistant-ai/skills -a $Tools --skill *
        npx skills add flutter/skills -a $Tools --skill *
    } else {
        npx skills add homeassistant-ai/skills --skill *
        npx skills add flutter/skills --skill *
    }
} finally {
    Pop-Location
}

# -- 3. OpenSpec: initialise OpenSpec commands and skills ----------------------
Write-Host "`n[3/5] Initialising OpenSpec..." -ForegroundColor Yellow
Push-Location $Root
try {
    if ($Tools) {
        npx openspec init --tools $Tools
    } else {
        npx openspec init
    }
} finally {
    Pop-Location
}

# -- 4. Home Assistant MCP (project scope) -------------------------------------
Write-Host "`n[4/5] Configuring Home Assistant MCP..." -ForegroundColor Yellow
#
# The homeassistant-custom MCP is typically configured at user level via
# Claude Desktop and should already be available in your session.
#
# If it is NOT available, uncomment and fill in the block below:
#
# if (-not $env:HA_URL) { Write-Error "HA_URL env var is not set"; exit 1 }
# if (-not $env:HA_TOKEN) { Write-Error "HA_TOKEN env var is not set"; exit 1 }
# claude mcp add --scope project homeassistant-custom `
#     npx @homeassistant-mcp/server `
#     --env HA_URL=$env:HA_URL `
#     --env HA_TOKEN=$env:HA_TOKEN
#
Write-Host "  (skipped - homeassistant-custom is configured at user level)" -ForegroundColor DarkGray

# -- 5. Flutter doctor ---------------------------------------------------------
Write-Host "`n[5/5] Checking Flutter environment..." -ForegroundColor Yellow
flutter doctor

Write-Host "`nSetup complete." -ForegroundColor Green
Write-Host "Restart your agent (e.g. Claude Code) or IDE to pick up the new /opsx:* slash commands." -ForegroundColor Cyan
