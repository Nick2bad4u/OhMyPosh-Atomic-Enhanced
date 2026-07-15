<#
.SYNOPSIS
    Generates Experimental Dividers themes for all palettes into a dedicated folder.

.DESCRIPTION
    Uses New-ExperimentalDividersThemeWithPalette.ps1 to create one palette-only
    extension per non-original palette. The non-extended original remains at the
    repository root. Output files are placed in an
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

.PARAMETER BaseUrl
    URL prefix used by generated extends values. Set this to an empty string to
    generate relative local extends paths instead.
#>

[CmdletBinding()]
param(
    [string]$SourceTheme = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',
    [string]$PalettesFile = 'color-palette-alternatives.json',
    [string]$OutputDirectory = 'experimentalDividers',
    [AllowEmptyString()]
    [string]$BaseUrl = 'https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/refs/heads/main',
    [switch]$UpdateAccentColor,
    [switch]$RecomputeDividers,
    [switch]$Force,

    # Also regenerate the root-level helper variants:
    # - OhMyPosh-Atomic-Custom-ExperimentalDividers.Fish.json
    # - OhMyPosh-Atomic-Custom-ExperimentalDividers.NoShellIntegration.json
    # - OhMyPosh-Atomic-Custom-ExperimentalDividers.Extended.json
    # - OhMyPosh-Atomic-Custom-ExperimentalDividers.ColorCycle.json
    [switch]$SkipRootVariants
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# This script lives in .\scripts\, but operates on files in the repository root.
$RepoRoot = Split-Path -Path $PSScriptRoot -Parent

# Write-Output does not support -ForegroundColor / -NoNewline, but this repo historically used it that way.
# Provide a local wrapper so scripts work when run standalone.
function Write-Output {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [object[]]$InputObject,

        [ConsoleColor]$ForegroundColor,
        [switch]$NoNewline
    )

    $text = ($InputObject | ForEach-Object { "$_" }) -join ''

    if ($PSBoundParameters.ContainsKey('ForegroundColor') -or $NoNewline) {
        $hasColor = $PSBoundParameters.ContainsKey('ForegroundColor')
        if ($NoNewline) {
            if ($hasColor) { Write-Host -NoNewline -ForegroundColor $ForegroundColor $text }
            else { Write-Host -NoNewline $text }
        }
        else {
            if ($hasColor) { Write-Host -ForegroundColor $ForegroundColor $text }
            else { Write-Host $text }
        }
        return
    }

    Microsoft.PowerShell.Utility\Write-Output $text
}

function Resolve-RepoPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path -Path $RepoRoot -ChildPath $Path)
}

function ConvertTo-PascalCase {
    param([string]$Text)
    $words = $Text -split '[\s_-]+'
    ($words | Where-Object { $_ } | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower() }) -join ''
}

# Resolve repo-relative inputs
$SourceTheme = Resolve-RepoPath $SourceTheme
$PalettesFile = Resolve-RepoPath $PalettesFile
$OutputDirectory = Resolve-RepoPath $OutputDirectory

if (-not (Test-Path -LiteralPath $SourceTheme)) { throw "Source theme not found: $SourceTheme" }
if (-not (Test-Path -LiteralPath $PalettesFile)) { throw "Palettes file not found: $PalettesFile" }

$palettes = (Get-Content -LiteralPath $PalettesFile -Raw | ConvertFrom-Json).palettes
$paletteNames = @($palettes.PSObject.Properties.Name | Where-Object { $_ -ine 'original' })

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$baseName = [IO.Path]::GetFileNameWithoutExtension($SourceTheme)
$staleOriginal = Join-Path -Path $OutputDirectory -ChildPath "$baseName.Original.json"
if (Test-Path -LiteralPath $staleOriginal) {
    Remove-Item -LiteralPath $staleOriginal -Force
    Write-Output "🧹 Removed generated Original duplicate: $staleOriginal" -ForegroundColor DarkGray
}

$extendsPath = if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
    [System.IO.Path]::GetRelativePath($OutputDirectory, $SourceTheme) -replace '\\', '/'
}
else {
    "$($BaseUrl.TrimEnd('/'))/$([System.IO.Path]::GetFileName($SourceTheme))"
}

foreach ($name in $paletteNames) {
    $pascal = ConvertTo-PascalCase $name
    $outFile = Join-Path $OutputDirectory "$baseName.$pascal.json"

    if ((Test-Path -LiteralPath $outFile) -and -not $Force) {
        Write-Output "⚠️  Skipping (exists): $outFile" -ForegroundColor Yellow
        continue
    }

    Write-Output "🎨 Generating $outFile" -ForegroundColor Cyan

    $params = @{
        PaletteName       = $name
        OutputPath        = $outFile
        UpdateAccentColor = $UpdateAccentColor
        SourceTheme       = $SourceTheme
        PalettesFile      = $PalettesFile
        RecomputeDividers = $RecomputeDividers
        ExtendsPath       = $extendsPath
    }

    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'New-ExperimentalDividersThemeWithPalette.ps1'
    & $scriptPath @params
}

if (-not $SkipRootVariants) {
    $leaf = Split-Path -Path $SourceTheme -Leaf
    if ($leaf -eq 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json') {
        Write-Output '\n🧩 Regenerating root variants (Fish / NoShellIntegration / Extended / ColorCycle)...' -ForegroundColor Cyan

        $fishScript = Join-Path -Path $PSScriptRoot -ChildPath 'Make-FishVariant.ps1'
        if (Test-Path -LiteralPath $fishScript) {
            & $fishScript -Source $SourceTheme
        }
        else {
            Write-Output "⚠️  Missing script (skipping): $fishScript" -ForegroundColor Yellow
        }

        $noShellScript = Join-Path -Path $PSScriptRoot -ChildPath 'Make-NoShellIntegration.ps1'
        if (Test-Path -LiteralPath $noShellScript) {
            & $noShellScript -Source $SourceTheme
        }
        else {
            Write-Output "⚠️  Missing script (skipping): $noShellScript" -ForegroundColor Yellow
        }

        $extendedScript = Join-Path -Path $PSScriptRoot -ChildPath 'Make-ExtendedVariant.ps1'
        if (Test-Path -LiteralPath $extendedScript) {
            & $extendedScript -Source $SourceTheme
        }
        else {
            Write-Output "⚠️  Missing script (skipping): $extendedScript" -ForegroundColor Yellow
        }

        $colorCycleScript = Join-Path -Path $PSScriptRoot -ChildPath 'Make-ColorCycleVariant.ps1'
        if (Test-Path -LiteralPath $colorCycleScript) {
            & $colorCycleScript -Source $SourceTheme
        }
        else {
            Write-Output "⚠️  Missing script (skipping): $colorCycleScript" -ForegroundColor Yellow
        }
    }
    else {
        Write-Output "\nℹ️  SkipRootVariants not set, but SourceTheme is '$leaf' (not the base ExperimentalDividers theme). Not generating root helper variants." -ForegroundColor DarkGray
    }
}

Write-Output '✅ Generation complete' -ForegroundColor Green
