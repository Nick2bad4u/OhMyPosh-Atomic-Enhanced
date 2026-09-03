<#
.SYNOPSIS
    Merges Oh My Posh theme styling from official themes into a custom theme structure.

.DESCRIPTION
    This script takes the structure/framework (blocks, tooltips, segments, positioning) from a custom theme
    and applies the visual styling (colors, templates, icons) from official themes. It preserves all
    custom functionality while adopting the aesthetic of official themes.

.PARAMETER CustomThemePath
    Path to your custom theme JSON file (the "harness" or structure to preserve)

.PARAMETER OfficialThemePath
    Path to an official theme JSON file, or a directory containing multiple official themes

.PARAMETER OutputPath
    Directory where merged theme files will be saved

.PARAMETER ProcessAll
    If specified, processes all .omp.json files in the OfficialThemePath directory

.EXAMPLE
    .\scripts\Merge-OhMyPoshThemes.ps1 -CustomThemePath .\OhMyPosh-Atomic-Custom.json -OfficialThemePath .\ohmyposh-official-themes\themes\dracula.omp.json -OutputPath .\output

.EXAMPLE
    .\scripts\Merge-OhMyPoshThemes.ps1 -CustomThemePath .\OhMyPosh-Atomic-Custom.json -OfficialThemePath .\ohmyposh-official-themes\themes -OutputPath .\output -ProcessAll

.NOTES
    Author: GitHub Copilot
    Date: October 22, 2025
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CustomThemePath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$OfficialThemePath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$ProcessAll
)

#region Helper Functions

# Load System.Drawing for color manipulation utilities
try {
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
}
catch {
    Write-Verbose "System.Drawing already loaded or unavailable: $_"
}

function Write-MergeMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter()]
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::Gray,

        [Parameter()]
        [switch]$NoNewline
    )

    $hostMessage = [Management.Automation.HostInformationMessage]@{
        Message         = $Message
        ForegroundColor = $ForegroundColor
        NoNewline       = $NoNewline.IsPresent
    }
    Write-Information -MessageData $hostMessage -InformationAction Continue
}

function Get-ColorFromHex {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Hex
    )

    if ([string]::IsNullOrWhiteSpace($Hex)) {
        return $null
    }

    try {
        return [System.Drawing.ColorTranslator]::FromHtml($Hex)
    }
    catch {
        return $null
    }
}

function Get-ColorHue {
    param(
        [string]$Hex
    )

    $color = Get-ColorFromHex -Hex $Hex
    if ($null -eq $color) {
        return $null
    }

    return [math]::Round($color.GetHue(),2)
}

function Get-ColorBrightness {
    param(
        [string]$Hex
    )

    $color = Get-ColorFromHex -Hex $Hex
    if ($null -eq $color) {
        return $null
    }

    return $color.GetBrightness()
}

function Get-AdjustedColor {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Hex,

        [Parameter(Mandatory = $true)]
        [double]$Factor
    )

    $color = Get-ColorFromHex -Hex $Hex
    if ($null -eq $color) {
        return $Hex
    }

    $adjustComponent = {
        param($component,$factor)
        $value = [math]::Max([math]::Min($component + (255 * $factor),255),0)
        return [int][math]::Round($value)
    }

    $r = & $adjustComponent $color.R $Factor
    $g = & $adjustComponent $color.G $Factor
    $b = & $adjustComponent $color.B $Factor

    return "#{0:X2}{1:X2}{2:X2}" -f $r,$g,$b
}

function Get-ContrastColor {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Hex
    )

    $color = Get-ColorFromHex -Hex $Hex
    if ($null -eq $color) {
        return '#ffffff'
    }

    $luminance = (0.299 * $color.R + 0.587 * $color.G + 0.114 * $color.B) / 255
    if ($luminance -gt 0.6) {
        return '#000000'
    }

    return '#ffffff'
}

function Get-ResolvedColorValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,

        [Parameter(Mandatory = $false)]
        [hashtable]$Palette
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    if ($Value -match '^#([0-9a-fA-F]{3,8})$') {
        return $Value.ToUpper()
    }

    if ($Value -match '^p:(.+)$' -and $Palette) {
        $paletteKey = $Matches[1]
        if ($Palette.ContainsKey($paletteKey)) {
            $paletteColor = $Palette[$paletteKey]
            if ($paletteColor -match '^#') {
                return $paletteColor.ToUpper()
            }
        }
    }

    return $null
}

function Select-ColorByHueRange {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Colors,

        [Parameter(Mandatory = $true)]
        [double]$MinHue,

        [Parameter(Mandatory = $true)]
        [double]$MaxHue
    )

    foreach ($color in $Colors) {
        $hue = Get-ColorHue -Hex $color
        if ($null -eq $hue) { continue }

        if ($MinHue -le $MaxHue) {
            if ($hue -ge $MinHue -and $hue -le $MaxHue) {
                return $color
            }
        }
        else {
            if ($hue -ge $MinHue -or $hue -le $MaxHue) {
                return $color
            }
        }
    }

    return $null
}

function Get-ColorDistance {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ColorA,

        [Parameter(Mandatory = $true)]
        [string]$ColorB
    )

    $a = Get-ColorFromHex -Hex $ColorA
    $b = Get-ColorFromHex -Hex $ColorB

    if ($null -eq $a -or $null -eq $b) {
        return [double]::PositiveInfinity
    }

    $hueA = $a.GetHue()
    $hueB = $b.GetHue()
    $hueDiff = [math]::Abs($hueA - $hueB)
    if ($hueDiff -gt 180) { $hueDiff = 360 - $hueDiff }

    $satDiff = [math]::Abs($a.GetSaturation() - $b.GetSaturation())
    $brightDiff = [math]::Abs($a.GetBrightness() - $b.GetBrightness())

    # Weighted distance emphasizing hue similarity
    return ($hueDiff / 360.0) * 0.6 + $satDiff * 0.2 + $brightDiff * 0.2
}

function Get-ClosestThemeColor {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetHex,

        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable]$ColorPool
    )

    $targetColor = Get-ColorFromHex -Hex $TargetHex
    if ($null -eq $targetColor) {
        return $null
    }

    $bestColor = $null
    $bestDistance = [double]::PositiveInfinity

    foreach ($candidate in $ColorPool) {
        if (-not $candidate) { continue }
        $distance = Get-ColorDistance -ColorA $TargetHex -ColorB $candidate
        if ($distance -lt $bestDistance) {
            $bestDistance = $distance
            $bestColor = $candidate
        }
    }

    return $bestColor
}

function Add-UniqueColorToPool {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$ColorPool,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$Value
    )

    if ($Value -isnot [string] -or $Value -notmatch '^#') {
        return
    }

    $color = $Value.ToUpper()
    if (-not $ColorPool.Contains($color)) {
        $null = $ColorPool.Add($color)
    }
}

function Add-PaletteColorsToPool {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$ColorPool,

        [Parameter(Mandatory = $false)]
        [hashtable]$Palette
    )

    if (-not $Palette) {
        return
    }

    foreach ($entry in $Palette.GetEnumerator()) {
        Add-UniqueColorToPool -ColorPool $ColorPool -Value $entry.Value
    }
}

function Add-TemplateColorsToPool {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$ColorPool,

        [Parameter(Mandatory = $true)]
        [object]$Value,

        [Parameter(Mandatory = $false)]
        [hashtable]$Palette
    )

    $strings = if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        $Value
    }
    else {
        @($Value)
    }

    foreach ($item in $strings) {
        if ($item -isnot [string]) {
            continue
        }

        foreach ($match in [regex]::Matches($item,'#[0-9a-fA-F]{6}')) {
            Add-UniqueColorToPool -ColorPool $ColorPool -Value $match.Value
        }

        if (-not $Palette) {
            continue
        }

        foreach ($paletteMatch in [regex]::Matches($item,'p:([A-Za-z0-9_\-]+)')) {
            $paletteKey = $paletteMatch.Groups[1].Value
            if ($Palette.ContainsKey($paletteKey)) {
                Add-UniqueColorToPool -ColorPool $ColorPool -Value $Palette[$paletteKey]
            }
        }
    }
}

function Add-SegmentColorsToPool {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$ColorPool,

        [Parameter(Mandatory = $true)]
        [object]$Segment,

        [Parameter(Mandatory = $false)]
        [hashtable]$Palette
    )

    foreach ($propertyName in @('background','foreground')) {
        if ($Segment.PSObject.Properties.Name -contains $propertyName) {
            $resolved = Get-ResolvedColorValue -Value $Segment.$propertyName -Palette $Palette
            Add-UniqueColorToPool -ColorPool $ColorPool -Value $resolved
        }
    }

    foreach ($templateProperty in @('background_templates','foreground_templates','template')) {
        if ($Segment.PSObject.Properties.Name -notcontains $templateProperty) {
            continue
        }

        $value = $Segment.$templateProperty
        if ($null -ne $value) {
            Add-TemplateColorsToPool -ColorPool $ColorPool -Value $value -Palette $Palette
        }
    }
}

function Get-ThemeBlockSegment {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Theme
    )

    if (-not $Theme.blocks) {
        return
    }

    foreach ($block in $Theme.blocks) {
        if (-not $block.segments) {
            continue
        }

        foreach ($segment in $block.segments) {
            if ($null -ne $segment) {
                $segment
            }
        }
    }
}

function Get-OfficialColorPool {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Theme,

        [Parameter(Mandatory = $false)]
        [hashtable]$Palette
    )

    $colors = New-Object System.Collections.Generic.List[string]

    Add-PaletteColorsToPool -ColorPool $colors -Palette $Palette

    foreach ($segment in @(Get-ThemeBlockSegment -Theme $Theme)) {
        Add-SegmentColorsToPool -ColorPool $colors -Segment $segment -Palette $Palette
    }

    return $colors.ToArray()
}

function Get-ThemePaletteMap {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Theme
    )

    $palette = @{}

    if (-not $Theme.Palette) {
        return $palette
    }

    $Theme.Palette.PSObject.Properties | ForEach-Object {
        $palette[$_.Name] = $_.Value
    }

    return $palette
}

function Get-ResolvedSegmentThemeColor {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Segment,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $false)]
        [hashtable]$Palette
    )

    if ($Segment.PSObject.Properties.Name -notcontains $PropertyName) {
        return $null
    }

    $value = $Segment.$PropertyName
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $null
    }

    $resolved = Get-ResolvedColorValue -Value $value -Palette $Palette
    if ($resolved) {
        return $resolved.ToUpper()
    }

    if ($value -match '^#') {
        return $value.ToUpper()
    }

    return $null
}

function Add-ThemeColorCandidate {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ThemeColors,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$Candidates,

        [Parameter(Mandatory = $true)]
        [ValidateSet('bg','fg')]
        [string]$ColorRole,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$Color
    )

    if (-not $Color) {
        return
    }

    if (-not $Candidates.Contains($Color)) {
        $null = $Candidates.Add($Color)
    }

    foreach ($slot in @("primary_$ColorRole","secondary_$ColorRole","accent_$ColorRole")) {
        if (-not $ThemeColors[$slot]) {
            $ThemeColors[$slot] = $Color
            return
        }
    }
}

function Add-ThemeSegmentColorCandidate {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Theme,

        [Parameter(Mandatory = $false)]
        [hashtable]$Palette,

        [Parameter(Mandatory = $true)]
        [hashtable]$ThemeColors,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$BackgroundCandidates,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$ForegroundCandidates
    )

    $segmentCounter = 0
    foreach ($segment in @(Get-ThemeBlockSegment -Theme $Theme)) {
        $background = Get-ResolvedSegmentThemeColor -Segment $segment -PropertyName 'background' -Palette $Palette
        Add-ThemeColorCandidate -ThemeColors $ThemeColors -Candidates $BackgroundCandidates -ColorRole bg -Color $background

        $foreground = Get-ResolvedSegmentThemeColor -Segment $segment -PropertyName 'foreground' -Palette $Palette
        Add-ThemeColorCandidate -ThemeColors $ThemeColors -Candidates $ForegroundCandidates -ColorRole fg -Color $foreground

        $segmentCounter++
        if ($segmentCounter -ge 12) {
            return
        }
    }
}

function Complete-ThemeBackgroundColor {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ThemeColors,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$Candidates
    )

    if ($Candidates.Count -eq 0) {
        return
    }

    if (-not $ThemeColors.primary_bg -and $Candidates.Length -gt 0) {
        $ThemeColors.primary_bg = $Candidates[0]
    }

    if (-not $ThemeColors.secondary_bg -and $Candidates.Length -gt 1) {
        $ThemeColors.secondary_bg = $Candidates[1]
    }

    if ($ThemeColors.accent_bg) {
        return
    }

    $accentCandidate = Select-ColorByHueRange -Colors $Candidates -MinHue 280 -MaxHue 360
    if (-not $accentCandidate) {
        $accentCandidate = Select-ColorByHueRange -Colors $Candidates -MinHue 0 -MaxHue 60
    }
    if (-not $accentCandidate -and $Candidates.Length -gt 2) {
        $accentCandidate = $Candidates[2]
    }
    $ThemeColors.accent_bg = $accentCandidate
}

function Complete-ThemeForegroundColor {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ThemeColors,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$Candidates
    )

    if (-not $ThemeColors.primary_fg -and $Candidates.Length -gt 0) {
        $ThemeColors.primary_fg = $Candidates[0]
    }
    if (-not $ThemeColors.primary_fg -and $ThemeColors.primary_bg) {
        $ThemeColors.primary_fg = Get-ContrastColor -Hex $ThemeColors.primary_bg
    }

    if (-not $ThemeColors.secondary_fg -and $ThemeColors.secondary_bg) {
        $ThemeColors.secondary_fg = Get-ContrastColor -Hex $ThemeColors.secondary_bg
    }

    if (-not $ThemeColors.accent_fg -and $ThemeColors.accent_bg) {
        $ThemeColors.accent_fg = Get-ContrastColor -Hex $ThemeColors.accent_bg
    }
}

function Get-PrimaryThemeColor {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Theme,

        [Parameter(Mandatory = $false)]
        [hashtable]$Palette
    )

    $colors = @{
        primary_bg = $null
        primary_fg = $null
        secondary_bg = $null
        secondary_fg = $null
        accent_bg = $null
        accent_fg = $null
    }

    $backgroundCandidates = New-Object System.Collections.Generic.List[string]
    $foregroundCandidates = New-Object System.Collections.Generic.List[string]
    Add-ThemeSegmentColorCandidate -Theme $Theme -Palette $Palette -ThemeColors $colors -BackgroundCandidates $backgroundCandidates -ForegroundCandidates $foregroundCandidates

    $backgroundArray = $backgroundCandidates.ToArray()
    Complete-ThemeBackgroundColor -ThemeColors $colors -Candidates $backgroundArray

    $foregroundArray = $foregroundCandidates.ToArray()
    Complete-ThemeForegroundColor -ThemeColors $colors -Candidates $foregroundArray

    return $colors
}

function Copy-PaletteMap {
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Palette
    )

    $copy = @{}
    if (-not $Palette) {
        return $copy
    }

    foreach ($entry in @($Palette.GetEnumerator())) {
        $copy[$entry.Key] = $entry.Value
    }

    return $copy
}

function Get-NormalizedOfficialColor {
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$OfficialColors
    )

    if (-not $OfficialColors -or $OfficialColors.Count -eq 0) {
        return @('#6272A4','#BD93F9','#FF79C6','#8BE9FD','#FFB86C','#F1FA8C')
    }

    return @($OfficialColors | ForEach-Object { $_.ToUpper() } | Select-Object -Unique)
}

function Get-AvailableColorPool {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Colors
    )

    $availableColors = New-Object System.Collections.Generic.List[string]
    foreach ($color in $Colors) {
        if (-not $availableColors.Contains($color)) {
            $null = $availableColors.Add($color)
        }
    }

    return ,$availableColors
}

function Get-PaletteColorDefault {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ThemeColors,

        [Parameter(Mandatory = $true)]
        [string[]]$ColorPool
    )

    $defaults = @{
        PrimaryBackground = if ($ThemeColors.primary_bg) { $ThemeColors.primary_bg.ToUpper() } else { $ColorPool[0] }
        SecondaryBackground = if ($ThemeColors.secondary_bg) { $ThemeColors.secondary_bg.ToUpper() } else { $null }
        AccentBackground = if ($ThemeColors.accent_bg) { $ThemeColors.accent_bg.ToUpper() } else { $null }
        PrimaryForeground = if ($ThemeColors.primary_fg) { $ThemeColors.primary_fg.ToUpper() } else { $null }
    }

    if (-not $defaults.SecondaryBackground -and $ColorPool.Count -gt 1) {
        $defaults.SecondaryBackground = $ColorPool[1]
    }
    if (-not $defaults.AccentBackground -and $ColorPool.Count -gt 2) {
        $defaults.AccentBackground = $ColorPool[2]
    }
    if (-not $defaults.PrimaryForeground -and $defaults.PrimaryBackground) {
        $defaults.PrimaryForeground = Get-ContrastColor -Hex $defaults.PrimaryBackground
    }

    return $defaults
}

function Get-FallbackThemeColor {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ColorPool,

        [Parameter(Mandatory = $true)]
        [double]$MinHue,

        [Parameter(Mandatory = $true)]
        [double]$MaxHue,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string[]]$Fallbacks
    )

    $selected = Select-ColorByHueRange -Colors $ColorPool -MinHue $MinHue -MaxHue $MaxHue
    if ($selected) {
        return $selected.ToUpper()
    }

    return @($Fallbacks | Where-Object { $_ })[0]
}

function Get-AvailableColorByHue {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$AvailableColors,

        [Parameter(Mandatory = $true)]
        [double]$MinHue,

        [Parameter(Mandatory = $true)]
        [double]$MaxHue,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$Fallback
    )

    if ($AvailableColors.Count -eq 0) {
        return $Fallback
    }

    $selected = Select-ColorByHueRange -Colors $AvailableColors.ToArray() -MinHue $MinHue -MaxHue $MaxHue
    if (-not $selected) {
        $selected = $AvailableColors[0]
    }

    $null = $AvailableColors.Remove($selected)
    return $selected
}

function Get-NextAvailableColor {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$AvailableColors,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$Fallback
    )

    if ($AvailableColors.Count -eq 0) {
        return $Fallback
    }

    $selected = $AvailableColors[0]
    $AvailableColors.RemoveAt(0)
    return $selected
}

function Get-OriginalPaletteColorMap {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Palette
    )

    $colorMap = @{}
    foreach ($key in $Palette.Keys) {
        $value = $Palette[$key]
        if ($value -match '^#([0-9a-fA-F]{3,8})$') {
            $colorMap[$key] = $value.ToUpper()
        }
    }

    return $colorMap
}

function Get-CompatibleThemeColor {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OriginalColor,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$AvailableColors
    )

    if ($AvailableColors.Count -eq 0) {
        return $null
    }

    $closest = Get-ClosestThemeColor -TargetHex $OriginalColor -ColorPool $AvailableColors
    if (-not $closest) {
        return $null
    }

    $originalHue = Get-ColorHue -Hex $OriginalColor
    $closestHue = Get-ColorHue -Hex $closest
    if ($null -eq $originalHue -or $null -eq $closestHue) {
        return $closest
    }

    $hueDiff = [math]::Abs($originalHue - $closestHue)
    if ($hueDiff -gt 180) {
        $hueDiff = 360 - $hueDiff
    }

    return $(if ($hueDiff -le 45) { $closest } else { $OriginalColor })
}

function Resolve-NamedPaletteColor {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$AvailableColors,

        [Parameter(Mandatory = $true)]
        [hashtable]$Defaults,

        [Parameter(Mandatory = $true)]
        [hashtable]$RoleColors
    )

    switch -Regex ($Name.ToLowerInvariant()) {
        'white' { return '#F8F8F2' }
        'black' { return '#1C1C1C' }
        'accent|purple|magenta|pink|violet' { return Get-AvailableColorByHue -AvailableColors $AvailableColors -MinHue 280 -MaxHue 360 -Fallback $Defaults.AccentBackground }
        'primary|shell|prompt' { return $Defaults.PrimaryBackground }
        '_fg$' { return $Defaults.PrimaryForeground }
        'text' { return $Defaults.PrimaryForeground }
        'session|secondary' { return $Defaults.SecondaryBackground }
        'yellow|orange|warning|battery|update' { return Get-AvailableColorByHue -AvailableColors $AvailableColors -MinHue 20 -MaxHue 80 -Fallback $RoleColors.Warning }
        'green|success|added|valid' { return Get-AvailableColorByHue -AvailableColors $AvailableColors -MinHue 80 -MaxHue 150 -Fallback $RoleColors.Success }
        'teal|cyan|info|sysinfo|node|python|blue' { return Get-AvailableColorByHue -AvailableColors $AvailableColors -MinHue 180 -MaxHue 260 -Fallback $RoleColors.Info }
        'red|error|alert|deleted|debug' { return Get-AvailableColorByHue -AvailableColors $AvailableColors -MinHue 330 -MaxHue 30 -Fallback $RoleColors.Error }
        'gray|grey|prompt_count|path|os' { return $RoleColors.NeutralDark }
        default { return Get-NextAvailableColor -AvailableColors $AvailableColors -Fallback $Defaults.PrimaryBackground }
    }
}

function Resolve-PaletteForegroundContrast {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Palette,

        [Parameter(Mandatory = $true)]
        [string]$PrimaryForeground
    )

    foreach ($key in @($Palette.Keys)) {
        if ($key -match '_fg$') {
            $baseKey = $key.Substring(0,$key.Length - 3)
            $backgroundKey = if ($Palette.ContainsKey($baseKey)) { $baseKey } else { "${baseKey}_bg" }
            $Palette[$key] = if ($Palette.ContainsKey($backgroundKey)) {
                Get-ContrastColor -Hex $Palette[$backgroundKey]
            }
            else {
                $PrimaryForeground
            }
        }
        elseif ($key -match 'text') {
            $Palette[$key] = $PrimaryForeground
        }
    }
}

function Get-ThemedPalette {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$CustomPalette,

        [Parameter(Mandatory = $false)]
        [hashtable]$OfficialPalette,

        [Parameter(Mandatory = $true)]
        [hashtable]$ThemeColors,

        [Parameter(Mandatory = $true)]
        [string[]]$OfficialColors
    )

    $converted = Copy-PaletteMap -Palette $OfficialPalette
    if (-not $CustomPalette -or $CustomPalette.Count -eq 0) {
        return $converted
    }

    $colorPool = Get-NormalizedOfficialColor -OfficialColors $OfficialColors
    $availableColors = Get-AvailableColorPool -Colors $colorPool
    $defaults = Get-PaletteColorDefault -ThemeColors $ThemeColors -ColorPool $colorPool
    $roleColors = @{
        Warning = Get-FallbackThemeColor -ColorPool $colorPool -MinHue 20 -MaxHue 80 -Fallbacks @($defaults.AccentBackground,$defaults.PrimaryBackground)
        Success = Get-FallbackThemeColor -ColorPool $colorPool -MinHue 80 -MaxHue 150 -Fallbacks @($defaults.SecondaryBackground,$defaults.PrimaryBackground)
        Info = Get-FallbackThemeColor -ColorPool $colorPool -MinHue 180 -MaxHue 260 -Fallbacks @($defaults.SecondaryBackground,$defaults.PrimaryBackground)
        Error = Get-FallbackThemeColor -ColorPool $colorPool -MinHue 330 -MaxHue 30 -Fallbacks @($defaults.AccentBackground,$defaults.PrimaryBackground)
        NeutralDark = Get-AdjustedColor -Hex $defaults.PrimaryBackground -Factor -0.25
    }
    $originalColorMap = Get-OriginalPaletteColorMap -Palette $CustomPalette

    foreach ($key in $CustomPalette.Keys) {
        if ($converted.ContainsKey($key)) {
            continue
        }

        $assigned = if ($originalColorMap.ContainsKey($key)) {
            Get-CompatibleThemeColor -OriginalColor $originalColorMap[$key] -AvailableColors $availableColors
        }
        if (-not $assigned) {
            $assigned = Resolve-NamedPaletteColor -Name $key -AvailableColors $availableColors -Defaults $defaults -RoleColors $roleColors
        }
        $converted[$key] = $(if ($assigned) { $assigned } else { $defaults.PrimaryBackground })
    }

    Resolve-PaletteForegroundContrast -Palette $converted -PrimaryForeground $defaults.PrimaryForeground
    return $converted
}

function Read-ThemeFile {
    <#
    .SYNOPSIS
        Reads and parses a JSON theme file
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $content = Get-Content -Path $Path -Raw -ErrorAction Stop
        return $content | ConvertFrom-Json -Depth 100
    }
    catch {
        Write-Error "Failed to read theme file '$Path': $_"
        return $null
    }
}

function Write-ThemeFile {
    <#
    .SYNOPSIS
        Writes a theme object to a JSON file with proper formatting
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Theme,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $json = $Theme | ConvertTo-Json -Depth 100
        # Format the JSON nicely
        $json | Set-Content -Path $Path -Encoding UTF8 -ErrorAction Stop
        Write-MergeMessage -Message "[OK] Saved theme to: $Path" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to write theme file '$Path': $_"
        return $false
    }
}

function Get-ThemePalette {
    <#
    .SYNOPSIS
        Extracts the color palette from a theme
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Theme
    )

    $palette = Get-ThemePaletteMap -Theme $Theme

    if (-not $palette -or $palette.Count -eq 0) {
        Write-Verbose "Theme has no explicit palette, will use direct color references"
    }

    return $palette
}

function Add-SegmentToTypeMap {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SegmentMap,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$Segment
    )

    if (-not $Segment.Type) {
        return
    }

    $type = $Segment.Type
    if (-not $SegmentMap.ContainsKey($type)) {
        $SegmentMap[$type] = @()
    }
    $SegmentMap[$type] += $Segment
}

function Get-SegmentsByType {
    <#
    .SYNOPSIS
        Groups all segments from a theme by their type
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Theme
    )

    $segmentMap = @{}
    foreach ($segment in @(Get-ThemeBlockSegment -Theme $Theme)) {
        Add-SegmentToTypeMap -SegmentMap $segmentMap -Segment $segment
    }
    if ($Theme.tooltips) {
        foreach ($tooltip in $Theme.tooltips) {
            Add-SegmentToTypeMap -SegmentMap $segmentMap -Segment $tooltip
        }
    }

    return $segmentMap
}

function Test-SegmentStyleValue {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return $false
    }
    if ($Value -isnot [string]) {
        return $true
    }

    return -not [string]::IsNullOrWhiteSpace($Value)
}

function Merge-SegmentStyling {
    <#
    .SYNOPSIS
        Merges styling from an official segment into a custom segment
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$CustomSegment,

        [Parameter(Mandatory = $true)]
        [object]$OfficialSegment
    )

    $styleProperties = @(
        'background',
        'background_templates',
        'foreground',
        'foreground_templates',
        'style'
    )

    foreach ($propertyName in $styleProperties) {
        if ($OfficialSegment.PSObject.Properties.Name -notcontains $propertyName) {
            continue
        }

        $value = $OfficialSegment.$propertyName
        if (Test-SegmentStyleValue -Value $value) {
            $CustomSegment | Add-Member -MemberType NoteProperty -Name $propertyName -Value $value -Force
        }
    }

    return $CustomSegment
}

function Add-MissingPromptType {
    <#
    .SYNOPSIS
        Adds missing prompt types (transient, secondary, debug, valid_line, error_line)
        from custom theme while applying the official theme styling cues
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$MergedTheme,

        [Parameter(Mandatory = $true)]
        [object]$CustomTheme,

        [Parameter(Mandatory = $true)]
        [object]$OfficialTheme,

        [Parameter(Mandatory = $true)]
        [hashtable]$ThemeColors
    )

    $promptTypes = @('transient_prompt','secondary_prompt','debug_prompt','valid_line','error_line')

    foreach ($promptType in $promptTypes) {
        if ((-not ($OfficialTheme.PSObject.Properties.Name -contains $promptType)) -and
            ($CustomTheme.PSObject.Properties.Name -contains $promptType)) {

            Write-Verbose "Adding missing $promptType with themed styling"

            $customPrompt = $CustomTheme.$promptType
            $promptCopy = $customPrompt | ConvertTo-Json -Depth 100 | ConvertFrom-Json

            $styledPrompt = ConvertTo-ThemedPrompt -Prompt $promptCopy -ThemeColors $ThemeColors

            $MergedTheme | Add-Member -MemberType NoteProperty -Name $promptType -Value $styledPrompt -Force
        }
    }

    return $MergedTheme
}

function ConvertTo-ThemedPrompt {
    <#
    .SYNOPSIS
        Applies official theme color cues to prompt objects (transient, secondary, debug, etc.)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Prompt,

        [Parameter(Mandatory = $true)]
        [hashtable]$ThemeColors
    )

    $primaryBg = $ThemeColors.primary_bg
    $primaryFg = $ThemeColors.primary_fg

    if (-not $primaryBg) { $primaryBg = '#444444' }
    if (-not $primaryFg) { $primaryFg = Get-ContrastColor -Hex $primaryBg }

    if (-not $Prompt.background -or $Prompt.background -eq 'transparent') {
        $Prompt.background = 'transparent'
    }
    elseif ($primaryBg) {
        $Prompt.background = $primaryBg
    }

    $Prompt.foreground = $primaryFg

    return $Prompt
}

function Add-MergedThemePalette {
    param(
        [Parameter(Mandatory = $true)]
        [object]$MergedTheme,

        [Parameter(Mandatory = $true)]
        [hashtable]$CustomPalette,

        [Parameter(Mandatory = $true)]
        [hashtable]$OfficialPalette,

        [Parameter(Mandatory = $true)]
        [hashtable]$ThemeColors,

        [Parameter(Mandatory = $true)]
        [string[]]$OfficialColors
    )

    $convertedPalette = Get-ThemedPalette -CustomPalette $CustomPalette -OfficialPalette $OfficialPalette -ThemeColors $ThemeColors -OfficialColors $OfficialColors
    if ($convertedPalette.Count -gt 0) {
        $MergedTheme.Palette = [pscustomobject]$convertedPalette
        Write-MergeMessage -Message "  [OK] Generated themed palette with $($convertedPalette.Count) colors" -ForegroundColor Green
        return
    }

    if ($CustomPalette.Count -gt 0) {
        $MergedTheme.Palette = [pscustomobject]$CustomPalette
        Write-MergeMessage -Message "  [OK] Preserved custom palette" -ForegroundColor Yellow
    }
}

function Merge-ThemeBlockStyling {
    param(
        [Parameter(Mandatory = $true)]
        [object]$MergedTheme,

        [Parameter(Mandatory = $true)]
        [hashtable]$OfficialSegments
    )

    $blocksProcessed = 0
    $segmentsProcessed = 0
    foreach ($block in @($MergedTheme.blocks)) {
        if (-not $block.segments) {
            continue
        }

        foreach ($segment in $block.segments) {
            $segmentType = $segment.Type
            if ($OfficialSegments.ContainsKey($segmentType)) {
                $officialSegment = $OfficialSegments[$segmentType][0]
                $null = Merge-SegmentStyling -CustomSegment $segment -OfficialSegment $officialSegment
                $segmentsProcessed++
                Write-Verbose "  Merged styling for segment: $segmentType"
            }
            else {
                Write-Verbose "  No official styling for segment: $segmentType (keeping custom)"
            }
        }
        $blocksProcessed++
    }

    return [pscustomobject]@{
        Blocks = $blocksProcessed
        Segments = $segmentsProcessed
    }
}

function Merge-ThemeTooltipStyling {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Tooltips,

        [Parameter(Mandatory = $true)]
        [hashtable]$OfficialSegments
    )

    $tooltipsProcessed = 0
    foreach ($tooltip in $Tooltips) {
        $tooltipType = $tooltip.Type
        if ($OfficialSegments.ContainsKey($tooltipType)) {
            $officialSegment = $OfficialSegments[$tooltipType][0]
            $null = Merge-SegmentStyling -CustomSegment $tooltip -OfficialSegment $officialSegment
            $tooltipsProcessed++
        }
    }

    return $tooltipsProcessed
}

function Copy-CustomThemeSetting {
    param(
        [Parameter(Mandatory = $true)]
        [object]$MergedTheme,

        [Parameter(Mandatory = $true)]
        [object]$CustomTheme
    )

    $propertyNames = @(
        'console_title_template',
        'version',
        'final_space',
        'enable_cursor_positioning',
        'patch_pwsh_bleed',
        'pwd',
        'shell_integration',
        'iterm_features',
        'maps',
        'tooltips_action',
        'upgrade',
        'var',
        'async'
    )

    foreach ($propertyName in $propertyNames) {
        if ($CustomTheme.PSObject.Properties.Name -contains $propertyName) {
            $MergedTheme | Add-Member -MemberType NoteProperty -Name $propertyName -Value $CustomTheme.$propertyName -Force
        }
    }
}

function Merge-Theme {
    <#
    .SYNOPSIS
        Main function that merges styling from official theme into custom theme structure
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$CustomTheme,

        [Parameter(Mandatory = $true)]
        [object]$OfficialTheme,

        [Parameter(Mandatory = $true)]
        [string]$OfficialThemeName
    )

    Write-MergeMessage -Message "`n=========================================" -ForegroundColor Cyan
    Write-MergeMessage -Message "  Merging: $OfficialThemeName" -ForegroundColor Cyan
    Write-MergeMessage -Message "=========================================`n" -ForegroundColor Cyan

    $merged = $CustomTheme | ConvertTo-Json -Depth 100 | ConvertFrom-Json
    $customPalette = Get-ThemePalette -Theme $CustomTheme
    $officialPalette = Get-ThemePalette -Theme $OfficialTheme
    Write-MergeMessage -Message "  - Custom palette entries: $($customPalette.Count)" -ForegroundColor Gray
    Write-MergeMessage -Message "  - Official palette entries: $($officialPalette.Count)" -ForegroundColor Gray

    $themeColors = Get-PrimaryThemeColor -Theme $OfficialTheme -Palette $officialPalette
    $officialColorPool = Get-OfficialColorPool -Theme $OfficialTheme -Palette $officialPalette
    Add-MergedThemePalette -MergedTheme $merged -CustomPalette $customPalette -OfficialPalette $officialPalette -ThemeColors $themeColors -OfficialColors $officialColorPool

    $customSegments = Get-SegmentsByType -Theme $CustomTheme
    $officialSegments = Get-SegmentsByType -Theme $OfficialTheme
    Write-MergeMessage -Message "  - Custom theme segments: $($customSegments.Count) types" -ForegroundColor Gray
    Write-MergeMessage -Message "  - Official theme segments: $($officialSegments.Count) types" -ForegroundColor Gray

    $processed = Merge-ThemeBlockStyling -MergedTheme $merged -OfficialSegments $officialSegments
    Write-MergeMessage -Message "  [OK] Processed $($processed.Blocks) blocks, $($processed.Segments) segments" -ForegroundColor Green

    if ($merged.tooltips) {
        $tooltipsProcessed = Merge-ThemeTooltipStyling -Tooltips $merged.tooltips -OfficialSegments $officialSegments
        Write-MergeMessage -Message "  [OK] Processed $tooltipsProcessed tooltips" -ForegroundColor Green
    }

    $merged = Add-MissingPromptType -MergedTheme $merged -CustomTheme $CustomTheme -OfficialTheme $OfficialTheme -ThemeColors $themeColors
    Copy-CustomThemeSetting -MergedTheme $merged -CustomTheme $CustomTheme
    Write-MergeMessage -Message "  [OK] Preserved custom settings and structure`n" -ForegroundColor Green

    return $merged
}

#endregion

#region Main Script

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-MergeMessage -Message "Created output directory: $OutputPath`n" -ForegroundColor Yellow
}

# Load custom theme
Write-MergeMessage -Message "=========================================" -ForegroundColor Magenta
Write-MergeMessage -Message "  Loading Custom Theme" -ForegroundColor Magenta
Write-MergeMessage -Message "=========================================`n" -ForegroundColor Magenta

$customTheme = Read-ThemeFile -Path $CustomThemePath
if ($null -eq $customTheme) {
    Write-Error "Failed to load custom theme. Exiting."
    exit 1
}

Write-MergeMessage -Message "[OK] Loaded custom theme from: $CustomThemePath`n" -ForegroundColor Green

# Determine which official themes to process
$officialThemes = @()

if ($ProcessAll -and (Test-Path $OfficialThemePath -PathType Container)) {
    # Process all themes in directory
    $officialThemes = Get-ChildItem -Path $OfficialThemePath -Filter "*.omp.json" | Select-Object -ExpandProperty FullName
    Write-MergeMessage -Message "Found $($officialThemes.Count) official themes to process`n" -ForegroundColor Yellow
}
elseif (Test-Path $OfficialThemePath -PathType Leaf) {
    # Process single theme file
    $officialThemes = @($OfficialThemePath)
}
else {
    Write-Error "Invalid official theme path. Please specify a valid file or directory with -ProcessAll switch."
    exit 1
}

if ($officialThemes.Count -eq 0) {
    throw "No official *.omp.json themes were found to merge at '$OfficialThemePath'."
}

# Process each official theme
$successCount = 0
$failCount = 0

foreach ($themePath in $officialThemes) {
    $themeName = [System.IO.Path]::GetFileNameWithoutExtension($themePath)

    # Load official theme
    $officialTheme = Read-ThemeFile -Path $themePath
    if ($null -eq $officialTheme) {
        Write-Warning "Skipping theme: $themeName (failed to load)"
        $failCount++
        continue
    }

    # Merge themes
    try {
        $mergedTheme = Merge-Theme -CustomTheme $customTheme -OfficialTheme $officialTheme -OfficialThemeName $themeName

        # Generate output filename (remove .omp if it exists in theme name)
        $cleanThemeName = $themeName -replace '\.omp$',''
        $outputFileName = "Custom-${cleanThemeName}.omp.json"
        $outputFilePath = Join-Path -Path $OutputPath -ChildPath $outputFileName

        # Save merged theme
        if (Write-ThemeFile -Theme $mergedTheme -Path $outputFilePath) {
            $successCount++
        }
        else {
            $failCount++
        }
    }
    catch {
        Write-Error "Failed to merge theme '$themeName': $_"
        $failCount++
    }
}

# Summary
Write-MergeMessage -Message "`n=========================================" -ForegroundColor Magenta
Write-MergeMessage -Message "  Merge Complete!" -ForegroundColor Magenta
Write-MergeMessage -Message "=========================================`n" -ForegroundColor Magenta

Write-MergeMessage -Message "  [OK] Successfully merged: $successCount theme(s)" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-MergeMessage -Message "  [ERROR] Failed: $failCount theme(s)" -ForegroundColor Red
}
Write-MergeMessage -Message "  - Output directory: $OutputPath`n" -ForegroundColor Cyan

if ($failCount -gt 0) {
    throw "Theme merge failed for $failCount of $($officialThemes.Count) theme(s). Review the errors above; successful outputs were retained."
}

#endregion
