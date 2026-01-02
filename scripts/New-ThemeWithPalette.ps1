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
    .\scripts\New-ThemeWithPalette.ps1 -PaletteName "tokyo_night" -OutputName "TokyoNight"
    Creates OhMyPosh-Atomic-Custom.TokyoNight.json with Tokyo Night palette

.EXAMPLE
    .\scripts\New-ThemeWithPalette.ps1 -PaletteName "nord_frost" -UpdateAccentColor
    Creates OhMyPosh-Atomic-Custom.NordFrost.json and updates accent_color

.EXAMPLE
    $customPalette = @{ accent = "#ff0000"; blue_primary = "#0000ff"; ... }
    .\scripts\New-ThemeWithPalette.ps1 -PaletteObject $customPalette -OutputName "CustomRed"

.NOTES
    Author: GitHub Copilot
    Version: 1.0
#>

[CmdletBinding(DefaultParameterSetName = 'ByPaletteName')]
param(
    [Parameter()]
    [string]$SourceTheme = "OhMyPosh-Atomic-Custom.json",

    [Parameter(ParameterSetName = 'ByPaletteName',Mandatory = $true)]
    [string]$PaletteName,

    [Parameter(ParameterSetName = 'ByPaletteObject',Mandatory = $true)]
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

# Resolve repo-relative inputs
$SourceTheme = Resolve-RepoPath $SourceTheme
$PalettesFile = Resolve-RepoPath $PalettesFile
if ($OutputPath -and -not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Resolve-RepoPath $OutputPath
}

# Helper function to convert PascalCase/snake_case to Title Case
function ConvertTo-TitleCase {
    param([string]$Text)

    # Convert snake_case to space separated
    $Text = $Text -replace '_',' '

    # Convert PascalCase to space separated
    $Text = $Text -creplace '([a-z])([A-Z])','$1 $2'

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

Write-Output "🎨 Oh My Posh Theme Palette Generator" -ForegroundColor Cyan
Write-Output "=" * 50 -ForegroundColor DarkGray

# Verify source theme exists
if (-not (Test-Path -LiteralPath $SourceTheme)) {
    Write-Error "Source theme file not found: $SourceTheme"
    exit 1
}

Write-Output "📖 Reading source theme: " -NoNewline
Write-Output $SourceTheme -ForegroundColor Yellow

# Read source theme
try {
    $themeContent = Get-Content -LiteralPath $SourceTheme -Raw
    $theme = $themeContent | ConvertFrom-Json -AsHashTable
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
    if (-not (Test-Path -LiteralPath $PalettesFile)) {
        Write-Error "Palettes file not found: $PalettesFile"
        exit 1
    }

    Write-Output "📚 Loading palettes from: " -NoNewline
    Write-Output $PalettesFile -ForegroundColor Yellow

    try {
        $palettesContent = Get-Content -LiteralPath $PalettesFile -Raw
        $palettes = ($palettesContent | ConvertFrom-Json).palettes
    }
    catch {
        Write-Error "Failed to parse palettes JSON: $_"
        exit 1
    }

    # Get the requested palette
    if (-not $palettes.PSObject.Properties.Name.Contains($PaletteName)) {
        Write-Output "`n❌ Palette '$PaletteName' not found!" -ForegroundColor Red
        Write-Output "`nAvailable palettes:" -ForegroundColor Cyan
        $palettes.PSObject.Properties | ForEach-Object {
            $name = $_.Name
            $description = $_.Value.description
            Write-Output "  • " -NoNewline -ForegroundColor DarkGray
            Write-Output $name -NoNewline -ForegroundColor Green
            Write-Output " - $description" -ForegroundColor Gray
        }
        exit 1
    }

    $paletteInfo = $palettes.$PaletteName
    $palette = $paletteInfo.Palette
    $paletteFriendlyName = $paletteInfo.Name

    Write-Output "✓ Found palette: " -NoNewline -ForegroundColor Green
    Write-Output $paletteFriendlyName -ForegroundColor Magenta
    Write-Output "  Description: " -NoNewline -ForegroundColor DarkGray
    Write-Output $paletteInfo.description -ForegroundColor Gray
}
else {
    # Use provided palette object
    $palette = $PaletteObject
    $paletteFriendlyName = "Custom Palette"

    Write-Output "✓ Using custom palette object" -ForegroundColor Green
}

# Convert palette to hashtable if it's a PSCustomObject
if ($palette -is [pscustomobject]) {
    $paletteHash = @{}
    $palette.PSObject.Properties | ForEach-Object {
        $paletteHash[$_.Name] = $_.Value
    }
    $palette = $paletteHash
}

# Update the theme palette
Write-Output "🔄 Applying new palette..." -ForegroundColor Cyan
$theme.Palette = $palette

# Update accent_color if requested
if ($UpdateAccentColor -and $palette.ContainsKey('accent')) {
    $oldAccent = $theme.accent_color
    $theme.accent_color = $palette.Accent
    Write-Output "  • Updated accent_color: " -NoNewline -ForegroundColor DarkGray
    Write-Output "$oldAccent" -NoNewline -ForegroundColor DarkRed
    Write-Output " → " -NoNewline
    Write-Output "$($palette.accent)" -ForegroundColor Green
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
Write-Output "💾 Saving new theme..." -ForegroundColor Cyan
try {
    # Convert hashtable back to JSON with proper formatting
    $jsonOutput = $theme | ConvertTo-Json -Depth 100

    # Write to file
    $jsonOutput | Set-Content -LiteralPath $outputFile -Encoding UTF8

    Write-Output "✅ SUCCESS!" -ForegroundColor Green
    Write-Output "`n📄 New theme created:" -ForegroundColor Cyan
    Write-Output "   $outputFile" -ForegroundColor Yellow
    Write-Output "`n🎨 Palette applied:" -ForegroundColor Cyan
    Write-Output "   $paletteFriendlyName" -ForegroundColor Magenta

    Write-Output "`n🚀 To use this theme, run:" -ForegroundColor Cyan
    Write-Output "   oh-my-posh init pwsh --config '$outputFile' | Invoke-Expression" -ForegroundColor White

    # Get file size
    $fileSize = (Get-Item $outputFile).Length
    $fileSizeKB = [math]::Round($fileSize / 1KB,2)
    Write-Output "`n📊 File size: " -NoNewline -ForegroundColor DarkGray
    Write-Output "$fileSizeKB KB" -ForegroundColor Gray

    # Count palette colors
    $colorCount = ($palette.Keys | Measure-Object).Count
    Write-Output "🎨 Palette colors: " -NoNewline -ForegroundColor DarkGray
    Write-Output $colorCount -ForegroundColor Gray
}
catch {
    Write-Error "Failed to save theme file: $_"
    exit 1
}

Write-Output "`n" + ("=" * 50) -ForegroundColor DarkGray
Write-Output "✨ Done!" -ForegroundColor Green
