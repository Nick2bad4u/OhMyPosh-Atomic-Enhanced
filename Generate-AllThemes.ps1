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
    Directory where theme files will be created. If not specified, uses source theme directory.

.PARAMETER UpdateAccentColor
    If specified, also updates the root "accent_color" property to match palette accent.

.PARAMETER ExcludePalettes
    Array of palette names to skip (e.g., if you don't want to generate certain themes).

.PARAMETER Force
    Overwrite existing theme files without prompting.

.EXAMPLE
    .\Generate-AllThemes.ps1
    Generates theme files for all palettes

.EXAMPLE
    .\Generate-AllThemes.ps1 -UpdateAccentColor -Force
    Generates all themes with updated accent colors, overwriting existing files

.EXAMPLE
    .\Generate-AllThemes.ps1 -ExcludePalettes @("original", "test_palette")
    Generates all themes except "original" and "test_palette"

.NOTES
    Author: GitHub Copilot
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$SourceThemes = @(
        "OhMyPosh-Atomic-Custom.json",
        "1_shell-Enhanced.omp.json",
        "slimfat-Enhanced.omp.json",
        "atomicBit-Enhanced.omp.json",
        "clean-detailed-Enhanced.omp.json"
    ),

    [Parameter()]
    [string]$PalettesFile = "color-palette-alternatives.json",

    [Parameter()]
    [string]$OutputDirectory,

    [Parameter()]
    [switch]$UpdateAccentColor,

    [Parameter()]
    [string[]]$ExcludePalettes = @(),

    [Parameter()]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Helper function to convert snake_case to PascalCase
function ConvertTo-PascalCase {
    param([string]$Text)

    $words = $Text -split '[\s_-]+'
    $pascalCase = ($words | ForEach-Object {
        $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower()
    }) -join ''

    return $pascalCase
}

Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
Write-Host "  🎨 Oh My Posh BATCH Theme Generator 🎨" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan

# Verify files exist
$missingThemes = @($SourceThemes | Where-Object { -not (Test-Path $_) })
if ($missingThemes.Count -gt 0) {
    Write-Error "Source theme file(s) not found: $($missingThemes -join ', ')"
    exit 1
}

if (-not (Test-Path $PalettesFile)) {
    Write-Error "Palettes file not found: $PalettesFile"
    exit 1
}

# Read palettes file
Write-Host "`n📚 Loading palettes from: " -NoNewline
Write-Host $PalettesFile -ForegroundColor Yellow

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
$ExcludePalettes = @($ExcludePalettes)  # Ensure it's an array
$allPaletteNames = $palettes.PSObject.Properties.Name | Where-Object {
    $_ -notin $ExcludePalettes
}

Write-Host "✓ Found " -NoNewline -ForegroundColor Green
Write-Host $allPaletteNames.Count -NoNewline -ForegroundColor White
Write-Host " palettes" -ForegroundColor Green

if ($ExcludePalettes.Count -gt 0 -and $ExcludePalettes[0]) {
    Write-Host "  Excluding: " -NoNewline -ForegroundColor DarkGray
    Write-Host ($ExcludePalettes -join ", ") -ForegroundColor Red
}

# Determine output directory
if (-not $OutputDirectory) {
    $OutputDirectory = "."
}

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

Write-Host "`n📁 Output directory: " -NoNewline
Write-Host $OutputDirectory -ForegroundColor Yellow

# Statistics
$totalSuccessCount = 0
$totalSkipCount = 0
$totalErrorCount = 0
$allResults = @()

Write-Host "`n" + ("-" * 70) -ForegroundColor DarkGray
Write-Host "Starting generation..." -ForegroundColor Cyan
Write-Host ("-" * 70) -ForegroundColor DarkGray

# Loop through each source theme
foreach ($SourceTheme in $SourceThemes) {
    Write-Host "`n🎨 Processing: " -NoNewline -ForegroundColor Cyan
    Write-Host $SourceTheme -ForegroundColor Yellow

    $successCount = 0
    $skipCount = 0
    $errorCount = 0

    foreach ($paletteName in $allPaletteNames) {
        $paletteInfo = $palettes.$paletteName
        $friendlyName = $paletteInfo.name
        $description = $paletteInfo.description

        Write-Host "`n[$($successCount + $skipCount + $errorCount + 1)/$($allPaletteNames.Count)] " -NoNewline -ForegroundColor DarkCyan
        Write-Host $friendlyName -ForegroundColor Magenta
        Write-Host "    $description" -ForegroundColor Gray

        # Generate output filename
        $outputName = ConvertTo-PascalCase $paletteName
        $sourceBaseName = [System.IO.Path]::GetFileNameWithoutExtension($SourceTheme)
        $outputFile = Join-Path $OutputDirectory "$sourceBaseName.$outputName.json"

        # Check if file exists
        if ((Test-Path $outputFile) -and -not $Force) {
            Write-Host "    ⚠️  File already exists, skipping (use -Force to overwrite)" -ForegroundColor Yellow
            $skipCount++
            $allResults += [PSCustomObject]@{
                SourceTheme = $SourceTheme
                Palette = $friendlyName
                Status = "Skipped"
                File = $outputFile
            }
            continue
        }

        # Call the New-ThemeWithPalette script
        try {
            $params = @{
                SourceTheme = $SourceTheme
                PaletteName = $paletteName
                OutputPath = $outputFile
                PalettesFile = $PalettesFile
            }

            if ($UpdateAccentColor) {
                $params.UpdateAccentColor = $true
            }

            # Run the script silently
            $null = & "$PSScriptRoot\New-ThemeWithPalette.ps1" @params 2>&1

            Write-Host "    ✅ Success: " -NoNewline -ForegroundColor Green
            Write-Host ([System.IO.Path]::GetFileName($outputFile)) -ForegroundColor White

            $successCount++
            $allResults += [PSCustomObject]@{
                SourceTheme = $SourceTheme
                Palette = $friendlyName
                Status = "Created"
                File = $outputFile
            }
        }
        catch {
            Write-Host "    ❌ Error: $_" -ForegroundColor Red
            $errorCount++
            $allResults += [PSCustomObject]@{
                SourceTheme = $SourceTheme
                Palette = $friendlyName
                Status = "Error"
                File = $outputFile
            }
        }
    }

    # Add to totals
    $totalSuccessCount += $successCount
    $totalSkipCount += $skipCount
    $totalErrorCount += $errorCount

    Write-Host "`n  Summary for $SourceTheme" -ForegroundColor Yellow
    Write-Host "  ✅ Created: $successCount | ⚠️  Skipped: $skipCount | ❌ Errors: $errorCount" -ForegroundColor Gray
}

# Summary
Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
Write-Host "  📊 OVERALL GENERATION SUMMARY" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan

Write-Host "`n✅ Successfully created: " -NoNewline -ForegroundColor Green
Write-Host $totalSuccessCount -ForegroundColor White

if ($totalSkipCount -gt 0) {
    Write-Host "⚠️  Skipped (existing): " -NoNewline -ForegroundColor Yellow
    Write-Host $totalSkipCount -ForegroundColor White
}

if ($totalErrorCount -gt 0) {
    Write-Host "❌ Errors: " -NoNewline -ForegroundColor Red
    Write-Host $totalErrorCount -ForegroundColor White
}

Write-Host "`n📁 Total files: " -NoNewline -ForegroundColor Cyan
Write-Host ($totalSuccessCount + $totalSkipCount) -ForegroundColor White

# List created files
if ($totalSuccessCount -gt 0) {
    Write-Host "`n📄 Created themes:" -ForegroundColor Cyan
    $allResults | Where-Object { $_.Status -eq "Created" } | ForEach-Object {
        Write-Host "   • " -NoNewline -ForegroundColor DarkGray
        Write-Host $_.Palette -NoNewline -ForegroundColor Magenta
        Write-Host " → " -NoNewline -ForegroundColor DarkGray
        Write-Host ([System.IO.Path]::GetFileName($_.File)) -ForegroundColor White
    }
}

# Show how to use
Write-Host "`n🚀 To use a theme, run:" -ForegroundColor Cyan
Write-Host "   oh-my-posh init pwsh --config 'PATH_TO_THEME.json' | Invoke-Expression" -ForegroundColor White

Write-Host "`n💡 Tip: Add one to your PowerShell profile for permanent use!" -ForegroundColor Yellow

Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
Write-Host "✨ Done!" -ForegroundColor Green
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""
