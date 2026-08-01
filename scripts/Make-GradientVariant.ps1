<#
.SYNOPSIS
Creates the standalone ExperimentalDividers Gradient variant.

.DESCRIPTION
Copies the canonical ExperimentalDividers theme and applies native two-stop
linear gradients to prompt-block backgrounds. Most content segments start with
parentBackground and end at their own configured background, so each rendered
segment continues from the previous active segment's final color.

Definition-selected one-cell transition dividers can be removed entirely or
collapsed into wider blank-cell ramps. The following wider content segment or
the retained ramp then performs the interpolation instead of exposing a stack
of solid one-cell color bands.

The definition supplies explicit entry gradients or v30 automatic shade
gradients for segments that cannot rely on a previous active background. It can
also make selected interactive segments non-interactive in this generated
variant because Oh My Posh does not support gradients on interactive segments.
The canonical source remains unchanged.

.PARAMETER Source
Path to the canonical ExperimentalDividers theme.

.PARAMETER Destination
Path to the generated Gradient theme.

.PARAMETER Definition
Path to the Gradient variant definition.

.PARAMETER Backup
Back up an existing destination before overwriting it.

.EXAMPLE
pwsh ./scripts/Make-GradientVariant.ps1
#>

[CmdletBinding()]
param(
    [string]$Source = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',
    [string]$Destination = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.Gradient.json',
    [string]$Definition = 'scripts/variants/ExperimentalDividers.Gradient.variant.json',
    [switch]$Backup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Path $PSScriptRoot -Parent
$SupportedColorPattern = '^(?:p:[A-Za-z0-9_-]+|#[0-9A-Fa-f]{3}|#[0-9A-Fa-f]{6})$'
$TemplateColorPattern = '(?<![A-Za-z0-9_-])(?:p:[A-Za-z0-9_-]+|#[0-9A-Fa-f]{6}|#[0-9A-Fa-f]{3})(?![A-Za-z0-9_-])'

function Resolve-RepoPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path -Path $RepoRoot -ChildPath $Path)
}

function Read-JsonFile {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "JSON file not found: $Path"
    }

    try {
        return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100)
    }
    catch {
        throw "Failed to parse JSON file '$Path': $($_.Exception.Message)"
    }
}

function Assert-SupportedColor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Color,
        [Parameter(Mandatory)][string]$Context,
        [switch]$AllowSelf
    )

    if ($AllowSelf -and $Color -eq 'self') {
        return
    }
    if ($Color -notmatch $SupportedColorPattern) {
        throw "Unsupported gradient stop '$Color' in $Context. Expected 'self', a palette reference, or a hex color."
    }
}

function Get-GradientStop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ConfiguredStop,
        [Parameter(Mandatory)][string]$CurrentColor
    )

    if ($ConfiguredStop -eq 'self') {
        return $CurrentColor
    }
    return $ConfiguredStop
}

function ConvertTo-ConnectedGradientColor {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Color,
        [AllowNull()]$EntryGradient,
        [AllowNull()][string]$EntryAutoShade
    )

    if ([string]::IsNullOrWhiteSpace($Color) -or $Color -eq 'transparent') {
        return $Color
    }
    if ($Color -match '^(?:linear|dark|light)-gradient\(') {
        throw "Source theme already contains a gradient background: '$Color'."
    }
    Assert-SupportedColor -Color $Color -Context 'source background'

    if (-not [string]::IsNullOrWhiteSpace($EntryAutoShade)) {
        return "$EntryAutoShade-gradient($Color)"
    }
    if ($null -eq $EntryGradient) {
        return "linear-gradient(parentBackground, $Color)"
    }

    $start = Get-GradientStop -ConfiguredStop ([string]$EntryGradient.start) -CurrentColor $Color
    $end = Get-GradientStop -ConfiguredStop ([string]$EntryGradient.end) -CurrentColor $Color
    return "linear-gradient($start, $end)"
}

function ConvertTo-ConnectedGradientTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Template,
        [AllowNull()]$EntryGradient,
        [AllowNull()][string]$EntryAutoShade
    )

    $entryGradientValue = $EntryGradient
    $entryAutoShadeValue = $EntryAutoShade
    return [regex]::Replace($Template, $TemplateColorPattern, {
            param($match)
            ConvertTo-ConnectedGradientColor `
                -Color $match.Value `
                -EntryGradient $entryGradientValue `
                -EntryAutoShade $entryAutoShadeValue
        })
}

function Invoke-GradientBackgroundConversion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Item,
        [AllowNull()]$EntryGradient,
        [AllowNull()][string]$EntryAutoShade
    )

    if ($Item.PSObject.Properties.Name -notcontains 'background') {
        return $false
    }

    $gradientBackground = ConvertTo-ConnectedGradientColor `
        -Color ([string]$Item.background) `
        -EntryGradient $EntryGradient `
        -EntryAutoShade $EntryAutoShade
    if ($gradientBackground -eq [string]$Item.background) {
        return $false
    }

    $Item.background = $gradientBackground
    if ($Item.PSObject.Properties.Name -contains 'background_templates') {
        $Item.background_templates = @($Item.background_templates | ForEach-Object {
                ConvertTo-ConnectedGradientTemplate `
                    -Template ([string]$_) `
                    -EntryGradient $EntryGradient `
                    -EntryAutoShade $EntryAutoShade
            })
    }

    return $true
}

function ConvertTo-DividerRampTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Template,
        [Parameter(Mandatory)][ValidateRange(4, 12)][int]$Cells
    )

    $overrideRegex = [regex]::new('<[^>]+>[\uE0B0\uE0B2]</>')
    $overrideMatches = $overrideRegex.Matches($Template)
    if ($overrideMatches.Count -ne 1) {
        throw "Divider ramp template must contain exactly one Powerline color override: $Template"
    }

    # Oh My Posh trims ASCII-space ramps, while its image exporter does not
    # advance visually blank glyphs. Full blocks provide stable cell width.
    # The `background` foreground keyword resolves to the gradient color at
    # each text position, so the blocks visually merge into their background.
    $fullBlock = [string][char]0x2588
    $ramp = "<background,transparent>$($fullBlock * $Cells)</>"
    return $overrideRegex.Replace($Template, $ramp, 1)
}

$Source = Resolve-RepoPath $Source
$Destination = Resolve-RepoPath $Destination
$Definition = Resolve-RepoPath $Definition

$sourceFullPath = [System.IO.Path]::GetFullPath($Source)
$destinationFullPath = [System.IO.Path]::GetFullPath($Destination)
if ($sourceFullPath.Equals($destinationFullPath, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Source and destination must be different files.'
}

$theme = Read-JsonFile -Path $Source
$variant = Read-JsonFile -Path $Definition

if ($theme.PSObject.Properties.Name -contains 'extends' -and -not [string]::IsNullOrWhiteSpace([string]$theme.extends)) {
    throw 'Gradient variants must be generated from a complete root theme without an active extends target.'
}
if ($null -eq $theme.palette) {
    throw 'Source theme must define a palette.'
}

$containers = @($variant.background_containers)
$supportedContainers = @('blocks', 'tooltips')
$unsupportedContainers = @($containers | Where-Object { $_ -notin $supportedContainers })
if ($unsupportedContainers.Count -gt 0) {
    throw "Unsupported background container(s): $($unsupportedContainers -join ', ')"
}
if ($containers.Count -eq 0) {
    throw 'Gradient definition must include at least one background container.'
}

$entryGradients = @{}
$configuredEntryGradients = @()
if ($variant.PSObject.Properties.Name -contains 'entry_gradients') {
    $configuredEntryGradients = @($variant.entry_gradients)
}
foreach ($entry in $configuredEntryGradients) {
    $alias = [string]$entry.alias
    if ([string]::IsNullOrWhiteSpace($alias)) {
        throw 'Every entry gradient must define a non-empty alias.'
    }
    if ($entryGradients.ContainsKey($alias)) {
        throw "Duplicate entry gradient alias: $alias"
    }

    Assert-SupportedColor -Color ([string]$entry.start) -Context "entry gradient '$alias' start" -AllowSelf
    Assert-SupportedColor -Color ([string]$entry.end) -Context "entry gradient '$alias' end" -AllowSelf
    $entryGradients[$alias] = $entry
}

$entryAutoShades = @{}
$configuredEntryAutoShades = @()
if ($variant.PSObject.Properties.Name -contains 'entry_auto_shades') {
    $configuredEntryAutoShades = @($variant.entry_auto_shades)
}
foreach ($entry in $configuredEntryAutoShades) {
    $alias = [string]$entry.alias
    $mode = [string]$entry.mode
    if ([string]::IsNullOrWhiteSpace($alias)) {
        throw 'Every entry auto-shade must define a non-empty alias.'
    }
    if ($entryAutoShades.ContainsKey($alias)) {
        throw "Duplicate entry auto-shade alias: $alias"
    }
    if ($entryGradients.ContainsKey($alias)) {
        throw "Entry alias cannot define both an explicit gradient and an auto-shade gradient: $alias"
    }
    if ($mode -cnotin @('dark', 'light')) {
        throw "Entry auto-shade '$alias' mode must be 'dark' or 'light'."
    }
    $entryAutoShades[$alias] = $mode
}

$nonInteractiveAliases = @($variant.make_non_interactive_aliases | ForEach-Object { [string]$_ })
if (@($nonInteractiveAliases | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
    throw 'make_non_interactive_aliases cannot contain an empty alias.'
}
if (@($nonInteractiveAliases | Sort-Object -Unique).Count -ne $nonInteractiveAliases.Count) {
    throw 'make_non_interactive_aliases cannot contain duplicate aliases.'
}

$removeSegmentAliases = @()
if ($variant.PSObject.Properties.Name -contains 'remove_segment_aliases') {
    $removeSegmentAliases = @($variant.remove_segment_aliases | ForEach-Object { [string]$_ })
}
if (@($removeSegmentAliases | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
    throw 'remove_segment_aliases cannot contain an empty alias.'
}
if (@($removeSegmentAliases | Sort-Object -Unique).Count -ne $removeSegmentAliases.Count) {
    throw 'remove_segment_aliases cannot contain duplicate aliases.'
}

$sourceAliasCounts = @{}
foreach ($segment in @($theme.blocks.segments)) {
    $alias = [string]$segment.alias
    if ([string]::IsNullOrWhiteSpace($alias)) {
        continue
    }
    if (-not $sourceAliasCounts.ContainsKey($alias)) {
        $sourceAliasCounts[$alias] = 0
    }
    $sourceAliasCounts[$alias]++
}

foreach ($removeAlias in $removeSegmentAliases) {
    if (-not $sourceAliasCounts.ContainsKey($removeAlias) -or $sourceAliasCounts[$removeAlias] -ne 1) {
        throw "Removed segment alias must identify exactly one source segment: $removeAlias"
    }
}

$dividerRamps = @{}
$collapsedDividerAliases = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$configuredDividerRamps = @()
if ($variant.PSObject.Properties.Name -contains 'divider_ramps') {
    $configuredDividerRamps = @($variant.divider_ramps)
}
foreach ($ramp in $configuredDividerRamps) {
    $alias = [string]$ramp.alias
    if ([string]::IsNullOrWhiteSpace($alias)) {
        throw 'Every divider ramp must define a non-empty alias.'
    }
    if ($dividerRamps.ContainsKey($alias)) {
        throw "Duplicate divider ramp alias: $alias"
    }
    if (-not $sourceAliasCounts.ContainsKey($alias) -or $sourceAliasCounts[$alias] -ne 1) {
        throw "Divider ramp alias must identify exactly one source segment: $alias"
    }
    if ($alias -in $removeSegmentAliases) {
        throw "Divider ramp alias cannot also be removed: $alias"
    }

    $cells = [int]$ramp.cells
    if ($cells -lt 4 -or $cells -gt 12) {
        throw "Divider ramp '$alias' cells must be between 4 and 12."
    }

    foreach ($collapsedAlias in @($ramp.collapse_aliases | ForEach-Object { [string]$_ })) {
        if ([string]::IsNullOrWhiteSpace($collapsedAlias)) {
            throw "Divider ramp '$alias' contains an empty collapse alias."
        }
        if ($collapsedAlias -eq $alias) {
            throw "Divider ramp '$alias' cannot collapse itself."
        }
        if (-not $sourceAliasCounts.ContainsKey($collapsedAlias) -or $sourceAliasCounts[$collapsedAlias] -ne 1) {
            throw "Collapsed divider alias must identify exactly one source segment: $collapsedAlias"
        }
        if ($collapsedAlias -in $removeSegmentAliases) {
            throw "Collapsed divider alias cannot also be removed directly: $collapsedAlias"
        }
        if (-not $collapsedDividerAliases.Add($collapsedAlias)) {
            throw "Collapsed divider alias is assigned more than once: $collapsedAlias"
        }
    }

    $dividerRamps[$alias] = $ramp
}

$removedSegmentCount = 0
foreach ($block in @($theme.blocks)) {
    $originalCount = @($block.segments).Count
    $block.segments = @($block.segments | Where-Object {
            [string]$_.alias -notin $removeSegmentAliases -and
            -not $collapsedDividerAliases.Contains([string]$_.alias)
        })
    $removedSegmentCount += $originalCount - @($block.segments).Count
}

$updatedCount = 0
$interactiveConvertedCount = 0
$interactiveSkipCount = 0
$dividerRampCount = 0
$foundAliases = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

if ('blocks' -in $containers) {
    foreach ($segment in @($theme.blocks.segments)) {
        $alias = [string]$segment.alias
        if (-not [string]::IsNullOrWhiteSpace($alias)) {
            [void]$foundAliases.Add($alias)
        }

        if ($alias -in $nonInteractiveAliases) {
            if ($segment.PSObject.Properties.Name -contains 'interactive') {
                if ([bool]$segment.interactive) {
                    $interactiveConvertedCount++
                }
                $segment.interactive = $false
            }
            else {
                $segment | Add-Member -NotePropertyName interactive -NotePropertyValue $false
            }
        }

        if ($segment.PSObject.Properties.Name -contains 'interactive' -and [bool]$segment.interactive) {
            $interactiveSkipCount++
            continue
        }

        if ($dividerRamps.ContainsKey($alias)) {
            $segment.template = ConvertTo-DividerRampTemplate `
                -Template ([string]$segment.template) `
                -Cells ([int]$dividerRamps[$alias].cells)
            if ($segment.PSObject.Properties.Name -contains 'foreground') {
                $segment.foreground = 'parentBackground'
            }
            else {
                $segment | Add-Member -NotePropertyName foreground -NotePropertyValue 'parentBackground'
            }
            $dividerRampCount++
        }

        $entryGradient = if ($entryGradients.ContainsKey($alias)) { $entryGradients[$alias] } else { $null }
        $entryAutoShade = if ($entryAutoShades.ContainsKey($alias)) { $entryAutoShades[$alias] } else { $null }
        if (Invoke-GradientBackgroundConversion `
                -Item $segment `
                -EntryGradient $entryGradient `
                -EntryAutoShade $entryAutoShade) {
            $updatedCount++
        }
    }
}

if ('tooltips' -in $containers) {
    foreach ($tooltip in @($theme.tooltips)) {
        $alias = [string]$tooltip.alias
        if (-not [string]::IsNullOrWhiteSpace($alias)) {
            [void]$foundAliases.Add($alias)
        }

        if ($tooltip.PSObject.Properties.Name -contains 'interactive' -and [bool]$tooltip.interactive) {
            $interactiveSkipCount++
            continue
        }

        $entryGradient = if ($entryGradients.ContainsKey($alias)) { $entryGradients[$alias] } else { $null }
        $entryAutoShade = if ($entryAutoShades.ContainsKey($alias)) { $entryAutoShades[$alias] } else { $null }
        if (Invoke-GradientBackgroundConversion `
                -Item $tooltip `
                -EntryGradient $entryGradient `
                -EntryAutoShade $entryAutoShade) {
            $updatedCount++
        }
    }
}

$requiredAliases = @($entryGradients.Keys) + @($entryAutoShades.Keys) + $nonInteractiveAliases + @($dividerRamps.Keys)
$missingAliases = @($requiredAliases | Sort-Object -Unique | Where-Object { -not $foundAliases.Contains($_) })
if ($missingAliases.Count -gt 0) {
    throw "Gradient definition references missing aliases: $($missingAliases -join ', ')"
}
if ($updatedCount -eq 0) {
    throw 'Gradient generator did not find any eligible backgrounds to update.'
}

if ($Backup -and (Test-Path -LiteralPath $Destination)) {
    Copy-Item -LiteralPath $Destination -Destination "$Destination.bak" -Force
}

$destinationDirectory = Split-Path -Path $Destination -Parent
if ($destinationDirectory -and -not (Test-Path -LiteralPath $destinationDirectory)) {
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
}

$theme | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $Destination -Encoding utf8

Write-Output "Generated Gradient variant: $Destination"
Write-Output "  Minimum Oh My Posh version: $($variant.minimum_oh_my_posh_version)"
Write-Output "  Connected gradient backgrounds: $updatedCount"
Write-Output "  Auto-shaded block entries: $($entryAutoShades.Count)"
Write-Output "  Removed one-cell transition dividers: $removedSegmentCount"
Write-Output "  Blank-cell divider ramps: $dividerRampCount"
Write-Output "  Interactive items made gradient-compatible: $interactiveConvertedCount"
Write-Output "  Remaining interactive items left solid: $interactiveSkipCount"
