#Requires -Version 5.1
<#
.SYNOPSIS
    Sets up all agent tooling for ha-flutter on Windows.
    Run this once after cloning, and any time slash commands or skills appear missing.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot

Write-Host "==> ha-flutter agent setup (Windows)" -ForegroundColor Cyan

# -- 1. Node dependencies (OpenSpec + future agent tools) ----------------------
Write-Host "`n[1/4] Installing npm devDependencies..." -ForegroundColor Yellow
Push-Location $Root
try {
    npm install
} finally {
    Pop-Location
}

# -- 2. OpenSpec: initialise Claude Code commands and skills -------------------
Write-Host "`n[2/4] Initialising OpenSpec for Claude Code..." -ForegroundColor Yellow
Push-Location $Root
try {
    npx openspec init --tools claude
} finally {
    Pop-Location
}

# -- 3. Home Assistant MCP (project scope) -------------------------------------
Write-Host "`n[3/4] Configuring Home Assistant MCP..." -ForegroundColor Yellow
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

# -- 4. Flutter doctor ---------------------------------------------------------
Write-Host "`n[4/4] Checking Flutter environment..." -ForegroundColor Yellow
flutter doctor

Write-Host "`nSetup complete." -ForegroundColor Green
Write-Host "Restart Claude Code to pick up the new /opsx:* slash commands." -ForegroundColor Cyan
