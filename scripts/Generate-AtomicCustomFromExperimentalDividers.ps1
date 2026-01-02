<#
.SYNOPSIS
Sync (generate) OhMyPosh-Atomic-Custom.json from the ExperimentalDividers theme, without bringing over divider blocks.

.DESCRIPTION
The ExperimentalDividers theme is treated as the "source of truth" for shared configuration such as tooltips,
maps, prompts, upgrade settings, etc.

This script updates a non-divider Atomic Custom theme (OhMyPosh-Atomic-Custom.json) by:
- Loading OhMyPosh-Atomic-Custom-ExperimentalDividers.json (source)
- Loading OhMyPosh-Atomic-Custom.json (template)
- Copying shared/non-layout properties (tooltips, maps, etc.) from source to template
- Keeping the template's blocks/layout (so it remains the non-divider variant)

It also merges any missing palette keys from the ExperimentalDividers theme into the non-divider theme
(to avoid missing palette keys for newly-added features).

.PARAMETER ExperimentalDividersPath
Path to OhMyPosh-Atomic-Custom-ExperimentalDividers.json (repo-root-relative by default).

.PARAMETER AtomicCustomTemplatePath
Path to the existing non-divider theme used as a layout template (repo-root-relative by default).

.PARAMETER OutputPath
Where to write the updated non-divider Atomic theme (repo-root-relative by default).

.EXAMPLE
pwsh ./scripts/Generate-AtomicCustomFromExperimentalDividers.ps1

.EXAMPLE
pwsh ./scripts/Generate-AtomicCustomFromExperimentalDividers.ps1 -ExperimentalDividersPath './OhMyPosh-Atomic-Custom-ExperimentalDividers.json'
#>

[CmdletBinding()]
param(
    [string]$ExperimentalDividersPath = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',
    [string]$AtomicCustomTemplatePath = 'OhMyPosh-Atomic-Custom.json',
    [string]$OutputPath = 'OhMyPosh-Atomic-Custom.json'
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

$ExperimentalDividersPath = Resolve-RepoPath $ExperimentalDividersPath
$AtomicCustomTemplatePath = Resolve-RepoPath $AtomicCustomTemplatePath
$OutputPath = Resolve-RepoPath $OutputPath

if (-not (Test-Path -LiteralPath $ExperimentalDividersPath)) {
    throw "ExperimentalDividers theme not found: $ExperimentalDividersPath"
}
if (-not (Test-Path -LiteralPath $AtomicCustomTemplatePath)) {
    throw "Atomic Custom template not found: $AtomicCustomTemplatePath"
}

Write-Host '🔁 Syncing non-divider Atomic Custom from ExperimentalDividers...' -ForegroundColor Cyan
Write-Host "  Source:   $ExperimentalDividersPath" -ForegroundColor DarkGray
Write-Host "  Template: $AtomicCustomTemplatePath" -ForegroundColor DarkGray
Write-Host "  Output:   $OutputPath" -ForegroundColor DarkGray

$exp = (Get-Content -LiteralPath $ExperimentalDividersPath -Raw | ConvertFrom-Json -Depth 100 -AsHashtable)
$tpl = (Get-Content -LiteralPath $AtomicCustomTemplatePath -Raw | ConvertFrom-Json -Depth 100 -AsHashtable)

# Keys that should be shared across all themes (non-layout config)
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

foreach ($k in $syncKeys) {
    if ($exp.ContainsKey($k)) {
        $tpl[$k] = $exp[$k]
    }
}

# Merge palette keys (overwrite existing keys + add missing keys)
if ($exp.ContainsKey('palette') -and $exp['palette'] -is [hashtable]) {
    if (-not $tpl.ContainsKey('palette') -or -not ($tpl['palette'] -is [hashtable])) {
        $tpl['palette'] = @{}
    }

    foreach ($k in $exp['palette'].Keys) {
        $tpl['palette'][$k] = $exp['palette'][$k]
    }
}

# Keep accent_color stable and aligned with the palette accent.
if ($tpl.ContainsKey('palette') -and $tpl['palette'] -is [hashtable] -and $tpl['palette'].ContainsKey('accent')) {
    $tpl['accent_color'] = $tpl['palette']['accent']
}

# Keep the non-divider theme's layout (blocks) intentionally.
# Also keep its accent_color format (hex) to remain stable for existing workflows.

# Write output
$tpl | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host "✅ Updated: $OutputPath" -ForegroundColor Green
