<#
.SYNOPSIS
    Batch generates Oh My Posh theme files for all available palettes.

.DESCRIPTION
    Reads color palettes from color-palette-alternatives.json and generates
    small Oh My Posh configs that extend each independent root theme. The
    original, non-extended themes remain at the repository root.

.PARAMETER SourceThemes
    Paths to the independent source Oh My Posh theme JSON files.
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
    If specified, adds an "accent_color" override that matches the palette accent.

.PARAMETER ExcludePalettes
    Additional palette names to skip. The original palette is always represented
    by the non-extended root theme and is never generated into a family folder.

.PARAMETER BaseUrl
    URL prefix used by generated extends values. Set this to an empty string to
    generate relative local extends paths instead.

.PARAMETER Force
    Overwrite existing theme files without prompting.

.EXAMPLE
    .\scripts\Generate-AllThemes.ps1
    Generates palette-only extension files for every non-original palette.

.EXAMPLE
    .\scripts\Generate-AllThemes.ps1 -UpdateAccentColor -Force
    Generates all themes with updated accent colors, overwriting existing files

.EXAMPLE
    .\scripts\Generate-AllThemes.ps1 -ExcludePalettes @("test_palette")
    Generates all non-original themes except "test_palette"

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
    [AllowEmptyString()]
    [string]$BaseUrl = 'https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/refs/heads/main',

    [Parameter()]
    [switch]$Force,

    # When generating ExperimentalDividers palette variants, optionally force recomputing divider blends.
    [Parameter()]
    [switch]$RecomputeDividers
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
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path -Path $RepoRoot -ChildPath $Path)
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

Write-ThemeGenerationMessage -InputObject ("`n" + ('=' * 70)) -ForegroundColor Cyan
Write-ThemeGenerationMessage -InputObject '  🎨 Oh My Posh BATCH Theme Generator 🎨' -ForegroundColor Cyan
Write-ThemeGenerationMessage -InputObject ('=' * 70) -ForegroundColor Cyan

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
Write-ThemeGenerationMessage -InputObject "`n📚 Loading palettes from: " -NoNewline
Write-ThemeGenerationMessage -InputObject $PalettesFile -ForegroundColor Yellow

try {
    $palettesContent = Get-Content $PalettesFile -Raw
    $palettesData = $palettesContent | ConvertFrom-Json
    $palettes = $palettesData.palettes
}
catch {
    Write-Error "Failed to parse palettes JSON: $_"
    exit 1
}

# Get all palette names. "original" is the root source file, not an extension.
$ExcludePalettes = @($ExcludePalettes) # Ensure it's an array
$allPaletteNames = @(
    $palettes.PSObject.Properties.Name | Where-Object {
        $_ -ine 'original' -and $_ -notin $ExcludePalettes
    }
)

Write-ThemeGenerationMessage -InputObject '✓ Found ' -NoNewline -ForegroundColor Green
Write-ThemeGenerationMessage -InputObject $allPaletteNames.Count -NoNewline -ForegroundColor White
Write-ThemeGenerationMessage -InputObject ' palettes' -ForegroundColor Green

if ($ExcludePalettes.Count -gt 0 -and $ExcludePalettes[0]) {
    Write-ThemeGenerationMessage -InputObject '  Excluding: ' -NoNewline -ForegroundColor DarkGray
    Write-ThemeGenerationMessage -InputObject ($ExcludePalettes -join ', ') -ForegroundColor Red
}

# Output directory behavior
# - If OutputDirectory is provided, all variants go there
# - If omitted, each SourceTheme goes to its default family folder
$usePerThemeOutput = -not $PSBoundParameters.ContainsKey('OutputDirectory') -or [string]::IsNullOrWhiteSpace($OutputDirectory)
if ($usePerThemeOutput) {
    Write-ThemeGenerationMessage -InputObject "`n📁 Output directory: " -NoNewline
    Write-ThemeGenerationMessage -InputObject '(per-theme default folders)' -ForegroundColor Yellow
}
else {
    # If a relative path is provided, interpret it relative to the repo root.
    $OutputDirectory = Resolve-RepoPath $OutputDirectory

    # Create output directory if it doesn't exist
    if (-not (Test-Path -LiteralPath $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    }
    Write-ThemeGenerationMessage -InputObject "`n📁 Output directory: " -NoNewline
    Write-ThemeGenerationMessage -InputObject $OutputDirectory -ForegroundColor Yellow
}

# Statistics
$totalSuccessCount = 0
$totalSkipCount = 0
$totalErrorCount = 0
$allResults = @()

Write-ThemeGenerationMessage -InputObject ("`n" + ('-' * 70)) -ForegroundColor DarkGray
Write-ThemeGenerationMessage -InputObject 'Starting generation...' -ForegroundColor Cyan
Write-ThemeGenerationMessage -InputObject ('-' * 70) -ForegroundColor DarkGray

# Loop through each source theme
foreach ($SourceTheme in $SourceThemes) {
    Write-ThemeGenerationMessage -InputObject "`n🎨 Processing: " -NoNewline -ForegroundColor Cyan
    Write-ThemeGenerationMessage -InputObject $SourceTheme -ForegroundColor Yellow

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
        Write-ThemeGenerationMessage -InputObject '  📁 Output: ' -NoNewline -ForegroundColor DarkGray
        Write-ThemeGenerationMessage -InputObject $themeOutputDirectory -ForegroundColor Yellow
    }

    $sourceBaseName = [System.IO.Path]::GetFileNameWithoutExtension($SourceTheme)
    $staleOriginal = Join-Path -Path $themeOutputDirectory -ChildPath "$sourceBaseName.Original.json"
    if (Test-Path -LiteralPath $staleOriginal) {
        Remove-Item -LiteralPath $staleOriginal -Force
        Write-ThemeGenerationMessage -InputObject "  🧹 Removed generated Original duplicate: $staleOriginal" -ForegroundColor DarkGray
    }

    $successCount = 0
    $skipCount = 0
    $errorCount = 0

    foreach ($paletteName in $allPaletteNames) {
        $paletteInfo = $palettes.$paletteName
        $friendlyName = $paletteInfo.Name
        $description = $paletteInfo.description

        Write-ThemeGenerationMessage -InputObject "`n[$($successCount + $skipCount + $errorCount + 1)/$($allPaletteNames.Count)] " -NoNewline -ForegroundColor DarkCyan
        Write-ThemeGenerationMessage -InputObject $friendlyName -ForegroundColor Magenta
        Write-ThemeGenerationMessage -InputObject "    $description" -ForegroundColor Gray

        # Generate output filename
        $outputName = ConvertTo-PascalCase $paletteName
        $outputFile = Join-Path $themeOutputDirectory "$sourceBaseName.$outputName.json"

        # Check if file exists
        if ((Test-Path $outputFile) -and -not $Force) {
            Write-ThemeGenerationMessage -InputObject '    ⚠️  File already exists, skipping (use -Force to overwrite)' -ForegroundColor Yellow
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
        $temporaryOutputFile = Join-Path -Path $themeOutputDirectory -ChildPath (
            '.{0}.{1}.tmp.json' -f $outputName, [guid]::NewGuid().ToString('N')
        )
        try {
            $params = @{
                SourceTheme  = $SourceTheme
                PaletteName  = $paletteName
                OutputPath   = $temporaryOutputFile
                PalettesFile = $PalettesFile
            }

            if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
                $params.ExtendsPath = [System.IO.Path]::GetRelativePath($themeOutputDirectory, $SourceTheme) -replace '\\', '/'
            }
            else {
                $params.ExtendsPath = "$($BaseUrl.TrimEnd('/'))/$([System.IO.Path]::GetFileName($SourceTheme))"
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

            if (-not (Test-Path -LiteralPath $temporaryOutputFile -PathType Leaf)) {
                throw "Generator did not create the expected output file: $temporaryOutputFile"
            }

            try {
                $null = Get-Content -LiteralPath $temporaryOutputFile -Raw | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                throw "Generator produced invalid JSON for '$friendlyName': $($_.Exception.Message)"
            }

            Move-Item -LiteralPath $temporaryOutputFile -Destination $outputFile -Force

            if (-not (Test-Path -LiteralPath $outputFile -PathType Leaf)) {
                throw "Generated output was not installed at the expected path: $outputFile"
            }

            Write-ThemeGenerationMessage -InputObject '    ✅ Success: ' -NoNewline -ForegroundColor Green
            Write-ThemeGenerationMessage -InputObject ([System.IO.Path]::GetFileName($outputFile)) -ForegroundColor White

            $successCount++
            $allResults += [pscustomobject]@{
                SourceTheme = $SourceTheme
                Palette     = $friendlyName
                Status      = 'Created'
                File        = $outputFile
            }
        }
        catch {
            Write-ThemeGenerationMessage -InputObject "    ❌ Error: $_" -ForegroundColor Red
            $errorCount++
            $allResults += [pscustomobject]@{
                SourceTheme = $SourceTheme
                Palette     = $friendlyName
                Status      = 'Error'
                File        = $outputFile
            }
        }
        finally {
            if (Test-Path -LiteralPath $temporaryOutputFile) {
                Remove-Item -LiteralPath $temporaryOutputFile -Force
            }
        }
    }

    # Add to totals
    $totalSuccessCount += $successCount
    $totalSkipCount += $skipCount
    $totalErrorCount += $errorCount

    Write-ThemeGenerationMessage -InputObject "`n  Summary for $SourceTheme" -ForegroundColor Yellow
    Write-ThemeGenerationMessage -InputObject "  ✅ Created: $successCount | ⚠️  Skipped: $skipCount | ❌ Errors: $errorCount" -ForegroundColor Gray
}

# Summary
Write-ThemeGenerationMessage -InputObject ("`n" + ('=' * 70)) -ForegroundColor Cyan
Write-ThemeGenerationMessage -InputObject '  📊 OVERALL GENERATION SUMMARY' -ForegroundColor Cyan
Write-ThemeGenerationMessage -InputObject ('=' * 70) -ForegroundColor Cyan

Write-ThemeGenerationMessage -InputObject "`n✅ Successfully created: " -NoNewline -ForegroundColor Green
Write-ThemeGenerationMessage -InputObject $totalSuccessCount -ForegroundColor White

if ($totalSkipCount -gt 0) {
    Write-ThemeGenerationMessage -InputObject '⚠️  Skipped (existing): ' -NoNewline -ForegroundColor Yellow
    Write-ThemeGenerationMessage -InputObject $totalSkipCount -ForegroundColor White
}

if ($totalErrorCount -gt 0) {
    Write-ThemeGenerationMessage -InputObject '❌ Errors: ' -NoNewline -ForegroundColor Red
    Write-ThemeGenerationMessage -InputObject $totalErrorCount -ForegroundColor White
}

Write-ThemeGenerationMessage -InputObject "`n📁 Total files: " -NoNewline -ForegroundColor Cyan
Write-ThemeGenerationMessage -InputObject ($totalSuccessCount + $totalSkipCount) -ForegroundColor White

# List created files
if ($totalSuccessCount -gt 0) {
    Write-ThemeGenerationMessage -InputObject "`n📄 Created themes:" -ForegroundColor Cyan
    $allResults | Where-Object { $_.Status -eq 'Created' } | ForEach-Object {
        Write-ThemeGenerationMessage -InputObject '   • ' -NoNewline -ForegroundColor DarkGray
        Write-ThemeGenerationMessage -InputObject $_.Palette -NoNewline -ForegroundColor Magenta
        Write-ThemeGenerationMessage -InputObject ' → ' -NoNewline -ForegroundColor DarkGray
        Write-ThemeGenerationMessage -InputObject ([System.IO.Path]::GetFileName($_.File)) -ForegroundColor White
    }
}

if ($totalErrorCount -gt 0) {
    throw "Theme generation failed for $totalErrorCount palette(s). Review the error summary above; existing outputs were left unchanged for failed palettes."
}

# Show how to use
Write-ThemeGenerationMessage -InputObject "`n🚀 To use a theme, run:" -ForegroundColor Cyan
Write-ThemeGenerationMessage -InputObject "   oh-my-posh init pwsh --config 'PATH_TO_THEME.json' | Invoke-Expression" -ForegroundColor White

Write-ThemeGenerationMessage -InputObject "`n💡 Tip: Add one to your PowerShell profile for permanent use!" -ForegroundColor Yellow

Write-ThemeGenerationMessage -InputObject ("`n" + ('=' * 70)) -ForegroundColor Cyan
Write-ThemeGenerationMessage -InputObject '✨ Done!' -ForegroundColor Green
Write-ThemeGenerationMessage -InputObject ('=' * 70) -ForegroundColor Cyan
Write-ThemeGenerationMessage -InputObject ''
