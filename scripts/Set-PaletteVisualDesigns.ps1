<#
.SYNOPSIS
Applies the curated visible-role color ramps to every generated palette.

.DESCRIPTION
The palette file contains many legacy semantic key names whose original hue no
longer describes how the key is used. This script treats those keys as visual
slots, applies the hand-reviewed ramps in Palette-Visual-Designs.json, and
propagates the ramp to related non-brand prompt roles. Vendor colors such as
AWS, Azure, Docker, Spotify, and YouTube remain untouched.

Run Normalize-Palettes.ps1 after this script so divider blends are rebuilt from
the updated role colors. Use -SyncRootThemes after normalization to copy the
normalized Original palette into all six complete root themes without
rewriting their prompt structure.
#>

[CmdletBinding()]
param(
    [string]$PalettesFile = 'color-palette-alternatives.json',
    [string]$DesignsFile = 'scripts/Palette-Visual-Designs.json',
    [string[]]$RootThemePaths = @(
        'OhMyPosh-Atomic-Custom.json',
        '1_shell-Enhanced.omp.json',
        'slimfat-Enhanced.omp.json',
        'atomicBit-Enhanced.omp.json',
        'clean-detailed-Enhanced.omp.json',
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'
    ),
    [switch]$SyncRootThemes,
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
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Hex)

    if ($Hex -notmatch '^#(?<r>[0-9a-fA-F]{2})(?<g>[0-9a-fA-F]{2})(?<b>[0-9a-fA-F]{2})$') {
        throw "Invalid #RRGGBB color '$Hex'."
    }

    return [pscustomobject]@{
        R = [Convert]::ToInt32($Matches.r, 16)
        G = [Convert]::ToInt32($Matches.g, 16)
        B = [Convert]::ToInt32($Matches.b, 16)
    }
}

function Mix-Color {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$From,
        [Parameter(Mandatory)][string]$To,
        [ValidateRange(0.0, 1.0)][double]$Amount
    )

    $fromRgb = Convert-HexToRgb $From
    $toRgb = Convert-HexToRgb $To
    $red = [int][math]::Round($fromRgb.R + (($toRgb.R - $fromRgb.R) * $Amount))
    $green = [int][math]::Round($fromRgb.G + (($toRgb.G - $fromRgb.G) * $Amount))
    $blue = [int][math]::Round($fromRgb.B + (($toRgb.B - $fromRgb.B) * $Amount))
    return '#{0:x2}{1:x2}{2:x2}' -f $red, $green, $blue
}

function Get-RelativeLuminance {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Hex)

    $rgb = Convert-HexToRgb $Hex
    $channels = foreach ($value in @($rgb.R, $rgb.G, $rgb.B)) {
        $normalized = $value / 255.0
        if ($normalized -le 0.04045) { $normalized / 12.92 }
        else { [math]::Pow(($normalized + 0.055) / 1.055, 2.4) }
    }

    return (0.2126 * $channels[0]) + (0.7152 * $channels[1]) + (0.0722 * $channels[2])
}

function Get-ContrastRatio {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$First,
        [Parameter(Mandatory)][string]$Second
    )

    $firstLuminance = Get-RelativeLuminance $First
    $secondLuminance = Get-RelativeLuminance $Second
    $lighter = [math]::Max($firstLuminance, $secondLuminance)
    $darker = [math]::Min($firstLuminance, $secondLuminance)
    return ($lighter + 0.05) / ($darker + 0.05)
}

function Get-ContrastAdjustedColor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Color,
        [Parameter(Mandatory)][string]$Foreground,
        [Parameter(Mandatory)][string]$Toward,
        [Parameter(Mandatory)][double]$MinimumContrast
    )

    if ((Get-ContrastRatio $Color $Foreground) -ge $MinimumContrast) { return $Color }
    if ((Get-ContrastRatio $Toward $Foreground) -lt $MinimumContrast) {
        throw "Cannot adjust $Color toward $Toward to reach ${MinimumContrast}:1 against $Foreground."
    }

    $low = 0.0
    $high = 1.0
    for ($iteration = 0; $iteration -lt 16; $iteration++) {
        $mid = ($low + $high) / 2.0
        $candidate = Mix-Color -From $Color -To $Toward -Amount $mid
        if ((Get-ContrastRatio $candidate $Foreground) -ge $MinimumContrast) { $high = $mid }
        else { $low = $mid }
    }

    return Mix-Color -From $Color -To $Toward -Amount $high
}

function Set-PaletteValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Palette,
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][string]$Value
    )

    if (-not $Palette.PSObject.Properties[$Key]) {
        throw "Palette is missing required key '$Key'. Run Normalize-Palettes.ps1 first."
    }
    $Palette.$Key = $Value
}

function Get-ReplacedTopLevelPalette {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RawTheme,
        [Parameter(Mandatory)][pscustomobject]$Palette
    )

    $match = [regex]::Match($RawTheme, '(?m)^(?<indent>[ \t]*)"palette"[ \t]*:[ \t]*\{')
    if (-not $match.Success) { throw 'Theme is missing a top-level palette object.' }

    $openingBrace = $match.Index + $match.Value.LastIndexOf('{')
    $depth = 0
    $inString = $false
    $escaped = $false
    $closingBrace = -1

    for ($index = $openingBrace; $index -lt $RawTheme.Length; $index++) {
        $character = $RawTheme[$index]
        if ($inString) {
            if ($escaped) { $escaped = $false; continue }
            if ($character -eq '\') { $escaped = $true; continue }
            if ($character -eq '"') { $inString = $false }
            continue
        }

        if ($character -eq '"') { $inString = $true; continue }
        if ($character -eq '{') { $depth++; continue }
        if ($character -eq '}') {
            $depth--
            if ($depth -eq 0) { $closingBrace = $index; break }
        }
    }

    if ($closingBrace -lt 0) { throw 'Could not find the end of the top-level palette object.' }

    $newline = if ($RawTheme.Contains("`r`n")) { "`r`n" } else { "`n" }
    $indent = $match.Groups['indent'].Value
    $paletteLines = @($Palette | ConvertTo-Json -Depth 20) -split "`r?`n"
    $formattedLines = @($paletteLines[0])
    if ($paletteLines.Count -gt 2) {
        $formattedLines += $paletteLines[1..($paletteLines.Count - 2)] | ForEach-Object { "$indent$_" }
    }
    $formattedLines += "$indent$($paletteLines[-1])"
    $formattedPalette = $formattedLines -join $newline

    return $RawTheme.Substring(0, $openingBrace) + $formattedPalette + $RawTheme.Substring($closingBrace + 1)
}

$PalettesFile = Resolve-RepoPath $PalettesFile
$DesignsFile = Resolve-RepoPath $DesignsFile
$RootThemePaths = @($RootThemePaths | ForEach-Object { Resolve-RepoPath $_ })

foreach ($requiredFile in @($PalettesFile, $DesignsFile)) {
    if (-not (Test-Path -LiteralPath $requiredFile)) { throw "Required file not found: $requiredFile" }
}

$palettesDocument = Get-Content -LiteralPath $PalettesFile -Raw | ConvertFrom-Json -Depth 100
$designsDocument = Get-Content -LiteralPath $DesignsFile -Raw | ConvertFrom-Json -Depth 100
$minimumContrast = [double]$designsDocument.minimum_contrast

$paletteNames = @($palettesDocument.palettes.PSObject.Properties.Name)
$designNames = @($designsDocument.palettes.PSObject.Properties.Name)
$missingDesigns = @($paletteNames | Where-Object { $_ -notin $designNames })
$extraDesigns = @($designNames | Where-Object { $_ -notin $paletteNames })
if ($missingDesigns.Count -or $extraDesigns.Count) {
    throw "Visual-design coverage mismatch. Missing: $($missingDesigns -join ', '); extra: $($extraDesigns -join ', ')."
}

$designRoleNames = @($designsDocument.roles.PSObject.Properties.Name)
$changedPalettes = New-Object System.Collections.Generic.List[string]

foreach ($paletteName in $paletteNames) {
    $paletteInfo = $palettesDocument.palettes.$paletteName
    $palette = $paletteInfo.palette
    $design = $designsDocument.palettes.$paletteName
    $before = $palette | ConvertTo-Json -Depth 20 -Compress

    foreach ($roleName in $designRoleNames) {
        $roleValue = $design.$roleName
        if ($roleValue -notmatch '^#[0-9a-fA-F]{6}$') {
            throw "Palette '$paletteName' has an invalid '$roleName' design value: '$roleValue'."
        }
        Set-PaletteValue $palette $roleName $roleValue
    }

    $black = $palette.black
    $white = $palette.white
    $navy = $palette.navy_text
    $danger = Get-ContrastAdjustedColor -Color $palette.red_alert -Foreground $black -Toward $white -MinimumContrast $minimumContrast
    $errorDark = Get-ContrastAdjustedColor -Color $palette.maroon_error -Foreground $white -Toward $black -MinimumContrast $minimumContrast
    $success = Get-ContrastAdjustedColor -Color $palette.green_added -Foreground $black -Toward $white -MinimumContrast $minimumContrast
    $project = Mix-Color -From $palette.purple_exec -To $palette.pink_weather -Amount 0.68
    $project = Get-ContrastAdjustedColor -Color $project -Foreground $black -Toward $white -MinimumContrast $minimumContrast
    $promptBackground = Mix-Color -From $black -To $white -Amount 0.12
    foreach ($promptForeground in @($white, $palette.blue_time, $palette.yellow_bright, $success)) {
        $promptBackground = Get-ContrastAdjustedColor -Color $promptBackground -Foreground $promptForeground -Toward $black -MinimumContrast $minimumContrast
    }
    $terminalAccent = Get-ContrastAdjustedColor -Color $palette.accent -Foreground '#000000' -Toward $white -MinimumContrast $minimumContrast

    $derivedValues = [ordered]@{
        accent                  = $terminalAccent
        blue_tooltip            = $palette.blue_time
        chart_teal              = $palette.teal_sysinfo
        windows_blue            = $palette.blue_primary
        python_blue             = $palette.blue_primary
        typescript_blue         = $palette.blue_time
        java_blue               = $palette.blue_primary
        shell_powershell_blue   = $palette.blue_primary
        blue_bright             = $palette.blue_time
        react_cyan              = $palette.blue_time
        tailwind_cyan           = $palette.teal_sysinfo
        playwright_teal         = $palette.teal_sysinfo
        orange_unmerged         = $palette.orange
        java_orange             = $palette.orange_battery
        orange_warning          = $palette.orange_battery
        yellow_git_changed      = $palette.yellow_bright
        yellow_modified         = $palette.yellow_bright
        yellow_root_alt         = $palette.yellow_bright
        yellow_discharging      = $palette.yellow_bright
        yellow_update           = $palette.yellow_bright
        npm_yellow              = $palette.yellow_bright
        prettier_yellow         = $palette.yellow_bright
        vite_yellow             = $palette.yellow_bright
        axios_yellow            = $palette.yellow_bright
        tooling_yellow          = $palette.yellow_bright
        python_yellow           = $palette.yellow_bright
        purple_ahead            = $project
        purple_session          = $project
        violet_project          = $project
        tooling_purple          = $project
        eslint_purple           = $project
        ipify_purple            = $project
        ipify_purple_v6         = $project
        zustand_purple          = $project
        purple_modified         = $project
        purple_behind           = $palette.blue_time
        typescript_eslint_pink  = $palette.pink_weather
        magenta_copied          = $palette.pink_weather
        magenta                 = $palette.pink_weather
        pink_storybook          = $palette.pink_weather
        red_alert               = $danger
        red_deleted             = $danger
        red                     = $danger
        electron_red            = $danger
        pink_error_line         = $danger
        pink_status_fail        = $danger
        maroon_error            = $errorDark
        green_added             = $success
        green_ahead             = $success
        green_charging          = $success
        green_full              = $success
        green_help              = $success
        green_success           = $success
        node_green              = $success
        vitest_green            = $success
        gray_path_fg            = $palette.gray_os_fg
        gray_prompt_count_bg    = $promptBackground
        gray_prompt_count_fg    = $white
        gray_untracked          = $palette.gray_os
        npm_dark                = $navy
        prettier_black          = $navy
        sysinfo_bg_ok           = $palette.teal_sysinfo
        sysinfo_bg_warn         = $palette.orange_battery
        sysinfo_bg_crit         = $danger
        sysinfo_warn            = $palette.yellow_bright
        sysinfo_crit            = $danger
        time_fg_day             = $navy
        time_fg_night           = $navy
        battery_crit_fg         = $navy
        copilot_bg              = $palette.purple_exec
        exec_warning            = $palette.yellow_bright
        exec_warn5              = $palette.yellow_bright
        exec_warn10             = $palette.yellow_bright
        exec_warn30             = $palette.orange_battery
        exec_warn60             = $palette.orange_battery
        exec_critical           = $danger
        exec_extreme            = $palette.pink_weather
        mem_critical            = $danger
        ver_alpha               = $palette.yellow_bright
        ver_beta                = $palette.orange_battery
        ver_deprecated          = $palette.gray_os
        ver_rc                  = $palette.blue_time
        ver_stable              = $success
    }

    foreach ($entry in $derivedValues.GetEnumerator()) {
        Set-PaletteValue $palette $entry.Key $entry.Value
    }

    $after = $palette | ConvertTo-Json -Depth 20 -Compress
    if ($before -cne $after) { $changedPalettes.Add($paletteName) }
}

$serializedPalettes = $palettesDocument | ConvertTo-Json -Depth 100
$existingPalettes = Get-Content -LiteralPath $PalettesFile -Raw
$sourceWouldChange = $existingPalettes.TrimEnd() -cne $serializedPalettes.TrimEnd()

if ($Check) {
    if ($sourceWouldChange) {
        Write-Error "Palette visual designs are stale: $($changedPalettes -join ', ')"
    }
}
elseif ($sourceWouldChange) {
    $serializedPalettes | Set-Content -LiteralPath $PalettesFile -Encoding utf8
    Write-Host "Applied curated visual roles to $($changedPalettes.Count) palette(s)." -ForegroundColor Green
}
else {
    Write-Host 'Palette visual roles are already current.' -ForegroundColor Green
}

if ($SyncRootThemes) {
    $originalPalette = $palettesDocument.palettes.original.palette
    $staleRoots = New-Object System.Collections.Generic.List[string]
    foreach ($themePath in $RootThemePaths) {
        if (-not (Test-Path -LiteralPath $themePath)) { throw "Root theme not found: $themePath" }
        $rawTheme = Get-Content -LiteralPath $themePath -Raw
        $updatedTheme = Get-ReplacedTopLevelPalette -RawTheme $rawTheme -Palette $originalPalette
        if ($updatedTheme -cne $rawTheme) {
            $staleRoots.Add((Split-Path -Path $themePath -Leaf))
            if (-not $Check) {
                Set-Content -LiteralPath $themePath -Value $updatedTheme -Encoding utf8 -NoNewline
            }
        }
    }

    if ($Check -and $staleRoots.Count) {
        Write-Error "Root Original palettes are stale: $($staleRoots -join ', ')"
    }
    elseif (-not $Check) {
        Write-Host "Synchronized the Original palette into $($RootThemePaths.Count) root themes." -ForegroundColor Green
    }
}

if ($Check) {
    Write-Host 'Palette visual designs are current.' -ForegroundColor Green
}
