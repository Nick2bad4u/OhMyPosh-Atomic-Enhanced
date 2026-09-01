<#
.SYNOPSIS
Creates the standalone ExperimentalDividers GradientRampsAutoShade variant.

.DESCRIPTION
Uses Make-GradientVariant.ps1 with the GradientRampsAutoShade definition. It
retains the connected two-stop divider ramps and uses automatic
dark gradients for independent prompt-block entries that cannot inherit a
parent background.

.PARAMETER Source
Path to the canonical ExperimentalDividers theme.

.PARAMETER Destination
Path to the generated GradientRampsAutoShade theme.

.PARAMETER Definition
Path to the GradientRampsAutoShade variant definition.

.PARAMETER Backup
Back up an existing destination before overwriting it.

.EXAMPLE
pwsh ./scripts/Make-GradientRampsAutoShadeVariant.ps1
#>

[CmdletBinding()]
param(
    [string]$Source = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',
    [string]$Destination = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRampsAutoShade.json',
    [string]$Definition = 'scripts/variants/ExperimentalDividers.GradientRampsAutoShade.variant.json',
    [switch]$Backup
)

$ErrorActionPreference = 'Stop'

$generator = Join-Path -Path $PSScriptRoot -ChildPath 'Make-GradientVariant.ps1'
& $generator `
    -Source $Source `
    -Destination $Destination `
    -Definition $Definition `
    -Backup:$Backup
