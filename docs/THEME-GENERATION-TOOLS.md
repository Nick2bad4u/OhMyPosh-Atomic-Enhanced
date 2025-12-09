# 🛠️ Theme Generation & PowerShell Tools Guide

## Table of Contents

1. [Theme Generation Overview](#theme-generation-overview)
2. [Available Generation Scripts](#available-generation-scripts)
3. [Using Generate-AllThemes.ps1](#using-generate-allthemesps1)
4. [Using New-ThemeWithPalette.ps1](#using-new-themewithpaletteps1)
5. [Using cycle-themes.ps1](#using-cycle-themesps1)
6. [Using Merge-OhMyPoshThemes.ps1](#using-merge-ohmyposhthemesps1)
7. [Validation Scripts](#validation-scripts)
8. [Preview Generation](#preview-generation)
9. [Color Palette Alternatives](#color-palette-alternatives)
10. [Advanced Theme Customization](#advanced-theme-customization)

---

## Theme Generation Overview

The OhMyPosh Atomic Enhanced project includes several PowerShell utilities to help you:

✅ Generate themes automatically
✅ Create custom palettes
✅ Cycle through themes
✅ Merge theme configurations
✅ Validate theme files
✅ Generate theme previews

### Why Use These Tools?

Instead of manually editing JSON, use these tools to:

- Generate themes from color palettes
- Create variations of existing themes
- Validate your configuration is correct
- Preview themes before using them
- Batch process multiple themes

---

## Available Generation Scripts

### Location

All scripts are in the **root directory** of the repository.

### Quick Reference Table

| Script                         | Purpose                     | Input          | Output                  |
| ------------------------------ | --------------------------- | -------------- | ----------------------- |
| **Generate-AllThemes.ps1**     | Generate all theme variants | Color palettes | Multiple .json files    |
| **New-ThemeWithPalette.ps1**   | Create theme from palette   | Palette file   | Single .json file       |
| **cycle-themes.ps1**           | Cycle through themes        | Theme folder   | Activates one at a time |
| **Merge-OhMyPoshThemes.ps1**   | Merge multiple themes       | Theme files    | Merged theme            |
| **pre-upload-validation.ps1**  | Validate before upload      | Theme path     | Pass/fail report        |
| **Generate-ThemePreviews.ps1** | Create preview images       | Theme files    | PNG preview images      |
| **sync-official-themes.ps1**   | Sync official themes        | Official repo  | Updated themes          |
| **validate-palette.ps1**       | Validate palette file       | Palette JSON   | Validation report       |

---

## Using Generate-AllThemes.ps1

### Purpose

Generates all theme variants from available color palettes.

### Usage

#### Basic Usage

```powershell
.\Generate-AllThemes.ps1
```

**What it does:**

- Reads all palette files
- Generates themes from each palette
- Saves as individual `.json` files
- Creates one theme per palette

#### Advanced Usage

```powershell
# Generate for specific theme type
.\Generate-AllThemes.ps1 -ThemeType "atomic"

# Generate and output to specific folder
.\Generate-AllThemes.ps1 -OutputPath "C:\my-themes"

# Generate using specific palettes only
.\Generate-AllThemes.ps1 -PaletteFilter "Blue*"
```

### Parameters

```powershell
# Common parameters:
-ThemeType <string>      # Theme template to use (atomic, atomicBit, etc.)
-OutputPath <string>     # Where to save generated themes
-PaletteFilter <string>  # Only use palettes matching pattern
-Force                   # Overwrite existing files
-Verbose                 # Show detailed output
```

### Example Workflow

```powershell
# 1. Prepare your palette file
Copy-Item "color-palette-alternatives.json" "my-palette.json"

# 2. Generate all themes from palette
.\Generate-AllThemes.ps1 -PaletteFilter "my-palette"

# 3. Check generated files
Get-ChildItem -Path ".\atomic" -Filter "*my-palette*"

# 4. Validate generated themes
.\pre-upload-validation.ps1 -ThemePath ".\atomic\OhMyPosh-Atomic-Custom.my-palette.json"

# 5. Test the theme
oh-my-posh init pwsh --config ".\atomic\OhMyPosh-Atomic-Custom.my-palette.json" | Invoke-Expression
```

---

## Using New-ThemeWithPalette.ps1

### Purpose

Creates a **single theme** from a specific color palette.

### Usage

#### Basic Usage

```powershell
.\New-ThemeWithPalette.ps1 -PalettePath "color-palette-alternatives.json" -OutputPath "my-theme.json"
```

#### With Template

```powershell
.\New-ThemeWithPalette.ps1 `
  -PalettePath "my-colors.json" `
  -TemplateFile "OhMyPosh-Atomic-Custom.json" `
  -OutputPath "my-custom-theme.json"
```

### Parameters

```powershell
-PalettePath <string>      # Path to palette JSON file (required)
-TemplateFile <string>     # Template to base theme on (default: atomic)
-OutputPath <string>       # Where to save theme (required)
-ThemeName <string>        # Name for the theme
-Description <string>      # Theme description
-Force                     # Overwrite existing file
```

### Example Workflow

```powershell
# 1. Create a palette file
$palette = @{
    "accent" = "#00BCD4"
    "primary" = "#0080FF"
    "warning" = "#FFD600"
    "error" = "#FF0000"
    "success" = "#00C853"
} | ConvertTo-Json

$palette | Out-File "my-palette.json"

# 2. Create theme from palette
.\New-ThemeWithPalette.ps1 `
  -PalettePath "my-palette.json" `
  -OutputPath "my-atomic-theme.json" `
  -ThemeName "My Custom Theme"

# 3. Test the theme
$config = ".\my-atomic-theme.json"
oh-my-posh init pwsh --config $config | Invoke-Expression

# 4. Verify it looks correct
oh-my-posh config show -config $config | Select-Object -First 20
```

---

## Using cycle-themes.ps1

### Purpose

Cycles through available themes, activating each one so you can preview them.

### Usage

#### Basic Usage

```powershell
.\cycle-themes.ps1
```

**What it does:**

- Displays each theme
- Waits for user input
- Shows next theme on Enter
- Shows previous on Backspace

#### Cycle Specific Folder

```powershell
.\cycle-themes.ps1 -ThemeFolder ".\atomic"
```

#### Set Timeout Between Themes

```powershell
.\cycle-themes.ps1 -DisplaySeconds 5
```

### Parameters

```powershell
-ThemeFolder <string>      # Which folder contains themes to cycle
-DisplaySeconds <number>   # Seconds to show each theme (0 = manual)
-Verbose                   # Show theme file paths
```

### Interactive Commands

| Key           | Action                  |
| ------------- | ----------------------- |
| **Enter**     | Next theme              |
| **Backspace** | Previous theme          |
| **Q**         | Quit                    |
| **S**         | Save current theme      |
| **C**         | Copy current theme path |

### Example Session

```powershell
# Start cycling
.\cycle-themes.ps1 -ThemeFolder ".\atomic"

# Output:
# Currently previewing: OhMyPosh-Atomic-Custom.BlueOcean.json
# Press Enter for next, Backspace for previous, Q to quit

# Press Enter to go to next...
# Currently previewing: OhMyPosh-Atomic-Custom.CatppuccinMocha.json

# Like this one? Press S to save
# [Saved: C:\...\OhMyPosh-Atomic-Custom.CatppuccinMocha.json]
```

---

## Using Merge-OhMyPoshThemes.ps1

### Purpose

Combines multiple theme configurations into a single theme file.

### Usage

#### Merge Two Themes

```powershell
.\Merge-OhMyPoshThemes.ps1 `
  -PrimaryTheme "base-theme.json" `
  -SecondaryTheme "accent-theme.json" `
  -OutputPath "merged-theme.json"
```

#### Merge Multiple Themes

```powershell
$themes = @(
  "theme1.json",
  "theme2.json",
  "theme3.json"
)

.\Merge-OhMyPoshThemes.ps1 -ThemeFiles $themes -OutputPath "combined.json"
```

### Parameters

```powershell
-PrimaryTheme <string>     # Main theme to use as base
-SecondaryTheme <string>   # Theme to merge in (overrides primary)
-ThemeFiles <array>        # Multiple themes to merge
-OutputPath <string>       # Where to save merged theme (required)
-Strategy <string>         # Merge strategy (overwrite|merge|deep)
-Force                     # Overwrite existing file
```

### Example Workflow

```powershell
# Scenario: Combine color palette from one theme with segments from another

# 1. Base atomic theme (for structure)
$base = "OhMyPosh-Atomic-Custom.json"

# 2. Theme with nice colors (for palette)
$colorTheme = "OhMyPosh-Atomic-Custom.NordFrost.json"

# 3. Merge them
.\Merge-OhMyPoshThemes.ps1 `
  -PrimaryTheme $base `
  -SecondaryTheme $colorTheme `
  -OutputPath "my-combined-theme.json"

# 4. Test
oh-my-posh init pwsh --config "my-combined-theme.json" | Invoke-Expression
```

---

## Validation Scripts

### pre-upload-validation.ps1

Validates a theme before uploading to ensure it's correct.

#### Usage

```powershell
.\pre-upload-validation.ps1 -ThemePath "OhMyPosh-Atomic-Custom-ExperimentalDividers.json"
```

#### What It Checks

- ✅ Valid JSON structure
- ✅ Required fields present
- ✅ Palette colors valid hex format
- ✅ No orphaned references
- ✅ Segment configurations valid

#### Output

```
✓ JSON structure valid
✓ All required fields present
✓ Color palette valid
✓ 25 segments configured
✓ No errors found
✓ Ready for upload!
```

### validate-palette.ps1

Validates a color palette file.

#### Usage

```powershell
.\validate-palette.ps1 -PalettePath "color-palette-alternatives.json"
```

#### What It Checks

- ✅ Valid JSON
- ✅ All colors are valid hex
- ✅ Colors are readable
- ✅ Sufficient color variety
- ✅ Contrast ratios adequate

---

## Preview Generation

### Generate-ThemePreviews.ps1

Creates preview images of themes.

#### Usage

```powershell
.\Generate-ThemePreviews.ps1 -ThemeFolder ".\atomic"
```

**Creates:** PNG image previews of each theme

#### Advanced Usage

```powershell
.\Generate-ThemePreviews.ps1 `
  -ThemeFolder ".\atomic" `
  -OutputPath ".\assets\theme-previews" `
  -ImageWidth 1920 `
  -ImageHeight 1080
```

---

## Color Palette Alternatives

### File Location

`color-palette-alternatives.json`

### What It Contains

Predefined color palettes for quick theme generation:

```json
{
  "palettes": {
    "BlueOcean": {
      "accent": "#00BCD4",
      "primary": "#0080FF",
      "warning": "#FFD600",
      "error": "#FF0000",
      "success": "#00C853"
    },
    "NordFrost": {
      "accent": "#88C0D0",
      "primary": "#5E81AC",
      ...
    }
  }
}
```

### Using Custom Palettes

```powershell
# 1. Add your palette to the file
$customPalette = @{
    "MyPalette" = @{
        "accent" = "#FF5733"
        "primary" = "#3399FF"
        "warning" = "#FFB700"
        "error" = "#FF4444"
        "success" = "#44FF44"
    }
}

# 2. Generate theme from it
.\New-ThemeWithPalette.ps1 `
  -PaletteName "MyPalette" `
  -OutputPath "my-palette-theme.json"
```

---

## Advanced Theme Customization

### Creating a Custom Theme Generation Script

```powershell
function New-AtomicTheme {
    param(
        [string]$ThemeName,
        [hashtable]$ColorPalette,
        [string]$OutputPath = ".\"
    )

    # Load base theme
    $baseTheme = Get-Content "OhMyPosh-Atomic-Custom.json" | ConvertFrom-Json

    # Update colors
    $baseTheme.palette = $ColorPalette

    # Save new theme
    $themePath = Join-Path $OutputPath "$ThemeName.json"
    $baseTheme | ConvertTo-Json -Depth 100 | Out-File $themePath

    Write-Host "✓ Created: $themePath"
}

# Usage
$myColors = @{
    "accent" = "#00BCD4"
    "primary" = "#0080FF"
    "error" = "#FF0000"
    "success" = "#00C853"
}

New-AtomicTheme -ThemeName "MyCustom" -ColorPalette $myColors
```

### Batch Processing Themes

```powershell
# Generate themes for multiple palettes
$palettes = @(
    "BlueOcean",
    "NordFrost",
    "DraculaNight",
    "GruvboxDark"
)

foreach ($palette in $palettes) {
    Write-Host "Generating: $palette"
    .\New-ThemeWithPalette.ps1 `
      -PaletteFilter $palette `
      -OutputPath ".\output\OhMyPosh-Atomic-Custom.$palette.json"
}

Write-Host "✓ Generated $($palettes.Count) themes"
```

### Testing Generated Themes

```powershell
# Test all generated themes
$themes = Get-ChildItem ".\output" -Filter "*.json"

foreach ($theme in $themes) {
    Write-Host "Testing: $($theme.Name)"

    # Load and validate
    $json = Get-Content $theme.FullName | ConvertFrom-Json

    # Check for errors
    if ($json.blocks -and $json.palette) {
        Write-Host "  ✓ Valid" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Invalid" -ForegroundColor Red
    }
}
```

---

## Workflow Examples

### Complete Workflow: Create & Test Custom Theme

```powershell
# Step 1: Create a color palette
$myPalette = @{
    "accent" = "#FF6B6B"
    "primary" = "#4ECDC4"
    "warning" = "#FFE66D"
    "error" = "#95E1D3"
    "success" = "#C7CEEA"
} | ConvertTo-Json

$myPalette | Out-File "my-palette.json"

# Step 2: Generate theme from palette
.\New-ThemeWithPalette.ps1 `
  -PalettePath "my-palette.json" `
  -OutputPath "my-theme.json" `
  -ThemeName "My Awesome Theme"

# Step 3: Validate the theme
.\pre-upload-validation.ps1 -ThemePath "my-theme.json"

# Step 4: Generate preview
.\Generate-ThemePreviews.ps1 -ThemeFile "my-theme.json"

# Step 5: Test the theme
$env:OHMYPOSH_DEBUG = "false"
oh-my-posh init pwsh --config "my-theme.json" | Invoke-Expression

# Step 6: If happy, save for later
Copy-Item "my-theme.json" ".\atomic\OhMyPosh-Atomic-Custom.MyAwesome.json"

# Step 7: Add to cycling tests
.\cycle-themes.ps1 -ThemeFolder ".\atomic"
```

### Batch Workflow: Generate Multiple Variants

```powershell
# Generate variants of a theme with different color shifts

function New-ThemeVariant {
    param([string]$BaseName, [hashtable]$ColorMods)

    $base = Get-Content "OhMyPosh-Atomic-Custom.json" | ConvertFrom-Json

    # Apply color modifications
    foreach ($color in $ColorMods.Keys) {
        $base.palette.$color = $ColorMods[$color]
    }

    $base | ConvertTo-Json -Depth 100 | Out-File "variant-$BaseName.json"
}

# Create variants with different accent colors
$accents = @(
    @{"accent" = "#FF6B6B"},
    @{"accent" = "#4ECDC4"},
    @{"accent" = "#FFE66D"}
)

foreach ($i in 0..2) {
    New-ThemeVariant "variant$i" $accents[$i]
}

Write-Host "✓ Created 3 theme variants"
```

---

## Troubleshooting Theme Scripts

### Script Won't Run

**Error:** `Script cannot be loaded because running scripts is disabled`

**Fix:**

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### JSON Errors

**Error:** `ConvertFrom-Json: Invalid JSON`

**Fix:** Validate JSON first

```powershell
function Test-JSON {
    param([string]$FilePath)
    try {
        Get-Content $FilePath | ConvertFrom-Json
        Write-Host "✓ Valid JSON"
    } catch {
        Write-Host "✗ Invalid JSON: $_"
    }
}

Test-JSON "my-theme.json"
```

### Theme Won't Load

**Error:** `Theme file not found or invalid`

**Fix:** Check path and permissions

```powershell
# Verify file exists
Test-Path "my-theme.json"

# Verify readable
Get-Content "my-theme.json" | Select-Object -First 5

# Test with full path
$fullPath = (Resolve-Path "my-theme.json").Path
oh-my-posh init pwsh --config $fullPath | Invoke-Expression
```

---

## Summary

The PowerShell tools provide:

✅ **Automated generation** - Generate themes from palettes
✅ **Batch processing** - Create multiple themes at once
✅ **Validation** - Ensure themes are correct before using
✅ **Preview** - See themes before committing
✅ **Merging** - Combine theme configurations
✅ **Cycling** - Preview multiple themes easily

**For more information:**

- See [ADVANCED-CUSTOMIZATION-GUIDE.md](./ADVANCED-CUSTOMIZATION-GUIDE.md)
- See [JSON-CONFIGURATION-GUIDE.md](./JSON-CONFIGURATION-GUIDE.md)
- See [THEME-GENERATOR-README.md](../THEME-GENERATOR-README.md)
