#!/usr/bin/env pwsh
# Cycle through all available themes to preview them

param(
    [switch]$Official,
    [switch]$Custom,
    [string]$Delay = "2"
)

$customThemes = @(
    "OhMyPosh-Atomic-Custom.json",
    "OhMyPosh-Atomic-Advanced-V1.json",
    "OhMyPosh-Atomic-Advanced-V2.json",
    "OhMyPosh-Atomic-Advanced-V3-BRACKETS.json"
)

$officialThemesPath = "ohmyposh-official-themes\themes"

function Show-ThemePreview {
    param(
        [string]$ThemePath,
        [string]$ThemeName
    )

    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor Cyan -NoNewline
    Write-Host " 🎨 $ThemeName" -ForegroundColor Yellow -NoNewline
    $padding = 57 - $ThemeName.Length
    Write-Host "$(' ' * $padding)║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Loading theme preview... (Press Ctrl+C to stop cycling)" -ForegroundColor Gray
    Write-Host ""

    oh-my-posh init pwsh --config $ThemePath | Invoke-Expression

    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Theme: $ThemeName" -ForegroundColor Yellow
    Write-Host "Path:  $ThemePath" -ForegroundColor Gray
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

if (-not $Official -and -not $Custom) {
    $Official = $true
    $Custom = $true
}

Write-Host "`n🎭 Oh-My-Posh Theme Cycler" -ForegroundColor Green
Write-Host "📍 This will cycle through all themes for $([int]$Delay)s each" -ForegroundColor Gray
Write-Host "⏹️  Press Ctrl+C to stop`n" -ForegroundColor Yellow
Start-Sleep -Seconds 2

$themes = @()

if ($Custom) {
    Write-Host "📦 Loading custom themes..." -ForegroundColor Cyan
    foreach ($theme in $customThemes) {
        if (Test-Path $theme) {
            $themes += @{
                Path = $theme
                Name = $theme.Replace(".json", "").Replace("OhMyPosh-Atomic-", "")
                Type = "Custom"
            }
        }
    }
}

if ($Official) {
    Write-Host "📦 Loading official themes..." -ForegroundColor Cyan
    if (Test-Path $officialThemesPath) {
        $officialFiles = Get-ChildItem "$officialThemesPath\*.json" | Sort-Object Name
        foreach ($file in $officialFiles) {
            $themes += @{
                Path = $file.FullName
                Name = $file.BaseName
                Type = "Official"
            }
        }
    }
    else {
        Write-Host "⚠️  Official themes folder not found. Run: git subtree pull --prefix=ohmyposh-official-themes ohmyposh-themes main --squash" -ForegroundColor Yellow
    }
}

if ($themes.Count -eq 0) {
    Write-Host "❌ No themes found!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Found $($themes.Count) themes`n" -ForegroundColor Green
Start-Sleep -Seconds 2

$currentIndex = 0

while ($true) {
    $theme = $themes[$currentIndex]
    Show-ThemePreview -ThemePath $theme.Path -ThemeName "$($theme.Type): $($theme.Name)"

    Write-Host "Next in $Delay seconds... (Showing $($currentIndex + 1) of $($themes.Count))" -ForegroundColor Gray
    Start-Sleep -Seconds $Delay

    $currentIndex = ($currentIndex + 1) % $themes.Count
}
