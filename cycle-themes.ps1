#!/usr/bin/env pwsh
# Cycle through all available themes to preview them

param(
    [switch]$Official,
    [switch]$Custom,
    [switch]$Variants,
    [string]$Delay = '2'
)

$customThemes = @(
    # Base themes
    'OhMyPosh-Atomic-Custom.json',
    'OhMyPosh-Atomic-Custom-ExperimentalDividers.json',
    '1_shell-Enhanced.omp.json',
    'slimfat-Enhanced.omp.json',
    'atomicBit-Enhanced.omp.json',
    'clean-detailed-Enhanced.omp.json'
)

$officialThemesPath = 'ohmyposh-official-themes\themes'

function Show-ThemePreview {
    param(
        [string]$ThemePath,
        [string]$ThemeName
    )

    Clear-Host
    Write-Output '╔════════════════════════════════════════════════════════════╗' -ForegroundColor Cyan
    Write-Output '║' -ForegroundColor Cyan -NoNewline
    Write-Output " 🎨 $ThemeName" -ForegroundColor Yellow -NoNewline
    $padding = 57 - $ThemeName.Length
    Write-Output "$(' ' * $padding)║" -ForegroundColor Cyan
    Write-Output '╚════════════════════════════════════════════════════════════╝' -ForegroundColor Cyan
    Write-Output ''
    Write-Output 'Loading theme preview... (Press Ctrl+C to stop cycling)' -ForegroundColor Gray
    Write-Output ''

    oh-my-posh init pwsh --config $ThemePath | Invoke-Expression

    Write-Output ''
    Write-Output '════════════════════════════════════════════════════════════' -ForegroundColor Cyan
    Write-Output "Theme: $ThemeName" -ForegroundColor Yellow
    Write-Output "Path:  $ThemePath" -ForegroundColor Gray
    Write-Output '════════════════════════════════════════════════════════════' -ForegroundColor Cyan
    Write-Output ''
}

if (-not $Official -and -not $Custom) {
    $Official = $true
    $Custom = $true
}

Write-Output "`n🎭 Oh-My-Posh Theme Cycler" -ForegroundColor Green
Write-Output "📍 This will cycle through all themes for $([int]$Delay)s each" -ForegroundColor Gray
Write-Output "⏹️  Press Ctrl+C to stop`n" -ForegroundColor Yellow
Start-Sleep -Seconds 2

$themes = @()

if ($Custom) {
    Write-Output '📦 Loading custom themes...' -ForegroundColor Cyan
    foreach ($theme in $customThemes) {
        if (Test-Path $theme) {
            $themes += @{
                Path = $theme
                Name = $theme.Replace('.json','').Replace('OhMyPosh-Atomic-','')
                Type = 'Custom'
            }
        }
    }

    if ($Variants) {
        Write-Output '🧩 Loading palette variants from theme-family folders...' -ForegroundColor Cyan
        $variantGlobs = @(
            'atomic/OhMyPosh-Atomic-Custom.*.json',
            '1_shell/1_shell-Enhanced.omp.*.json',
            'slimfat/slimfat-Enhanced.omp.*.json',
            'atomicBit/atomicBit-Enhanced.omp.*.json',
            'cleanDetailed/clean-detailed-Enhanced.omp.*.json',
            'experimentalDividers/OhMyPosh-Atomic-Custom-ExperimentalDividers.*.json'
        )
        foreach ($glob in $variantGlobs) {
            Get-ChildItem -File -Path $glob -ErrorAction SilentlyContinue | ForEach-Object {
                $themes += @{
                    Path = $_.FullName
                    Name = $_.Name
                }
            }
        }
    }
}

if ($Official) {
    Write-Output '📦 Loading official themes...' -ForegroundColor Cyan
    if (Test-Path $officialThemesPath) {
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
        Write-Output '⚠️  Official themes folder not found. Run: git subtree pull --prefix=ohmyposh-official-themes ohmyposh-themes main --squash' -ForegroundColor Yellow
    }
}

if ($themes.Count -eq 0) {
    Write-Output '❌ No themes found!' -ForegroundColor Red
    exit 1
}

Write-Output "✓ Found $($themes.Count) themes`n" -ForegroundColor Green
Start-Sleep -Seconds 2

$currentIndex = 0

while ($true) {
    $theme = $themes[$currentIndex]
    Show-ThemePreview -ThemePath $theme.Path -ThemeName "$($theme.Type): $($theme.Name)"

    Write-Output "Next in $Delay seconds... (Showing $($currentIndex + 1) of $($themes.Count))" -ForegroundColor Gray
    Start-Sleep -Seconds $Delay

    $currentIndex = ($currentIndex + 1) % $themes.Count
}
