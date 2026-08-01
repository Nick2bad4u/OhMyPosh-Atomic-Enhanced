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
$GeneratedBaseUrl = 'https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/refs/heads/main'
$GeneratedFamilies = @{
    atomic               = 'OhMyPosh-Atomic-Custom.json'
    '1_shell'            = '1_shell-Enhanced.omp.json'
    slimfat              = 'slimfat-Enhanced.omp.json'
    atomicBit            = 'atomicBit-Enhanced.omp.json'
    cleanDetailed        = 'clean-detailed-Enhanced.omp.json'
    experimentalDividers = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json'
}

function Resolve-RepoPath {
    param([Parameter(Mandatory)][string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path -Path $RepoRoot -ChildPath $Path)
}

function Get-FileList {
    $base = @(
        'OhMyPosh-Atomic-Custom.json',
        'OhMyPosh-Atomic-Custom-ColorCycle.json',
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.ColorCycle.json',
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.Extended.json',
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.Gradient.json',
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRamps.json',
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRampsAutoShade.json',
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.NoNetwork.json',
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
            $directory = Resolve-RepoPath (Split-Path $g -Parent)
            $generatedFiles = @(Get-ChildItem -LiteralPath $directory -Filter (Split-Path $g -Leaf) -File -ErrorAction SilentlyContinue)
            if ($generatedFiles.Count -ne 37) {
                throw "Expected exactly 37 palette extensions in '$directory'; found $($generatedFiles.Count)."
            }
            if ($generatedFiles.Name -like '*.Original.json') {
                throw "Generated Original duplicate found in '$directory'."
            }
            $generatedFiles | ForEach-Object { $files.Add($_.FullName) }
        }
    }

    return ($files | Sort-Object -Unique)
}

function Fail([string]$Message) {
    throw $Message
}

function Get-GeneratedBasePath([string]$ThemePath) {
    $directoryName = Split-Path -Path (Split-Path -Path $ThemePath -Parent) -Leaf
    if (-not $GeneratedFamilies.ContainsKey($directoryName)) { return $null }
    return (Join-Path -Path $RepoRoot -ChildPath $GeneratedFamilies[$directoryName])
}

function Resolve-GeneratedTheme($overlay, [string]$basePath) {
    $base = Get-Content -LiteralPath $basePath -Raw | ConvertFrom-Json -Depth 200 -AsHashtable

    foreach ($entry in $overlay.palette.GetEnumerator()) {
        $base.palette[$entry.Key] = $entry.Value
    }

    if ($overlay.ContainsKey('accent_color')) {
        $base.accent_color = $overlay.accent_color
    }

    return ($base | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 200)
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
$extendsSmokeFiles = @{}

foreach ($file in $files) {
    $errors = New-Object System.Collections.Generic.List[string]
    $raw = $null
    $theme = $null
    $declaration = $null

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
        $declaration = $raw | ConvertFrom-Json -Depth 200 -AsHashtable
        $theme = $raw | ConvertFrom-Json -Depth 200

        $basePath = Get-GeneratedBasePath $file
        if ($basePath) {
            $leaf = Split-Path -Path $file -Leaf
            if ($leaf -like '*.Original.json') {
                $errors.Add('Generated Original duplicate found; the non-extended original belongs at the repository root.') | Out-Null
            }

            $allowedKeys = @('$schema', 'extends', 'palette', 'accent_color')
            $unexpectedKeys = @($declaration.Keys | Where-Object { $_ -notin $allowedKeys })
            if ($unexpectedKeys.Count -gt 0) {
                $errors.Add('Palette extension contains non-color properties: ' + ($unexpectedKeys -join ', ')) | Out-Null
            }

            $expectedExtends = "$GeneratedBaseUrl/$(Split-Path -Path $basePath -Leaf)"
            if ($declaration.extends -cne $expectedExtends) {
                $errors.Add("Incorrect extends target. Expected '$expectedExtends', found '$($declaration.extends)'.") | Out-Null
            }

            if (-not $declaration.ContainsKey('palette') -or $declaration.palette.Count -eq 0) {
                $errors.Add('Palette extension is missing its palette override.') | Out-Null
            }

            if (-not $extendsSmokeFiles.ContainsKey($basePath)) {
                $extendsSmokeFiles[$basePath] = $file
            }

            $raw = Get-Content -LiteralPath $basePath -Raw
            $theme = Resolve-GeneratedTheme -overlay $declaration -basePath $basePath
        }
        elseif ((Split-Path -Path $file -Leaf) -in $GeneratedFamilies.Values -and $declaration.extends) {
            $errors.Add('Root Original themes must be complete configs without an active extends target.') | Out-Null
        }

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

        $themeLeaf = Split-Path -Path $file -Leaf
        if ($themeLeaf -eq 'OhMyPosh-Atomic-Custom-ExperimentalDividers.Gradient.json') {
            $gradientItems = @($segments | Where-Object {
                    $colors = @([string]$_.background) + @($_.background_templates | ForEach-Object { [string]$_ })
                    ($colors -join ' ') -match 'linear-gradient\('
                })

            if ($gradientItems.Count -lt 10) {
                $errors.Add("Gradient helper has too few connected items: $($gradientItems.Count).") | Out-Null
            }

            $interactiveGradients = @($gradientItems | Where-Object {
                    $_.PSObject.Properties.Name -contains 'interactive' -and [bool]$_.interactive
                })
            if ($interactiveGradients.Count -gt 0) {
                $aliases = @($interactiveGradients.alias | Where-Object { $_ }) -join ', '
                $errors.Add("Gradient helper shades unsupported interactive items: $aliases") | Out-Null
            }

            $expectedDividerAliases = @('divider-15', 'divider-16')
            $remainingDividerAliases = @($theme.blocks.segments |
                Where-Object { [string]$_.alias -match '^divider(?:-|$)' } |
                ForEach-Object { [string]$_.alias } |
                Sort-Object)
            $unexpectedDividerAliases = @(Compare-Object `
                    -ReferenceObject @($expectedDividerAliases | Sort-Object) `
                    -DifferenceObject $remainingDividerAliases |
                ForEach-Object { [string]$_.InputObject })
            if ($unexpectedDividerAliases.Count -gt 0) {
                $errors.Add("Gradient helper must retain only the transparent divider caps: $($unexpectedDividerAliases -join ', ')") | Out-Null
            }

            if ($raw -match '(?:dark|light)-gradient\(') {
                $errors.Add('Gradient helper must use explicit two-stop linear gradients instead of auto-shade gradients.') | Out-Null
            }

            $shellGradient = @($theme.blocks.segments | Where-Object { $_.alias -eq 'shell-lprompt' })[0]
            if ([string]$shellGradient.background -cne 'linear-gradient(p:blue_primary, p:divider_navy_text_to_purple_exec)') {
                $errors.Add("Gradient helper has an incorrect shell entry gradient: $($shellGradient.background)") | Out-Null
            }

            $npmGradient = @($theme.blocks.segments | Where-Object { $_.alias -eq 'npm-rprompt' })[0]
            if ([string]$npmGradient.background -cne 'linear-gradient(p:yellow_dark, p:npm_yellow)') {
                $errors.Add("Gradient helper has an incorrect rprompt entry gradient: $($npmGradient.background)") | Out-Null
            }

            foreach ($requiredAlias in @('path-lprompt', 'git-lprompt')) {
                $requiredSegment = @($theme.blocks.segments | Where-Object { $_.alias -eq $requiredAlias })[0]
                if ($requiredSegment.PSObject.Properties.Name -notcontains 'interactive' -or [bool]$requiredSegment.interactive) {
                    $errors.Add("Gradient helper must make '$requiredAlias' non-interactive.") | Out-Null
                }
                if ([string]$requiredSegment.background -notmatch '^linear-gradient\(parentBackground, ') {
                    $errors.Add("Gradient helper does not connect '$requiredAlias' to parentBackground.") | Out-Null
                }
            }

            $gradientTooltips = @($theme.tooltips | Where-Object {
                    ((@([string]$_.background) + @($_.background_templates | ForEach-Object { [string]$_ })) -join ' ') -match 'gradient\('
                })
            if ($gradientTooltips.Count -gt 0) {
                $aliases = @($gradientTooltips.alias | Where-Object { $_ }) -join ', '
                $errors.Add("Gradient helper must leave standalone tooltips solid: $aliases") | Out-Null
            }
        }
        elseif ($themeLeaf -in @(
                'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRamps.json',
                'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRampsAutoShade.json'
            )) {
            $rampHelperName = if ($themeLeaf -like '*.GradientRampsAutoShade.json') {
                'GradientRampsAutoShade'
            }
            else {
                'GradientRamps'
            }
            $gradientItems = @($segments | Where-Object {
                    $colors = @([string]$_.background) + @($_.background_templates | ForEach-Object { [string]$_ })
                    ($colors -join ' ') -match '(?:linear|dark|light)-gradient\('
                })

            if ($gradientItems.Count -lt 20) {
                $errors.Add("$rampHelperName helper has too few connected items: $($gradientItems.Count).") | Out-Null
            }

            $interactiveGradients = @($gradientItems | Where-Object {
                    $_.PSObject.Properties.Name -contains 'interactive' -and [bool]$_.interactive
                })
            if ($interactiveGradients.Count -gt 0) {
                $aliases = @($interactiveGradients.alias | Where-Object { $_ }) -join ', '
                $errors.Add("$rampHelperName helper shades unsupported interactive items: $aliases") | Out-Null
            }

            $expectedRampAliases = @(
                'divider-root-lprompt-in-2',
                'divider-04',
                'divider-07',
                'divider-11',
                'divider-14b',
                'divider-21',
                'divider-23',
                'divider-25',
                'divider-27'
            )
            $gradientDividers = @($theme.blocks.segments | Where-Object {
                    [string]$_.alias -match '^divider(?:-|$)' -and
                    ((@([string]$_.background) + @($_.background_templates | ForEach-Object { [string]$_ })) -join ' ') -match '(?:linear|dark|light)-gradient\('
                })
            $unexpectedRampAliases = @(Compare-Object `
                    -ReferenceObject @($expectedRampAliases | Sort-Object) `
                    -DifferenceObject @($gradientDividers.alias | Sort-Object) |
                ForEach-Object { [string]$_.InputObject })
            if ($unexpectedRampAliases.Count -gt 0) {
                $errors.Add("$rampHelperName helper divider ramps do not match its definition: $($unexpectedRampAliases -join ', ')") | Out-Null
            }

            foreach ($rampAlias in $expectedRampAliases) {
                $rampSegment = @($gradientDividers | Where-Object { $_.alias -eq $rampAlias })[0]
                if ($null -eq $rampSegment) {
                    continue
                }
                $fullBlock = [string][char]0x2588
                $rampCellTemplate = [regex]::Replace([string]$rampSegment.template, '\{\{.*?\}\}', '')
                $expectedRampTemplate = "<background,transparent>$($fullBlock * 6)</>"
                if ($rampCellTemplate -cne $expectedRampTemplate) {
                    $errors.Add("$rampHelperName helper divider ramp '$rampAlias' does not contain exactly six position-matched full-block cells.") | Out-Null
                }
                if ([string]$rampSegment.template -match '[\uE0B0\uE0B2]') {
                    $errors.Add("$rampHelperName helper divider ramp '$rampAlias' retained a Powerline transition glyph.") | Out-Null
                }
            }

            $collapsedDividerAliases = @(
                'divider-root-lprompt-in',
                'divider-01',
                'divider-02',
                'divider-03',
                'divider-05',
                'divider-06',
                'divider-08',
                'divider-09',
                'divider-10',
                'divider-12',
                'divider-13',
                'divider-14',
                'divider-14a',
                'divider-17',
                'divider-18',
                'divider-19',
                'divider-20',
                'divider-22',
                'divider-24',
                'divider-battery-in',
                'divider-26'
            )
            $retainedCollapsedAliases = @($theme.blocks.segments.alias | Where-Object { $_ -in $collapsedDividerAliases })
            if ($retainedCollapsedAliases.Count -gt 0) {
                $errors.Add("$rampHelperName helper retained dividers that should be collapsed: $($retainedCollapsedAliases -join ', ')") | Out-Null
            }

            $shellGradient = @($theme.blocks.segments | Where-Object { $_.alias -eq 'shell-lprompt' })[0]
            $npmGradient = @($theme.blocks.segments | Where-Object { $_.alias -eq 'npm-rprompt' })[0]
            $rightBlockGradient = @($theme.blocks.segments | Where-Object { $_.alias -eq 'divider-21' })[0]
            if ($rampHelperName -eq 'GradientRamps') {
                if ($raw -match '(?:dark|light)-gradient\(') {
                    $errors.Add('GradientRamps helper must use explicit two-stop linear gradients instead of auto-shade gradients.') | Out-Null
                }
                if ([string]$shellGradient.background -cne 'linear-gradient(p:blue_primary, p:divider_navy_text_to_purple_exec)') {
                    $errors.Add("GradientRamps helper has an incorrect shell entry gradient: $($shellGradient.background)") | Out-Null
                }
                if ([string]$npmGradient.background -cne 'linear-gradient(p:yellow_dark, p:npm_yellow)') {
                    $errors.Add("GradientRamps helper has an incorrect rprompt entry gradient: $($npmGradient.background)") | Out-Null
                }
                if ([string]$rightBlockGradient.background -cne 'linear-gradient(p:divider_green_ahead, p:divider_teal_sysinfo)') {
                    $errors.Add("GradientRamps helper has an incorrect right-block entry gradient: $($rightBlockGradient.background)") | Out-Null
                }
            }
            else {
                $autoShadeItems = @($theme.blocks.segments | Where-Object {
                        ((@([string]$_.background) + @($_.background_templates | ForEach-Object { [string]$_ })) -join ' ') -match '(?:dark|light)-gradient\('
                    })
                $unexpectedAutoShadeAliases = @(Compare-Object `
                        -ReferenceObject @('divider-21', 'npm-rprompt', 'shell-lprompt') `
                        -DifferenceObject @($autoShadeItems.alias | Sort-Object) |
                    ForEach-Object { [string]$_.InputObject })
                if ($unexpectedAutoShadeAliases.Count -gt 0) {
                    $errors.Add("GradientRampsAutoShade helper auto-shaded entries do not match its definition: $($unexpectedAutoShadeAliases -join ', ')") | Out-Null
                }
                $expectedAutoShadeBackgrounds = @{
                    'shell-lprompt' = 'dark-gradient(p:blue_primary)'
                    'npm-rprompt'   = 'dark-gradient(p:npm_yellow)'
                    'divider-21'    = 'dark-gradient(p:divider_teal_sysinfo)'
                }
                foreach ($entryAlias in $expectedAutoShadeBackgrounds.Keys) {
                    $entrySegment = @($theme.blocks.segments | Where-Object { $_.alias -eq $entryAlias })[0]
                    if ([string]$entrySegment.background -cne $expectedAutoShadeBackgrounds[$entryAlias]) {
                        $errors.Add("GradientRampsAutoShade helper has an incorrect '$entryAlias' entry gradient: $($entrySegment.background)") | Out-Null
                    }
                }
            }

            foreach ($requiredAlias in @('path-lprompt', 'git-lprompt')) {
                $requiredSegment = @($theme.blocks.segments | Where-Object { $_.alias -eq $requiredAlias })[0]
                if ($requiredSegment.PSObject.Properties.Name -notcontains 'interactive' -or [bool]$requiredSegment.interactive) {
                    $errors.Add("$rampHelperName helper must make '$requiredAlias' non-interactive.") | Out-Null
                }
                if ([string]$requiredSegment.background -notmatch '^linear-gradient\(parentBackground, ') {
                    $errors.Add("$rampHelperName helper does not connect '$requiredAlias' to parentBackground.") | Out-Null
                }
            }

            $gradientTooltips = @($theme.tooltips | Where-Object {
                    ((@([string]$_.background) + @($_.background_templates | ForEach-Object { [string]$_ })) -join ' ') -match 'gradient\('
                })
            if ($gradientTooltips.Count -gt 0) {
                $aliases = @($gradientTooltips.alias | Where-Object { $_ }) -join ', '
                $errors.Add("$rampHelperName helper must leave standalone tooltips solid: $aliases") | Out-Null
            }
        }
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

# Exercise Oh My Posh's real merge implementation once per generated family when
# the CLI is available. CI environments without the CLI still receive the strict
# declaration and local merge checks above.
if ($IncludeGenerated -and $extendsSmokeFiles.Count -gt 0 -and (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    $tempRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("omp-theme-extends-{0}" -f [guid]::NewGuid())
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

    try {
        foreach ($basePath in $extendsSmokeFiles.Keys) {
            $overlayPath = $extendsSmokeFiles[$basePath]
            $overlay = Get-Content -LiteralPath $overlayPath -Raw | ConvertFrom-Json -Depth 200 -AsHashtable

            $name = Split-Path -Path (Split-Path -Path $overlayPath -Parent) -Leaf
            $remoteResolvedPath = Join-Path -Path $tempRoot -ChildPath "$name.remote.resolved.json"
            $remoteOutput = & oh-my-posh config export --config $overlayPath --output $remoteResolvedPath 2>&1
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $remoteResolvedPath)) {
                $allErrors.Add("${overlayPath}: oh-my-posh failed to resolve the emitted extends URL: $($remoteOutput -join ' ')") | Out-Null
                continue
            }

            $remoteResolved = Get-Content -LiteralPath $remoteResolvedPath -Raw | ConvertFrom-Json -Depth 200
            if (-not $remoteResolved.blocks -or -not $remoteResolved.palette) {
                $allErrors.Add("${overlayPath}: emitted extends URL resolved without inherited blocks or palette.") | Out-Null
                continue
            }

            $overlay.extends = $basePath
            $localOverlayPath = Join-Path -Path $tempRoot -ChildPath "$name.json"
            $resolvedPath = Join-Path -Path $tempRoot -ChildPath "$name.resolved.json"
            $overlay | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $localOverlayPath -Encoding utf8

            $exportOutput = & oh-my-posh config export --config $localOverlayPath --output $resolvedPath 2>&1
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $resolvedPath)) {
                $allErrors.Add("${overlayPath}: oh-my-posh failed to resolve extends: $($exportOutput -join ' ')") | Out-Null
                continue
            }

            $resolved = Get-Content -LiteralPath $resolvedPath -Raw | ConvertFrom-Json -Depth 200
            if (-not $resolved.blocks -or -not $resolved.palette) {
                $allErrors.Add("${overlayPath}: resolved config is missing inherited blocks or palette.") | Out-Null
            }
        }
    }
    finally {
        $resolvedTempRoot = [System.IO.Path]::GetFullPath($tempRoot)
        $systemTempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
        if ($resolvedTempRoot.StartsWith($systemTempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $resolvedTempRoot -Recurse -Force
        }
    }
}

# The generated-set gate also proves all 38 curated palettes across all six
# family roots and verifies that every overlay matches the palette source.
if ($IncludeGenerated) {
    $visualQualityScript = Resolve-RepoPath 'scripts/Test-PaletteVisualQuality.ps1'
    if (-not (Test-Path -LiteralPath $visualQualityScript)) {
        $allErrors.Add("Palette visual-quality script not found: $visualQualityScript") | Out-Null
    }
    else {
        $visualQualityOutput = & pwsh -NoProfile -File $visualQualityScript 2>&1
        if ($LASTEXITCODE -ne 0) {
            $allErrors.Add("Palette visual-quality validation failed: $($visualQualityOutput -join ' ')") | Out-Null
        }
        else {
            $visualQualityOutput | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
        }
    }
}

# Root helper themes are generated artifacts. Regenerate them into an isolated
# temporary directory and compare normalized JSON so CI catches source/fixture
# drift without rewriting the worktree.
$generatorChecks = @(
    @{
        Name      = 'Atomic ColorCycle'
        Script    = Resolve-RepoPath 'scripts/Make-ColorCycleVariant.ps1'
        Expected  = Resolve-RepoPath 'OhMyPosh-Atomic-Custom-ColorCycle.json'
        Parameters = @{ Source = Resolve-RepoPath 'OhMyPosh-Atomic-Custom.json' }
    },
    @{
        Name      = 'ExperimentalDividers ColorCycle'
        Script    = Resolve-RepoPath 'scripts/Make-ColorCycleVariant.ps1'
        Expected  = Resolve-RepoPath 'OhMyPosh-Atomic-Custom-ExperimentalDividers.ColorCycle.json'
        Parameters = @{ Source = Resolve-RepoPath 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json' }
    },
    @{
        Name      = 'ExperimentalDividers Extended'
        Script    = Resolve-RepoPath 'scripts/Make-ExtendedVariant.ps1'
        Expected  = Resolve-RepoPath 'OhMyPosh-Atomic-Custom-ExperimentalDividers.Extended.json'
        Parameters = @{ Source = Resolve-RepoPath 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json' }
    },
    @{
        Name      = 'ExperimentalDividers Gradient'
        Script    = Resolve-RepoPath 'scripts/Make-GradientVariant.ps1'
        Expected  = Resolve-RepoPath 'OhMyPosh-Atomic-Custom-ExperimentalDividers.Gradient.json'
        Parameters = @{ Source = Resolve-RepoPath 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json' }
    },
    @{
        Name      = 'ExperimentalDividers GradientRamps'
        Script    = Resolve-RepoPath 'scripts/Make-GradientRampsVariant.ps1'
        Expected  = Resolve-RepoPath 'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRamps.json'
        Parameters = @{ Source = Resolve-RepoPath 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json' }
    },
    @{
        Name      = 'ExperimentalDividers GradientRampsAutoShade'
        Script    = Resolve-RepoPath 'scripts/Make-GradientRampsAutoShadeVariant.ps1'
        Expected  = Resolve-RepoPath 'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRampsAutoShade.json'
        Parameters = @{ Source = Resolve-RepoPath 'OhMyPosh-Atomic-Custom-ExperimentalDividers.json' }
    }
)

$generatorTempRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("omp-theme-generators-{0}" -f [guid]::NewGuid())
New-Item -ItemType Directory -Path $generatorTempRoot -Force | Out-Null

try {
    foreach ($check in $generatorChecks) {
        if (-not (Test-Path -LiteralPath $check.Script)) {
            $allErrors.Add("$($check.Name): generator script not found: $($check.Script)") | Out-Null
            continue
        }
        if (-not (Test-Path -LiteralPath $check.Expected)) {
            $allErrors.Add("$($check.Name): generated theme not found: $($check.Expected)") | Out-Null
            continue
        }

        $generatedPath = Join-Path -Path $generatorTempRoot -ChildPath (Split-Path -Path $check.Expected -Leaf)
        $parameters = @{} + $check.Parameters
        $parameters.Destination = $generatedPath

        try {
            $null = & $check.Script @parameters
            $expectedJson = Get-Content -LiteralPath $check.Expected -Raw | ConvertFrom-Json -Depth 100 -AsHashtable | ConvertTo-Json -Depth 100 -Compress
            $generatedJson = Get-Content -LiteralPath $generatedPath -Raw | ConvertFrom-Json -Depth 100 -AsHashtable | ConvertTo-Json -Depth 100 -Compress
            if ($expectedJson -cne $generatedJson) {
                $allErrors.Add("$($check.Name): generated output is stale; run $($check.Script).") | Out-Null
            }
        }
        catch {
            $allErrors.Add("$($check.Name): generator check failed: $($_.Exception.Message)") | Out-Null
        }
    }
}
finally {
    $resolvedGeneratorTempRoot = [System.IO.Path]::GetFullPath($generatorTempRoot)
    $systemTempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
    if ($resolvedGeneratorTempRoot.StartsWith($systemTempRoot, [StringComparison]::OrdinalIgnoreCase)) {
        Remove-Item -LiteralPath $resolvedGeneratorTempRoot -Recurse -Force
    }
}

if ($allErrors.Count -gt 0) {
    Write-Host "\nTheme tests FAILED ($($allErrors.Count) issue(s))." -ForegroundColor Red
    foreach ($errorMessage in $allErrors) {
        Write-Host "  - $errorMessage" -ForegroundColor Red
    }
    exit 1
}

Write-Host '\nAll theme tests passed.' -ForegroundColor Green
exit 0
