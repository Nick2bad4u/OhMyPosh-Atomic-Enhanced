<#
.SYNOPSIS
Smoke-tests deterministic Oh My Posh v30 SVG preview generation.

.DESCRIPTION
Runs the repository preview generator against all three gradient variants and two
generated extends overlays, then validates the resulting SVG documents. The
test writes only to a uniquely named system temporary directory and removes it.

.PARAMETER MinimumOhMyPoshVersion
Minimum supported Oh My Posh CLI version. The CI workflow installs the exact
v30.0.0 release before invoking this test.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [version]$MinimumOhMyPoshVersion = '30.0.0',

    [Parameter()]
    [ValidateRange(1, 10000)]
    [int]$ExpectedGalleryCount = 237
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Path $PSScriptRoot -Parent
$GeneratorPath = Join-Path -Path $PSScriptRoot -ChildPath 'Generate-ThemePreviews.ps1'
$PreviewDataPath = Join-Path -Path $RepoRoot -ChildPath 'theme-preview.data.json'
$SettingsPath = Join-Path -Path $RepoRoot -ChildPath 'image.settings.json'
$TemporaryRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$OutputDirectory = Join-Path -Path $TemporaryRoot -ChildPath ("omp-preview-smoke-{0}" -f [guid]::NewGuid())

function Get-InstalledOhMyPoshVersion {
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        throw 'oh-my-posh was not found in PATH.'
    }

    $global:LASTEXITCODE = 0
    $versionText = [string](& oh-my-posh version 2>$null | Select-Object -First 1)
    if ($LASTEXITCODE -ne 0 -or $versionText -notmatch '(?<version>\d+\.\d+\.\d+)') {
        throw "Unable to determine the installed Oh My Posh version from '$versionText'."
    }

    return [version]$Matches.version
}

function Get-SvgDocument {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing generated SVG: $Path"
    }

    try {
        [xml]$document = Get-Content -LiteralPath $Path -Raw
    }
    catch {
        throw "Generated preview is not valid XML: $Path"
    }

    if ($document.DocumentElement.LocalName -ne 'svg' -or
        $document.DocumentElement.NamespaceURI -ne 'http://www.w3.org/2000/svg') {
        throw "Generated preview does not have an SVG root element: $Path"
    }

    return $document
}

function Assert-CommittedGallery {
    param(
        [Parameter(Mandatory)][string]$AssetDirectory,
        [Parameter(Mandatory)][string]$ReadmePath,
        [Parameter(Mandatory)][int]$ExpectedCount
    )

    $svgFiles = @(Get-ChildItem -LiteralPath $AssetDirectory -Filter '*.svg' -File)
    $legacyPngFiles = @(Get-ChildItem -LiteralPath $AssetDirectory -Filter '*.png' -File)
    if ($svgFiles.Count -ne $ExpectedCount) {
        throw "Expected $ExpectedCount committed SVG previews; found $($svgFiles.Count)."
    }
    if ($legacyPngFiles.Count -ne 0) {
        throw "Committed gallery still contains legacy PNG previews: $($legacyPngFiles.Name -join ', ')"
    }

    foreach ($file in $svgFiles) {
        $null = Get-SvgDocument -Path $file.FullName
    }

    $readme = Get-Content -LiteralPath $ReadmePath -Raw
    $referenceMatches = [regex]::Matches($readme, 'assets/theme-previews/([^"\s]+\.svg)')
    $references = @($referenceMatches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    if ($references.Count -ne $ExpectedCount) {
        throw "Expected $ExpectedCount unique README SVG references; found $($references.Count)."
    }

    $missingTargets = @($references | Where-Object {
            -not (Test-Path -LiteralPath (Join-Path -Path $AssetDirectory -ChildPath $_))
        })
    $orphanedFiles = @($svgFiles.Name | Where-Object { $_ -notin $references })
    if ($missingTargets.Count -ne 0) {
        throw "README references missing SVG previews: $($missingTargets -join ', ')"
    }
    if ($orphanedFiles.Count -ne 0) {
        throw "SVG previews are missing from README: $($orphanedFiles -join ', ')"
    }

    $repoRoot = Split-Path -Path $ReadmePath -Parent
    $originalPreviewNames = @{
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.json' = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.Original.svg'
        'OhMyPosh-Atomic-Custom.json'                      = 'OhMyPosh-Atomic-Custom.Original.svg'
        '1_shell-Enhanced.omp.json'                        = '1_shell-Enhanced.omp.Original.svg'
        'slimfat-Enhanced.omp.json'                        = 'slimfat-Enhanced.omp.Original.svg'
        'atomicBit-Enhanced.omp.json'                      = 'atomicBit-Enhanced.omp.Original.svg'
        'clean-detailed-Enhanced.omp.json'                 = 'clean-detailed-Enhanced.omp.Original.svg'
    }
    $rootThemePreviews = @(foreach ($file in Get-ChildItem -LiteralPath $repoRoot -Filter '*.json' -File) {
            $candidate = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json -Depth 100 -AsHashtable
            if (-not $candidate.Contains('blocks') -and -not $candidate.Contains('extends')) {
                continue
            }

            if ($originalPreviewNames.ContainsKey($file.Name)) {
                $originalPreviewNames[$file.Name]
            }
            else {
                "$($file.BaseName).svg"
            }
        })
    $uniqueRootThemePreviews = @($rootThemePreviews | Sort-Object -Unique)
    if ($uniqueRootThemePreviews.Count -ne $rootThemePreviews.Count) {
        throw 'Multiple root themes map to the same SVG preview name.'
    }

    $missingRootPreviews = @($uniqueRootThemePreviews | Where-Object {
            -not (Test-Path -LiteralPath (Join-Path -Path $AssetDirectory -ChildPath $_))
        })
    $missingRootReferences = @($uniqueRootThemePreviews | Where-Object { $_ -notin $references })
    if ($missingRootPreviews.Count -ne 0) {
        throw "Root themes are missing SVG previews: $($missingRootPreviews -join ', ')"
    }
    if ($missingRootReferences.Count -ne 0) {
        throw "Root theme previews are missing from README: $($missingRootReferences -join ', ')"
    }
}

$installedVersion = Get-InstalledOhMyPoshVersion
if ($installedVersion -lt $MinimumOhMyPoshVersion) {
    throw "Oh My Posh v$MinimumOhMyPoshVersion or later is required; found v$installedVersion."
}

$themes = @(
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.Gradient.json'
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRamps.json'
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRampsAutoShade.json'
    'experimentalDividers/OhMyPosh-Atomic-Custom-ExperimentalDividers.NordFrost.json'
    'cleanDetailed/clean-detailed-Enhanced.omp.OneDark.json'
)
$settings = Get-Content -LiteralPath $SettingsPath -Raw | ConvertFrom-Json -Depth 20 -AsHashtable

try {
    & $GeneratorPath `
        -ThemePattern $themes `
        -ImageSettings $SettingsPath `
        -PreviewData $PreviewDataPath `
        -OutputDirectory $OutputDirectory `
        -SkipReadmeUpdate `
        -Force

    $expectedPreviews = [ordered]@{
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.Gradient.svg'      = 200
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRamps.svg' = 200
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRampsAutoShade.svg' = 200
        'OhMyPosh-Atomic-Custom-ExperimentalDividers.NordFrost.svg'              = 200
        'clean-detailed-Enhanced.omp.OneDark.svg'                                = 100
    }
    $expectedNames = @($expectedPreviews.Keys)

    foreach ($name in $expectedNames) {
        $path = Join-Path -Path $OutputDirectory -ChildPath $name
        $document = Get-SvgDocument -Path $path

        $fontFamily = [string]$document.DocumentElement.GetAttribute('font-family')
        if ($fontFamily -notmatch 'CodeNewRoman Nerd Font Mono') {
            throw "$name did not receive the configured v30 --font-family value."
        }

        $width = [double]::Parse(
            $document.DocumentElement.GetAttribute('width'),
            [Globalization.CultureInfo]::InvariantCulture
        )
        $height = [double]::Parse(
            $document.DocumentElement.GetAttribute('height'),
            [Globalization.CultureInfo]::InvariantCulture
        )
        if ($width -le 0 -or $height -le 0) {
            throw "$name has invalid SVG dimensions."
        }
        $expectedSvgWidth = 32 + ([double]$expectedPreviews[$name] * 16 * [double]$settings.cell_width)
        if ([math]::Abs($width - $expectedSvgWidth) -gt 0.02) {
            throw "$name did not receive the configured v30 --terminal-width and --cell-width values."
        }

        $svgText = Get-Content -LiteralPath $path -Raw
        $backgroundPattern = 'class="omp-window-content"\s+fill="{0}"' -f [regex]::Escape([string]$settings.background_color)
        if ($svgText -notmatch $backgroundPattern) {
            throw "$name did not receive the configured v30 --background-color value."
        }
    }

    $legacyPngs = @(Get-ChildItem -LiteralPath $OutputDirectory -Filter '*.png' -File)
    if ($legacyPngs.Count -ne 0) {
        throw "Preview smoke test produced legacy PNG output: $($legacyPngs.Name -join ', ')"
    }

    $gradientPath = Join-Path -Path $OutputDirectory -ChildPath $expectedNames[0]
    $rampsPath = Join-Path -Path $OutputDirectory -ChildPath $expectedNames[1]
    $autoShadePath = Join-Path -Path $OutputDirectory -ChildPath $expectedNames[2]
    $gradientHash = (Get-FileHash -LiteralPath $gradientPath -Algorithm SHA256).Hash
    $rampsHash = (Get-FileHash -LiteralPath $rampsPath -Algorithm SHA256).Hash
    $autoShadeHash = (Get-FileHash -LiteralPath $autoShadePath -Algorithm SHA256).Hash
    $uniqueGradientHashes = @(@($gradientHash, $rampsHash, $autoShadeHash) | Sort-Object -Unique)
    if ($uniqueGradientHashes.Count -ne 3) {
        throw 'The gradient variants must produce distinct SVG output.'
    }

    $rampsSvg = Get-Content -LiteralPath $rampsPath -Raw
    if (-not $rampsSvg.Contains('█')) {
        throw 'GradientRamps SVG does not contain its position-matched full-block ramp glyphs.'
    }
    $autoShadeSvg = Get-Content -LiteralPath $autoShadePath -Raw
    if (-not $autoShadeSvg.Contains('█')) {
        throw 'GradientRampsAutoShade SVG does not contain its position-matched full-block ramp glyphs.'
    }

    Assert-CommittedGallery `
        -AssetDirectory (Join-Path -Path $RepoRoot -ChildPath 'assets/theme-previews') `
        -ReadmePath (Join-Path -Path $RepoRoot -ChildPath 'README.md') `
        -ExpectedCount $ExpectedGalleryCount

    Write-Output "Oh My Posh v$installedVersion SVG preview smoke test passed: $($expectedNames.Count) runtime previews and $ExpectedGalleryCount committed gallery previews."
}
finally {
    $resolvedOutput = [System.IO.Path]::GetFullPath($OutputDirectory)
    if ($resolvedOutput.StartsWith($TemporaryRoot, [StringComparison]::OrdinalIgnoreCase) -and
        (Test-Path -LiteralPath $resolvedOutput)) {
        Remove-Item -LiteralPath $resolvedOutput -Recurse -Force
    }
}
