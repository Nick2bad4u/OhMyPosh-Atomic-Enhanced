<#
.SYNOPSIS
    Generates Experimental Dividers themes for all palettes into a dedicated folder.

.DESCRIPTION
    Uses New-ExperimentalDividersThemeWithPalette.ps1 to create one themed file per palette
    found in color-palette-alternatives.json. Output files are placed in an
    "experimentalDividers" directory (created if missing) and named:
        OhMyPosh-Atomic-Custom-ExperimentalDividers.<Palette>.json

.PARAMETER SourceTheme
    Source Experimental Dividers theme file. Default: OhMyPosh-Atomic-Custom-ExperimentalDividers.json

.PARAMETER PalettesFile
    Palette definitions JSON. Default: color-palette-alternatives.json

.PARAMETER OutputDirectory
    Destination directory. Default: .\experimentalDividers

.PARAMETER UpdateAccentColor
    Pass-through to converter. When set, updates accent_color to palette accent.

.PARAMETER Force
    Overwrite existing files.
#>

[CmdletBinding()]
param(
    [string]$SourceTheme = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',
    [string]$PalettesFile = 'color-palette-alternatives.json',
    [string]$OutputDirectory = 'experimentalDividers',
    [switch]$UpdateAccentColor,
    [switch]$RecomputeDividers,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-PascalCase {
    param([string]$Text)
    $words = $Text -split '[\s_-]+'
    ($words | Where-Object { $_ } | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower() }) -join ''
}

if (-not (Test-Path $SourceTheme)) { throw "Source theme not found: $SourceTheme" }
if (-not (Test-Path $PalettesFile)) { throw "Palettes file not found: $PalettesFile" }

$palettes = (Get-Content $PalettesFile -Raw | ConvertFrom-Json).palettes
$paletteNames = $palettes.PSObject.Properties.Name

if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$baseName = [IO.Path]::GetFileNameWithoutExtension($SourceTheme)

foreach ($name in $paletteNames) {
    $pascal = ConvertTo-PascalCase $name
    $outFile = Join-Path $OutputDirectory "$baseName.$pascal.json"

    if ((Test-Path $outFile) -and -not $Force) {
        Write-Output "⚠️  Skipping (exists): $outFile" -ForegroundColor Yellow
        continue
    }

    Write-Output "🎨 Generating $outFile" -ForegroundColor Cyan

    $params = @{
        PaletteName = $name
        OutputPath = $outFile
        UpdateAccentColor = $UpdateAccentColor
        SourceTheme = $SourceTheme
        PalettesFile = $PalettesFile
        RecomputeDividers = $RecomputeDividers
    }

    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'New-ExperimentalDividersThemeWithPalette.ps1'
    & $scriptPath @params
}

Write-Output '✅ Generation complete' -ForegroundColor Green
