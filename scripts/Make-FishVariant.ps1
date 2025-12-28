<#
.SYNOPSIS
Generate a Fish-safe variant of the ExperimentalDividers theme.

.DESCRIPTION
Fish (fish_prompt/fish_right_prompt) does not reliably handle cursor-positioned right-aligned
prompt blocks rendered inside the left prompt. This script generates a Fish-specific variant
from the main ExperimentalDividers theme by:

1) Disabling enable_cursor_positioning
2) Removing the right-aligned prompt block (type=prompt, alignment=right)
3) Prepending its segments into the rprompt block so Fish renders them via fish_right_prompt

To keep your hand-tuned Fish layout/settings stable over time (like the NoShellIntegration
variant), the script will, when an existing Fish variant file is present:

- Preserve the existing rprompt segment order/selection by alias
- Deep-merge segment overrides by alias (existing Fish segment values override regenerated)

This allows the Fish variant to track upstream theme changes while retaining a small set of
Fish-only tweaks.

.PARAMETER Source
Path to the source theme JSON (defaults to repo root theme).

.PARAMETER Destination
Path to the destination Fish JSON (defaults to repo root Fish variant).

.PARAMETER Backup
If set, back up the existing destination before overwriting.

.PARAMETER IncludeNewRPromptSegments
If set, any newly introduced rprompt segments (not present in the existing Fish variant)
will be appended after the preserved alias order. By default, the script keeps the existing
Fish rprompt selection exactly.

.EXAMPLE
./scripts/Make-FishVariant.ps1

.EXAMPLE
./scripts/Make-FishVariant.ps1 -Backup

# Requires PowerShell 6+ (PowerShell Core / pwsh recommended.)
#>

[CmdletBinding()]
param(
    [string]$Source = (Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'),
    [string]$Destination = (Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'OhMyPosh-Atomic-Custom-ExperimentalDividers.Fish.json'),
    [switch]$Backup,
    [switch]$IncludeNewRPromptSegments
)

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "Make-FishVariant.ps1 requires PowerShell 7+ (pwsh). Detected $($PSVersionTable.PSVersion)."
}

function Write-Info([string]$Message) { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Warn([string]$Message) { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err([string]$Message) { Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Merge-Deep {
    param(
        [Parameter(Mandatory)]$Base,
        [Parameter(Mandatory)]$Override
    )

    if ($null -eq $Override) { return $Base }
    if ($null -eq $Base) { return $Override }

    # For arrays, prefer Override entirely
    if (($Base -is [object[]]) -or ($Override -is [object[]])) {
        return $Override
    }

    # For hashtables, merge keys recursively
    if (($Base -is [hashtable]) -and ($Override -is [hashtable])) {
        $out = [ordered]@{}
        foreach ($k in $Base.Keys) { $out[$k] = $Base[$k] }
        foreach ($k in $Override.Keys) {
            if ($out.Contains($k)) {
                $out[$k] = Merge-Deep -Base $out[$k] -Override $Override[$k]
            }
            else {
                $out[$k] = $Override[$k]
            }
        }
        return $out
    }

    # Scalars: override wins
    return $Override
}

function Get-BlocksByType {
    param(
        [Parameter(Mandatory)][hashtable]$Theme,
        [Parameter(Mandatory)][string]$Type
    )
    return @($Theme.blocks | Where-Object { $_.type -eq $Type })
}

function Get-RightAlignedPromptBlockIndex {
    param([Parameter(Mandatory)][hashtable]$Theme)
    for ($i = 0; $i -lt $Theme.blocks.Count; $i++) {
        $b = $Theme.blocks[$i]
        if ($b.type -eq 'prompt' -and $b.alignment -eq 'right') { return $i }
    }
    return -1
}

function Find-FirstBlockIndex {
    param(
        [Parameter(Mandatory)][hashtable]$Theme,
        [Parameter(Mandatory)][string]$Type
    )
    for ($i = 0; $i -lt $Theme.blocks.Count; $i++) {
        if ($Theme.blocks[$i].type -eq $Type) { return $i }
    }
    return -1
}

function Get-SegmentMapByAlias {
    param([Parameter(Mandatory)][hashtable]$Theme)

    $map = @{}
    foreach ($b in $Theme.blocks) {
        if ($null -eq $b.segments) { continue }
        foreach ($s in $b.segments) {
            if ($null -eq $s.alias -or $s.alias -eq '') { continue }
            $map[$s.alias] = $s
        }
    }
    return $map
}

try {
    if (-not (Test-Path -LiteralPath $Source)) {
        Write-Err "Source not found: $Source"
        exit 1
    }

    if ((Test-Path -LiteralPath $Destination) -and $Backup) {
        $bak = "$Destination.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
        Copy-Item -LiteralPath $Destination -Destination $bak -Force
        Write-Info "Backed up existing destination to: $bak"
    }

    Write-Info "Reading source JSON: $Source"
    $theme = (Get-Content -LiteralPath $Source -Raw -ErrorAction Stop) | ConvertFrom-Json -AsHashtable -Depth 99 -ErrorAction Stop

    # Fish-safe: disable cursor positioning.
    $theme['enable_cursor_positioning'] = $false

    $rightIdx = Get-RightAlignedPromptBlockIndex -Theme $theme
    if ($rightIdx -lt 0) {
        Write-Warn 'No right-aligned prompt block found (type=prompt, alignment=right). Nothing to merge.'
    }
    else {
        $rightBlock = $theme.blocks[$rightIdx]
        $rightSegs = @($rightBlock.segments)

        # Remove the right-aligned prompt block
        $theme.blocks = @($theme.blocks | Where-Object { $_ -ne $rightBlock })

        # Merge into rprompt
        $rIdx = Find-FirstBlockIndex -Theme $theme -Type 'rprompt'
        if ($rIdx -lt 0) {
            Write-Err 'Missing rprompt block (type=rprompt). Cannot build Fish variant.'
            exit 1
        }

        if ($null -eq $theme.blocks[$rIdx].segments) { $theme.blocks[$rIdx].segments = @() }
        $theme.blocks[$rIdx].segments = @($rightSegs + $theme.blocks[$rIdx].segments)
    }

    # Preserve existing Fish customizations if present
    $existing = $null
    if (Test-Path -LiteralPath $Destination) {
        Write-Info "Found existing Fish variant: $Destination (preserving Fish-only tweaks)"
        $existing = (Get-Content -LiteralPath $Destination -Raw -ErrorAction Stop) | ConvertFrom-Json -AsHashtable -Depth 99 -ErrorAction Stop

        $existingSegMap = Get-SegmentMapByAlias -Theme $existing

        # Deep-merge segment overrides by alias
        foreach ($b in $theme.blocks) {
            if ($null -eq $b.segments) { continue }
            for ($i = 0; $i -lt $b.segments.Count; $i++) {
                $seg = $b.segments[$i]
                $alias = $seg.alias
                if ($null -eq $alias -or $alias -eq '') { continue }
                if ($existingSegMap.ContainsKey($alias)) {
                    $b.segments[$i] = Merge-Deep -Base $seg -Override $existingSegMap[$alias]
                }
            }
        }

        # Preserve rprompt selection + ordering by alias
        $newRIdx = Find-FirstBlockIndex -Theme $theme -Type 'rprompt'
        $oldRIdx = Find-FirstBlockIndex -Theme $existing -Type 'rprompt'
        if ($newRIdx -ge 0 -and $oldRIdx -ge 0) {
            $newSegs = @($theme.blocks[$newRIdx].segments)
            $newMap = @{}
            foreach ($s in $newSegs) {
                if ($null -ne $s.alias -and $s.alias -ne '') { $newMap[$s.alias] = $s }
            }

            $ordered = @()
            $oldAliases = @()
            foreach ($s in @($existing.blocks[$oldRIdx].segments)) {
                if ($null -ne $s.alias -and $s.alias -ne '') { $oldAliases += $s.alias }
            }

            foreach ($a in $oldAliases) {
                if ($newMap.ContainsKey($a)) {
                    $ordered += $newMap[$a]
                }
                else {
                    # Segment no longer exists upstream; keep existing as fallback
                    $fallback = $existingSegMap[$a]
                    if ($null -ne $fallback) { $ordered += $fallback }
                }
            }

            if ($IncludeNewRPromptSegments) {
                foreach ($s in $newSegs) {
                    if ($null -eq $s.alias -or $s.alias -eq '') { continue }
                    if ($oldAliases -notcontains $s.alias) { $ordered += $s }
                }
            }

            $theme.blocks[$newRIdx].segments = $ordered
        }
    }
    else {
        Write-Info 'No existing Fish variant found; generating fresh.'
    }

    # Write destination JSON
    $jsonOut = $theme | ConvertTo-Json -Depth 99
    $destDir = Split-Path -Path $Destination -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    # PowerShell 7: utf8 is BOM-less. Keep newline at end.
    Set-Content -LiteralPath $Destination -Value $jsonOut -Encoding utf8
    Write-Info "Wrote Fish variant JSON to: $Destination"
}
catch {
    Write-Err "An error occurred: $_"
    throw
}

Write-Info 'Done.'
