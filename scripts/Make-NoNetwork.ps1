<#
.SYNOPSIS
Creates a "NoNetwork" variant of an Oh My Posh theme by removing segments/tooltips that can make outbound network calls.

.DESCRIPTION
This repository ships themes that may use segments/tooltips such as:
- http (npm registry lookups, etc.)
- ipify (public IP)
- owm (OpenWeatherMap)
- lastfm, strava, withings, wakatime, brewfather

This script removes those segments from:
- blocks[].segments
- tooltips[]

It writes a new file with the suffix .NoNetwork.json by default.

.PARAMETER SourceTheme
Path to the source theme JSON.

.PARAMETER OutputPath
Optional explicit output path.

.PARAMETER RemoveTypes
Optional list of segment types to remove.

.EXAMPLE
pwsh ./scripts/Make-NoNetwork.ps1 -SourceTheme ./OhMyPosh-Atomic-Custom-ExperimentalDividers.json
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SourceTheme,

    [string]$OutputPath,

    [string[]]$RemoveTypes = @('http', 'ipify', 'owm', 'lastfm', 'strava', 'withings', 'wakatime', 'brewfather')
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Path $PSScriptRoot -Parent

function Resolve-RepoPath {
    param([Parameter(Mandatory)][string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path -Path $RepoRoot -ChildPath $Path)
}

$SourceTheme = Resolve-RepoPath $SourceTheme
if (-not (Test-Path -LiteralPath $SourceTheme)) {
    throw "Source theme not found: $SourceTheme"
}

$raw = Get-Content -LiteralPath $SourceTheme -Raw

try {
    $theme = $raw | ConvertFrom-Json -Depth 100
}
catch {
    throw "Failed to parse JSON: $SourceTheme`n$($_.Exception.Message)"
}

if (-not $OutputPath) {
    $dir = Split-Path -Path $SourceTheme -Parent
    $name = [System.IO.Path]::GetFileNameWithoutExtension($SourceTheme)
    $OutputPath = Join-Path -Path $dir -ChildPath ($name + '.NoNetwork.json')
}
else {
    $OutputPath = Resolve-RepoPath $OutputPath
}

$remove = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($t in $RemoveTypes) { [void]$remove.Add($t.ToLowerInvariant()) }

function Get-SegmentTypeLower($seg) {
    if ($null -eq $seg) { return $null }
    # Oh My Posh uses 'type' in JSON; PowerShell deserializes as property 'type'
    $t = $seg.type
    if (-not $t) { $t = $seg.Type }
    if (-not $t) { return $null }
    return ([string]$t).ToLowerInvariant()
}

$removedCounts = [ordered]@{ blocks = 0; tooltips = 0 }

# Remove from blocks[].segments
if ($theme.blocks) {
    foreach ($block in $theme.blocks) {
        if (-not $block.segments) { continue }
        $before = @($block.segments).Count
        $block.segments = @($block.segments | Where-Object {
                $t = Get-SegmentTypeLower $_
                if (-not $t) { return $true }
                return (-not $remove.Contains($t))
            })
        $after = @($block.segments).Count
        $removedCounts.blocks += ($before - $after)
    }
}

# Remove from tooltips[]
if ($theme.tooltips) {
    $before = @($theme.tooltips).Count
    $theme.tooltips = @($theme.tooltips | Where-Object {
            $t = Get-SegmentTypeLower $_
            if (-not $t) { return $true }
            return (-not $remove.Contains($t))
        })
    $after = @($theme.tooltips).Count
    $removedCounts.tooltips = ($before - $after)
}

# Write output
$jsonOut = $theme | ConvertTo-Json -Depth 100
Set-Content -LiteralPath $OutputPath -Value $jsonOut -Encoding utf8

Write-Host "Created NoNetwork theme: $OutputPath" -ForegroundColor Green
Write-Host "Removed segments: blocks=$($removedCounts.blocks), tooltips=$($removedCounts.tooltips)" -ForegroundColor Cyan
