<#
.SYNOPSIS
Sync common configuration (tooltips, maps, palette keys, etc.) from OhMyPosh-Atomic-Custom.json into the other base theme templates.

.DESCRIPTION
When the Atomic Custom theme is updated (especially tooltips and shared behavior), the other base templates
(1_shell, slimfat, atomicBit, clean-detailed) should inherit those shared updates.

This script updates those base theme template JSON files in the repo root by copying over selected top-level
keys from OhMyPosh-Atomic-Custom.json, while keeping each theme's own blocks/layout.

It also ensures palette key parity by copying Atomic Custom's palette keys/values into the target themes
(while preserving any extra keys the target themes may have).

.PARAMETER AtomicCustomPath
Path to OhMyPosh-Atomic-Custom.json (repo-root-relative by default).

.PARAMETER TargetThemes
Array of theme template files to update.

.EXAMPLE
pwsh ./scripts/Sync-ThemeTemplatesFromAtomicCustom.ps1
#>

[CmdletBinding()]
param(
    [string]$AtomicCustomPath = 'OhMyPosh-Atomic-Custom.json',
    [string[]]$TargetThemes = @(
        '1_shell-Enhanced.omp.json',
        'slimfat-Enhanced.omp.json',
        'atomicBit-Enhanced.omp.json',
        'clean-detailed-Enhanced.omp.json'
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

$AtomicCustomPath = Resolve-RepoPath $AtomicCustomPath
if (-not (Test-Path -LiteralPath $AtomicCustomPath)) {
    throw "Atomic Custom theme not found: $AtomicCustomPath"
}

$atomic = (Get-Content -LiteralPath $AtomicCustomPath -Raw | ConvertFrom-Json -Depth 100 -AsHashtable)

$syncKeys = @(
    'tooltips',
    'tooltips_action',
    'maps',
    'var',
    'cycle',
    'console_title_template',
    'debug_prompt',
    'error_line',
    'valid_line',
    'secondary_prompt',
    'transient_prompt',
    'upgrade',
    'enable_cursor_positioning',
    'patch_pwsh_bleed',
    'pwd',
    'iterm_features',
    'final_space',
    'shell_integration',
    'terminal_background',
    'version'
)

Write-Host '🔁 Syncing base theme templates from Atomic Custom...' -ForegroundColor Cyan
Write-Host "  Source: $AtomicCustomPath" -ForegroundColor DarkGray

foreach ($t in $TargetThemes) {
    $targetPath = Resolve-RepoPath $t
    if (-not (Test-Path -LiteralPath $targetPath)) {
        Write-Host "⚠️  Skipping missing target: $targetPath" -ForegroundColor Yellow
        continue
    }

    $theme = (Get-Content -LiteralPath $targetPath -Raw | ConvertFrom-Json -Depth 100 -AsHashtable)

    foreach ($k in $syncKeys) {
        if ($atomic.ContainsKey($k)) {
            $theme[$k] = $atomic[$k]
        }
    }

    # Palette: ensure targets have the same base palette keys/values as Atomic.
    if ($atomic.ContainsKey('palette') -and $atomic['palette'] -is [hashtable]) {
        if (-not $theme.ContainsKey('palette') -or -not ($theme['palette'] -is [hashtable])) {
            $theme['palette'] = @{}
        }
        foreach ($k in $atomic['palette'].Keys) {
            $theme['palette'][$k] = $atomic['palette'][$k]
        }
    }

    # Intentionally do NOT overwrite the target theme's blocks/layout.

    $theme | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $targetPath -Encoding UTF8
    Write-Host "✅ Updated: $t" -ForegroundColor Green
}
