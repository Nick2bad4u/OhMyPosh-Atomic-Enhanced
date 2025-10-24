<#
.SYNOPSIS
    Generates preview images for all custom Oh My Posh themes and updates README.

.DESCRIPTION
    This script finds all custom-generated theme files (excluding official themes),
    generates PNG preview images using oh-my-posh export, saves them to an assets
    folder, and automatically updates the README.md with a beautiful gallery.

.PARAMETER ThemePattern
    Glob pattern to match theme files. Default matches generated theme variants.

.PARAMETER ImageSettings
    Path to image settings JSON file for oh-my-posh export.
    Default: "image.settings.json"

.PARAMETER OutputDirectory
    Directory where preview images will be saved.
    Default: "assets/theme-previews"

.PARAMETER ReadmePath
    Path to README.md file to update.
    Default: "README.md"

.PARAMETER Force
    Regenerate all images even if they already exist.

.PARAMETER SkipReadmeUpdate
    Generate images but don't update the README.

.EXAMPLE
    .\Generate-ThemePreviews.ps1
    Generates previews for all custom themes and updates README

.EXAMPLE
    .\Generate-ThemePreviews.ps1 -Force
    Regenerates all preview images

.EXAMPLE
    .\Generate-ThemePreviews.ps1 -SkipReadmeUpdate
    Only generates images without updating README

.NOTES
    Author: GitHub Copilot
    Requires: oh-my-posh CLI installed and in PATH
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$ThemePattern = @(
        "OhMyPosh-Atomic-Custom.*.json",
        "1_shell-Enhanced.omp.*.json"
    ),

    [Parameter()]
    [string]$ImageSettings = "image.settings.json",

    [Parameter()]
    [string]$OutputDirectory = "assets/theme-previews",

    [Parameter()]
    [string]$ReadmePath = "README.md",

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$SkipReadmeUpdate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Color scheme for output
$colors = @{
    Header = 'Cyan'
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'White'
    Accent = 'Magenta'
}

function Write-Header {
    param([string]$Text)
    Write-Host "`n$('=' * 70)" -ForegroundColor $colors.Header
    Write-Host "  $Text" -ForegroundColor $colors.Header
    Write-Host "$('=' * 70)`n" -ForegroundColor $colors.Header
}

function Write-Step {
    param([string]$Text)
    Write-Host "▶ $Text" -ForegroundColor $colors.Info
}

function Write-Success {
    param([string]$Text)
    Write-Host "  ✓ $Text" -ForegroundColor $colors.Success
}

function Write-Warning {
    param([string]$Text)
    Write-Host "  ⚠ $Text" -ForegroundColor $colors.Warning
}

function Write-ErrorMessage {
    param([string]$Text)
    Write-Host "  ✗ $Text" -ForegroundColor $colors.Error
}

Write-Header "🎨 Oh My Posh Theme Preview Generator"

# Verify oh-my-posh is installed
Write-Step "Checking oh-my-posh installation..."
try {
    $ompVersion = oh-my-posh version 2>$null
    Write-Success "oh-my-posh v$ompVersion detected"
}
catch {
    Write-ErrorMessage "oh-my-posh not found in PATH!"
    Write-Host "`nPlease install oh-my-posh: https://ohmyposh.dev/docs/installation" -ForegroundColor $colors.Warning
    exit 1
}

# Verify image settings file exists
if (-not (Test-Path $ImageSettings)) {
    Write-Warning "Image settings file not found: $ImageSettings"
    Write-Host "  Using default oh-my-posh image settings" -ForegroundColor $colors.Info
    $imageSettingsParam = @()
}
else {
    Write-Success "Found image settings: $ImageSettings"
    $imageSettingsParam = @("--settings", (Resolve-Path $ImageSettings).Path)
}

# Create output directory
Write-Step "Setting up output directory..."
if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    Write-Success "Created: $OutputDirectory"
}
else {
    Write-Success "Using existing: $OutputDirectory"
}

# Find all custom theme files
Write-Step "Scanning for custom theme files..."
$themeFiles = @()
foreach ($pattern in $ThemePattern) {
    $found = Get-ChildItem -Filter $pattern -ErrorAction SilentlyContinue
    if ($found) {
        $themeFiles += $found
    }
}

if ($themeFiles.Count -eq 0) {
    Write-Warning "No custom theme files found!"
    Write-Host "  Patterns searched: $($ThemePattern -join ', ')" -ForegroundColor $colors.Info
    exit 0
}

Write-Success "Found $($themeFiles.Count) theme files"

# Generate preview images
Write-Header "📸 Generating Preview Images"

$results = @()
$successCount = 0
$skipCount = 0
$errorCount = 0

foreach ($theme in $themeFiles) {
    $themeName = [System.IO.Path]::GetFileNameWithoutExtension($theme.Name)
    $outputImage = Join-Path $OutputDirectory "$themeName.png"

    Write-Host "`n[$($results.Count + 1)/$($themeFiles.Count)] " -NoNewline -ForegroundColor $colors.Accent
    Write-Host $theme.Name -ForegroundColor $colors.Info

    # Check if image already exists
    if ((Test-Path $outputImage) -and -not $Force) {
        Write-Warning "Image already exists, skipping (use -Force to regenerate)"
        $skipCount++
        $results += [PSCustomObject]@{
            Theme = $theme.Name
            ThemeName = $themeName
            Status = 'Skipped'
            ImagePath = $outputImage
            RelativePath = "assets/theme-previews/$themeName.png"
        }
        continue
    }

    # Generate image
    try {
        $configPath = $theme.FullName

        # Build command arguments
        $args = @(
            'config', 'export', 'image',
            '--config', $configPath,
            '--output', $outputImage
        ) + $imageSettingsParam

        # Run oh-my-posh export
        $output = & oh-my-posh @args 2>&1

        if ($LASTEXITCODE -eq 0 -and (Test-Path $outputImage)) {
            Write-Success "Generated: $themeName.png"
            $successCount++
            $results += [PSCustomObject]@{
                Theme = $theme.Name
                ThemeName = $themeName
                Status = 'Success'
                ImagePath = $outputImage
                RelativePath = "assets/theme-previews/$themeName.png"
            }
        }
        else {
            throw "oh-my-posh returned exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-ErrorMessage "Failed: $_"
        $errorCount++
        $results += [PSCustomObject]@{
            Theme = $theme.Name
            ThemeName = $themeName
            Status = 'Error'
            ImagePath = $null
            RelativePath = $null
        }
    }
}

# Summary
Write-Header "📊 Generation Summary"
Write-Host "✓ Successfully generated: " -NoNewline -ForegroundColor $colors.Success
Write-Host $successCount -ForegroundColor $colors.Info

if ($skipCount -gt 0) {
    Write-Host "⚠ Skipped (existing): " -NoNewline -ForegroundColor $colors.Warning
    Write-Host $skipCount -ForegroundColor $colors.Info
}

if ($errorCount -gt 0) {
    Write-Host "✗ Errors: " -NoNewline -ForegroundColor $colors.Error
    Write-Host $errorCount -ForegroundColor $colors.Info
}

# Update README if requested
if (-not $SkipReadmeUpdate) {
    Write-Header "📝 Updating README"

    if (-not (Test-Path $ReadmePath)) {
        Write-ErrorMessage "README not found: $ReadmePath"
        exit 1
    }

    Write-Step "Reading README.md..."
    $readmeContent = Get-Content $ReadmePath -Raw

    # Group themes by base theme
    $atomicThemes = $results | Where-Object { $_.Theme -like "OhMyPosh-Atomic-Custom.*" -and $_.Status -eq 'Success' } | Sort-Object ThemeName
    $shellThemes = $results | Where-Object { $_.Theme -like "1_shell-Enhanced.omp.*" -and $_.Status -eq 'Success' } | Sort-Object ThemeName

    # Generate gallery markdown
    $galleryMarkdown = @"
## 🎨 Theme Gallery

All themes are available in multiple color palettes. Choose the one that fits your style!

### 🚀 OhMyPosh Atomic Custom Variants

<table>
"@

    # Add Atomic themes in 2-column grid
    $atomicCount = 0
    foreach ($theme in $atomicThemes) {
        if ($atomicCount % 2 -eq 0) {
            $galleryMarkdown += "`n<tr>"
        }

        $displayName = $theme.ThemeName -replace '^OhMyPosh-Atomic-Custom\.', ''
        $galleryMarkdown += @"

<td align="center" width="50%">
<h4>$displayName</h4>
<img src="$($theme.RelativePath)" alt="$displayName theme preview" width="100%">
</td>
"@

        $atomicCount++
        if ($atomicCount % 2 -eq 0) {
            $galleryMarkdown += "`n</tr>"
        }
    }

    # Close row if odd number
    if ($atomicCount % 2 -ne 0) {
        $galleryMarkdown += "`n</tr>"
    }

    $galleryMarkdown += @"

</table>

### ✨ 1_shell-Enhanced Variants

<table>
"@

    # Add shell themes in 2-column grid
    $shellCount = 0
    foreach ($theme in $shellThemes) {
        if ($shellCount % 2 -eq 0) {
            $galleryMarkdown += "`n<tr>"
        }

        $displayName = $theme.ThemeName -replace '^1_shell-Enhanced\.omp\.', ''
        $galleryMarkdown += @"

<td align="center" width="50%">
<h4>$displayName</h4>
<img src="$($theme.RelativePath)" alt="$displayName theme preview" width="100%">
</td>
"@

        $shellCount++
        if ($shellCount % 2 -eq 0) {
            $galleryMarkdown += "`n</tr>"
        }
    }

    # Close row if odd number
    if ($shellCount % 2 -ne 0) {
        $galleryMarkdown += "`n</tr>"
    }

    $galleryMarkdown += @"

</table>

### 🎯 Quick Install

To use any theme, copy the command for your preferred variant:

``````pwsh
# Replace <THEME_FILE> with the desired theme file name
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/<THEME_FILE>" | Invoke-Expression
``````

**Available Palettes:**
- **Original** - Your current vibrant tech theme
- **Nord Frost** - Arctic cool tones
- **Gruvbox Dark** - Warm retro earth tones
- **Dracula Night** - Bold purple/pink
- **Tokyo Night** - Modern neon blues
- **Monokai Pro** - Classic neon colors
- **Solarized Dark** - Eye-friendly
- **Catppuccin Mocha** - Soft pastels
- **Forest Ember** - Deep greens with amber
- **Pink Paradise** - Vibrant pink/magenta 💗
- **Purple Reign** - Royal purples 👑
- **Red Alert** - Fiery reds/oranges 🔥
- **Blue Ocean** - Deep ocean blues 🌊
- **Green Matrix** - Matrix-inspired greens 💚
- **Amber Sunset** - Warm sunset tones 🌅
- **Teal Cyan** - Electric teals ⚡

---
"@

    # Find insertion point in README
    $galleryMarker = "## 🎨 Theme Gallery"

    if ($readmeContent -match [regex]::Escape($galleryMarker)) {
        Write-Step "Updating existing gallery section..."

        # Find the end of the gallery section (next ## heading or end of file)
        if ($readmeContent -match "(?s)($([regex]::Escape($galleryMarker))).*?(?=^## |\z)") {
            $readmeContent = $readmeContent -replace "(?s)($([regex]::Escape($galleryMarker))).*?(?=^## |\z)", $galleryMarkdown
        }
    }
    else {
        Write-Step "Adding new gallery section..."
        # Insert before the last section (RepoBeats or end of file)
        if ($readmeContent -match "(?s)(.*)(^!\[RepoBeats.*|\z)") {
            $before = $Matches[1]
            $after = $Matches[2]
            $readmeContent = $before + "`n`n" + $galleryMarkdown + "`n`n" + $after
        }
        else {
            # Append to end
            $readmeContent += "`n`n" + $galleryMarkdown
        }
    }

    # Write updated README
    $readmeContent | Set-Content $ReadmePath -Encoding UTF8 -NoNewline
    Write-Success "README.md updated with $($atomicCount + $shellCount) theme previews"
}

# Final message
Write-Header "✨ Complete!"

if ($successCount -gt 0) {
    Write-Host "Generated preview images are in: " -NoNewline -ForegroundColor $colors.Info
    Write-Host $OutputDirectory -ForegroundColor $colors.Accent
}

if (-not $SkipReadmeUpdate -and ($atomicThemes.Count -gt 0 -or $shellThemes.Count -gt 0)) {
    Write-Host "`n💡 Don't forget to:" -ForegroundColor $colors.Warning
    Write-Host "   1. Review the updated README.md" -ForegroundColor $colors.Info
    Write-Host "   2. Commit and push the new preview images" -ForegroundColor $colors.Info
    Write-Host "   3. Verify the gallery renders correctly on GitHub" -ForegroundColor $colors.Info
}

Write-Host ""
