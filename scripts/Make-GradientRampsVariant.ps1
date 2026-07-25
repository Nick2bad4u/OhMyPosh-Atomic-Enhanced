<#
.SYNOPSIS
Creates the standalone ExperimentalDividers GradientRamps variant.

.DESCRIPTION
Uses Make-GradientVariant.ps1 with the GradientRamps definition. It preserves
the connected two-stop gradient behavior while retaining one endpoint from
each divider chain as a six-cell, position-matched full-block ramp. The
`background` foreground keyword gives each block the gradient color at that
text position, so the ramp keeps stable terminal width without introducing
a contrasting foreground divider glyph.

.PARAMETER Source
Path to the canonical ExperimentalDividers theme.

.PARAMETER Destination
Path to the generated GradientRamps theme.

.PARAMETER Definition
Path to the GradientRamps variant definition.

.PARAMETER Backup
Back up an existing destination before overwriting it.

.EXAMPLE
pwsh ./scripts/Make-GradientRampsVariant.ps1
#>

[CmdletBinding()]
param(
    [string]$Source = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',
    [string]$Destination = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRamps.json',
    [string]$Definition = 'scripts/variants/ExperimentalDividers.GradientRamps.variant.json',
    [switch]$Backup
)

$ErrorActionPreference = 'Stop'

$generator = Join-Path -Path $PSScriptRoot -ChildPath 'Make-GradientVariant.ps1'
& $generator `
    -Source $Source `
    -Destination $Destination `
    -Definition $Definition `
    -Backup:$Backup
