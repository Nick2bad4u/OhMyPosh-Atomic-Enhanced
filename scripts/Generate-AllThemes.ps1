<#
.SYNOPSIS
    Batch generates Oh My Posh theme files for all available palettes.

.DESCRIPTION
    Reads all palettes from color-palette-alternatives.json and generates
    a themed variant for each one, creating a complete collection of themes.

.PARAMETER SourceTheme
    Path to the source Oh My Posh theme JSON file.
    Default: "OhMyPosh-Atomic-Custom.json"

.PARAMETER PalettesFile
    Path to the JSON file containing palette definitions.
    Default: "color-palette-alternatives.json"

.PARAMETER OutputDirectory
    Directory where theme files will be created.

    Default behavior (when omitted):
    - Writes palette variants into the repo's theme-family folders:
        - OhMyPosh-Atomic-Custom.json        -> .\atomic\
        - 1_shell-Enhanced.omp.json          -> .\1_shell\
        - slimfat-Enhanced.omp.json          -> .\slimfat\
        - atomicBit-Enhanced.omp.json        -> .\atomicBit\
        - clean-detailed-Enhanced.omp.json   -> .\cleanDetailed\

    Pass -OutputDirectory to override and put all generated variants in one location.

.PARAMETER UpdateAccentColor
    If specified, also updates the root "accent_color" property to match palette accent.

.PARAMETER ExcludePalettes
    Array of palette names to skip (e.g., if you don't want to generate certain themes).

.PARAMETER Force
    Overwrite existing theme files without prompting.

.EXAMPLE
    .\scripts\Generate-AllThemes.ps1
    Generates theme files for all palettes

.EXAMPLE
    .\scripts\Generate-AllThemes.ps1 -UpdateAccentColor -Force
    Generates all themes with updated accent colors, overwriting existing files

.EXAMPLE
    .\scripts\Generate-AllThemes.ps1 -ExcludePalettes @("original", "test_palette")
    Generates all themes except "original" and "test_palette"

.NOTES
    Author: GitHub Copilot
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$SourceThemes = @(
        'OhMyPosh-Atomic-Custom.json',
        '1_shell-Enhanced.omp.json',
        'slimfat-Enhanced.omp.json',
        'atomicBit-Enhanced.omp.json',
        'clean-detailed-Enhanced.omp.json'
    ),

    [Parameter()]
    [string]$PalettesFile = 'color-palette-alternatives.json',

    [Parameter()]
    [string]$OutputDirectory,

    [Parameter()]
    [switch]$UpdateAccentColor,

    [Parameter()]
    [string[]]$ExcludePalettes = @(),

    [Parameter()]
    [switch]$Force

    ,

    # --- Base theme sync pipeline ---
    # By default, we keep OhMyPosh-Atomic-Custom.json and the other base templates
    # (1_shell/slimfat/atomicBit/clean-detailed) in sync with the ExperimentalDividers theme,
    # so new tooltips and shared config flow into every generated variant.

    [Parameter()]
    [switch]$SkipExperimentalDividersSync,

    [Parameter()]
    [switch]$SkipBaseThemeSync,

    [Parameter()]
    [string]$ExperimentalDividersTheme = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',

    [Parameter()]
    [string]$AtomicCustomTheme = 'OhMyPosh-Atomic-Custom.json'

    ,

    # When generating ExperimentalDividers palette variants, optionally force recomputing divider blends.
    [Parameter()]
    [switch]$RecomputeDividers
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# This script lives in .\scripts\, but operates on files in the repository root.
$RepoRoot = Split-Path -Path $PSScriptRoot -Parent

function Resolve-RepoPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path -Path $RepoRoot -ChildPath $Path)
}

# --- Optional base theme sync pipeline (runs before palette generation) ---
$ExperimentalDividersThemePath = Resolve-RepoPath $ExperimentalDividersTheme
$AtomicCustomThemePath = Resolve-RepoPath $AtomicCustomTheme

if (-not $SkipExperimentalDividersSync) {
    $syncAtomicScript = Join-Path -Path $PSScriptRoot -ChildPath 'Generate-AtomicCustomFromExperimentalDividers.ps1'
    if (Test-Path -LiteralPath $syncAtomicScript) {
        if (Test-Path -LiteralPath $ExperimentalDividersThemePath) {
            & $syncAtomicScript -ExperimentalDividersPath $ExperimentalDividersThemePath -AtomicCustomTemplatePath $AtomicCustomThemePath -OutputPath $AtomicCustomThemePath
        }
        else {
            Write-Output "⚠️  ExperimentalDividers theme not found (skipping sync): $ExperimentalDividersThemePath" -ForegroundColor Yellow
        }
    }
    else {
        Write-Output "⚠️  Missing sync script (skipping): $syncAtomicScript" -ForegroundColor Yellow
    }
}

if (-not $SkipBaseThemeSync) {
    $syncTemplatesScript = Join-Path -Path $PSScriptRoot -ChildPath 'Sync-ThemeTemplatesFromAtomicCustom.ps1'
    if (Test-Path -LiteralPath $syncTemplatesScript) {
        if (Test-Path -LiteralPath $AtomicCustomThemePath) {
            & $syncTemplatesScript -AtomicCustomPath $AtomicCustomThemePath
        }
        else {
            Write-Output "⚠️  Atomic Custom theme not found (skipping template sync): $AtomicCustomThemePath" -ForegroundColor Yellow
        }
    }
    else {
        Write-Output "⚠️  Missing template sync script (skipping): $syncTemplatesScript" -ForegroundColor Yellow
    }
}

function Get-DefaultThemeOutputDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceTheme
    )

    $leaf = Split-Path -Path $SourceTheme -Leaf
    switch -Wildcard ($leaf) {
        'OhMyPosh-Atomic-Custom.json' { return (Join-Path $RepoRoot 'atomic') }
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.json' { return (Join-Path $RepoRoot 'experimentalDividers') }
        '1_shell-Enhanced.omp.json' { return (Join-Path $RepoRoot '1_shell') }
        'slimfat-Enhanced.omp.json' { return (Join-Path $RepoRoot 'slimfat') }
        'atomicBit-Enhanced.omp.json' { return (Join-Path $RepoRoot 'atomicBit') }
        'clean-detailed-Enhanced.omp.json' { return (Join-Path $RepoRoot 'cleanDetailed') }
        default { return $RepoRoot }
    }
}

# Helper function to convert snake_case to PascalCase
function ConvertTo-PascalCase {
    param([string]$Text)

    $words = $Text -split '[\s_-]+'
    $pascalCase = ($words | ForEach-Object {
            $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower()
        }) -join ''

    return $pascalCase
}

Write-Output "`n" + ('=' * 70) -ForegroundColor Cyan
Write-Output '  🎨 Oh My Posh BATCH Theme Generator 🎨' -ForegroundColor Cyan
Write-Output ('=' * 70) -ForegroundColor Cyan

# Resolve repo-relative paths
$SourceThemes = @($SourceThemes | ForEach-Object { Resolve-RepoPath $_ })
$PalettesFile = Resolve-RepoPath $PalettesFile

# Verify files exist
$missingThemes = @($SourceThemes | Where-Object { -not (Test-Path -LiteralPath $_) })
if ($missingThemes.Count -gt 0) {
    Write-Error "Source theme file(s) not found: $($missingThemes -join ', ')"
    exit 1
}

if (-not (Test-Path -LiteralPath $PalettesFile)) {
    Write-Error "Palettes file not found: $PalettesFile"
    exit 1
}

# Read palettes file
Write-Output "`n📚 Loading palettes from: " -NoNewline
Write-Output $PalettesFile -ForegroundColor Yellow

try {
    $palettesContent = Get-Content $PalettesFile -Raw
    $palettesData = $palettesContent | ConvertFrom-Json
    $palettes = $palettesData.palettes
}
catch {
    Write-Error "Failed to parse palettes JSON: $_"
    exit 1
}

# Get all palette names
$ExcludePalettes = @($ExcludePalettes) # Ensure it's an array
$allPaletteNames = @(
    $palettes.PSObject.Properties.Name | Where-Object {
        $_ -notin $ExcludePalettes
    }
)

Write-Output '✓ Found ' -NoNewline -ForegroundColor Green
Write-Output $allPaletteNames.Count -NoNewline -ForegroundColor White
Write-Output ' palettes' -ForegroundColor Green

if ($ExcludePalettes.Count -gt 0 -and $ExcludePalettes[0]) {
    Write-Output '  Excluding: ' -NoNewline -ForegroundColor DarkGray
    Write-Output ($ExcludePalettes -join ', ') -ForegroundColor Red
}

# Output directory behavior
# - If OutputDirectory is provided, all variants go there
# - If omitted, each SourceTheme goes to its default family folder
$usePerThemeOutput = -not $PSBoundParameters.ContainsKey('OutputDirectory') -or [string]::IsNullOrWhiteSpace($OutputDirectory)
if ($usePerThemeOutput) {
    Write-Output "`n📁 Output directory: " -NoNewline
    Write-Output '(per-theme default folders)' -ForegroundColor Yellow
}
else {
    # If a relative path is provided, interpret it relative to the repo root.
    $OutputDirectory = Resolve-RepoPath $OutputDirectory

    # Create output directory if it doesn't exist
    if (-not (Test-Path -LiteralPath $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    }
    Write-Output "`n📁 Output directory: " -NoNewline
    Write-Output $OutputDirectory -ForegroundColor Yellow
}

# Statistics
$totalSuccessCount = 0
$totalSkipCount = 0
$totalErrorCount = 0
$allResults = @()

Write-Output "`n" + ('-' * 70) -ForegroundColor DarkGray
Write-Output 'Starting generation...' -ForegroundColor Cyan
Write-Output ('-' * 70) -ForegroundColor DarkGray

# Loop through each source theme
foreach ($SourceTheme in $SourceThemes) {
    Write-Output "`n🎨 Processing: " -NoNewline -ForegroundColor Cyan
    Write-Output $SourceTheme -ForegroundColor Yellow

    $themeOutputDirectory = if ($usePerThemeOutput) {
        Get-DefaultThemeOutputDirectory -SourceTheme $SourceTheme
    }
    else {
        $OutputDirectory
    }

    if (-not (Test-Path -LiteralPath $themeOutputDirectory)) {
        New-Item -ItemType Directory -Path $themeOutputDirectory -Force | Out-Null
    }

    if ($usePerThemeOutput) {
        Write-Output '  📁 Output: ' -NoNewline -ForegroundColor DarkGray
        Write-Output $themeOutputDirectory -ForegroundColor Yellow
    }

    $successCount = 0
    $skipCount = 0
    $errorCount = 0

    foreach ($paletteName in $allPaletteNames) {
        $paletteInfo = $palettes.$paletteName
        $friendlyName = $paletteInfo.Name
        $description = $paletteInfo.description

        Write-Output "`n[$($successCount + $skipCount + $errorCount + 1)/$($allPaletteNames.Count)] " -NoNewline -ForegroundColor DarkCyan
        Write-Output $friendlyName -ForegroundColor Magenta
        Write-Output "    $description" -ForegroundColor Gray

        # Generate output filename
        $outputName = ConvertTo-PascalCase $paletteName
        $sourceBaseName = [System.IO.Path]::GetFileNameWithoutExtension($SourceTheme)
        $outputFile = Join-Path $themeOutputDirectory "$sourceBaseName.$outputName.json"

        # Check if file exists
        if ((Test-Path $outputFile) -and -not $Force) {
            Write-Output '    ⚠️  File already exists, skipping (use -Force to overwrite)' -ForegroundColor Yellow
            $skipCount++
            $allResults += [pscustomobject]@{
                SourceTheme = $SourceTheme
                Palette     = $friendlyName
                Status      = 'Skipped'
                File        = $outputFile
            }
            continue
        }

        # Call the theme conversion script.
        # ExperimentalDividers needs special handling for divider blend colors and extended palette keys.
        try {
            $params = @{
                SourceTheme  = $SourceTheme
                PaletteName  = $paletteName
                OutputPath   = $outputFile
                PalettesFile = $PalettesFile
            }

            if ($UpdateAccentColor) {
                $params.UpdateAccentColor = $true
            }

            $sourceLeaf = [System.IO.Path]::GetFileName($SourceTheme)
            $isExperimentalDividers = $sourceLeaf -ieq 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'

            $scriptPath = if ($isExperimentalDividers) {
                Join-Path -Path $PSScriptRoot -ChildPath 'New-ExperimentalDividersThemeWithPalette.ps1'
            }
            else {
                Join-Path -Path $PSScriptRoot -ChildPath 'New-ThemeWithPalette.ps1'
            }

            if ($isExperimentalDividers -and $RecomputeDividers) {
                $params.RecomputeDividers = $true
            }

            $null = & $scriptPath @params 2>&1

            Write-Output '    ✅ Success: ' -NoNewline -ForegroundColor Green
            Write-Output ([System.IO.Path]::GetFileName($outputFile)) -ForegroundColor White

            $successCount++
            $allResults += [pscustomobject]@{
                SourceTheme = $SourceTheme
                Palette     = $friendlyName
                Status      = 'Created'
                File        = $outputFile
            }
        }
        catch {
            Write-Output "    ❌ Error: $_" -ForegroundColor Red
            $errorCount++
            $allResults += [pscustomobject]@{
                SourceTheme = $SourceTheme
                Palette     = $friendlyName
                Status      = 'Error'
                File        = $outputFile
            }
        }
    }

    # Add to totals
    $totalSuccessCount += $successCount
    $totalSkipCount += $skipCount
    $totalErrorCount += $errorCount

    Write-Output "`n  Summary for $SourceTheme" -ForegroundColor Yellow
    Write-Output "  ✅ Created: $successCount | ⚠️  Skipped: $skipCount | ❌ Errors: $errorCount" -ForegroundColor Gray
}

# Summary
Write-Output "`n" + ('=' * 70) -ForegroundColor Cyan
Write-Output '  📊 OVERALL GENERATION SUMMARY' -ForegroundColor Cyan
Write-Output ('=' * 70) -ForegroundColor Cyan

Write-Output "`n✅ Successfully created: " -NoNewline -ForegroundColor Green
Write-Output $totalSuccessCount -ForegroundColor White

if ($totalSkipCount -gt 0) {
    Write-Output '⚠️  Skipped (existing): ' -NoNewline -ForegroundColor Yellow
    Write-Output $totalSkipCount -ForegroundColor White
}

if ($totalErrorCount -gt 0) {
    Write-Output '❌ Errors: ' -NoNewline -ForegroundColor Red
    Write-Output $totalErrorCount -ForegroundColor White
}

Write-Output "`n📁 Total files: " -NoNewline -ForegroundColor Cyan
Write-Output ($totalSuccessCount + $totalSkipCount) -ForegroundColor White

# List created files
if ($totalSuccessCount -gt 0) {
    Write-Output "`n📄 Created themes:" -ForegroundColor Cyan
    $allResults | Where-Object { $_.Status -eq 'Created' } | ForEach-Object {
        Write-Output '   • ' -NoNewline -ForegroundColor DarkGray
        Write-Output $_.Palette -NoNewline -ForegroundColor Magenta
        Write-Output ' → ' -NoNewline -ForegroundColor DarkGray
        Write-Output ([System.IO.Path]::GetFileName($_.File)) -ForegroundColor White
    }
}

# Show how to use
Write-Output "`n🚀 To use a theme, run:" -ForegroundColor Cyan
Write-Output "   oh-my-posh init pwsh --config 'PATH_TO_THEME.json' | Invoke-Expression" -ForegroundColor White

Write-Output "`n💡 Tip: Add one to your PowerShell profile for permanent use!" -ForegroundColor Yellow

Write-Output "`n" + ('=' * 70) -ForegroundColor Cyan
Write-Output '✨ Done!' -ForegroundColor Green
Write-Output ('=' * 70) -ForegroundColor Cyan
Write-Output ''
