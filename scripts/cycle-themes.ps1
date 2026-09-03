#!/usr/bin/env pwsh
# Cycle through all available themes to preview them

param(
    [switch]$Official,
    [switch]$Custom,
    [switch]$Variants,
    [string]$Delay = '2'
)

# This script lives in .\scripts\, but operates on files in the repository root.
$RepoRoot = Split-Path -Path $PSScriptRoot -Parent

function Resolve-RepoPath {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path -Path $RepoRoot -ChildPath $Path)
}

function Write-ThemeMessage {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$Message = '',
        [ConsoleColor]$ForegroundColor
    )

    if ($PSBoundParameters.ContainsKey('ForegroundColor')) {
        $foregroundSequence = $PSStyle.Foreground.FromConsoleColor($ForegroundColor)
        $Message = "$foregroundSequence$Message$($PSStyle.Reset)"
    }

    Write-Information -MessageData $Message -InformationAction Continue
}

$customThemes = @(
    # Base themes
    'OhMyPosh-Atomic-Custom.json',
    'OhMyPosh-Atomic-Custom-ColorCycle.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.ColorCycle.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.Extended.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.Gradient.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRamps.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRampsAutoShade.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.Fish.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.NoShellIntegration.json',
    '1_shell-Enhanced.omp.json',
    'slimfat-Enhanced.omp.json',
    'atomicBit-Enhanced.omp.json',
    'clean-detailed-Enhanced.omp.json'
)

$customThemes = @($customThemes | ForEach-Object { Resolve-RepoPath $_ })
$officialThemesPath = Resolve-RepoPath 'ohmyposh-official-themes\themes'

function Show-ThemePreview {
    param(
        [string]$ThemePath,
        [string]$ThemeName
    )

    Clear-Host
    Write-ThemeMessage -Message ('=' * 60) -ForegroundColor Cyan
    $padding = [math]::Max(0, 57 - $ThemeName.Length)
    Write-ThemeMessage -Message "Theme: $ThemeName$(' ' * $padding)" -ForegroundColor Yellow
    Write-ThemeMessage -Message ('=' * 60) -ForegroundColor Cyan
    Write-ThemeMessage
    Write-ThemeMessage -Message 'Loading theme preview... (Press Ctrl+C to stop cycling)' -ForegroundColor Gray
    Write-ThemeMessage

    & oh-my-posh print primary --config $ThemePath --shell pwsh --force
    $previewExitCode = $LASTEXITCODE
    if ($previewExitCode -ne 0) {
        throw "Oh My Posh could not render theme '$ThemePath' (exit code $previewExitCode)."
    }

    Write-ThemeMessage
    Write-ThemeMessage -Message ('=' * 60) -ForegroundColor Cyan
    Write-ThemeMessage -Message "Theme: $ThemeName" -ForegroundColor Yellow
    Write-ThemeMessage -Message "Path:  $ThemePath" -ForegroundColor Gray
    Write-ThemeMessage -Message ('=' * 60) -ForegroundColor Cyan
    Write-ThemeMessage
}

if (-not $Official -and -not $Custom) {
    $Official = $true
    $Custom = $true
}

Write-ThemeMessage -Message "`nOh-My-Posh Theme Cycler" -ForegroundColor Green
Write-ThemeMessage -Message "This will cycle through all themes for $([int]$Delay)s each" -ForegroundColor Gray
Write-ThemeMessage -Message "Press Ctrl+C to stop`n" -ForegroundColor Yellow
Start-Sleep -Seconds 2

$themes = @()

if ($Custom) {
    Write-ThemeMessage -Message 'Loading custom themes...' -ForegroundColor Cyan
    foreach ($theme in $customThemes) {
        if (Test-Path -LiteralPath $theme) {
            $themes += @{
                Path = $theme
                Name = $theme.Replace('.json','').Replace('OhMyPosh-Atomic-','')
                Type = 'Custom'
            }
        }
    }

    if ($Variants) {
        Write-ThemeMessage -Message 'Loading palette variants from theme-family folders...' -ForegroundColor Cyan
        $variantGlobs = @(
            'atomic/OhMyPosh-Atomic-Custom.*.json',
            '1_shell/1_shell-Enhanced.omp.*.json',
            'slimfat/slimfat-Enhanced.omp.*.json',
            'atomicBit/atomicBit-Enhanced.omp.*.json',
            'cleanDetailed/clean-detailed-Enhanced.omp.*.json',
            'experimentalDividers/OhMyPosh-Atomic-Custom-ExperimentalDividers.*.json'
        )
        foreach ($glob in $variantGlobs) {
            $resolvedGlob = Resolve-RepoPath $glob
            Get-ChildItem -File -Path $resolvedGlob -ErrorAction SilentlyContinue | ForEach-Object {
                $themes += @{
                    Path = $_.FullName
                    Name = $_.Name
                }
            }
        }
    }
}

if ($Official) {
    Write-ThemeMessage -Message 'Loading official themes...' -ForegroundColor Cyan
    if (Test-Path -LiteralPath $officialThemesPath) {
        $officialFiles = Get-ChildItem "$officialThemesPath\*.json" | Sort-Object Name
        foreach ($file in $officialFiles) {
            $themes += @{
                Path = $file.FullName
                Name = $file.BaseName
                Type = 'Official'
            }
        }
    }
    else {
        Write-ThemeMessage -Message 'WARNING: Official themes folder not found. Run scripts/sync-official-themes.ps1.' -ForegroundColor Yellow
    }
}

if ($themes.Count -eq 0) {
    Write-ThemeMessage -Message 'ERROR: No themes found!' -ForegroundColor Red
    exit 1
}

Write-ThemeMessage -Message "Found $($themes.Count) themes`n" -ForegroundColor Green
Start-Sleep -Seconds 2

$currentIndex = 0

while ($true) {
    $theme = $themes[$currentIndex]
    Show-ThemePreview -ThemePath $theme.Path -ThemeName "$($theme.Type): $($theme.Name)"

    Write-ThemeMessage -Message "Next in $Delay seconds... (Showing $($currentIndex + 1) of $($themes.Count))" -ForegroundColor Gray
    Start-Sleep -Seconds $Delay

    $currentIndex = ($currentIndex + 1) % $themes.Count
}
