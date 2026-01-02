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

function Get-OfficialColorPool {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Theme,

        [Parameter(Mandatory = $false)]
        [hashtable]$Palette
    )

    $colors = New-Object System.Collections.Generic.List[string]

    if ($Palette) {
        foreach ($entry in $Palette.GetEnumerator()) {
            if ($entry.Value -match '^#') {
                $color = $entry.Value.ToUpper()
                if (-not $colors.Contains($color)) {
                    $null = $colors.Add($color)
                }
            }
        }
    }

    if ($Theme.blocks) {
        foreach ($block in $Theme.blocks) {
            if (-not $block.segments) { continue }

            foreach ($segment in $block.segments) {
                foreach ($propName in @('background','foreground')) {
                    if ($segment.PSObject.Properties.Name -contains $propName) {
                        $resolved = Get-ResolvedColorValue -Value $segment.$propName -Palette $Palette
                        if ($resolved -and -not $colors.Contains($resolved)) {
                            $null = $colors.Add($resolved)
                        }
                    }
                }

                foreach ($templateProp in @('background_templates','foreground_templates','template')) {
                    if (-not ($segment.PSObject.Properties.Name -contains $templateProp)) { continue }
                    $value = $segment.$templateProp
                    if ($null -eq $value) { continue }

                    $strings = @()
                    if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
                        $strings = $value
                    }
                    else {
                        $strings = @($value)
                    }

                    foreach ($item in $strings) {
                        if (-not ($item -is [string])) { continue }
                        foreach ($match in [regex]::Matches($item,'#[0-9a-fA-F]{6}')) {
                            $hex = $match.Value.ToUpper()
                            if (-not $colors.Contains($hex)) {
                                $null = $colors.Add($hex)
                            }
                        }

                        foreach ($paletteMatch in [regex]::Matches($item,'p:([A-Za-z0-9_\-]+)')) {
                            $paletteKey = $paletteMatch.Groups[1].Value
                            if ($Palette -and $Palette.ContainsKey($paletteKey)) {
                                $paletteColor = $Palette[$paletteKey]
                                if ($paletteColor -match '^#') {
                                    $hexPalette = $paletteColor.ToUpper()
                                    if (-not $colors.Contains($hexPalette)) {
                                        $null = $colors.Add($hexPalette)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
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
    $segmentCounter = 0

    if ($Theme.blocks) {
        foreach ($block in $Theme.blocks) {
            if (-not $block.segments) { continue }

            foreach ($segment in $block.segments) {
                $resolvedBg = Get-ResolvedColorValue -Value $segment.background -Palette $Palette
                if (-not $resolvedBg -and $segment.PSObject.Properties.Name -contains 'background' -and $segment.background -match '^#') {
                    $resolvedBg = $segment.background
                }

                if ($resolvedBg) {
                    $resolvedBg = $resolvedBg.ToUpper()
                    if (-not $backgroundCandidates.Contains($resolvedBg)) {
                        $null = $backgroundCandidates.Add($resolvedBg)
                    }

                    if (-not $colors.primary_bg) {
                        $colors.primary_bg = $resolvedBg
                    }
                    elseif (-not $colors.secondary_bg) {
                        $colors.secondary_bg = $resolvedBg
                    }
                    elseif (-not $colors.accent_bg) {
                        $colors.accent_bg = $resolvedBg
                    }
                }

                $resolvedFg = Get-ResolvedColorValue -Value $segment.foreground -Palette $Palette
                if (-not $resolvedFg -and $segment.PSObject.Properties.Name -contains 'foreground' -and $segment.foreground -match '^#') {
                    $resolvedFg = $segment.foreground
                }

                if ($resolvedFg) {
                    $resolvedFg = $resolvedFg.ToUpper()
                    if (-not $foregroundCandidates.Contains($resolvedFg)) {
                        $null = $foregroundCandidates.Add($resolvedFg)
                    }

                    if (-not $colors.primary_fg) {
                        $colors.primary_fg = $resolvedFg
                    }
                    elseif (-not $colors.secondary_fg) {
                        $colors.secondary_fg = $resolvedFg
                    }
                    elseif (-not $colors.accent_fg) {
                        $colors.accent_fg = $resolvedFg
                    }
                }

                $segmentCounter++
                if ($segmentCounter -ge 12) { break }
            }

            if ($segmentCounter -ge 12) { break }
        }
    }

    $backgroundArray = $backgroundCandidates.ToArray()
    if (-not $colors.primary_bg -and $backgroundArray.Length -gt 0) {
        $colors.primary_bg = $backgroundArray[0]
    }

    if (-not $colors.secondary_bg -and $backgroundArray.Length -gt 1) {
        $colors.secondary_bg = $backgroundArray[1]
    }

    if (-not $colors.accent_bg) {
        $accentCandidate = Select-ColorByHueRange -Colors $backgroundArray -MinHue 280 -MaxHue 360
        if (-not $accentCandidate) {
            $accentCandidate = Select-ColorByHueRange -Colors $backgroundArray -MinHue 0 -MaxHue 60
        }
        if (-not $accentCandidate -and $backgroundArray.Length -gt 2) {
            $accentCandidate = $backgroundArray[2]
        }
        $colors.accent_bg = $accentCandidate
    }

    $foregroundArray = $foregroundCandidates.ToArray()
    if (-not $colors.primary_fg -and $foregroundArray.Length -gt 0) {
        $colors.primary_fg = $foregroundArray[0]
    }
    if (-not $colors.primary_fg -and $colors.primary_bg) {
        $colors.primary_fg = Get-ContrastColor -Hex $colors.primary_bg
    }

    if (-not $colors.secondary_fg -and $colors.secondary_bg) {
        $colors.secondary_fg = Get-ContrastColor -Hex $colors.secondary_bg
    }

    if (-not $colors.accent_fg -and $colors.accent_bg) {
        $colors.accent_fg = Get-ContrastColor -Hex $colors.accent_bg
    }

    return $colors
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

    $converted = @{}

    if ($OfficialPalette) {
        foreach ($entry in $OfficialPalette.GetEnumerator()) {
            $converted[$entry.Key] = $entry.Value
        }
    }

    if (-not $CustomPalette -or $CustomPalette.Count -eq 0) {
        return $converted
    }

    $colorPool = if ($OfficialColors -and $OfficialColors.Count -gt 0) {
        ($OfficialColors | ForEach-Object { $_.ToUpper() }) | Select-Object -Unique
    }
    else {
        @('#6272A4','#BD93F9','#FF79C6','#8BE9FD','#FFB86C','#F1FA8C')
    }

    $availableColors = New-Object System.Collections.Generic.List[string]
    foreach ($poolColor in $colorPool) {
        if (-not $availableColors.Contains($poolColor)) {
            $null = $availableColors.Add($poolColor)
        }
    }

    $primaryBg = if ($ThemeColors.primary_bg) { $ThemeColors.primary_bg.ToUpper() } else { ($colorPool[0]) }
    $secondaryBg = if ($ThemeColors.secondary_bg) { $ThemeColors.secondary_bg.ToUpper() } else { $null }
    $accentBg = if ($ThemeColors.accent_bg) { $ThemeColors.accent_bg.ToUpper() } else { $null }
    $primaryFg = if ($ThemeColors.primary_fg) { $ThemeColors.primary_fg.ToUpper() } else { $null }

    if (-not $secondaryBg -and $colorPool.Count -gt 1) { $secondaryBg = $colorPool[1] }
    if (-not $accentBg -and $colorPool.Count -gt 2) { $accentBg = $colorPool[2] }
    if (-not $primaryFg -and $primaryBg) { $primaryFg = Get-ContrastColor -Hex $primaryBg }

    $warningColor = Select-ColorByHueRange -Colors $colorPool -MinHue 20 -MaxHue 80
    if ($warningColor) { $warningColor = $warningColor.ToUpper() }
    $successColor = Select-ColorByHueRange -Colors $colorPool -MinHue 80 -MaxHue 150
    if ($successColor) { $successColor = $successColor.ToUpper() }
    $infoColor = Select-ColorByHueRange -Colors $colorPool -MinHue 180 -MaxHue 260
    if ($infoColor) { $infoColor = $infoColor.ToUpper() }
    $errorColor = Select-ColorByHueRange -Colors $colorPool -MinHue 330 -MaxHue 30
    if ($errorColor) { $errorColor = $errorColor.ToUpper() }

    if (-not $warningColor) { $warningColor = $accentBg }
    if (-not $warningColor) { $warningColor = $primaryBg }
    if (-not $successColor) { $successColor = $secondaryBg }
    if (-not $successColor) { $successColor = $primaryBg }
    if (-not $infoColor) { $infoColor = $secondaryBg }
    if (-not $infoColor) { $infoColor = $primaryBg }
    if (-not $errorColor) { $errorColor = $accentBg }
    if (-not $errorColor) { $errorColor = $primaryBg }

    $neutralColorDark = if ($primaryBg) { Get-AdjustedColor -Hex $primaryBg -Factor -0.25 } else { '#2B2B2B' }

    $getColorByHue = {
        param($minHue,$maxHue,$fallback)
        if ($availableColors.Count -eq 0) {
            return $fallback
        }
        $selected = $null
        if ($null -ne $minHue -and $null -ne $maxHue) {
            $selected = Select-ColorByHueRange -Colors $availableColors.ToArray() -MinHue $minHue -MaxHue $maxHue
        }
        if (-not $selected) {
            $selected = $availableColors[0]
        }
        $null = $availableColors.Remove($selected)
        return $selected
    }

    $getNextAvailable = {
        param($fallback)
        if ($availableColors.Count -eq 0) {
            return $fallback
        }
        $selected = $availableColors[0]
        $null = $availableColors.RemoveAt(0)
        return $selected
    }

    $originalColorMap = @{}
    foreach ($key in $CustomPalette.Keys) {
        $value = $CustomPalette[$key]
        if ($value -match '^#([0-9a-fA-F]{3,8})$') {
            $originalColorMap[$key] = $value.ToUpper()
        }
    }

    foreach ($key in $CustomPalette.Keys) {
        if ($converted.ContainsKey($key)) { continue }

        $assigned = $null
        if ($availableColors.Count -gt 0 -and $originalColorMap.ContainsKey($key)) {
            $closest = Get-ClosestThemeColor -TargetHex $originalColorMap[$key] -ColorPool $availableColors
            if ($closest) {
                $originalHue = Get-ColorHue -Hex $originalColorMap[$key]
                $closestHue = Get-ColorHue -Hex $closest
                $useClosest = $true
                if ($null -ne $originalHue -and $null -ne $closestHue) {
                    $hueDiff = [math]::Abs($originalHue - $closestHue)
                    if ($hueDiff -gt 180) { $hueDiff = 360 - $hueDiff }
                    if ($hueDiff -gt 45) {
                        $useClosest = $false
                    }
                }

                if ($useClosest) {
                    $assigned = $closest
                }
                else {
                    $assigned = $originalColorMap[$key]
                }
            }
        }

        if (-not $assigned) {
            $lower = $key.ToLowerInvariant()
            switch -Regex ($lower) {
                'white' { $assigned = '#F8F8F2'; break }
                'black' { $assigned = '#1C1C1C'; break }
                'accent|purple|magenta|pink|violet' { $assigned = & $getColorByHue 280 360 $accentBg; break }
                'primary|shell|prompt' { $assigned = $primaryBg; break }
                '_fg$' { $assigned = $primaryFg; break }
                'text' { $assigned = $primaryFg; break }
                'session|secondary' { $assigned = $secondaryBg; break }
                'yellow|orange|warning|battery|update' { $assigned = & $getColorByHue 20 80 $warningColor; break }
                'green|success|added|valid' { $assigned = & $getColorByHue 80 150 $successColor; break }
                'teal|cyan|info|sysinfo|node|python|blue' { $assigned = & $getColorByHue 180 260 $infoColor; break }
                'red|error|alert|deleted|debug' { $assigned = & $getColorByHue 330 30 $errorColor; break }
                'gray|grey|prompt_count|path|os' { $assigned = $neutralColorDark; break }
                default { $assigned = & $getNextAvailable $primaryBg }
            }
        }

        if (-not $assigned) { $assigned = $primaryBg }

        $converted[$key] = $assigned
    }

    foreach ($key in @($converted.Keys)) {
        if ($key -match '_fg$') {
            $baseKey = $key.Substring(0,$key.Length - 3)
            if ($converted.ContainsKey($baseKey)) {
                $converted[$key] = Get-ContrastColor -Hex $converted[$baseKey]
            }
            elseif ($converted.ContainsKey("${baseKey}_bg")) {
                $converted[$key] = Get-ContrastColor -Hex $converted["${baseKey}_bg"]
            }
            else {
                $converted[$key] = $primaryFg
            }
        }
        elseif ($key -match 'text') {
            $converted[$key] = $primaryFg
        }
    }

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
        Write-Output "? Saved theme to: $Path" -ForegroundColor Green
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

    if ($Theme.blocks) {
        foreach ($block in $Theme.blocks) {
            if ($block.segments) {
                foreach ($segment in $block.segments) {
                    if ($segment.Type) {
                        $type = $segment.Type
                        if (-not $segmentMap.ContainsKey($type)) {
                            $segmentMap[$type] = @()
                        }
                        $segmentMap[$type] += $segment
                    }
                }
            }
        }
    }

    # Also check tooltips
    if ($Theme.tooltips) {
        foreach ($tooltip in $Theme.tooltips) {
            if ($tooltip.Type) {
                $type = $tooltip.Type
                if (-not $segmentMap.ContainsKey($type)) {
                    $segmentMap[$type] = @()
                }
                $segmentMap[$type] += $tooltip
            }
        }
    }

    return $segmentMap
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
        [object]$OfficialSegment,

        [Parameter(Mandatory = $false)]
        [hashtable]$OfficialPalette
    )

    # Properties to transfer from official theme
    $styleProperties = @(
        'background',
        'background_templates',
        'foreground',
        'foreground_templates',
        'template',
        'style'
    )

    foreach ($prop in $styleProperties) {
        if ($OfficialSegment.PSObject.Properties.Name -contains $prop) {
            # Transfer the property value
            $value = $OfficialSegment.$prop

            # If it's a color and the official theme doesn't use palette references,
            # we keep it as-is (direct color)
            $shouldAssign = $false
            if ($null -ne $value) {
                if ($value -is [string]) {
                    if (-not [string]::IsNullOrWhiteSpace($value)) {
                        $shouldAssign = $true
                    }
                }
                else {
                    $shouldAssign = $true
                }
            }

            if ($shouldAssign) {
                $CustomSegment | Add-Member -MemberType NoteProperty -Name $prop -Value $value -Force
            }
        }
    }

    return $CustomSegment
}

function Convert-ColorsToPalette {
    <#
    .SYNOPSIS
        Converts direct color references to palette references
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Segment,

        [Parameter(Mandatory = $true)]
        [hashtable]$Palette
    )

    # This function would map direct hex colors to palette references
    # For now, we'll preserve whatever format the official theme uses
    return $Segment
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

            $styledPrompt = Set-PromptThemeColors -Prompt $promptCopy -ThemeColors $ThemeColors -PromptType $promptType

            $MergedTheme | Add-Member -MemberType NoteProperty -Name $promptType -Value $styledPrompt -Force
        }
    }

    return $MergedTheme
}

function Set-PromptThemeColor {
    <#
    .SYNOPSIS
        Applies official theme color cues to prompt objects (transient, secondary, debug, etc.)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Prompt,

        [Parameter(Mandatory = $true)]
        [hashtable]$ThemeColors,

        [Parameter(Mandatory = $true)]
        [string]$PromptType
    )

    $primaryBg = $ThemeColors.primary_bg
    $primaryFg = $ThemeColors.primary_fg
    $secondaryBg = $ThemeColors.secondary_bg
    $accentBg = $ThemeColors.accent_bg

    if (-not $primaryBg) { $primaryBg = '#444444' }
    if (-not $primaryFg) { $primaryFg = Get-ContrastColor -Hex $primaryBg }
    if (-not $secondaryBg) { $secondaryBg = Get-AdjustedColor -Hex $primaryBg -Factor 0.1 }
    if (-not $accentBg) { $accentBg = $secondaryBg }

    if (-not $Prompt.background -or $Prompt.background -eq 'transparent') {
        $Prompt.background = 'transparent'
    }
    elseif ($primaryBg) {
        $Prompt.background = $primaryBg
    }

    if (-not $Prompt.foreground -or $Prompt.foreground -eq 'transparent') {
        $Prompt.foreground = $primaryFg
    }
    else {
        $Prompt.foreground = $primaryFg
    }

    return $Prompt
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

    Write-Output "`n?????????????????????????????????????????" -ForegroundColor Cyan
    Write-Output "  Merging: $OfficialThemeName" -ForegroundColor Cyan
    Write-Output "?????????????????????????????????????????`n" -ForegroundColor Cyan

    # Start with a deep copy of the custom theme
    $merged = $CustomTheme | ConvertTo-Json -Depth 100 | ConvertFrom-Json

    # Extract palettes and derive themed palette
    $customPalette = Get-ThemePalette -Theme $CustomTheme
    $officialPalette = Get-ThemePalette -Theme $OfficialTheme
    Write-Output "  ? Custom palette entries: $($customPalette.Count)" -ForegroundColor Gray
    Write-Output "  ? Official palette entries: $($officialPalette.Count)" -ForegroundColor Gray

    $themeColors = Get-PrimaryThemeColors -Theme $OfficialTheme -Palette $officialPalette
    $officialColorPool = Get-OfficialColorPool -Theme $OfficialTheme -Palette $officialPalette

    $convertedPalette = Get-ThemedPalette -CustomPalette $customPalette -OfficialPalette $officialPalette -ThemeColors $themeColors -OfficialColors $officialColorPool
    if ($convertedPalette.Count -gt 0) {
        $merged.Palette = [pscustomobject]$convertedPalette
        Write-Output "  ? Generated themed palette with $($convertedPalette.Count) colors" -ForegroundColor Green
    }
    elseif ($customPalette.Count -gt 0) {
        $merged.Palette = [pscustomobject]$customPalette
        Write-Output "  ? Preserved custom palette" -ForegroundColor Yellow
    }

    # Get segment mappings
    $customSegments = Get-SegmentsByType -Theme $CustomTheme
    $officialSegments = Get-SegmentsByType -Theme $OfficialTheme

    Write-Output "  ? Custom theme segments: $($customSegments.Count) types" -ForegroundColor Gray
    Write-Output "  ? Official theme segments: $($officialSegments.Count) types" -ForegroundColor Gray

    # Process each block in the custom theme
    $blocksProcessed = 0
    $segmentsProcessed = 0

    foreach ($block in $merged.blocks) {
        if ($block.segments) {
            foreach ($segment in $block.segments) {
                $segmentType = $segment.Type

                if ($officialSegments.ContainsKey($segmentType)) {
                    # Found matching segment type in official theme
                    $officialSegment = $officialSegments[$segmentType][0] # Use first match

                    # Merge styling
                    $segment = Merge-SegmentStyling -CustomSegment $segment -OfficialSegment $officialSegment -OfficialPalette $officialPalette
                    $segmentsProcessed++

                    Write-Verbose "  ? Merged styling for segment: $segmentType"
                }
                else {
                    Write-Verbose "  ? No official styling for segment: $segmentType (keeping custom)"
                }
            }
            $blocksProcessed++
        }
    }

    Write-Output "  ? Processed $blocksProcessed blocks, $segmentsProcessed segments" -ForegroundColor Green

    # Process tooltips
    if ($merged.tooltips) {
        $tooltipsProcessed = 0
        foreach ($tooltip in $merged.tooltips) {
            $tooltipType = $tooltip.Type

            if ($officialSegments.ContainsKey($tooltipType)) {
                $officialSegment = $officialSegments[$tooltipType][0]
                $tooltip = Merge-SegmentStyling -CustomSegment $tooltip -OfficialSegment $officialSegment -OfficialPalette $officialPalette
                $tooltipsProcessed++
            }
        }
        Write-Output "  ? Processed $tooltipsProcessed tooltips" -ForegroundColor Green
    }

    # Add missing prompt types with themed styling
    $merged = Add-MissingPromptTypes -MergedTheme $merged -CustomTheme $CustomTheme -OfficialTheme $OfficialTheme -ThemeColors $themeColors

    # Preserve custom theme settings
    $preserveProperties = @(
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

    foreach ($prop in $preserveProperties) {
        if ($CustomTheme.PSObject.Properties.Name -contains $prop) {
            $merged | Add-Member -MemberType NoteProperty -Name $prop -Value $CustomTheme.$prop -Force
        }
    }

    Write-Output "  ? Preserved custom settings and structure`n" -ForegroundColor Green

    return $merged
}

#endregion

#region Main Script

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Output "Created output directory: $OutputPath`n" -ForegroundColor Yellow
}

# Load custom theme
Write-Output "?????????????????????????????????????????" -ForegroundColor Magenta
Write-Output "  Loading Custom Theme" -ForegroundColor Magenta
Write-Output "?????????????????????????????????????????`n" -ForegroundColor Magenta

$customTheme = Read-ThemeFile -Path $CustomThemePath
if ($null -eq $customTheme) {
    Write-Error "Failed to load custom theme. Exiting."
    exit 1
}

Write-Output "? Loaded custom theme from: $CustomThemePath`n" -ForegroundColor Green

# Determine which official themes to process
$officialThemes = @()

if ($ProcessAll -and (Test-Path $OfficialThemePath -PathType Container)) {
    # Process all themes in directory
    $officialThemes = Get-ChildItem -Path $OfficialThemePath -Filter "*.omp.json" | Select-Object -ExpandProperty FullName
    Write-Output "Found $($officialThemes.Count) official themes to process`n" -ForegroundColor Yellow
}
elseif (Test-Path $OfficialThemePath -PathType Leaf) {
    # Process single theme file
    $officialThemes = @($OfficialThemePath)
}
else {
    Write-Error "Invalid official theme path. Please specify a valid file or directory with -ProcessAll switch."
    exit 1
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
        $mergedTheme = Merge-Themes -CustomTheme $customTheme -OfficialTheme $officialTheme -OfficialThemeName $themeName

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
Write-Output "`n?????????????????????????????????????????" -ForegroundColor Magenta
Write-Output "  Merge Complete!" -ForegroundColor Magenta
Write-Output "?????????????????????????????????????????`n" -ForegroundColor Magenta

Write-Output "  ? Successfully merged: $successCount theme(s)" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Output "  ? Failed: $failCount theme(s)" -ForegroundColor Red
}
Write-Output "  ? Output directory: $OutputPath`n" -ForegroundColor Cyan

#endregion
