#!/usr/bin/env pwsh
# Interactive theme viewer - press Enter to go to next theme

param(
    [switch]$Official,
    [switch]$Custom,
    [Parameter()]
    [ValidateSet('All', 'Atomic', 'ExperimentalDividers', '1Shell', 'Slimfat', 'AtomicBit', 'CleanDetailed')]
    [string]$ThemeFamily = 'All'
)

# Define base themes
$baseThemes = @(
    @{Name = 'Experimental Dividers'; Prefix = 'OhMyPosh-Atomic-Custom-ExperimentalDividers'; VariantsFolder = 'experimentalDividers' },
    @{Name = 'Atomic Custom'; Prefix = 'OhMyPosh-Atomic-Custom' },
    @{Name = '1_shell Enhanced'; Prefix = '1_shell-Enhanced.omp' },
    @{Name = 'Slimfat Enhanced'; Prefix = 'slimfat-Enhanced.omp' },
    @{Name = 'AtomicBit Enhanced'; Prefix = 'atomicBit-Enhanced.omp' },
    @{Name = 'Clean-Detailed Enhanced'; Prefix = 'clean-detailed-Enhanced.omp' }
)

# Map each theme family prefix to its variant folder
$variantFolders = @{
    'OhMyPosh-Atomic-Custom'                      = 'atomic'
    '1_shell-Enhanced.omp'                        = '1_shell'
    'slimfat-Enhanced.omp'                        = 'slimfat'
    'atomicBit-Enhanced.omp'                      = 'atomicBit'
    'clean-detailed-Enhanced.omp'                 = 'cleanDetailed'
    'OhMyPosh-Atomic-Custom-ExperimentalDividers' = 'experimentalDividers'
}

# Define all palette variants
$paletteVariants = @(
    'Original', 'NordFrost', 'GruvboxDark', 'DraculaNight', 'TokyoNight',
    'MonokaiPro', 'SolarizedDark', 'CatppuccinMocha', 'ForestEmber',
    'PinkParadise', 'PurpleReign', 'RedAlert', 'BlueOcean', 'GreenMatrix',
    'AmberSunset', 'TealCyan', 'RainbowBright', 'ChristmasCheer',
    'HalloweenSpooky', 'EasterPastel', 'FireIce', 'MidnightGold',
    'CherryMint', 'LavenderPeach'
)

# Build custom themes list
$customThemes = @()

foreach ($base in $baseThemes) {
    # Add base theme file if it exists
    $baseFile = "$($base.Prefix).json"
    if (Test-Path $baseFile) {
        $customThemes += @{
            Name   = "$($base.Name) (Base)"
            Path   = $baseFile
            Family = $base.Name
        }
    }

    # Special-case: NoShellIntegration variant lives in repo root
    if ($base.Prefix -eq 'OhMyPosh-Atomic-Custom-ExperimentalDividers') {
        $noShell = 'OhMyPosh-Atomic-Custom-ExperimentalDividers.NoShellIntegration.json'
        if (Test-Path $noShell) {
            $customThemes += @{
                Name   = "$($base.Name) (NoShellIntegration)"
                Path   = $noShell
                Family = $base.Name
            }
        }
    }

    # Add all palette variants
    foreach ($palette in $paletteVariants) {
        $folder = $variantFolders[$base.Prefix]
        $variantFile = if ($folder) {
            Join-Path -Path $folder -ChildPath "$($base.Prefix).$palette.json"
        }
        else {
            "$($base.Prefix).$palette.json"
        }
        if (Test-Path $variantFile) {
            $customThemes += @{
                Name   = "$($base.Name) - $palette"
                Path   = $variantFile
                Family = $base.Name
            }
        }
    }
}

$officialThemesPath = 'ohmyposh-official-themes\themes'

if (-not $Official -and -not $Custom) {
    $Official = $true
    $Custom = $true
}

$themes = @()

if ($Custom) {
    foreach ($theme in $customThemes) {
        # Filter by theme family if specified
        if ($ThemeFamily -ne 'All') {
            $familyMatch = switch ($ThemeFamily) {
                'Atomic' { $theme.Family -eq 'Atomic Custom' }
                'ExperimentalDividers' { $theme.Family -eq 'Experimental Dividers' }
                '1Shell' { $theme.Family -eq '1_shell Enhanced' }
                'Slimfat' { $theme.Family -eq 'Slimfat Enhanced' }
                'AtomicBit' { $theme.Family -eq 'AtomicBit Enhanced' }
                'CleanDetailed' { $theme.Family -eq 'Clean-Detailed Enhanced' }
                default { $true }
            }
            if (-not $familyMatch) { continue }
        }

        if (Test-Path $theme.Path) {
            $themes += @{
                Type   = 'Enhanced'
                Name   = $theme.Name
                Path   = $theme.Path
                Family = $theme.Family
            }
        }
    }
}

if ($Official) {
    if (Test-Path $officialThemesPath) {
        $officialFiles = Get-ChildItem "$officialThemesPath\*.json" | Sort-Object Name
        foreach ($file in $officialFiles) {
            $themes += @{
                Type = 'Official'
                Name = $file.BaseName
                Path = $file.FullName
            }
        }
    }
}

if ($themes.Count -eq 0) {
    Write-Host '❌ No themes found!' -ForegroundColor Red
    exit 1
}

$currentIndex = 0

function Show-Theme {
    param([int]$Index)

    $theme = $themes[$Index]

    # Show preview using oh-my-posh print command
    Write-Host ''
    Write-Host '════════════════════════════════════════════════════════════' -ForegroundColor Cyan
    Write-Host "Theme $($Index + 1) of $($themes.Count): $($theme.Type) - $($theme.Name)" -ForegroundColor Yellow
    Write-Host "Path: $($theme.Path)" -ForegroundColor Gray
    Write-Host '════════════════════════════════════════════════════════════' -ForegroundColor Cyan
    Write-Host ''

    # Print the preview
    oh-my-posh print preview --config $theme.Path --force 2>$null

    Write-Host ''
    Write-Host '════════════════════════════════════════════════════════════' -ForegroundColor Cyan
    Write-Host "Press ENTER for next, Q to quit, or type a number (1-$($themes.Count))" -ForegroundColor Green
    Write-Host '════════════════════════════════════════════════════════════' -ForegroundColor Cyan
    Write-Host ''
}

# Show first theme
Show-Theme -Index $currentIndex

while ($true) {
    $userInput = Read-Host '❯'

    if ($userInput -eq 'q' -or $userInput -eq 'Q') {
        Write-Host 'Goodbye!' -ForegroundColor Green
        break
    }

    # Try to parse as number
    if ($userInput -match '^\d+$') {
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
