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

# Present colored generator status through the redirectable information stream.
function Write-ThemeGenerationMessage {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [object[]]$InputObject,

        [ConsoleColor]$ForegroundColor,
        [switch]$NoNewline
    )

    $text = ($InputObject | ForEach-Object { "$_" }) -join ''

    if (-not $PSBoundParameters.ContainsKey('ForegroundColor') -and -not $NoNewline) {
        Microsoft.PowerShell.Utility\Write-Output -InputObject $text
        return
    }

    $message = [System.Management.Automation.HostInformationMessage]::new()
    $message.Message = $text
    $message.NoNewLine = [bool]$NoNewline
    if ($PSBoundParameters.ContainsKey('ForegroundColor')) {
        $message.ForegroundColor = $ForegroundColor
    }

    Write-Information -MessageData $message -InformationAction Continue
}

function Resolve-RepoPath {
    [OutputType([string])]
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
    Write-ThemeGenerationMessage -InputObject "🧹 Removed generated Original duplicate: $staleOriginal" -ForegroundColor DarkGray
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
        Write-ThemeGenerationMessage -InputObject "⚠️  Skipping (exists): $outFile" -ForegroundColor Yellow
        continue
    }

    Write-ThemeGenerationMessage -InputObject "🎨 Generating $outFile" -ForegroundColor Cyan

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
        Write-ThemeGenerationMessage -InputObject '\n🧩 Regenerating root variants (Fish / NoShellIntegration / Extended / ColorCycle / Gradient / GradientRamps / GradientRampsAutoShade)...' -ForegroundColor Cyan

        $fishScript = Join-Path -Path $PSScriptRoot -ChildPath 'Make-FishVariant.ps1'
        if (Test-Path -LiteralPath $fishScript) {
            & $fishScript -Source $SourceTheme
        }
        else {
            Write-ThemeGenerationMessage -InputObject "⚠️  Missing script (skipping): $fishScript" -ForegroundColor Yellow
        }

        $noShellScript = Join-Path -Path $PSScriptRoot -ChildPath 'Make-NoShellIntegration.ps1'
        if (Test-Path -LiteralPath $noShellScript) {
            & $noShellScript -Source $SourceTheme
        }
        else {
            Write-ThemeGenerationMessage -InputObject "⚠️  Missing script (skipping): $noShellScript" -ForegroundColor Yellow
        }

        $extendedScript = Join-Path -Path $PSScriptRoot -ChildPath 'Make-ExtendedVariant.ps1'
        if (Test-Path -LiteralPath $extendedScript) {
            & $extendedScript -Source $SourceTheme
        }
        else {
            Write-ThemeGenerationMessage -InputObject "⚠️  Missing script (skipping): $extendedScript" -ForegroundColor Yellow
        }

        $colorCycleScript = Join-Path -Path $PSScriptRoot -ChildPath 'Make-ColorCycleVariant.ps1'
        if (Test-Path -LiteralPath $colorCycleScript) {
            & $colorCycleScript -Source $SourceTheme
        }
        else {
            Write-ThemeGenerationMessage -InputObject "⚠️  Missing script (skipping): $colorCycleScript" -ForegroundColor Yellow
        }

        $gradientScript = Join-Path -Path $PSScriptRoot -ChildPath 'Make-GradientVariant.ps1'
        if (Test-Path -LiteralPath $gradientScript) {
            & $gradientScript -Source $SourceTheme
        }
        else {
            Write-ThemeGenerationMessage -InputObject "⚠️  Missing script (skipping): $gradientScript" -ForegroundColor Yellow
        }

        $gradientRampsScript = Join-Path -Path $PSScriptRoot -ChildPath 'Make-GradientRampsVariant.ps1'
        if (Test-Path -LiteralPath $gradientRampsScript) {
            & $gradientRampsScript -Source $SourceTheme
        }
        else {
            Write-ThemeGenerationMessage -InputObject "⚠️  Missing script (skipping): $gradientRampsScript" -ForegroundColor Yellow
        }

        $gradientRampsAutoShadeScript = Join-Path -Path $PSScriptRoot -ChildPath 'Make-GradientRampsAutoShadeVariant.ps1'
        if (Test-Path -LiteralPath $gradientRampsAutoShadeScript) {
            & $gradientRampsAutoShadeScript -Source $SourceTheme
        }
        else {
            Write-ThemeGenerationMessage -InputObject "⚠️  Missing script (skipping): $gradientRampsAutoShadeScript" -ForegroundColor Yellow
        }
    }
    else {
        Write-ThemeGenerationMessage -InputObject "\nℹ️  SkipRootVariants not set, but SourceTheme is '$leaf' (not the base ExperimentalDividers theme). Not generating root helper variants." -ForegroundColor DarkGray
    }
}

Write-ThemeGenerationMessage -InputObject '✅ Generation complete' -ForegroundColor Green
