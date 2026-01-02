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
    .\scripts\Generate-ThemePreviews.ps1
    Generates previews for all custom themes and updates README

.EXAMPLE
    .\scripts\Generate-ThemePreviews.ps1 -Force
    Regenerates all preview images

.EXAMPLE
    .\scripts\Generate-ThemePreviews.ps1 -SkipReadmeUpdate
    Only generates images without updating README

.NOTES
    Author: GitHub Copilot
    Requires: oh-my-posh CLI installed and in PATH
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$ThemePattern = @(
        # ExperimentalDividers variants
        'experimentalDividers/OhMyPosh-Atomic-Custom-ExperimentalDividers.*.json',

        # Folder-based variants for each theme family
        'atomic/OhMyPosh-Atomic-Custom.*.json',
        '1_shell/1_shell-Enhanced.omp.*.json',
        'slimfat/slimfat-Enhanced.omp.*.json',
        'atomicBit/atomicBit-Enhanced.omp.*.json',
        'cleanDetailed/clean-detailed-Enhanced.omp.*.json'
    ),

    [Parameter()]
    [string]$ImageSettings = 'image.settings.json',

    [Parameter()]
    [string]$OutputDirectory = 'assets/theme-previews',

    [Parameter()]
    [string]$ReadmePath = 'README.md',

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$SkipReadmeUpdate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# This script lives in .\scripts\, but operates on files in the repository root.
$RepoRoot = Split-Path -Path $PSScriptRoot -Parent

function Resolve-RepoPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path -Path $RepoRoot -ChildPath $Path)
}

# Resolve repo-relative inputs (so the script works from any current directory)
$ThemePattern = @($ThemePattern | ForEach-Object { Resolve-RepoPath $_ })
$ImageSettings = Resolve-RepoPath $ImageSettings
$OutputDirectory = Resolve-RepoPath $OutputDirectory
$ReadmePath = Resolve-RepoPath $ReadmePath

# Write-Output does not support -ForegroundColor / -NoNewline, but this script uses it for colored console output.
# Provide a local wrapper so output stays clean without rewriting every callsite.
function Write-Output {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [object[]]$InputObject,

        [ConsoleColor]$ForegroundColor,
        [switch]$NoNewline
    )

    $text = ($InputObject | ForEach-Object { "$_" }) -join ''

    if ($PSBoundParameters.ContainsKey('ForegroundColor') -or $NoNewline) {
        $hasColor = $PSBoundParameters.ContainsKey('ForegroundColor')
        if ($NoNewline) {
            if ($hasColor) { Write-Host -NoNewline -ForegroundColor $ForegroundColor $text }
            else { Write-Host -NoNewline $text }
        }
        else {
            if ($hasColor) { Write-Host -ForegroundColor $ForegroundColor $text }
            else { Write-Host $text }
        }
        return
    }

    Microsoft.PowerShell.Utility\Write-Output $text
}

# Color scheme for output
$colors = @{
    Header  = 'Cyan'
    Success = 'Green'
    Warning = 'Yellow'
    Error   = 'Red'
    Info    = 'White'
    Accent  = 'Magenta'
}

function Write-Header {
    param([string]$Text)
    Write-Output "`n$('=' * 70)" -ForegroundColor $colors.Header
    Write-Output "  $Text" -ForegroundColor $colors.Header
    Write-Output "$('=' * 70)`n" -ForegroundColor $colors.Header
}

function Write-Step {
    param([string]$Text)
    Write-Output "▶ $Text" -ForegroundColor $colors.Info
}

function Write-Success {
    param([string]$Text)
    Write-Output "  ✓ $Text" -ForegroundColor $colors.Success
}

function Write-WarningOutput {
    param([string]$Text)
    Write-Output "  ⚠ $Text" -ForegroundColor $colors.Warning
}

function Write-ErrorMessage {
    param([string]$Text)
    Write-Output "  ✗ $Text" -ForegroundColor $colors.Error
}

Write-Header '🎨 Oh My Posh Theme Preview Generator'

# Verify oh-my-posh is installed
Write-Step 'Checking oh-my-posh installation...'
try {
    $ompVersion = oh-my-posh version 2>$null
    Write-Success "oh-my-posh v$ompVersion detected"
}
catch {
    Write-ErrorMessage 'oh-my-posh not found in PATH!'
    Write-Output "`nPlease install oh-my-posh: https://ohmyposh.dev/docs/installation" -ForegroundColor $colors.Warning
    exit 1
}

# Verify image settings file exists
if (-not (Test-Path -LiteralPath $ImageSettings)) {
    Write-WarningOutput "Image settings file not found: $ImageSettings"
    Write-Output '  Using default oh-my-posh image settings' -ForegroundColor $colors.Info
    $imageSettingsParam = @()
}
else {
    Write-Success "Found image settings: $ImageSettings"
    $imageSettingsParam = @('--settings', (Resolve-Path $ImageSettings).Path)
}

# Create output directory
Write-Step 'Setting up output directory...'
if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    Write-Success "Created: $OutputDirectory"
}
else {
    Write-Success "Using existing: $OutputDirectory"
}

# Find all custom theme files
Write-Step 'Scanning for custom theme files...'
$themeFiles = @()
foreach ($pattern in $ThemePattern) {
    # NOTE: -Filter only matches leaf names and does not support path segments.
    # Use -Path so patterns like 'atomic/*.json' work correctly.
    $found = Get-ChildItem -File -Path $pattern -ErrorAction SilentlyContinue
    if ($found) {
        $themeFiles += $found
    }
}

if ($themeFiles.Count -eq 0) {
    Write-WarningOutput 'No custom theme files found!'
    Write-Output "  Patterns searched: $($ThemePattern -join ', ')" -ForegroundColor $colors.Info
    exit 0
}

Write-Success "Found $($themeFiles.Count) theme files"

# Generate preview images
Write-Header '📸 Generating Preview Images'

$results = @()
$successCount = 0
$skipCount = 0
$errorCount = 0

foreach ($theme in $themeFiles) {
    $themeName = [System.IO.Path]::GetFileNameWithoutExtension($theme.Name)
    $outputImage = Join-Path $OutputDirectory "$themeName.png"

    Write-Output "`n[$($results.Count + 1)/$($themeFiles.Count)] " -NoNewline -ForegroundColor $colors.Accent
    Write-Output $theme.Name -ForegroundColor $colors.Info

    # Check if image already exists
    if ((Test-Path $outputImage) -and -not $Force) {
        Write-WarningOutput 'Image already exists, skipping (use -Force to regenerate)'
        $skipCount++
        $results += [pscustomobject]@{
            Theme        = $theme.Name
            ThemeName    = $themeName
            Status       = 'Skipped'
            ImagePath    = $outputImage
            RelativePath = "assets/theme-previews/$themeName.png"
        }
        continue
    }

    # Generate image
    try {
        $configPath = $theme.FullName

        # Build command arguments (avoid PowerShell automatic variable 'args')
        $exportArgs = @(
            'config', 'export', 'image',
            '--config', $configPath,
            '--output', $outputImage
        ) + $imageSettingsParam

        # Run oh-my-posh export and capture result for diagnostics
        $exportResult = & oh-my-posh @exportArgs 2>&1

        if ($LASTEXITCODE -eq 0 -and (Test-Path $outputImage)) {
            Write-Success "Generated: $themeName.png"
            $successCount++
            $results += [pscustomobject]@{
                Theme        = $theme.Name
                ThemeName    = $themeName
                Status       = 'Success'
                ImagePath    = $outputImage
                RelativePath = "assets/theme-previews/$themeName.png"
            }
        }
        else {
            Write-WarningOutput "oh-my-posh returned exit code $LASTEXITCODE"
            Write-ErrorMessage "Export output: $exportResult"
            throw "oh-my-posh returned exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-ErrorMessage "Failed: $_"
        $errorCount++
        $results += [pscustomobject]@{
            Theme        = $theme.Name
            ThemeName    = $themeName
            Status       = 'Error'
            ImagePath    = $null
            RelativePath = $null
        }
    }
}

# Summary
Write-Header '📊 Generation Summary'
Write-Output '✓ Successfully generated: ' -NoNewline -ForegroundColor $colors.Success
Write-Output $successCount -ForegroundColor $colors.Info

if ($skipCount -gt 0) {
    Write-Output '⚠ Skipped (existing): ' -NoNewline -ForegroundColor $colors.Warning
    Write-Output $skipCount -ForegroundColor $colors.Info
}

if ($errorCount -gt 0) {
    Write-Output '✗ Errors: ' -NoNewline -ForegroundColor $colors.Error
    Write-Output $errorCount -ForegroundColor $colors.Info
}

# Update README if requested
if (-not $SkipReadmeUpdate) {
    Write-Header '📝 Updating README'

    if (-not (Test-Path $ReadmePath)) {
        Write-ErrorMessage "README not found: $ReadmePath"
        exit 1
    }

    Write-Step 'Reading README.md...'
    $readmeContent = Get-Content -LiteralPath $ReadmePath -Raw

    # Group themes by base theme (ensure they're arrays even if empty)
    $includeStatuses = @('Success', 'Skipped')
    $experimentalDividersThemes = @($results | Where-Object { $_.Theme -like 'OhMyPosh-Atomic-Custom-ExperimentalDividers.*' -and $_.Status -in $includeStatuses } | Sort-Object ThemeName)
    $atomicThemes = @($results | Where-Object { $_.Theme -like 'OhMyPosh-Atomic-Custom.*' -and $_.Status -in $includeStatuses -and $_.Theme -notlike 'OhMyPosh-Atomic-Custom-ExperimentalDividers.*' } | Sort-Object ThemeName)
    $shellThemes = @($results | Where-Object { $_.Theme -like '1_shell-Enhanced.omp.*' -and $_.Status -in $includeStatuses } | Sort-Object ThemeName)
    $slimfatThemes = @($results | Where-Object { $_.Theme -like 'slimfat-Enhanced.omp.*' -and $_.Status -in $includeStatuses } | Sort-Object ThemeName)
    $atomicBitThemes = @($results | Where-Object { $_.Theme -like 'atomicBit-Enhanced.omp.*' -and $_.Status -in $includeStatuses } | Sort-Object ThemeName)
    $cleanDetailedThemes = @($results | Where-Object { $_.Theme -like 'clean-detailed-Enhanced.omp.*' -and $_.Status -in $includeStatuses } | Sort-Object ThemeName)

    # Function to generate table rows for a theme group
    function Get-ThemeTableRows {
        param(
            [array]$Themes,
            [string]$StripPrefix
        )

        $markdown = ''
        $count = 0

        foreach ($theme in $Themes) {
            if ($count % 2 -eq 0) {
                $markdown += "`n<tr>"
            }

            $displayName = $theme.ThemeName -replace "^$StripPrefix", ''
            $markdown += @"

<td align="center" width="50%">
<h4>$displayName</h4>
<img src="$($theme.RelativePath)" alt="$displayName theme preview" width="100%">
</td>
"@

            $count++
            if ($count % 2 -eq 0) {
                $markdown += "`n</tr>"
            }
        }

        # Close row if odd number
        if ($count % 2 -ne 0) {
            $markdown += "`n</tr>"
        }

        return $markdown
    }

    # Generate gallery markdown
    $galleryMarkdown = @'
## 🎨 Theme Gallery

All themes are available in multiple color palettes. Choose the one that fits your style!
'@
    # Add Experimental Dividers first
    if ($experimentalDividersThemes.Count -gt 0) {
        $galleryMarkdown += @'

### 🌈 Experimental Dividers Variants (NEW)

<table>
'@

        $galleryMarkdown += Get-ThemeTableRows -Themes $experimentalDividersThemes -StripPrefix 'OhMyPosh-Atomic-Custom-ExperimentalDividers\.'

        $galleryMarkdown += @'

</table>
'@
    }

    # Add Atomic themes (non-experimental)
    $galleryMarkdown += @'

### 🚀 OhMyPosh Atomic Custom Variants

<table>
'@
    $galleryMarkdown += Get-ThemeTableRows -Themes $atomicThemes -StripPrefix 'OhMyPosh-Atomic-Custom\.'

    $galleryMarkdown += @'

</table>

### ✨ 1_shell-Enhanced Variants

<table>
'@

    # Add 1_shell themes
    $galleryMarkdown += Get-ThemeTableRows -Themes $shellThemes -StripPrefix '1_shell-Enhanced\.omp\.'

    $galleryMarkdown += @'

</table>

### 🎯 Slimfat-Enhanced Variants

<table>
'@

    # Add Slimfat themes
    $galleryMarkdown += Get-ThemeTableRows -Themes $slimfatThemes -StripPrefix 'slimfat-Enhanced\.omp\.'

    $galleryMarkdown += @'

</table>

### 📦 AtomicBit-Enhanced Variants

<table>
'@

    # Add AtomicBit themes
    $galleryMarkdown += Get-ThemeTableRows -Themes $atomicBitThemes -StripPrefix 'atomicBit-Enhanced\.omp\.'

    $galleryMarkdown += @'

</table>

### 🧹 Clean-Detailed-Enhanced Variants

<table>
'@

    # Add Clean-Detailed themes
    $galleryMarkdown += Get-ThemeTableRows -Themes $cleanDetailedThemes -StripPrefix 'clean-detailed-Enhanced\.omp\.'

    $galleryMarkdown += @"

</table>

### 🎯 Quick Install

To use any theme, copy the command for your preferred variant:

``````pwsh
# Replace <THEME_FOLDER> and <THEME_FILE> with the desired theme names
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/<THEME_FOLDER>/<THEME_FILE>" | Invoke-Expression
``````

**Theme File Naming Convention:**

- `OhMyPosh-Atomic-Custom.<Palette>.json` - Flagship comprehensive theme

- `1_shell-Enhanced.omp.<Palette>.json` - Single-line sleek theme

- `slimfat-Enhanced.omp.<Palette>.json` - Two-line compact theme

- `atomicBit-Enhanced.omp.<Palette>.json` - Box-style technical theme

- `clean-detailed-Enhanced.omp.<Palette>.json` - Minimalist clean theme

**Examples:**
``````pwsh
# Atomic Custom with Nord Frost palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/atomic/OhMyPosh-Atomic-Custom.NordFrost.json" | Invoke-Expression

# 1_shell Enhanced with Tokyo Night palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/1_shell/1_shell-Enhanced.omp.TokyoNight.json" | Invoke-Expression

# Slimfat Enhanced with Dracula Night palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/slimfat/slimfat-Enhanced.omp.DraculaNight.json" | Invoke-Expression

# AtomicBit Enhanced with Gruvbox Dark palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/atomicBit/atomicBit-Enhanced.omp.GruvboxDark.json" | Invoke-Expression

# Clean-Detailed Enhanced with Catppuccin Mocha palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/cleanDetailed/clean-detailed-Enhanced.omp.CatppuccinMocha.json" | Invoke-Expression
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

- **Rainbow Bright** - Vibrant rainbow colors 🌈

- **Christmas Cheer** - Festive holiday colors 🎄

- **Halloween Spooky** - Spooky Halloween theme 🎃

- **Easter Pastel** - Soft pastel Easter colors 🐰

- **Fire & Ice** - Dual-tone red/orange and blue/cyan ❄️🔥

- **Midnight Gold** - Deep navy blue and gold ⭐

- **Cherry Mint** - Cherry red and mint green 🍒

- **Lavender Peach** - Soft lavender and warm peach 🍑

---
"@

    # Find insertion point in README
    $galleryMarker = '## 🎨 Theme Gallery'

    if ($readmeContent -match [regex]::Escape($galleryMarker)) {
        Write-Step 'Updating existing gallery section...'

        # Find the end of the gallery section (next ## heading or end of file)
        if ($readmeContent -match "(?s)($([regex]::Escape($galleryMarker))).*?(?=^## |\z)") {
            $readmeContent = $readmeContent -replace "(?s)($([regex]::Escape($galleryMarker))).*?(?=^## |\z)", $galleryMarkdown
        }
    }
    else {
        Write-Step 'Adding new gallery section...'
        # Insert before the last section (RepoBeats or end of file)
        if ($readmeContent -match '(?s)(.*)(^!\[RepoBeats.*|\z)') {
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
    $readmeContent | Set-Content -LiteralPath $ReadmePath -Encoding UTF8 -NoNewline

    $totalThemes = $experimentalDividersThemes.Count + $atomicThemes.Count + $shellThemes.Count + $slimfatThemes.Count + $atomicBitThemes.Count + $cleanDetailedThemes.Count
    Write-Success "README.md updated with $totalThemes theme previews across 6 families"
}

# Final message
Write-Header '✨ Complete!'

if ($successCount -gt 0) {
    Write-Output 'Generated preview images are in: ' -NoNewline -ForegroundColor $colors.Info
    Write-Output $OutputDirectory -ForegroundColor $colors.Accent
}

if (-not $SkipReadmeUpdate) {
    $totalGalleryThemes = ($experimentalDividersThemes.Count + $atomicThemes.Count + $shellThemes.Count + $slimfatThemes.Count + $atomicBitThemes.Count + $cleanDetailedThemes.Count)
    if ($totalGalleryThemes -gt 0) {
        Write-Output "`n💡 Don't forget to:" -ForegroundColor $colors.Warning
        Write-Output '   1. Review the updated README.md' -ForegroundColor $colors.Info
        Write-Output '   2. Commit and push the new preview images' -ForegroundColor $colors.Info
        Write-Output '   3. Verify the gallery renders correctly on GitHub' -ForegroundColor $colors.Info
        Write-Output "`n📊 Gallery Stats:" -ForegroundColor $colors.Accent
        Write-Output "   • Experimental Dividers: $($experimentalDividersThemes.Count) themes" -ForegroundColor $colors.Info
        Write-Output "   • Atomic Custom: $($atomicThemes.Count) themes" -ForegroundColor $colors.Info
        Write-Output "   • 1_shell-Enhanced: $($shellThemes.Count) themes" -ForegroundColor $colors.Info
        Write-Output "   • Slimfat-Enhanced: $($slimfatThemes.Count) themes" -ForegroundColor $colors.Info
        Write-Output "   • AtomicBit-Enhanced: $($atomicBitThemes.Count) themes" -ForegroundColor $colors.Info
        Write-Output "   • Clean-Detailed-Enhanced: $($cleanDetailedThemes.Count) themes" -ForegroundColor $colors.Info
        Write-Output "   • Total: $totalGalleryThemes themes in gallery" -ForegroundColor $colors.Success
    }
}

Write-Output ''
