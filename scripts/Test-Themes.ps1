<#
.SYNOPSIS
Repo test runner for Oh My Posh theme files.

.DESCRIPTION
This script performs "CI-grade" validation on the base theme templates in this repo:
- JSON parse validation (fails on duplicate keys)
- Palette reference validation (p:<key> must exist)
- No secrets-file references (repo removed secrets.json/schema workflows)
- Network segment hygiene checks (timeouts, cache, https URLs, env var usage for API keys)

By default this validates the primary templates (root-level theme JSONs).

.PARAMETER IncludeGenerated
If set, also validates generated theme variants in the theme family folders (can be slower).

.EXAMPLE
pwsh ./scripts/Test-Themes.ps1
pwsh ./scripts/Test-Themes.ps1 -IncludeGenerated
#>

[CmdletBinding()]
param(
    [switch]$IncludeGenerated
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Path $PSScriptRoot -Parent

function Resolve-RepoPath {
    param([Parameter(Mandatory)][string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path -Path $RepoRoot -ChildPath $Path)
}

function Get-FileList {
    $base = @(
        'OhMyPosh-Atomic-Custom.json',
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.NoShellIntegration.json',
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.Fish.json',
        '1_shell-Enhanced.omp.json',
        'slimfat-Enhanced.omp.json',
        'atomicBit-Enhanced.omp.json',
        'clean-detailed-Enhanced.omp.json'
    ) | ForEach-Object { Resolve-RepoPath $_ }

    $files = New-Object System.Collections.Generic.List[string]
    foreach ($f in $base) {
        if (Test-Path -LiteralPath $f) { $files.Add($f) }
        else { Write-Warning "Missing base theme file (skipped): $f" }
    }

    if ($IncludeGenerated) {
        $globs = @(
            'atomic/*.json',
            '1_shell/*.json',
            'slimfat/*.json',
            'atomicBit/*.json',
            'cleanDetailed/*.json',
            'experimentalDividers/*.json'
        )

        foreach ($g in $globs) {
            Get-ChildItem -LiteralPath (Resolve-RepoPath (Split-Path $g -Parent)) -Filter (Split-Path $g -Leaf) -File -ErrorAction SilentlyContinue |
                ForEach-Object { $files.Add($_.FullName) }
        }
    }

    return ($files | Sort-Object -Unique)
}

function Fail([string]$Message) {
    throw $Message
}

function Get-AllSegments($theme) {
    $all = New-Object System.Collections.Generic.List[object]

    if ($theme.blocks) {
        foreach ($b in $theme.blocks) {
            if ($b.segments) {
                foreach ($s in $b.segments) { $all.Add($s) }
            }
        }
    }

    if ($theme.tooltips) {
        foreach ($t in $theme.tooltips) { $all.Add($t) }
    }

    return $all
}

function Get-SegmentTypeLower($seg) {
    $t = $seg.type
    if (-not $t) { $t = $seg.Type }
    if (-not $t) { return '' }
    return ([string]$t).ToLowerInvariant()
}

function Get-SegmentOptions($seg) {
    # Oh My Posh renamed segment config key in some versions: properties <-> options.
    $opt = $seg.options
    if ($null -eq $opt) { $opt = $seg.properties }
    return $opt
}

function Assert-TimeoutInRange($value, [string]$label, [ref]$errors) {
    if ($null -eq $value) { return }
    try {
        $n = [int]$value
        if ($n -lt 250 -or $n -gt 60000) {
            $errors.Value.Add("$label out of range (250..60000): $n") | Out-Null
        }
    }
    catch {
        $errors.Value.Add("$label is not an integer: $value") | Out-Null
    }
}

$files = Get-FileList
if (-not $files -or $files.Count -eq 0) {
    Fail 'No theme files found to test.'
}

Write-Host "Testing $($files.Count) theme file(s)..." -ForegroundColor Cyan

$allErrors = New-Object System.Collections.Generic.List[string]

foreach ($file in $files) {
    $errors = New-Object System.Collections.Generic.List[string]
    $raw = $null
    $theme = $null

    try {
        $raw = Get-Content -LiteralPath $file -Raw

        # Quick "no secrets files" guard
        if ($raw -match 'secrets\.schema\.json|secrets\.example\.json|OhMyPosh-Atomic-Custom\.secrets\.json') {
            $errors.Add('Theme references removed secrets files (should use env vars directly).') | Out-Null
        }

        # Guard against placeholder secrets accidentally being committed inside theme JSON
        if ($raw -match '"(api_key|access_token|refresh_token|token)"\s*:\s*"YOUR_') {
            $errors.Add('Theme appears to contain placeholder secret values (YOUR_*). Use environment variables instead.') | Out-Null
        }

        # Parse JSON (ConvertFrom-Json fails on duplicate keys)
        $theme = $raw | ConvertFrom-Json -Depth 200

        # Palette validation
        if ($null -eq $theme.palette -or -not $theme.palette.PSObject.Properties) {
            $errors.Add('Missing or invalid palette object.') | Out-Null
        }
        else {
            $paletteKeys = @($theme.palette.PSObject.Properties.Name)
            $refs = [regex]::Matches($raw, 'p:([a-zA-Z0-9_\-\.]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
            $missing = @($refs | Where-Object { $_ -notin $paletteKeys })
            if ($missing.Count -gt 0) {
                $errors.Add('Missing palette keys: ' + ($missing -join ', ')) | Out-Null
            }
        }

        # Segment hygiene checks
        $segments = Get-AllSegments $theme

        foreach ($seg in $segments) {
            $t = Get-SegmentTypeLower $seg
            $opt = Get-SegmentOptions $seg

            switch ($t) {
                'http' {
                    if ($null -eq $opt -or -not $opt.url) {
                        $errors.Add('http segment missing options.url') | Out-Null
                    }
                    elseif ($opt.url -notmatch '^https://') {
                        $errors.Add("http segment url is not https: $($opt.url)") | Out-Null
                    }

                    if ($null -eq $opt -or -not $opt.method) {
                        $errors.Add('http segment missing options.method') | Out-Null
                    }

                    if ($null -eq $seg.cache -or -not $seg.cache.duration -or -not $seg.cache.strategy) {
                        $errors.Add('http segment missing cache.duration/strategy') | Out-Null
                    }

                    # Timeouts: either top-level timeout or options.http_timeout
                    $timeout = $seg.timeout
                    if ($null -eq $timeout) { $timeout = $opt.http_timeout }
                    if ($null -eq $timeout) {
                        $errors.Add('http segment missing timeout/http_timeout') | Out-Null
                    }
                    else {
                        Assert-TimeoutInRange $timeout 'http timeout' ([ref]$errors)
                    }
                }

                'ipify' {
                    if ($null -eq $seg.cache -or -not $seg.cache.duration) {
                        $errors.Add('ipify segment missing cache.duration') | Out-Null
                    }
                    $timeout = $seg.http_timeout
                    if ($null -ne $timeout) { Assert-TimeoutInRange $timeout 'ipify http_timeout' ([ref]$errors) }
                }

                'owm' {
                    # Oh My Posh may read the OWM API key directly from env vars without requiring it in the theme.
                    # If api_key is present in the theme, ensure it's sourced from env vars (not hard-coded).
                    if ($opt -and $opt.api_key -and ([string]$opt.api_key -notmatch '\.Env\.')) {
                        $errors.Add('owm api_key is present but does not appear to come from env vars (expected .Env.*).') | Out-Null
                    }
                    if ($null -ne $opt.http_timeout) { Assert-TimeoutInRange $opt.http_timeout 'owm http_timeout' ([ref]$errors) }
                }

                'lastfm' {
                    if ($opt -and $opt.api_key -and ([string]$opt.api_key -notmatch '\.Env\.')) {
                        $errors.Add('lastfm api_key is present but does not appear to come from env vars (expected .Env.*).') | Out-Null
                    }
                    if ($opt -and $opt.username -and ([string]$opt.username -notmatch '\.Env\.')) {
                        $errors.Add('lastfm username is present but does not appear to come from env vars (expected .Env.*).') | Out-Null
                    }
                    if ($null -ne $opt.http_timeout) { Assert-TimeoutInRange $opt.http_timeout 'lastfm http_timeout' ([ref]$errors) }
                }

                'strava' {
                    foreach ($k in @('access_token', 'refresh_token')) {
                        $v = if ($opt) { $opt.$k } else { $null }
                        if ($v -and ([string]$v -notmatch '\.Env\.')) { $errors.Add("strava $k is present but does not appear to come from env vars (expected .Env.*)") | Out-Null }
                    }
                }

                'withings' {
                    foreach ($k in @('access_token', 'refresh_token')) {
                        $v = if ($opt) { $opt.$k } else { $null }
                        if ($v -and ([string]$v -notmatch '\.Env\.')) { $errors.Add("withings $k is present but does not appear to come from env vars (expected .Env.*)") | Out-Null }
                    }
                }

                default { }
            }
        }
    }
    catch {
        $errors.Add($_.Exception.Message) | Out-Null
    }

    if ($errors.Count -gt 0) {
        Write-Host "✗ $file" -ForegroundColor Red
        foreach ($e in $errors) {
            Write-Host "  - $e" -ForegroundColor Red
            $allErrors.Add("${file}: $e") | Out-Null
        }
    }
    else {
        Write-Host "✓ $file" -ForegroundColor Green
    }
}

if ($allErrors.Count -gt 0) {
    Write-Host "\nTheme tests FAILED ($($allErrors.Count) issue(s))." -ForegroundColor Red
    exit 1
}

Write-Host '\nAll theme tests passed.' -ForegroundColor Green
exit 0
