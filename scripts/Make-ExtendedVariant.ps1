<#
.SYNOPSIS
Creates the standalone ExperimentalDividers Extended variant.

.DESCRIPTION
Copies the canonical ExperimentalDividers theme and inserts the Extended-only
segments and tooltips at deterministic positions from a declarative variant
definition. All shared settings stay synchronized with the canonical source.

.PARAMETER Source
Path to the canonical ExperimentalDividers theme.

.PARAMETER Destination
Path to the generated Extended theme.

.PARAMETER Definition
Path to the Extended variant definition.

.PARAMETER Backup
Back up an existing destination before overwriting it.

.EXAMPLE
pwsh ./scripts/Make-ExtendedVariant.ps1
#>

[CmdletBinding()]
param(
    [string]$Source = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',
    [string]$Destination = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.Extended.json',
    [string]$Definition = 'scripts/variants/ExperimentalDividers.Extended.variant.json',
    [switch]$Backup
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

$insertedSegmentCount = 0
foreach ($insertion in @($variant.segment_insertions)) {
    $blockMatches = @($theme.blocks | Where-Object {
            $_.type -eq $insertion.block.type -and $_.alignment -eq $insertion.block.alignment
        })

    if ($blockMatches.Count -ne 1) {
        throw "Expected one $($insertion.block.type)/$($insertion.block.alignment) block; found $($blockMatches.Count)."
    }

    $block = $blockMatches[0]
    $segments = @($block.segments)
    $anchorIndexes = @(for ($index = 0; $index -lt $segments.Count; $index++) {
            if ($segments[$index].alias -eq $insertion.after_alias) { $index }
        })

    if ($anchorIndexes.Count -ne 1) {
        throw "Expected one segment anchor '$($insertion.after_alias)'; found $($anchorIndexes.Count)."
    }

    $beforeIndexes = @(for ($index = 0; $index -lt $segments.Count; $index++) {
            if ($segments[$index].alias -eq $insertion.before_alias) { $index }
        })
    if ($beforeIndexes.Count -ne 1) {
        throw "Expected one segment anchor '$($insertion.before_alias)'; found $($beforeIndexes.Count)."
    }
    if ($beforeIndexes[0] -ne $anchorIndexes[0] + 1) {
        throw "Segment anchors '$($insertion.after_alias)' and '$($insertion.before_alias)' are no longer adjacent."
    }

    $existingAliases = @($theme.blocks.segments.alias | Where-Object { $_ })
    $newSegments = @($insertion.segments)
    $newAliases = @($newSegments.alias | Where-Object { $_ })
    $duplicateAliases = @($newAliases | Where-Object { $_ -in $existingAliases } | Select-Object -Unique)
    if ($duplicateAliases.Count -gt 0) {
        throw "Extended segment aliases already exist in the source: $($duplicateAliases -join ', ')"
    }
    if (@($newAliases | Group-Object | Where-Object Count -gt 1).Count -gt 0) {
        throw 'Extended variant definition contains duplicate segment aliases.'
    }

    $anchorIndex = $anchorIndexes[0]
    $before = if ($anchorIndex -ge 0) { @($segments[0..$anchorIndex]) } else { @() }
    $after = if ($anchorIndex + 1 -lt $segments.Count) { @($segments[($anchorIndex + 1)..($segments.Count - 1)]) } else { @() }
    $block.segments = @($before + $newSegments + $after)
    $insertedSegmentCount += $newSegments.Count
}

$insertedTooltipCount = 0
foreach ($insertion in @($variant.tooltip_insertions)) {
    $tooltips = @($theme.tooltips)
    $anchorIndexes = @(for ($index = 0; $index -lt $tooltips.Count; $index++) {
            if ($tooltips[$index].alias -eq $insertion.after_alias) { $index }
        })

    if ($anchorIndexes.Count -ne 1) {
        throw "Expected one tooltip anchor '$($insertion.after_alias)'; found $($anchorIndexes.Count)."
    }

    $beforeIndexes = @(for ($index = 0; $index -lt $tooltips.Count; $index++) {
            if ($tooltips[$index].alias -eq $insertion.before_alias) { $index }
        })
    if ($beforeIndexes.Count -ne 1) {
        throw "Expected one tooltip anchor '$($insertion.before_alias)'; found $($beforeIndexes.Count)."
    }
    if ($beforeIndexes[0] -ne $anchorIndexes[0] + 1) {
        throw "Tooltip anchors '$($insertion.after_alias)' and '$($insertion.before_alias)' are no longer adjacent."
    }

    $existingTooltipAliases = @($tooltips.alias | Where-Object { $_ })
    $newTooltips = @($insertion.tooltips)
    $newTooltipAliases = @($newTooltips.alias | Where-Object { $_ })
    $duplicateTooltipAliases = @($newTooltipAliases | Where-Object { $_ -in $existingTooltipAliases } | Select-Object -Unique)
    if ($duplicateTooltipAliases.Count -gt 0) {
        throw "Extended tooltip aliases already exist in the source: $($duplicateTooltipAliases -join ', ')"
    }
    if (@($newTooltipAliases | Group-Object | Where-Object Count -gt 1).Count -gt 0) {
        throw 'Extended variant definition contains duplicate tooltip aliases.'
    }

    $anchorIndex = $anchorIndexes[0]
    $before = if ($anchorIndex -ge 0) { @($tooltips[0..$anchorIndex]) } else { @() }
    $after = if ($anchorIndex + 1 -lt $tooltips.Count) { @($tooltips[($anchorIndex + 1)..($tooltips.Count - 1)]) } else { @() }
    $theme.tooltips = @($before + $newTooltips + $after)
    $insertedTooltipCount += $newTooltips.Count
}

if ((Test-Path -LiteralPath $Destination) -and $Backup) {
    $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
    Copy-Item -LiteralPath $Destination -Destination "$Destination.bak.$timestamp" -Force
}

$destinationDirectory = Split-Path -Path $Destination -Parent
if (-not (Test-Path -LiteralPath $destinationDirectory)) {
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
}

$theme | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $Destination -Encoding utf8

Write-Output "Created ExperimentalDividers Extended theme: $Destination"
Write-Output "Inserted segments: $insertedSegmentCount; inserted tooltips: $insertedTooltipCount"
