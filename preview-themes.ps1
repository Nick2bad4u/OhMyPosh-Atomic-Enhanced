#!/usr/bin/env pwsh
# Interactive theme viewer - press Enter to go to next theme

param(
    [switch]$Official,
    [switch]$Custom
)

$customThemes = @(
    @{Name = "Original"; Path = "OhMyPosh-Atomic-Custom.json" },
    @{Name = "V1 (Cyberpunk)"; Path = "OhMyPosh-Atomic-Advanced-V1.json" },
    @{Name = "V2 (Waves)"; Path = "OhMyPosh-Atomic-Advanced-V2.json" },
    @{Name = "V3 (Brackets)"; Path = "OhMyPosh-Atomic-Advanced-V3-BRACKETS.json" }
)

$officialThemesPath = "ohmyposh-official-themes\themes"

if (-not $Official -and -not $Custom) {
    $Official = $true
    $Custom = $true
}

$themes = @()

if ($Custom) {
    foreach ($theme in $customThemes) {
        if (Test-Path $theme.Path) {
            $themes += @{
                Type = "Custom"
                Name = $theme.Name
                Path = $theme.Path
            }
        }
    }
}

if ($Official) {
    if (Test-Path $officialThemesPath) {
        $officialFiles = Get-ChildItem "$officialThemesPath\*.json" | Sort-Object Name
        foreach ($file in $officialFiles) {
            $themes += @{
                Type = "Official"
                Name = $file.BaseName
                Path = $file.FullName
            }
        }
    }
}

if ($themes.Count -eq 0) {
    Write-Host "❌ No themes found!" -ForegroundColor Red
    exit 1
}

$currentIndex = 0

function Show-Theme {
    param([int]$Index)

    $theme = $themes[$Index]

    # Show preview using oh-my-posh print command
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Theme $($Index + 1) of $($themes.Count): $($theme.Type) - $($theme.Name)" -ForegroundColor Yellow
    Write-Host "Path: $($theme.Path)" -ForegroundColor Gray
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    # Print the preview
    oh-my-posh print preview --config $theme.Path --force 2>$null

    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Press ENTER for next, Q to quit, or type a number (1-$($themes.Count))" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

# Show first theme
Show-Theme -Index $currentIndex

while ($true) {
    $userInput = Read-Host "❯"

    if ($userInput -eq "q" -or $userInput -eq "Q") {
        Write-Host "Goodbye!" -ForegroundColor Green
        break
    }

    # Try to parse as number
    if ($userInput -match "^\d+$") {
        $num = [int]$userInput
        if ($num -ge 1 -and $num -le $themes.Count) {
            $currentIndex = $num - 1
        }
        else {
            Write-Host "Invalid theme number (1-$($themes.Count))" -ForegroundColor Red
            continue
        }
    }
    else {
        # Default to next theme
        $currentIndex = ($currentIndex + 1) % $themes.Count
    }

    Clear-Host
    Show-Theme -Index $currentIndex
}
