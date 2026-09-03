<#
.SYNOPSIS
    Verifies batch generator and merger process contracts.

.DESCRIPTION
    Runs focused subprocess checks for successful generation and merging, caught
    generation failures, empty merge inputs, malformed themes, mixed merge
    results, and unwritable output paths. All fixtures and outputs are isolated
    under a temporary directory.
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$pwshPath = (Get-Command pwsh -ErrorAction Stop).Source
$temporaryBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$temporaryRoot = [System.IO.Path]::GetFullPath(
    (Join-Path -Path $temporaryBase -ChildPath "omp-failure-contracts-$([guid]::NewGuid().ToString('N'))")
)
$pathComparison = if ($IsWindows) {
    [System.StringComparison]::OrdinalIgnoreCase
}
else {
    [System.StringComparison]::Ordinal
}

if (-not $temporaryRoot.StartsWith($temporaryBase, $pathComparison) -or
    [System.IO.Path]::GetFileName($temporaryRoot) -notlike 'omp-failure-contracts-*') {
    throw "Refusing to use unexpected test path: $temporaryRoot"
}

function Invoke-ExpectedFailure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [Parameter()]
        [string[]]$Arguments = @()
    )

    $output = @(& $pwshPath -NoLogo -NoProfile -File $ScriptPath @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
        $tail = @($output | Select-Object -Last 10) -join [Environment]::NewLine
        throw "$Name unexpectedly returned process success.$([Environment]::NewLine)$tail"
    }

    Write-Information -MessageData "PASS: $Name returned exit code $exitCode." -InformationAction Continue
}

function Invoke-ExpectedSuccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ScriptPath,

        [Parameter()]
        [string[]]$Arguments = @()
    )

    $output = @(& $pwshPath -NoLogo -NoProfile -File $ScriptPath @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $tail = @($output | Select-Object -Last 10) -join [Environment]::NewLine
        throw "$Name returned exit code $exitCode.$([Environment]::NewLine)$tail"
    }

    Write-Information -MessageData "PASS: $Name returned process success." -InformationAction Continue
}

function Assert-TemplateValuePreserved {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CustomSegment,

        [Parameter(Mandatory)]
        [object]$MergedSegment,

        [Parameter(Mandatory)]
        [string]$Location
    )

    $customHasTemplate = $CustomSegment.PSObject.Properties.Name -contains 'template'
    $mergedHasTemplate = $MergedSegment.PSObject.Properties.Name -contains 'template'
    if ($customHasTemplate -ne $mergedHasTemplate -or
        ($customHasTemplate -and $CustomSegment.template -cne $MergedSegment.template)) {
        throw "Merge changed the custom template at $Location."
    }
}

New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null

try {
    $generateRoot = Join-Path -Path $temporaryRoot -ChildPath 'generate'
    $generateOutput = Join-Path -Path $generateRoot -ChildPath 'output'
    New-Item -ItemType Directory -Path $generateOutput -Force | Out-Null

    $sourceTheme = Join-Path -Path $generateRoot -ChildPath 'source.json'
    [System.IO.File]::WriteAllText(
        $sourceTheme,
        '{"$schema":"https://example.invalid/theme.schema.json","blocks":[],"palette":{}}'
    )

    $brokenPalettes = Join-Path -Path $generateRoot -ChildPath 'palettes.json'
    [System.IO.File]::WriteAllText(
        $brokenPalettes,
        '{"palettes":{"broken_palette":{"Name":"Broken Palette","description":"Intentional failure fixture","Palette":"not-an-object"}}}'
    )

    $retainedOutput = Join-Path -Path $generateOutput -ChildPath 'source.BrokenPalette.json'
    [System.IO.File]::WriteAllText($retainedOutput, 'existing-output-must-survive')

    Invoke-ExpectedFailure -Name 'Generate-AllThemes child failure' `
        -ScriptPath (Join-Path -Path $PSScriptRoot -ChildPath 'Generate-AllThemes.ps1') `
        -Arguments @(
            '-SourceThemes', $sourceTheme,
            '-PalettesFile', $brokenPalettes,
            '-OutputDirectory', $generateOutput,
            '-Force'
        )

    if ([System.IO.File]::ReadAllText($retainedOutput) -ne 'existing-output-must-survive') {
        throw 'Generate-AllThemes replaced the previous output after a failed child generation.'
    }
    if (@(Get-ChildItem -LiteralPath $generateOutput -Filter '*.tmp.json' -File).Count -gt 0) {
        throw 'Generate-AllThemes left temporary output files behind after failure.'
    }

    $sourcePalettes = Get-Content -LiteralPath (Join-Path -Path $repoRoot -ChildPath 'color-palette-alternatives.json') -Raw |
        ConvertFrom-Json -ErrorAction Stop
    $singlePalettePath = Join-Path -Path $generateRoot -ChildPath 'single-palette.json'
    $singlePalette = [ordered]@{
        palettes = [ordered]@{
            tokyo_night = $sourcePalettes.palettes.tokyo_night
        }
    }
    [System.IO.File]::WriteAllText($singlePalettePath, ($singlePalette | ConvertTo-Json -Depth 100))

    $successfulOutput = Join-Path -Path $generateRoot -ChildPath 'successful-output'
    New-Item -ItemType Directory -Path $successfulOutput -Force | Out-Null
    $expectedGeneratedFile = Join-Path -Path $successfulOutput -ChildPath 'OhMyPosh-Atomic-Custom.TokyoNight.json'
    [System.IO.File]::WriteAllText($expectedGeneratedFile, 'stale-output-that-must-be-replaced')
    Invoke-ExpectedSuccess -Name 'Generate-AllThemes atomic success' `
        -ScriptPath (Join-Path -Path $PSScriptRoot -ChildPath 'Generate-AllThemes.ps1') `
        -Arguments @(
            '-SourceThemes', (Join-Path -Path $repoRoot -ChildPath 'OhMyPosh-Atomic-Custom.json'),
            '-PalettesFile', $singlePalettePath,
            '-OutputDirectory', $successfulOutput,
            '-Force'
        )

    $generatedTheme = Get-Content -LiteralPath $expectedGeneratedFile -Raw | ConvertFrom-Json -ErrorAction Stop
    if ($generatedTheme.extends -notmatch 'OhMyPosh-Atomic-Custom\.json$') {
        throw 'Generate-AllThemes success output does not extend the requested source theme.'
    }
    if (@(Get-ChildItem -LiteralPath $successfulOutput -Filter '*.tmp.json' -File).Count -gt 0) {
        throw 'Generate-AllThemes left temporary output files behind after success.'
    }

    $mergeScript = Join-Path -Path $PSScriptRoot -ChildPath 'Merge-OhMyPoshThemes.ps1'
    $customTheme = Join-Path -Path $repoRoot -ChildPath 'OhMyPosh-Atomic-Custom.json'
    $validOfficialTheme = Join-Path -Path $repoRoot -ChildPath 'ohmyposh-official-themes/themes/dracula.omp.json'

    $emptyThemes = Join-Path -Path $temporaryRoot -ChildPath 'empty-themes'
    New-Item -ItemType Directory -Path $emptyThemes -Force | Out-Null
    Invoke-ExpectedFailure -Name 'Merge empty ProcessAll input' -ScriptPath $mergeScript `
        -Arguments @(
            '-CustomThemePath', $customTheme,
            '-OfficialThemePath', $emptyThemes,
            '-OutputPath', (Join-Path -Path $temporaryRoot -ChildPath 'empty-output'),
            '-ProcessAll'
        )

    $malformedTheme = Join-Path -Path $temporaryRoot -ChildPath 'malformed.omp.json'
    [System.IO.File]::WriteAllText($malformedTheme, '{not-valid-json')
    Invoke-ExpectedFailure -Name 'Merge malformed theme' -ScriptPath $mergeScript `
        -Arguments @(
            '-CustomThemePath', $customTheme,
            '-OfficialThemePath', $malformedTheme,
            '-OutputPath', (Join-Path -Path $temporaryRoot -ChildPath 'malformed-output')
        )

    $mixedThemes = Join-Path -Path $temporaryRoot -ChildPath 'mixed-themes'
    $mixedOutput = Join-Path -Path $temporaryRoot -ChildPath 'mixed-output'
    New-Item -ItemType Directory -Path $mixedThemes -Force | Out-Null
    Copy-Item -LiteralPath $validOfficialTheme -Destination (Join-Path -Path $mixedThemes -ChildPath 'valid.omp.json')
    [System.IO.File]::WriteAllText((Join-Path -Path $mixedThemes -ChildPath 'invalid.omp.json'), '{not-valid-json')
    Invoke-ExpectedFailure -Name 'Merge mixed success and failure' -ScriptPath $mergeScript `
        -Arguments @(
            '-CustomThemePath', $customTheme,
            '-OfficialThemePath', $mixedThemes,
            '-OutputPath', $mixedOutput,
            '-ProcessAll'
        )
    if (-not (Test-Path -LiteralPath (Join-Path -Path $mixedOutput -ChildPath 'Custom-valid.omp.json') -PathType Leaf)) {
        throw 'The mixed merge did not retain the successful output before returning failure.'
    }

    $blockedOutput = Join-Path -Path $temporaryRoot -ChildPath 'output-is-a-file'
    [System.IO.File]::WriteAllText($blockedOutput, 'not-a-directory')
    Invoke-ExpectedFailure -Name 'Merge write failure' -ScriptPath $mergeScript `
        -Arguments @(
            '-CustomThemePath', $customTheme,
            '-OfficialThemePath', $validOfficialTheme,
            '-OutputPath', $blockedOutput
        )

    $successfulMergeOutput = Join-Path -Path $temporaryRoot -ChildPath 'successful-merge'
    Invoke-ExpectedSuccess -Name 'Merge visual styling success' -ScriptPath $mergeScript `
        -Arguments @(
            '-CustomThemePath', $customTheme,
            '-OfficialThemePath', $validOfficialTheme,
            '-OutputPath', $successfulMergeOutput
        )

    $customThemeObject = Get-Content -LiteralPath $customTheme -Raw | ConvertFrom-Json -ErrorAction Stop
    $mergedThemePath = Join-Path -Path $successfulMergeOutput -ChildPath 'Custom-dracula.omp.json'
    $mergedThemeObject = Get-Content -LiteralPath $mergedThemePath -Raw | ConvertFrom-Json -ErrorAction Stop
    if ($customThemeObject.blocks.Count -ne $mergedThemeObject.blocks.Count) {
        throw 'Merge changed the custom block count.'
    }

    for ($blockIndex = 0; $blockIndex -lt $customThemeObject.blocks.Count; $blockIndex++) {
        $customSegments = @($customThemeObject.blocks[$blockIndex].segments)
        $mergedSegments = @($mergedThemeObject.blocks[$blockIndex].segments)
        if ($customSegments.Count -ne $mergedSegments.Count) {
            throw "Merge changed the segment count in block $blockIndex."
        }

        for ($segmentIndex = 0; $segmentIndex -lt $customSegments.Count; $segmentIndex++) {
            Assert-TemplateValuePreserved -CustomSegment $customSegments[$segmentIndex] `
                -MergedSegment $mergedSegments[$segmentIndex] `
                -Location "block $blockIndex, segment $segmentIndex"
        }
    }

    $customTooltips = @($customThemeObject.tooltips)
    $mergedTooltips = @($mergedThemeObject.tooltips)
    if ($customTooltips.Count -ne $mergedTooltips.Count) {
        throw 'Merge changed the custom tooltip count.'
    }
    for ($tooltipIndex = 0; $tooltipIndex -lt $customTooltips.Count; $tooltipIndex++) {
        Assert-TemplateValuePreserved -CustomSegment $customTooltips[$tooltipIndex] `
            -MergedSegment $mergedTooltips[$tooltipIndex] `
            -Location "tooltip $tooltipIndex"
    }

    Write-Information -MessageData 'All script process-contract checks passed.' -InformationAction Continue
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
