<#
.SYNOPSIS
Orchestrates the full generation pipeline:
1. Syncs root variants.
2. Generates Experimental Divider variants.
3. Stages these root/variant changes.
4. Generates all colored themes (unstaged).

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
# 1. Generate "root" variants
# --------------------------------------------------------------------------
Write-Host "`n🔄 Step 1: Syncing root variants..." -ForegroundColor Cyan

# A. Sync ExperimentalDividers -> AtomicCustom
Write-Host '   Syncing AtomicCustom from ExperimentalDividers...' -ForegroundColor Gray
& "$ScriptRoot/Generate-AtomicCustomFromExperimentalDividers.ps1" `
    -ExperimentalDividersPath 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json' `
    -AtomicCustomTemplatePath 'OhMyPosh-Atomic-Custom.json' `
    -OutputPath 'OhMyPosh-Atomic-Custom.json'

# B. Sync AtomicCustom -> Other Root Themes
Write-Host '   Syncing other root themes from AtomicCustom...' -ForegroundColor Gray
& "$ScriptRoot/Sync-ThemeTemplatesFromAtomicCustom.ps1" `
    -AtomicCustomPath 'OhMyPosh-Atomic-Custom.json' `
    -TargetThemes @(
    '1_shell-Enhanced.omp.json',
    'slimfat-Enhanced.omp.json',
    'atomicBit-Enhanced.omp.json',
    'clean-detailed-Enhanced.omp.json'
)

# --------------------------------------------------------------------------
# 2. Generate Experimental Divider variants
# --------------------------------------------------------------------------
Write-Host "`n🔄 Step 2: Generating Experimental Divider variants..." -ForegroundColor Cyan

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
# 3. Stage changes
# --------------------------------------------------------------------------
Write-Host "`n🔄 Step 3: Staging root and variant changes..." -ForegroundColor Cyan

$filesToStage = @(
    'OhMyPosh-Atomic-Custom.json',
    '1_shell-Enhanced.omp.json',
    'slimfat-Enhanced.omp.json',
    'atomicBit-Enhanced.omp.json',
    'clean-detailed-Enhanced.omp.json',
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
# 4. Force run theme generation
# --------------------------------------------------------------------------
Write-Host "`n🔄 Step 4: Generating colored themes (this may take a moment)..." -ForegroundColor Cyan
Write-Host '   (Output files will NOT be staged)' -ForegroundColor Gray

# We explicitly include the ExperimentalDividers theme here so its variants are generated too.
$allSourceThemes = @(
    'OhMyPosh-Atomic-Custom.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',
    '1_shell-Enhanced.omp.json',
    'slimfat-Enhanced.omp.json',
    'atomicBit-Enhanced.omp.json',
    'clean-detailed-Enhanced.omp.json'
)

# We skip the sync steps because we just performed them manually.
& "$ScriptRoot/Generate-AllThemes.ps1" -SourceThemes $allSourceThemes -SkipExperimentalDividersSync -SkipBaseThemeSync -Force

Write-Host "`n✅ Pipeline complete!" -ForegroundColor Green
