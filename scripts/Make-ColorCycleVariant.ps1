<#
.SYNOPSIS
Creates a standalone ColorCycle variant from a complete Oh My Posh theme.

.DESCRIPTION
Copies the source theme, adds the shared top-level color cycle, merges the
cycle's palette colors into the source palette, and removes direct color fields
from prompt-block segments so the cycle is the single color authority. The
source prompt structure, tooltips, and behavior otherwise remain canonical.

.PARAMETER Source
Path to the complete source theme. Defaults to OhMyPosh-Atomic-Custom.json.

.PARAMETER Destination
Optional output path. The default source preserves the legacy
OhMyPosh-Atomic-Custom-ColorCycle.json name; other sources insert .ColorCycle
before the .json suffix.

.PARAMETER Definition
Path to the shared color-cycle definition.

.PARAMETER Backup
Back up an existing destination before overwriting it.

.EXAMPLE
pwsh ./scripts/Make-ColorCycleVariant.ps1

.EXAMPLE
pwsh ./scripts/Make-ColorCycleVariant.ps1 `
    -Source ./OhMyPosh-Atomic-Custom-ExperimentalDividers.json
#>

[CmdletBinding()]
param(
    [Alias('SourceTheme')]
    [string]$Source = 'OhMyPosh-Atomic-Custom.json',
    [Alias('OutputPath')]
    [string]$Destination,
    [string]$Definition = 'scripts/variants/ColorCycle.variant.json',
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
$Definition = Resolve-RepoPath $Definition

if (-not $Destination) {
    $sourceDirectory = Split-Path -Path $Source -Parent
    $sourceName = [System.IO.Path]::GetFileNameWithoutExtension($Source)
    $destinationName = if ($sourceName -eq 'OhMyPosh-Atomic-Custom') {
        'OhMyPosh-Atomic-Custom-ColorCycle.json'
    }
    else {
        "$sourceName.ColorCycle.json"
    }
    $Destination = Join-Path -Path $sourceDirectory -ChildPath $destinationName
}
else {
    $Destination = Resolve-RepoPath $Destination
}

$sourceFullPath = [System.IO.Path]::GetFullPath($Source)
$destinationFullPath = [System.IO.Path]::GetFullPath($Destination)
if ($sourceFullPath.Equals($destinationFullPath, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Source and destination must be different files.'
}

$theme = Read-JsonFile -Path $Source
$variant = Read-JsonFile -Path $Definition

if ($theme.PSObject.Properties.Name -contains 'extends' -and -not [string]::IsNullOrWhiteSpace([string]$theme.extends)) {
    throw 'ColorCycle variants must be generated from a complete root theme without an active extends target.'
}

if (-not $variant.palette -or @($variant.palette.PSObject.Properties).Count -eq 0) {
    throw "ColorCycle definition has no palette entries: $Definition"
}
if (-not $variant.cycle -or @($variant.cycle).Count -eq 0) {
    throw "ColorCycle definition has no cycle entries: $Definition"
}

if (-not $theme.palette) {
    if ($theme.PSObject.Properties.Name -contains 'palette') {
        $theme.palette = [pscustomobject]@{}
    }
    else {
        $theme | Add-Member -NotePropertyName 'palette' -NotePropertyValue ([pscustomobject]@{})
    }
}

foreach ($entry in $variant.palette.PSObject.Properties) {
    if ($theme.palette.PSObject.Properties.Name -contains $entry.Name) {
        $theme.palette.($entry.Name) = $entry.Value
    }
    else {
        $theme.palette | Add-Member -NotePropertyName $entry.Name -NotePropertyValue $entry.Value
    }
}

$segmentColorProperties = @(
    'background',
    'foreground',
    'background_templates',
    'foreground_templates'
)
$removedSegmentColorProperties = 0
foreach ($block in @($theme.blocks)) {
    foreach ($segment in @($block.segments)) {
        foreach ($propertyName in $segmentColorProperties) {
            if ($segment.PSObject.Properties.Name -contains $propertyName) {
                $segment.PSObject.Properties.Remove($propertyName)
                $removedSegmentColorProperties++
            }
        }
    }
}

$cycle = @($variant.cycle)
foreach ($entry in $cycle) {
    foreach ($name in @('background', 'foreground')) {
        $value = [string]$entry.$name
        if ([string]::IsNullOrWhiteSpace($value)) {
            throw "ColorCycle entry is missing '$name': $($entry | ConvertTo-Json -Compress)"
        }

        if ($value.StartsWith('p:', [StringComparison]::Ordinal)) {
            $paletteKey = $value.Substring(2)
            if ($theme.palette.PSObject.Properties.Name -notcontains $paletteKey) {
                throw "ColorCycle entry references missing palette key '$paletteKey'."
            }
        }
    }
}

if ($theme.PSObject.Properties.Name -contains 'cycle') {
    $theme.cycle = $cycle
}
else {
    $theme | Add-Member -NotePropertyName 'cycle' -NotePropertyValue $cycle
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

Write-Output "Created ColorCycle theme: $Destination"
Write-Output "Cycle entries: $($cycle.Count); palette additions: $(@($variant.palette.PSObject.Properties).Count); removed segment color fields: $removedSegmentColorProperties"
