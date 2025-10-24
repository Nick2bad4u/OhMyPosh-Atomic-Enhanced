<#
.SYNOPSIS
    Creates a new Oh My Posh theme file with a different color palette.

.DESCRIPTION
    Takes a source Oh My Posh theme JSON file and applies a new color palette,
    generating a new theme file with an updated name. Supports both direct palette
    objects and palette names from the color-palette-alternatives.json file.

.PARAMETER SourceTheme
    Path to the source Oh My Posh theme JSON file.
    Default: "OhMyPosh-Atomic-Custom.json"

.PARAMETER PaletteName
    Name of the palette from color-palette-alternatives.json.
    Examples: "nord_frost", "dracula_night", "tokyo_night", etc.

.PARAMETER PaletteObject
    A hashtable or PSCustomObject containing the palette colors.
    Use this if you want to provide a custom palette directly.

.PARAMETER OutputName
    The name suffix for the output file. Will be inserted before .json extension.
    Example: "TokyoNight" creates "OhMyPosh-Atomic-Custom.TokyoNight.json"

.PARAMETER OutputPath
    Full path for the output file. If specified, OutputName is ignored.

.PARAMETER PalettesFile
    Path to the JSON file containing palette definitions.
    Default: "color-palette-alternatives.json"

.PARAMETER UpdateAccentColor
    If specified, also updates the root "accent_color" property to match the palette accent.

.EXAMPLE
    .\New-ThemeWithPalette.ps1 -PaletteName "tokyo_night" -OutputName "TokyoNight"
    Creates OhMyPosh-Atomic-Custom.TokyoNight.json with Tokyo Night palette

.EXAMPLE
    .\New-ThemeWithPalette.ps1 -PaletteName "nord_frost" -UpdateAccentColor
    Creates OhMyPosh-Atomic-Custom.NordFrost.json and updates accent_color

.EXAMPLE
    $customPalette = @{ accent = "#ff0000"; blue_primary = "#0000ff"; ... }
    .\New-ThemeWithPalette.ps1 -PaletteObject $customPalette -OutputName "CustomRed"

.NOTES
    Author: GitHub Copilot
    Version: 1.0
#>

[CmdletBinding(DefaultParameterSetName = 'ByPaletteName')]
param(
    [Parameter()]
    [string]$SourceTheme = "OhMyPosh-Atomic-Custom.json",

    [Parameter(ParameterSetName = 'ByPaletteName', Mandatory = $true)]
    [string]$PaletteName,

    [Parameter(ParameterSetName = 'ByPaletteObject', Mandatory = $true)]
    [object]$PaletteObject,

    [Parameter()]
    [string]$OutputName,

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [string]$PalettesFile = "color-palette-alternatives.json",

    [Parameter()]
    [switch]$UpdateAccentColor
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Helper function to convert PascalCase/snake_case to Title Case
function ConvertTo-TitleCase {
    param([string]$Text)

    # Convert snake_case to space separated
    $Text = $Text -replace '_', ' '

    # Convert PascalCase to space separated
    $Text = $Text -creplace '([a-z])([A-Z])', '$1 $2'

    # Title case
    $textInfo = (Get-Culture).TextInfo
    return $textInfo.ToTitleCase($Text.ToLower())
}

# Helper function to format name for file output
function ConvertTo-FileNameFormat {
    param([string]$Text)

    # Remove spaces and special characters, convert to PascalCase
    $words = $Text -split '[\s_-]+'
    $pascalCase = ($words | ForEach-Object {
        $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower()
    }) -join ''

    return $pascalCase
}

Write-Host "🎨 Oh My Posh Theme Palette Generator" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor DarkGray

# Verify source theme exists
if (-not (Test-Path $SourceTheme)) {
    Write-Error "Source theme file not found: $SourceTheme"
    exit 1
}

Write-Host "📖 Reading source theme: " -NoNewline
Write-Host $SourceTheme -ForegroundColor Yellow

# Read source theme
try {
    $themeContent = Get-Content $SourceTheme -Raw
    $theme = $themeContent | ConvertFrom-Json -AsHashtable
}
catch {
    Write-Error "Failed to parse source theme JSON: $_"
    exit 1
}

# Get the palette
$palette = $null
$paletteFriendlyName = ""

if ($PSCmdlet.ParameterSetName -eq 'ByPaletteName') {
    # Load palettes file
    if (-not (Test-Path $PalettesFile)) {
        Write-Error "Palettes file not found: $PalettesFile"
        exit 1
    }

    Write-Host "📚 Loading palettes from: " -NoNewline
    Write-Host $PalettesFile -ForegroundColor Yellow

    try {
        $palettesContent = Get-Content $PalettesFile -Raw
        $palettes = ($palettesContent | ConvertFrom-Json).palettes
    }
    catch {
        Write-Error "Failed to parse palettes JSON: $_"
        exit 1
    }

    # Get the requested palette
    if (-not $palettes.PSObject.Properties.Name.Contains($PaletteName)) {
        Write-Host "`n❌ Palette '$PaletteName' not found!" -ForegroundColor Red
        Write-Host "`nAvailable palettes:" -ForegroundColor Cyan
        $palettes.PSObject.Properties | ForEach-Object {
            $name = $_.Name
            $description = $_.Value.description
            Write-Host "  • " -NoNewline -ForegroundColor DarkGray
            Write-Host $name -NoNewline -ForegroundColor Green
            Write-Host " - $description" -ForegroundColor Gray
        }
        exit 1
    }

    $paletteInfo = $palettes.$PaletteName
    $palette = $paletteInfo.palette
    $paletteFriendlyName = $paletteInfo.name

    Write-Host "✓ Found palette: " -NoNewline -ForegroundColor Green
    Write-Host $paletteFriendlyName -ForegroundColor Magenta
    Write-Host "  Description: " -NoNewline -ForegroundColor DarkGray
    Write-Host $paletteInfo.description -ForegroundColor Gray
}
else {
    # Use provided palette object
    $palette = $PaletteObject
    $paletteFriendlyName = "Custom Palette"

    Write-Host "✓ Using custom palette object" -ForegroundColor Green
}

# Convert palette to hashtable if it's a PSCustomObject
if ($palette -is [PSCustomObject]) {
    $paletteHash = @{}
    $palette.PSObject.Properties | ForEach-Object {
        $paletteHash[$_.Name] = $_.Value
    }
    $palette = $paletteHash
}

# Update the theme palette
Write-Host "🔄 Applying new palette..." -ForegroundColor Cyan
$theme.palette = $palette

# Update accent_color if requested
if ($UpdateAccentColor -and $palette.ContainsKey('accent')) {
    $oldAccent = $theme.accent_color
    $theme.accent_color = $palette.accent
    Write-Host "  • Updated accent_color: " -NoNewline -ForegroundColor DarkGray
    Write-Host "$oldAccent" -NoNewline -ForegroundColor DarkRed
    Write-Host " → " -NoNewline
    Write-Host "$($palette.accent)" -ForegroundColor Green
}

# Determine output file path
if ($OutputPath) {
    $outputFile = $OutputPath
}
else {
    # Generate output name if not provided
    if (-not $OutputName) {
        if ($PSCmdlet.ParameterSetName -eq 'ByPaletteName') {
            $OutputName = ConvertTo-FileNameFormat $PaletteName
        }
        else {
            $OutputName = "Custom-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        }
    }

    # Build output path
    $sourceBaseName = [System.IO.Path]::GetFileNameWithoutExtension($SourceTheme)
    $sourceDir = Split-Path $SourceTheme -Parent
    if (-not $sourceDir) { $sourceDir = "." }

    $outputFile = Join-Path $sourceDir "$sourceBaseName.$OutputName.json"
}

# Convert back to JSON and save
Write-Host "💾 Saving new theme..." -ForegroundColor Cyan
try {
    # Convert hashtable back to JSON with proper formatting
    $jsonOutput = $theme | ConvertTo-Json -Depth 100

    # Write to file
    $jsonOutput | Set-Content -Path $outputFile -Encoding UTF8

    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "`n📄 New theme created:" -ForegroundColor Cyan
    Write-Host "   $outputFile" -ForegroundColor Yellow
    Write-Host "`n🎨 Palette applied:" -ForegroundColor Cyan
    Write-Host "   $paletteFriendlyName" -ForegroundColor Magenta

    Write-Host "`n🚀 To use this theme, run:" -ForegroundColor Cyan
    Write-Host "   oh-my-posh init pwsh --config '$outputFile' | Invoke-Expression" -ForegroundColor White

    # Get file size
    $fileSize = (Get-Item $outputFile).Length
    $fileSizeKB = [math]::Round($fileSize / 1KB, 2)
    Write-Host "`n📊 File size: " -NoNewline -ForegroundColor DarkGray
    Write-Host "$fileSizeKB KB" -ForegroundColor Gray

    # Count palette colors
    $colorCount = ($palette.Keys | Measure-Object).Count
    Write-Host "🎨 Palette colors: " -NoNewline -ForegroundColor DarkGray
    Write-Host $colorCount -ForegroundColor Gray
}
catch {
    Write-Error "Failed to save theme file: $_"
    exit 1
}

Write-Host "`n" + ("=" * 50) -ForegroundColor DarkGray
Write-Host "✨ Done!" -ForegroundColor Green
