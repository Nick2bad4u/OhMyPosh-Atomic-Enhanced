<#
.SYNOPSIS
Orchestrates the full generation pipeline for independent root themes:
1. Generates Experimental Divider helper variants.
2. Stages those root helper changes.
3. Generates palette-only extensions (unstaged).

.EXAMPLE
./scripts/Dev-Generate-All.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ScriptRoot = $PSScriptRoot
$RepoRoot = Split-Path -Path $ScriptRoot -Parent

# Ensure we are in the repo root
Set-Location $RepoRoot

Write-Host "`n🚀 Starting Dev-Generate-All pipeline..." -ForegroundColor Cyan

# --------------------------------------------------------------------------
# 1. Generate ExperimentalDividers root helpers
# --------------------------------------------------------------------------
Write-Host "`n🔄 Step 1: Generating Experimental Divider helper variants..." -ForegroundColor Cyan

# Fish
Write-Host '   Generating Fish variant...' -ForegroundColor Gray
& "$ScriptRoot/Make-FishVariant.ps1" -Source 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'

# NoShellIntegration
Write-Host '   Generating NoShellIntegration variant...' -ForegroundColor Gray
& "$ScriptRoot/Make-NoShellIntegration.ps1" -Source 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'

# NoNetwork
Write-Host '   Generating NoNetwork variant...' -ForegroundColor Gray
& "$ScriptRoot/Make-NoNetwork.ps1" -SourceTheme 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'

# --------------------------------------------------------------------------
# 2. Stage changes
# --------------------------------------------------------------------------
Write-Host "`n🔄 Step 2: Staging root helper changes..." -ForegroundColor Cyan

$filesToStage = @(
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.Fish.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.NoShellIntegration.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.NoNetwork.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'
)

foreach ($file in $filesToStage) {
    if (Test-Path $file) {
        Write-Host "   Staging: $file" -ForegroundColor Gray
        git add $file
    }
    else {
        Write-Host "   ⚠️ File not found (skipping stage): $file" -ForegroundColor Yellow
    }
}

# --------------------------------------------------------------------------
# 3. Force run theme generation
# --------------------------------------------------------------------------
Write-Host "`n🔄 Step 3: Generating palette extensions (this may take a moment)..." -ForegroundColor Cyan
Write-Host '   (Output files will NOT be staged)' -ForegroundColor Gray

& "$ScriptRoot/Generate-AllThemes.ps1" -Force
& "$ScriptRoot/Generate-ExperimentalDividers.ps1" -Force -SkipRootVariants

Write-Host "`n✅ Pipeline complete!" -ForegroundColor Green
