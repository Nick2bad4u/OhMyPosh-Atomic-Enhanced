<#
.SYNOPSIS
Normalizes all palettes in color-palette-alternatives.json so they include every palette key used by the current theme templates.

.DESCRIPTION
As the themes evolve (especially ExperimentalDividers), new palette keys get introduced (divider_* blends,
cloud tooltip colors, shell badge colors, winget colors, etc.).

If the palette definition file doesn't contain those keys, palette-generated themes can end up with missing
`p:<key>` references at runtime.

This script:
- Uses OhMyPosh-Atomic-Custom.json as the canonical palette key list + defaults
- Ensures every palette in color-palette-alternatives.json contains those keys
- Recomputes derived keys so they are *palette-specific*:
  - divider_* blend colors
  - debug_bg/debug_fg
  - copilot_bg

Everything else (e.g. cloud provider tooltip brand colors) is copied from the canonical palette as defaults.

.PARAMETER PalettesFile
Palette definitions JSON file. Default: color-palette-alternatives.json

.PARAMETER CanonicalTheme
Theme file to use as the canonical keyset + default values. Default: OhMyPosh-Atomic-Custom.json

.PARAMETER BlendPercentage
Blend factor (0-1) used for divider_* computed colors. Default: 0.5

.PARAMETER Backup
If set, writes a .bak copy of the palette file before overwriting.

.EXAMPLE
pwsh .\scripts\Normalize-Palettes.ps1 -Backup
#>

[CmdletBinding()]
param(
    [string]$PalettesFile = 'color-palette-alternatives.json',
    [string]$CanonicalTheme = 'OhMyPosh-Atomic-Custom.json',
    [ValidateRange(0.0, 1.0)]
    [double]$BlendPercentage = 0.5,
    [switch]$Backup,
    [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Path $PSScriptRoot -Parent

function Resolve-RepoPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path -Path $RepoRoot -ChildPath $Path)
}

function Convert-HexToRgb {
    param([Parameter(Mandatory)][string]$Hex)

    $clean = $Hex.Trim()
    if ($clean.StartsWith('#')) { $clean = $clean.Substring(1) }
    if ($clean.Length -ne 6) { throw "Invalid hex color '$Hex'. Use #RRGGBB." }

    return [pscustomobject]@{
        R = [Convert]::ToInt32($clean.Substring(0, 2), 16)
        G = [Convert]::ToInt32($clean.Substring(2, 2), 16)
        B = [Convert]::ToInt32($clean.Substring(4, 2), 16)
    }
}

function Convert-RgbToHsl {
    param([Parameter(Mandatory)][pscustomobject]$Rgb)

    $r = $Rgb.R / 255.0
    $g = $Rgb.G / 255.0
    $b = $Rgb.B / 255.0

    $max = [math]::Max($r, [math]::Max($g, $b))
    $min = [math]::Min($r, [math]::Min($g, $b))
    $delta = $max - $min

    $l = ($max + $min) / 2.0
    if ($delta -eq 0) {
        $h = 0; $s = 0
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

    return [pscustomobject]@{ H = $h; S = $s; L = $l }
}

function Convert-HslToRgb {
    param(
        [Parameter(Mandatory)][double]$H,
        [Parameter(Mandatory)][double]$S,
        [Parameter(Mandatory)][double]$L
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
        [Parameter(Mandatory)][string]$FromColor,
        [Parameter(Mandatory)][string]$ToColor,
        [double]$Blend = 0.5
    )

    $fromHsl = Convert-RgbToHsl (Convert-HexToRgb $FromColor)
    $toHsl = Convert-RgbToHsl (Convert-HexToRgb $ToColor)

    # Hue wrap handling (shortest path)
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

function Get-ContrastColor {
    param([Parameter(Mandatory)][string]$Hex)

    $rgb = Convert-HexToRgb $Hex
    # Relative luminance approximation
    $lum = (0.2126 * ($rgb.R / 255.0)) + (0.7152 * ($rgb.G / 255.0)) + (0.0722 * ($rgb.B / 255.0))
    if ($lum -gt 0.6) { return '#000000' }
    return '#ffffff'
}

$PalettesFile = Resolve-RepoPath $PalettesFile
$CanonicalTheme = Resolve-RepoPath $CanonicalTheme

if (-not (Test-Path -LiteralPath $PalettesFile)) { throw "Palettes file not found: $PalettesFile" }
if (-not (Test-Path -LiteralPath $CanonicalTheme)) { throw "Canonical theme not found: $CanonicalTheme" }

$palettesDoc = Get-Content -LiteralPath $PalettesFile -Raw | ConvertFrom-Json -Depth 100
$canonicalDoc = Get-Content -LiteralPath $CanonicalTheme -Raw | ConvertFrom-Json -Depth 100

if (-not $palettesDoc.palettes) { throw "Palettes JSON is missing a 'palettes' object." }
if (-not $canonicalDoc.palette) { throw "Canonical theme JSON is missing a 'palette' object." }

$canonicalKeyOrder = @($canonicalDoc.palette.PSObject.Properties.Name)
$canonicalDefaults = @{}
foreach ($p in $canonicalDoc.palette.PSObject.Properties) {
    $canonicalDefaults[$p.Name] = $p.Value
}

# Divider rules (derived)
$dividerCopyMap = @{
    'divider_accent'               = 'accent'
    'divider_blue_time'            = 'blue_time'
    'divider_blue_tooltip'         = 'blue_tooltip'
    'divider_chart_teal'           = 'chart_teal'
    'divider_gray_os'              = 'gray_os'
    'divider_gray_prompt_count_bg' = 'gray_prompt_count_bg'
    'divider_green_added'          = 'green_added'
    'divider_green_ahead'          = 'green_ahead'
    'divider_green_valid_line'     = 'green_valid_line'
    'divider_navy_text'            = 'navy_text'
    'divider_npm_dark'             = 'npm_dark'
    'divider_purple_ahead'         = 'purple_ahead'
    'divider_purple_exec'          = 'purple_exec'
    'divider_tailwind_cyan'        = 'tailwind_cyan'
    'divider_teal_sysinfo'         = 'teal_sysinfo'
    'divider_tooling_yellow'       = 'tooling_yellow'
    'divider_violet_project'       = 'violet_project'
    'divider_red_alert_to_orange'  = $null # handled in blend map
}

$dividerBlendMap = [ordered]@{
    'divider_blue_primary_to_red_alert'                = @('blue_primary', 'red_alert')
    'divider_blue_primary_to_tooling_purple'           = @('blue_primary', 'tooling_purple')
    'divider_tooling_purple_to_typescript_eslint_pink' = @('tooling_purple', 'typescript_eslint_pink')
    'divider_typescript_eslint_pink_to_orange'         = @('typescript_eslint_pink', 'orange')
    'divider_orange_to_green_added'                    = @('orange', 'green_added')
    'divider_green_added_to_yellow_bright'             = @('green_added', 'yellow_bright')
    'divider_yellow_bright_to_navy_text'               = @('yellow_bright', 'navy_text')
    'divider_navy_text_to_purple_exec'                 = @('navy_text', 'purple_exec')
    'divider_purple_exec_to_electron_red'              = @('purple_exec', 'electron_red')
    'divider_blue_time_to_electron_red'                = @('blue_time', 'electron_red')
    'divider_blue_time_to_violet_project'              = @('blue_time', 'violet_project')
    'divider_electron_red_to_maroon_error'             = @('electron_red', 'maroon_error')
    'divider_gray_os_to_electron_red'                  = @('gray_os', 'electron_red')
    'divider_gray_os_to_gray_prompt_count_bg'          = @('gray_os', 'gray_prompt_count_bg')
    'divider_maroon_error_to_pink_weather'             = @('maroon_error', 'pink_weather')
    'divider_teal_sysinfo_to_electron_red'             = @('teal_sysinfo', 'electron_red')
    # Optional (used by some older experimental logic)
    'divider_blue_primary_to_ipify_purple'             = @('blue_primary', 'ipify_purple')
    'divider_ipify_purple_to_typescript_eslint_pink'   = @('ipify_purple', 'typescript_eslint_pink')
    'divider_red_alert_to_orange'                      = @('red_alert', 'orange')
}

$paletteNames = @($palettesDoc.palettes.PSObject.Properties.Name)
Write-Host "🎨 Normalizing palettes: $($paletteNames.Count)" -ForegroundColor Cyan
Write-Host "  Canonical theme: $CanonicalTheme" -ForegroundColor DarkGray
Write-Host "  Palettes file:   $PalettesFile" -ForegroundColor DarkGray
Write-Host "  Blend:           $BlendPercentage" -ForegroundColor DarkGray

$anyWouldChange = $false

foreach ($name in $paletteNames) {
    $paletteInfo = $palettesDoc.palettes.$name
    if (-not $paletteInfo) { continue }

    # Convert to hashtable for easy mutation
    $existing = @{}
    foreach ($prop in $paletteInfo.palette.PSObject.Properties) {
        $existing[$prop.Name] = $prop.Value
    }

    $wouldChange = $false
    $changeReasons = New-Object System.Collections.Generic.List[string]

    # Fill missing keys from canonical defaults
    foreach ($k in $canonicalKeyOrder) {
        if (-not $existing.ContainsKey($k)) {
            $wouldChange = $true
            $changeReasons.Add("missing '$k'")
            $existing[$k] = $canonicalDefaults[$k]
        }
    }

    # Derived: debug colors (accent background by design)
    $expectedDebugBg = $existing['accent']
    $expectedDebugFg = Get-ContrastColor $expectedDebugBg

    if (-not $existing.ContainsKey('debug_bg') -or $existing['debug_bg'] -ne $expectedDebugBg) {
        $wouldChange = $true
        $changeReasons.Add('debug_bg')
    }
    if (-not $existing.ContainsKey('debug_fg') -or $existing['debug_fg'] -ne $expectedDebugFg) {
        $wouldChange = $true
        $changeReasons.Add('debug_fg')
    }

    $existing['debug_bg'] = $expectedDebugBg
    $existing['debug_fg'] = $expectedDebugFg

    # Derived: Copilot default background (used when unlimited)
    if ($existing.ContainsKey('copilot_bg')) {
        $existing['copilot_bg'] = if ($existing.ContainsKey('violet_project')) { $existing['violet_project'] }
        elseif ($existing.ContainsKey('purple_session')) { $existing['purple_session'] }
        else { $existing['accent'] }
    }

    # Divider copies
    foreach ($k in $dividerCopyMap.Keys) {
        $src = $dividerCopyMap[$k]
        if ($src -and $existing.ContainsKey($src)) {
            if (-not $existing.ContainsKey($k) -or $existing[$k] -ne $existing[$src]) {
                $wouldChange = $true
                $changeReasons.Add($k)
            }
            $existing[$k] = $existing[$src]
        }
    }

    # Divider blends
    foreach ($pair in $dividerBlendMap.GetEnumerator()) {
        $targetKey = $pair.Key
        $fromKey, $toKey = $pair.Value

        # Only compute if target exists in canonical or already present.
        if (-not $canonicalDefaults.ContainsKey($targetKey) -and -not $existing.ContainsKey($targetKey)) { continue }

        if (-not $existing.ContainsKey($fromKey) -or -not $existing.ContainsKey($toKey)) {
            # Fall back to canonical defaults if missing
            if (-not $existing.ContainsKey($fromKey) -and $canonicalDefaults.ContainsKey($fromKey)) { $existing[$fromKey] = $canonicalDefaults[$fromKey] }
            if (-not $existing.ContainsKey($toKey) -and $canonicalDefaults.ContainsKey($toKey)) { $existing[$toKey] = $canonicalDefaults[$toKey] }
        }

        if ($existing.ContainsKey($fromKey) -and $existing.ContainsKey($toKey)) {
            $expected = Get-InterpolatedColor -FromColor $existing[$fromKey] -ToColor $existing[$toKey] -Blend $BlendPercentage
            if (-not $existing.ContainsKey($targetKey) -or $existing[$targetKey] -ne $expected) {
                $wouldChange = $true
                $changeReasons.Add($targetKey)
            }
            $existing[$targetKey] = $expected
        }
    }

    # Multi-step derived divider keys
    if ($canonicalDefaults.ContainsKey('divider_root_in_2')) {
        if (-not $existing.ContainsKey('divider_blue_primary_to_red_alert')) {
            $existing['divider_blue_primary_to_red_alert'] = Get-InterpolatedColor -FromColor $existing['blue_primary'] -ToColor $existing['red_alert'] -Blend $BlendPercentage
        }
        $expected = Get-InterpolatedColor -FromColor $existing['divider_blue_primary_to_red_alert'] -ToColor $existing['red_alert'] -Blend $BlendPercentage
        if (-not $existing.ContainsKey('divider_root_in_2') -or $existing['divider_root_in_2'] -ne $expected) {
            $wouldChange = $true
            $changeReasons.Add('divider_root_in_2')
        }
        $existing['divider_root_in_2'] = $expected
    }
    if ($canonicalDefaults.ContainsKey('divider_root_out_1')) {
        $expected = Get-InterpolatedColor -FromColor $existing['red_alert'] -ToColor $existing['tooling_purple'] -Blend $BlendPercentage
        if (-not $existing.ContainsKey('divider_root_out_1') -or $existing['divider_root_out_1'] -ne $expected) {
            $wouldChange = $true
            $changeReasons.Add('divider_root_out_1')
        }
        $existing['divider_root_out_1'] = $expected
    }
    if ($canonicalDefaults.ContainsKey('divider_root_out_2')) {
        $expected = Get-InterpolatedColor -FromColor $existing['tooling_purple'] -ToColor $existing['typescript_eslint_pink'] -Blend $BlendPercentage
        if (-not $existing.ContainsKey('divider_root_out_2') -or $existing['divider_root_out_2'] -ne $expected) {
            $wouldChange = $true
            $changeReasons.Add('divider_root_out_2')
        }
        $existing['divider_root_out_2'] = $expected
    }

    # Rebuild palette object in a stable order (canonical keys first)
    $ordered = [ordered]@{}
    foreach ($k in $canonicalKeyOrder) {
        $ordered[$k] = $existing[$k]
    }

    foreach ($k in ($existing.Keys | Sort-Object)) {
        if (-not $ordered.Contains($k)) {
            $ordered[$k] = $existing[$k]
        }
    }

    $paletteInfo.palette = [pscustomobject]$ordered

    if ($Check -and $wouldChange) {
        $anyWouldChange = $true
        Write-Host "❌ Palette '$name' is not normalized: $($changeReasons | Select-Object -Unique | Sort-Object -CaseSensitive | Join-String -Separator ', ')" -ForegroundColor Red
    }
}

if ($Check) {
    if ($anyWouldChange) {
        Write-Host '❌ Palettes are NOT normalized. Run: pwsh .\scripts\Normalize-Palettes.ps1 -Backup' -ForegroundColor Red
        exit 2
    }
    Write-Host '✅ Palettes are normalized.' -ForegroundColor Green
    exit 0
}

if ($Backup) {
    Copy-Item -LiteralPath $PalettesFile -Destination "$PalettesFile.bak" -Force
    Write-Host "📦 Backup written: $PalettesFile.bak" -ForegroundColor Yellow
}

$palettesDoc | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $PalettesFile -Encoding UTF8
Write-Host '✅ Palettes normalized.' -ForegroundColor Green
