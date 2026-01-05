#
# Creates a palette-converted version of the **Atomic-Custom-ExperimentalDividers** theme.
# This script works like New-ThemeWithPalette.ps1 but automatically generates all of the
# extra divider blend colors and carries forward the extended palette keys (cycle colors,
# Copilot badge colors, etc.) that the experimental theme needs.
#
# It keeps the existing New-ThemeWithPalette.ps1 untouched.
#
<#
.SYNOPSIS
    Creates a new Oh My Posh Experimental Dividers theme file with a different color palette.

.DESCRIPTION
    - Loads the Atomic-Custom-ExperimentalDividers base theme.
    - Pulls a palette by name from color-palette-alternatives.json **or** accepts a custom palette object.
    - Automatically synthesizes all divider/transition colors by blending the relevant base colors in HSL space.
    - Carries forward required extra palette keys (cycle_* colors, copilot colors, zod_blue, etc.).
    - Saves the converted theme to a new file without modifying the original theme or scripts.

.PARAMETER SourceTheme
    Path to the source Experimental Dividers theme JSON file.
    Default: "OhMyPosh-Atomic-Custom-ExperimentalDividers.json"

.PARAMETER PaletteName
    Name of the palette from color-palette-alternatives.json.

.PARAMETER PaletteObject
    A hashtable or PSCustomObject containing palette colors (alternative to PaletteName).

.PARAMETER OutputName
    Suffix for the output file name (inserted before .json). Example: "NordFrost" -> OhMyPosh-Atomic-Custom-ExperimentalDividers.NordFrost.json

.PARAMETER OutputPath
    Full path for the output file. Overrides OutputName when provided.

.PARAMETER PalettesFile
    Path to the palette definitions JSON. Default: color-palette-alternatives.json

.PARAMETER UpdateAccentColor
    When set, updates the root accent_color in the theme to match the palette's "accent" entry if present.

.PARAMETER BlendPercentage
    Blend factor (0-1) used when generating divider colors. 0.5 = midpoint (default).

.EXAMPLE
    .\scripts\New-ExperimentalDividersThemeWithPalette.ps1 -PaletteName "nord_frost" -OutputName "NordFrost" -UpdateAccentColor

.EXAMPLE
    $custom = @{ accent = '#ff00ff'; blue_primary = '#112233'; red_alert = '#aa0000'; ... }
    .\scripts\New-ExperimentalDividersThemeWithPalette.ps1 -PaletteObject $custom -OutputName "MyPalette"

.NOTES
    This script is intentionally separate so the original New-ThemeWithPalette.ps1 remains unchanged.
#>

[CmdletBinding(DefaultParameterSetName = 'ByPaletteName')]
param(
    [Parameter()]
    [string]$SourceTheme = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',

    [Parameter(ParameterSetName = 'ByPaletteName', Mandatory = $true)]
    [string]$PaletteName,

    [Parameter(ParameterSetName = 'ByPaletteObject', Mandatory = $true)]
    [object]$PaletteObject,

    [Parameter()]
    [string]$OutputName,

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [string]$PalettesFile = 'color-palette-alternatives.json',

    [Parameter()]
    [switch]$UpdateAccentColor,

    [Parameter()]
    [switch]$RecomputeDividers,

    [Parameter()]
    [ValidateRange(0.0, 1.0)]
    [double]$BlendPercentage = 0.5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# This script lives in .\scripts\, but operates on files in the repository root.
$RepoRoot = Split-Path -Path $PSScriptRoot -Parent

# Write-Output does not support -ForegroundColor / -NoNewline, but this repo historically used it that way.
# Provide a local wrapper so the script works when run standalone.
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

# Resolve repo-relative inputs
$SourceTheme = Resolve-RepoPath $SourceTheme
$PalettesFile = Resolve-RepoPath $PalettesFile
if ($OutputPath -and -not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Resolve-RepoPath $OutputPath
}

# region Helper functions

function ConvertTo-Hashtable {
    param([object]$InputObject)

    if ($InputObject -is [hashtable]) {
        return $InputObject
    }

    if ($InputObject -is [pscustomobject]) {
        $hash = @{}
        foreach ($prop in $InputObject.PSObject.Properties) {
            $hash[$prop.Name] = $prop.Value
        }
        return $hash
    }

    throw 'Palette must be a hashtable or PSCustomObject.'
}

function ConvertTo-FileNameFormat {
    param([string]$Text)

    $words = $Text -split '[\s_-]+'
    $pascalCase = ($words | ForEach-Object {
            if ($_.Length -gt 0) {
                $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower()
            }
        }) -join ''

    return $pascalCase
}

function Get-PaletteColor {
    param(
        [hashtable]$Palette,
        [hashtable]$FallbackPalette,
        [string]$Key
    )

    if ($Palette.ContainsKey($Key)) { return $Palette[$Key] }
    if ($FallbackPalette -and $FallbackPalette.ContainsKey($Key)) { return $FallbackPalette[$Key] }

    throw "Required base color '$Key' is missing. Add it to the palette or pass it via -PaletteObject."
}

function Convert-HexToRgb {
    param([string]$Hex)

    $clean = $Hex.Trim()
    if ($clean.StartsWith('#')) { $clean = $clean.Substring(1) }

    if ($clean.Length -ne 6) {
        throw "Invalid hex color '$Hex'. Use #RRGGBB format."
    }

    return [pscustomobject]@{
        R = [Convert]::ToInt32($clean.Substring(0, 2), 16)
        G = [Convert]::ToInt32($clean.Substring(2, 2), 16)
        B = [Convert]::ToInt32($clean.Substring(4, 2), 16)
    }
}

function Convert-RgbToHsl {
    param([pscustomobject]$Rgb)

    $r = $Rgb.R / 255.0
    $g = $Rgb.G / 255.0
    $b = $Rgb.B / 255.0

    $max = [math]::Max($r, [math]::Max($g, $b))
    $min = [math]::Min($r, [math]::Min($g, $b))
    $delta = $max - $min

    $l = ($max + $min) / 2.0
    if ($delta -eq 0) {
        $h = 0
        $s = 0
    }
    else {
        $s = $delta / (1 - [math]::Abs(2 * $l - 1))

        switch ($max) {
            { $_ -eq $r } { $h = 60 * ((($g - $b) / $delta) % 6); break }
            { $_ -eq $g } { $h = 60 * ((($b - $r) / $delta) + 2); break }
            default { $h = 60 * ((($r - $g) / $delta) + 4); break }
        }

        if ($h -lt 0) { $h += 360 }
    }

    return [pscustomobject]@{
        H = $h
        S = $s
        L = $l
    }
}

function Convert-HslToRgb {
    param(
        [double]$H,
        [double]$S,
        [double]$L
    )

    $c = (1 - [math]::Abs(2 * $L - 1)) * $S
    $hPrime = $H / 60.0
    $x = $c * (1 - [math]::Abs(($hPrime % 2) - 1))
    $m = $L - ($c / 2)

    switch ($hPrime) {
        { $_ -lt 1 } { $r1 = $c; $g1 = $x; $b1 = 0; break }
        { $_ -lt 2 } { $r1 = $x; $g1 = $c; $b1 = 0; break }
        { $_ -lt 3 } { $r1 = 0; $g1 = $c; $b1 = $x; break }
        { $_ -lt 4 } { $r1 = 0; $g1 = $x; $b1 = $c; break }
        { $_ -lt 5 } { $r1 = $x; $g1 = 0; $b1 = $c; break }
        default { $r1 = $c; $g1 = 0; $b1 = $x; break }
    }

    $r = [math]::Round(($r1 + $m) * 255)
    $g = [math]::Round(($g1 + $m) * 255)
    $b = [math]::Round(($b1 + $m) * 255)

    return [pscustomobject]@{ R = [int]$r; G = [int]$g; B = [int]$b }
}

function Get-InterpolatedColor {
    param(
        [string]$FromColor,
        [string]$ToColor,
        [double]$Blend = 0.5
    )

    $fromHsl = Convert-RgbToHsl (Convert-HexToRgb $FromColor)
    $toHsl = Convert-RgbToHsl (Convert-HexToRgb $ToColor)

    # Hue wrap handling (shortest path around the color wheel)
    $hueDelta = $toHsl.H - $fromHsl.H
    if ([math]::Abs($hueDelta) -gt 180) {
        if ($hueDelta -gt 0) { $hueDelta -= 360 }
        else { $hueDelta += 360 }
    }

    $h = ($fromHsl.H + $hueDelta * $Blend) % 360
    if ($h -lt 0) { $h += 360 }

    $s = $fromHsl.S + ($toHsl.S - $fromHsl.S) * $Blend
    $l = $fromHsl.L + ($toHsl.L - $fromHsl.L) * $Blend

    $rgb = Convert-HslToRgb -H $h -S $s -L $l
    return '#{0:X2}{1:X2}{2:X2}' -f $rgb.R, $rgb.G, $rgb.B
}

# endregion Helper functions

Write-Output '🎨 Experimental Dividers Palette Converter' -ForegroundColor Cyan
Write-Output ('=' * 60) -ForegroundColor DarkGray

# Validate source theme
if (-not (Test-Path -LiteralPath $SourceTheme)) {
    Write-Error "Source theme not found: $SourceTheme"
    exit 1
}

Write-Output '📖 Reading source theme: ' -NoNewline
Write-Output $SourceTheme -ForegroundColor Yellow

try {
    $themeContent = Get-Content -LiteralPath $SourceTheme -Raw
    $theme = $themeContent | ConvertFrom-Json -AsHashtable
}
catch {
    Write-Error "Failed to parse source theme JSON: $_"
    exit 1
}

$sourcePalette = ConvertTo-Hashtable $theme['palette']

# Load palette
$palette = $null
$paletteFriendlyName = ''

if ($PSCmdlet.ParameterSetName -eq 'ByPaletteName') {
    if (-not (Test-Path -LiteralPath $PalettesFile)) {
        Write-Error "Palettes file not found: $PalettesFile"
        exit 1
    }

    Write-Output '📚 Loading palettes from: ' -NoNewline
    Write-Output $PalettesFile -ForegroundColor Yellow

    try {
        $palettesContent = Get-Content -LiteralPath $PalettesFile -Raw
        $palettes = ($palettesContent | ConvertFrom-Json).palettes
    }
    catch {
        Write-Error "Failed to parse palettes JSON: $_"
        exit 1
    }

    if (-not $palettes.PSObject.Properties.Name.Contains($PaletteName)) {
        Write-Output "`n❌ Palette '$PaletteName' not found." -ForegroundColor Red
        Write-Output 'Available palettes:' -ForegroundColor Cyan
        $palettes.PSObject.Properties | ForEach-Object {
            Write-Output '  • ' -NoNewline -ForegroundColor DarkGray
            Write-Output $_.Name -NoNewline -ForegroundColor Green
            Write-Output " - $($_.Value.description)" -ForegroundColor Gray
        }
        exit 1
    }

    $paletteInfo = $palettes.$PaletteName
    $palette = ConvertTo-Hashtable $paletteInfo.Palette
    $paletteFriendlyName = $paletteInfo.Name

    Write-Output '✓ Using palette: ' -NoNewline -ForegroundColor Green
    Write-Output $paletteFriendlyName -ForegroundColor Magenta
}
else {
    Write-Output '✓ Using custom palette object' -ForegroundColor Green
    $palette = ConvertTo-Hashtable $PaletteObject
    $paletteFriendlyName = 'Custom Palette'
}

# Work on a copy so we can add derived colors
$workingPalette = @{}
foreach ($entry in $palette.GetEnumerator()) {
    $workingPalette[$entry.Key] = $entry.Value
}

# Carry forward extended keys (cycle colors, copilot colors, zod_blue) when missing
$carryKeys = @(
    'copilot_bg', 'copilot_fg', 'zod_blue',
    'cycle_apricot', 'cycle_aqua', 'cycle_black_forest', 'cycle_blush', 'cycle_charcoal', 'cycle_coral', 'cycle_creme',
    'cycle_deep_jungle', 'cycle_deep_mocha', 'cycle_deep_navy', 'cycle_deep_plum', 'cycle_deep_teal', 'cycle_eggplant',
    'cycle_electric_cyan', 'cycle_espresso', 'cycle_forest', 'cycle_hot_pink', 'cycle_ice_blue', 'cycle_inky', 'cycle_lilac',
    'cycle_magenta', 'cycle_mahogany', 'cycle_marmalade', 'cycle_midnight_blue', 'cycle_mint', 'cycle_neon_green',
    'cycle_nightshade', 'cycle_onyx', 'cycle_oxblood', 'cycle_periwinkle', 'cycle_rust', 'cycle_seaweed', 'cycle_sky_blue',
    'cycle_soft_lavender', 'cycle_spring_green', 'cycle_spring_mint', 'cycle_stormy_night', 'cycle_sunburst',
    'cycle_sunshine', 'cycle_swamp', 'cycle_violet', 'cycle_watermelon'
)

foreach ($key in $carryKeys) {
    if (-not $workingPalette.ContainsKey($key) -and $sourcePalette.ContainsKey($key)) {
        $workingPalette[$key] = $sourcePalette[$key]
    }
}

# Ensure all source palette base keys exist (fallback to source values when missing)
foreach ($key in $sourcePalette.Keys) {
    if (-not $workingPalette.ContainsKey($key)) {
        $workingPalette[$key] = $sourcePalette[$key]
    }
}

# Divider blend definitions (fromKey -> toKey)
$dividerPairs = [ordered]@{
    'divider_blue_primary_to_ipify_purple'           = @('blue_primary', 'ipify_purple')
    'divider_blue_primary_to_red_alert'              = @('blue_primary', 'red_alert')
    'divider_ipify_purple_to_typescript_eslint_pink' = @('ipify_purple', 'typescript_eslint_pink')
    'divider_typescript_eslint_pink_to_orange'       = @('typescript_eslint_pink', 'orange')
    'divider_orange_to_green_added'                  = @('orange', 'green_added')
    'divider_green_added_to_yellow_bright'           = @('green_added', 'yellow_bright')
    'divider_yellow_bright_to_navy_text'             = @('yellow_bright', 'navy_text')
    'divider_navy_text_to_purple_exec'               = @('navy_text', 'purple_exec')
    'divider_purple_exec_to_electron_red'            = @('purple_exec', 'electron_red')
    'divider_red_alert_to_orange'                    = @('red_alert', 'orange')
    'divider_blue_time_to_electron_red'              = @('blue_time', 'electron_red')
    'divider_blue_time_to_violet_project'            = @('blue_time', 'violet_project')
    'divider_electron_red_to_maroon_error'           = @('electron_red', 'maroon_error')
    'divider_gray_os_to_electron_red'                = @('gray_os', 'electron_red')
    'divider_gray_os_to_gray_prompt_count_bg'        = @('gray_os', 'gray_prompt_count_bg')
    'divider_maroon_error_to_pink_weather'           = @('maroon_error', 'pink_weather')
    'divider_teal_sysinfo_to_electron_red'           = @('teal_sysinfo', 'electron_red')
}

Write-Output "🔧 Generating divider blend colors (blend=$BlendPercentage)..." -ForegroundColor Cyan

foreach ($pair in $dividerPairs.GetEnumerator()) {
    $targetKey = $pair.Key
    $fromKey, $toKey = $pair.Value

    $fromColor = Get-PaletteColor -Palette $workingPalette -FallbackPalette $sourcePalette -Key $fromKey
    $toColor = Get-PaletteColor -Palette $workingPalette -FallbackPalette $sourcePalette -Key $toKey

    if ($RecomputeDividers -or -not $workingPalette.ContainsKey($targetKey)) {
        $workingPalette[$targetKey] = Get-InterpolatedColor -FromColor $fromColor -ToColor $toColor -Blend $BlendPercentage
    }
}

# Re-apply to theme
$theme['palette'] = $workingPalette

if ($UpdateAccentColor -and $workingPalette.ContainsKey('accent')) {
    $oldAccent = $theme['accent_color']
    $theme['accent_color'] = $workingPalette['accent']
    Write-Output "  • Updated accent_color: $oldAccent → $($workingPalette['accent'])" -ForegroundColor DarkGray
}

# Determine output path
if ($OutputPath) {
    $outputFile = $OutputPath
}
else {
    if (-not $OutputName) {
        $OutputName = ConvertTo-FileNameFormat ($PaletteName ?? 'Custom')
    }

    $sourceBaseName = [System.IO.Path]::GetFileNameWithoutExtension($SourceTheme)
    $sourceDir = Split-Path $SourceTheme -Parent
    if (-not $sourceDir) { $sourceDir = '.' }

    $outputFile = Join-Path $sourceDir "$sourceBaseName.$OutputName.json"
}

Write-Output '💾 Saving new theme...' -ForegroundColor Cyan

try {
    $jsonOutput = $theme | ConvertTo-Json -Depth 100
    $jsonOutput | Set-Content -LiteralPath $outputFile -Encoding UTF8

    Write-Output "✅ Created: $outputFile" -ForegroundColor Green
    Write-Output "🎨 Palette applied: $paletteFriendlyName" -ForegroundColor Magenta
    Write-Output "📊 Palette size: $($workingPalette.Keys.Count) entries" -ForegroundColor Gray
}
catch {
    Write-Error "Failed to save theme file: $_"
    exit 1
}

Write-Output ('=' * 60) -ForegroundColor DarkGray
Write-Output '✨ Done!' -ForegroundColor Green
