<#
.SYNOPSIS
Validates curated palette coverage, identity, synchronization, and contrast.

.DESCRIPTION
This gate focuses on the semantic color roles that are rendered in the six
theme-family previews. It verifies that every palette has an explicit curated
design, that the source values still match that design, that each signature
ramp remains visually distinct, and that filled prompt roles meet WCAG 2.1 AA
normal-text contrast (4.5:1 by default).
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
    )
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

function Resolve-ConfiguredColor {
    [CmdletBinding()]
    param(
        [AllowNull()][AllowEmptyString()][string]$Value,
        [Parameter(Mandatory)][pscustomobject]$Palette,
        [AllowNull()][string]$TransparentFallback
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -eq 'transparent') {
        return $TransparentFallback
    }
    if ($Value -match '^p:(?<key>[A-Za-z0-9_]+)$') {
        $key = $Matches.key
        if (-not $Palette.PSObject.Properties[$key]) {
            throw "Missing palette key '$key'."
        }
        return [string]$Palette.$key
    }
    if ($Value -match '^#[0-9a-fA-F]{6}$') { return $Value }
    throw "Unsupported direct color '$Value'."
}

function Get-PaletteSignature {
    [CmdletBinding()]
    param([Parameter(Mandatory)][pscustomobject]$Palette)

    return (($Palette.PSObject.Properties | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ';')
}

$PalettesFile = Resolve-RepoPath $PalettesFile
$DesignsFile = Resolve-RepoPath $DesignsFile
$RootThemePaths = @($RootThemePaths | ForEach-Object { Resolve-RepoPath $_ })

$palettesDocument = Get-Content -LiteralPath $PalettesFile -Raw | ConvertFrom-Json -Depth 100
$designsDocument = Get-Content -LiteralPath $DesignsFile -Raw | ConvertFrom-Json -Depth 100
$minimumContrast = [double]$designsDocument.minimum_contrast
$errors = New-Object System.Collections.Generic.List[string]

$paletteNames = @($palettesDocument.palettes.PSObject.Properties.Name)
$designNames = @($designsDocument.palettes.PSObject.Properties.Name)
$designRoleNames = @($designsDocument.roles.PSObject.Properties.Name)

if ($paletteNames.Count -ne 38) {
    $errors.Add("Expected 38 palettes, found $($paletteNames.Count).")
}

foreach ($paletteName in $paletteNames) {
    if ($paletteName -notin $designNames) {
        $errors.Add("Palette '$paletteName' has no curated visual design.")
    }
}
foreach ($designName in $designNames) {
    if ($designName -notin $paletteNames) {
        $errors.Add("Visual design '$designName' has no palette source.")
    }
}

$contracts = @(
    @{ Label = 'shell'; Background = 'blue_primary'; Foreground = 'white' },
    @{ Label = 'path'; Background = 'orange'; Foreground = 'black' },
    @{ Label = 'git'; Background = 'yellow_bright'; Foreground = 'navy_text' },
    @{ Label = 'execution'; Background = 'purple_exec'; Foreground = 'white' },
    @{ Label = 'sysinfo'; Background = 'teal_sysinfo'; Foreground = 'black' },
    @{ Label = 'sysinfo-ok'; Background = 'sysinfo_bg_ok'; Foreground = 'black' },
    @{ Label = 'sysinfo-warning'; Background = 'sysinfo_bg_warn'; Foreground = 'black' },
    @{ Label = 'sysinfo-critical'; Background = 'sysinfo_bg_crit'; Foreground = 'black' },
    @{ Label = 'operating-system'; Background = 'gray_os'; Foreground = 'gray_os_fg' },
    @{ Label = 'time'; Background = 'blue_time'; Foreground = 'time_fg_day' },
    @{ Label = 'time-night'; Background = 'blue_time'; Foreground = 'time_fg_night' },
    @{ Label = 'battery'; Background = 'orange_battery'; Foreground = 'black' },
    @{ Label = 'battery-discharging'; Background = 'yellow_discharging'; Foreground = 'battery_crit_fg' },
    @{ Label = 'weather'; Background = 'pink_weather'; Foreground = 'black' },
    @{ Label = 'prompt-count'; Background = 'gray_prompt_count_bg'; Foreground = 'gray_prompt_count_fg' },
    @{ Label = 'root'; Background = 'red_alert'; Foreground = 'black' },
    @{ Label = 'status'; Background = 'maroon_error'; Foreground = 'white' },
    @{ Label = 'node'; Background = 'node_green'; Foreground = 'black' },
    @{ Label = 'python'; Background = 'python_blue'; Foreground = 'white' },
    @{ Label = 'java'; Background = 'java_blue'; Foreground = 'white' },
    @{ Label = 'npm'; Background = 'npm_yellow'; Foreground = 'npm_dark' },
    @{ Label = 'upgrade'; Background = 'yellow_update'; Foreground = 'gray_os_fg' },
    @{ Label = 'copilot'; Background = 'copilot_bg'; Foreground = 'white' }
)

$terminalForegroundRoles = @(
    'accent',
    'blue_time',
    'gray_untracked',
    'green_added',
    'green_ahead',
    'green_charging',
    'green_success',
    'orange',
    'pink_weather',
    'purple_ahead',
    'purple_behind',
    'purple_session',
    'red_alert',
    'typescript_blue',
    'violet_project',
    'white',
    'yellow_bright',
    'yellow_git_changed',
    'yellow_modified'
)

$signatureRoles = @(
    'blue_primary', 'orange', 'yellow_bright', 'purple_exec', 'teal_sysinfo',
    'gray_os', 'blue_time', 'orange_battery', 'pink_weather'
)

foreach ($paletteName in $paletteNames) {
    $palette = $palettesDocument.palettes.$paletteName.palette
    if ($paletteName -in $designNames) {
        $design = $designsDocument.palettes.$paletteName
        foreach ($roleName in $designRoleNames) {
            if (-not $palette.PSObject.Properties[$roleName]) {
                $errors.Add("${paletteName}: missing curated role '$roleName'.")
                continue
            }
            if ($palette.$roleName -cne $design.$roleName) {
                $errors.Add("${paletteName}: '$roleName' drifted from $($design.$roleName) to $($palette.$roleName).")
            }
        }
    }

    $uniqueSignatureColors = @($signatureRoles | ForEach-Object { $palette.$_ } | Select-Object -Unique)
    if ($uniqueSignatureColors.Count -lt 6) {
        $errors.Add("${paletteName}: signature ramp collapsed to only $($uniqueSignatureColors.Count) distinct colors.")
    }

    foreach ($contract in $contracts) {
        $backgroundKey = $contract.Background
        $foregroundKey = $contract.Foreground
        if (-not $palette.PSObject.Properties[$backgroundKey] -or -not $palette.PSObject.Properties[$foregroundKey]) {
            $errors.Add("$paletteName/$($contract.Label): missing '$backgroundKey' or '$foregroundKey'.")
            continue
        }
        try {
            $ratio = Get-ContrastRatio $palette.$backgroundKey $palette.$foregroundKey
            if ($ratio -lt $minimumContrast) {
                $errors.Add(('{0}/{1}: {2} {3} against {4} {5} is {6:N2}:1, below {7:N1}:1.' -f
                        $paletteName, $contract.Label, $backgroundKey, $palette.$backgroundKey,
                        $foregroundKey, $palette.$foregroundKey, $ratio, $minimumContrast))
            }
        }
        catch {
            $errors.Add("$paletteName/$($contract.Label): $($_.Exception.Message)")
        }
    }

    foreach ($foregroundKey in $terminalForegroundRoles) {
        if (-not $palette.PSObject.Properties[$foregroundKey]) {
            $errors.Add("${paletteName}: missing terminal foreground '$foregroundKey'.")
            continue
        }
        $ratio = Get-ContrastRatio $palette.$foregroundKey '#000000'
        if ($ratio -lt $minimumContrast) {
            $errors.Add(('{0}/terminal: {1} {2} against #000000 is {3:N2}:1, below {4:N1}:1.' -f
                    $paletteName, $foregroundKey, $palette.$foregroundKey, $ratio, $minimumContrast))
        }
    }
}

$originalPaletteJson = $palettesDocument.palettes.original.palette | ConvertTo-Json -Depth 20 -Compress
foreach ($rootThemePath in $RootThemePaths) {
    if (-not (Test-Path -LiteralPath $rootThemePath)) {
        $errors.Add("Missing root theme: $rootThemePath")
        continue
    }
    $rootTheme = Get-Content -LiteralPath $rootThemePath -Raw | ConvertFrom-Json -Depth 100
    $rootPaletteJson = $rootTheme.palette | ConvertTo-Json -Depth 20 -Compress
    if ($rootPaletteJson -cne $originalPaletteJson) {
        $errors.Add("$(Split-Path -Path $rootThemePath -Leaf): Original palette is not synchronized with $PalettesFile.")
    }
}

# Traverse the direct/fallback colors actually configured in every block. This
# catches root usage drift (for example, accidentally pairing a dark background
# role with dark text) that a source-only contract cannot detect.
$previewSettingsPath = Resolve-RepoPath 'image.settings.json'
$previewSettings = Get-Content -LiteralPath $previewSettingsPath -Raw | ConvertFrom-Json -Depth 20
$terminalBackground = [string]$previewSettings.background_color
$directContractCount = 0

foreach ($rootThemePath in $RootThemePaths) {
    $rootTheme = Get-Content -LiteralPath $rootThemePath -Raw | ConvertFrom-Json -Depth 100
    $rootName = Split-Path -Path $rootThemePath -Leaf
    for ($blockIndex = 0; $blockIndex -lt $rootTheme.blocks.Count; $blockIndex++) {
        $block = $rootTheme.blocks[$blockIndex]
        for ($segmentIndex = 0; $segmentIndex -lt $block.segments.Count; $segmentIndex++) {
            $segment = $block.segments[$segmentIndex]
            $foregroundProperty = $segment.PSObject.Properties['foreground']
            if (-not $foregroundProperty) { continue }
            $foregroundValue = [string]$foregroundProperty.Value
            if ([string]::IsNullOrWhiteSpace($foregroundValue) -or $foregroundValue -eq 'transparent') { continue }
            $backgroundProperty = $segment.PSObject.Properties['background']
            $backgroundValue = if ($backgroundProperty) { [string]$backgroundProperty.Value } else { '' }

            foreach ($paletteProperty in $palettesDocument.palettes.PSObject.Properties) {
                $paletteName = $paletteProperty.Name
                $palette = $paletteProperty.Value.palette
                try {
                    $foreground = Resolve-ConfiguredColor -Value $foregroundValue -Palette $palette -TransparentFallback $null
                    $background = Resolve-ConfiguredColor -Value $backgroundValue -Palette $palette -TransparentFallback $terminalBackground
                    $ratio = Get-ContrastRatio $foreground $background
                    $directContractCount++
                    if ($ratio -lt $minimumContrast) {
                        $aliasProperty = $segment.PSObject.Properties['alias']
                        $segmentName = if ($aliasProperty -and $aliasProperty.Value) { [string]$aliasProperty.Value } else { [string]$segment.type }
                        $errors.Add(('{0}/{1}/block[{2}]/segment[{3}] {4}: foreground {5} ({6}) against background {7} ({8}) is {9:N2}:1.' -f
                                $rootName, $paletteName, $blockIndex, $segmentIndex, $segmentName,
                                $foregroundValue, $foreground, $backgroundValue, $background, $ratio))
                    }
                }
                catch {
                    $errors.Add("$rootName/$paletteName/block[$blockIndex]/segment[$segmentIndex]: $($_.Exception.Message)")
                }
            }
        }
    }
}

# Prove that all six generated folders contain the current 37 non-Original
# source palettes. Matching by a normalized key/value signature avoids relying
# on filename transliteration rules while still detecting stale values exactly.
$generatedDirectories = @('atomic', '1_shell', 'slimfat', 'atomicBit', 'cleanDetailed', 'experimentalDividers')
$expectedPaletteBySignature = @{}
$nonOriginalPaletteProperties = @($palettesDocument.palettes.PSObject.Properties | Where-Object Name -ne 'original')
foreach ($paletteProperty in $nonOriginalPaletteProperties) {
    $signature = Get-PaletteSignature $paletteProperty.Value.palette
    if ($expectedPaletteBySignature.ContainsKey($signature)) {
        $errors.Add("Palettes '$($expectedPaletteBySignature[$signature])' and '$($paletteProperty.Name)' have identical full definitions.")
    }
    else {
        $expectedPaletteBySignature[$signature] = $paletteProperty.Name
    }
}

$generatedOverlayCount = 0
foreach ($directoryName in $generatedDirectories) {
    $directoryPath = Resolve-RepoPath $directoryName
    $overlayFiles = @(Get-ChildItem -LiteralPath $directoryPath -Filter '*.json' -File)
    if ($overlayFiles.Count -ne 37) {
        $errors.Add("${directoryName}: expected 37 generated overlays, found $($overlayFiles.Count).")
    }

    $seenPalettes = @{}
    foreach ($overlayFile in $overlayFiles) {
        try {
            $overlay = Get-Content -LiteralPath $overlayFile.FullName -Raw | ConvertFrom-Json -Depth 100
            if (-not $overlay.palette) { throw 'Generated overlay has no palette object.' }
            $matchingPaletteNames = @(
                foreach ($paletteProperty in $nonOriginalPaletteProperties) {
                    $matchesSource = $true
                    foreach ($sourceColor in $paletteProperty.Value.palette.PSObject.Properties) {
                        $overlayColor = $overlay.palette.PSObject.Properties[$sourceColor.Name]
                        if (-not $overlayColor -or [string]$overlayColor.Value -cne [string]$sourceColor.Value) {
                            $matchesSource = $false
                            break
                        }
                    }
                    if ($matchesSource) { $paletteProperty.Name }
                }
            )
            if ($matchingPaletteNames.Count -ne 1) {
                throw "Generated palette matches $($matchingPaletteNames.Count) current non-Original palette sources; expected exactly one."
            }
            $paletteName = $matchingPaletteNames[0]
            if ($seenPalettes.ContainsKey($paletteName)) {
                throw "Palette '$paletteName' appears more than once in this family."
            }
            $seenPalettes[$paletteName] = $overlayFile.Name
            $generatedOverlayCount++
        }
        catch {
            $errors.Add("$directoryName/$($overlayFile.Name): $($_.Exception.Message)")
        }
    }

    foreach ($paletteName in $designNames | Where-Object { $_ -ne 'original' }) {
        if (-not $seenPalettes.ContainsKey($paletteName)) {
            $errors.Add("${directoryName}: missing current generated palette '$paletteName'.")
        }
    }
}

if ($errors.Count) {
    Write-Host "Palette visual-quality validation failed ($($errors.Count) issue(s)):" -ForegroundColor Red
    foreach ($message in $errors) { Write-Host "  - $message" -ForegroundColor Red }
    exit 1
}

Write-Host "Palette visual-quality validation passed: $($paletteNames.Count) curated palettes, $directContractCount direct six-family contrast evaluations, and $generatedOverlayCount synchronized overlays." -ForegroundColor Green
