<#
.SYNOPSIS
Orchestrates the full generation pipeline for independent root themes:
1. Generates Atomic and ExperimentalDividers root helper variants.
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

Write-Information -MessageData "`n🚀 Starting Dev-Generate-All pipeline..." -InformationAction Continue

# --------------------------------------------------------------------------
# 1. Generate ExperimentalDividers root helpers
# --------------------------------------------------------------------------
Write-Information -MessageData "`n🔄 Step 1: Generating Experimental Divider helper variants..." -InformationAction Continue

# Fish
Write-Information -MessageData '   Generating Fish variant...' -InformationAction Continue
& "$ScriptRoot/Make-FishVariant.ps1" -Source 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'

# NoShellIntegration
Write-Information -MessageData '   Generating NoShellIntegration variant...' -InformationAction Continue
& "$ScriptRoot/Make-NoShellIntegration.ps1" -Source 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'

# NoNetwork
Write-Information -MessageData '   Generating NoNetwork variant...' -InformationAction Continue
& "$ScriptRoot/Make-NoNetwork.ps1" -SourceTheme 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'

# Extended
Write-Information -MessageData '   Generating Extended variant...' -InformationAction Continue
& "$ScriptRoot/Make-ExtendedVariant.ps1" -Source 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'

# ExperimentalDividers ColorCycle
Write-Information -MessageData '   Generating ExperimentalDividers ColorCycle variant...' -InformationAction Continue
& "$ScriptRoot/Make-ColorCycleVariant.ps1" -Source 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'

# ExperimentalDividers Gradient
Write-Information -MessageData '   Generating ExperimentalDividers Gradient variant...' -InformationAction Continue
& "$ScriptRoot/Make-GradientVariant.ps1" -Source 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'

# ExperimentalDividers GradientRamps
Write-Information -MessageData '   Generating ExperimentalDividers GradientRamps variant...' -InformationAction Continue
& "$ScriptRoot/Make-GradientRampsVariant.ps1" -Source 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'

# ExperimentalDividers GradientRampsAutoShade
Write-Information -MessageData '   Generating ExperimentalDividers GradientRampsAutoShade variant...' -InformationAction Continue
& "$ScriptRoot/Make-GradientRampsAutoShadeVariant.ps1" -Source 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'

# Atomic ColorCycle
Write-Information -MessageData '   Generating Atomic ColorCycle variant...' -InformationAction Continue
& "$ScriptRoot/Make-ColorCycleVariant.ps1" -Source 'OhMyPosh-Atomic-Custom.json'

# --------------------------------------------------------------------------
# 2. Stage changes
# --------------------------------------------------------------------------
Write-Information -MessageData "`n🔄 Step 2: Staging root helper changes..." -InformationAction Continue

$filesToStage = @(
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.Fish.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.NoShellIntegration.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.NoNetwork.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.Extended.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.ColorCycle.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.Gradient.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRamps.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRampsAutoShade.json',
    'OhMyPosh-Atomic-Custom-ColorCycle.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'
)

foreach ($file in $filesToStage) {
    if (Test-Path -LiteralPath $file) {
        Write-Information -MessageData "   Staging: $file" -InformationAction Continue
        & git add -- $file
        if ($LASTEXITCODE -ne 0) {
            throw "git add failed for '$file' with exit code $LASTEXITCODE."
        }
    }
    else {
        Write-Warning "File not found (skipping stage): $file"
    }
}

# --------------------------------------------------------------------------
# 3. Force run theme generation
# --------------------------------------------------------------------------
Write-Information -MessageData "`n🔄 Step 3: Generating palette extensions (this may take a moment)..." -InformationAction Continue
Write-Information -MessageData '   (Output files will NOT be staged)' -InformationAction Continue

& "$ScriptRoot/Generate-AllThemes.ps1" -Force
& "$ScriptRoot/Generate-ExperimentalDividers.ps1" -Force -SkipRootVariants

Write-Information -MessageData "`n✅ Pipeline complete!" -InformationAction Continue
