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

All PowerShell helper scripts live in the **`scripts/`** directory of the repository.

### Quick Reference Table

| Script | Purpose | Input | Output |
| --- | --- | --- | --- |
| **scripts/Generate-AtomicCustomFromExperimentalDividers.ps1** | Sync non-divider Atomic Custom from ExperimentalDividers (tooltips/shared config) | ExperimentalDividers theme + Atomic Custom template | Updated `OhMyPosh-Atomic-Custom.json` |
| **scripts/Sync-ThemeTemplatesFromAtomicCustom.ps1** | Sync other base templates from Atomic Custom | `OhMyPosh-Atomic-Custom.json` | Updated base templates (`1_shell`, `slimfat`, etc.) |
| **scripts/Generate-AllThemes.ps1** | Generate all theme variants | Color palettes | Theme-family folders (default) or one output folder |
| **scripts/New-ThemeWithPalette.ps1** | Create theme from palette | Palette file | Single .json file |
| **scripts/cycle-themes.ps1** | Cycle through themes | Theme folder | Activates one at a time |
| **scripts/Merge-OhMyPoshThemes.ps1** | Merge multiple themes | Theme files | Merged theme |
| **scripts/pre-upload-validation.ps1** | Validate before upload | Theme path | Pass/fail report |
| **scripts/Generate-ThemePreviews.ps1** | Create preview images | Theme files | PNG preview images |
| **scripts/sync-official-themes.ps1** | Sync official themes | Official repo | Updated themes |
| **scripts/validate-palette.ps1** | Validate palette file | Palette JSON | Validation report |
| **scripts/Normalize-Palettes.ps1** | Expand/normalize all palettes to include the full keyset (tooltips/shell/dividers/debug/etc) | `OhMyPosh-Atomic-Custom.json` + `color-palette-alternatives.json` | Updated `color-palette-alternatives.json` |

> Note: `scripts/Generate-AllThemes.ps1` now runs the two sync scripts above by default, so updates you make to
> `OhMyPosh-Atomic-Custom-ExperimentalDividers.json` (tooltips/shared settings) flow into all generated theme variants.

---

## Using Generate-AllThemes.ps1

### Purpose

Generates all theme variants from available color palettes.

### Usage

#### Basic Usage

```powershell
.\scripts\Generate-AllThemes.ps1
```

**What it does:**

- Reads palettes from `color-palette-alternatives.json` (by default)
- Generates variants for each source theme template
- Writes variants into the theme-family folders by default:
  - `./atomic/`
  - `./1_shell/`
  - `./slimfat/`
  - `./atomicBit/`
  - `./cleanDetailed/`

#### Advanced Usage

```powershell
# Use a custom palettes file
.\scripts\Generate-AllThemes.ps1 -PalettesFile ".\color-palette-alternatives.json" -Force

# Exclude specific palettes
.\scripts\Generate-AllThemes.ps1 -ExcludePalettes @('original') -Force

# Only generate for some source themes
.\scripts\Generate-AllThemes.ps1 -SourceThemes @(
  'OhMyPosh-Atomic-Custom.json',
  '1_shell-Enhanced.omp.json'
) -Force

# Override output: put ALL generated variants into one directory
.\scripts\Generate-AllThemes.ps1 -OutputDirectory "C:\my-themes" -Force
```

### Parameters

```powershell
# Common parameters:
-SourceThemes <string[]>     # Theme templates to generate from
-PalettesFile <string>       # Palette JSON file (default: .\color-palette-alternatives.json)
-ExcludePalettes <string[]>  # Palette IDs to skip (e.g. 'original')
-OutputDirectory <string>    # Optional: write all generated variants to one folder
-Force                        # Overwrite existing files
-UpdateAccentColor            # Update theme accent_color to match palette accent
```

### Example Workflow

```powershell
# 1. Prepare your palette file
Copy-Item "color-palette-alternatives.json" "my-palette.json"

# 2. Generate all themes from palette
.\scripts\Generate-AllThemes.ps1 -PalettesFile "my-palette.json" -Force

# 3. Check generated files
Get-ChildItem -Path ".\atomic" -Filter "OhMyPosh-Atomic-Custom.*.json"

# 4. Validate generated themes
.\scripts\pre-upload-validation.ps1 -ThemePath ".\atomic\OhMyPosh-Atomic-Custom.TokyoNight.json"

# 5. Test the theme
oh-my-posh init pwsh --config ".\atomic\OhMyPosh-Atomic-Custom.TokyoNight.json" | Invoke-Expression
```

---

## Using New-ThemeWithPalette.ps1

### Purpose

Creates a **single theme** from a specific color palette.

### Usage

#### Basic Usage

```powershell
.\scripts\New-ThemeWithPalette.ps1 -PaletteName "tokyo_night" -OutputName "TokyoNight"
```

#### With Template

```powershell
.\scripts\New-ThemeWithPalette.ps1 `
  -SourceTheme "OhMyPosh-Atomic-Custom.json" `
  -PaletteName "nord_frost" `
  -OutputPath ".\atomic\OhMyPosh-Atomic-Custom.NordFrost.json" `
  -UpdateAccentColor
```

### Parameters

```powershell
-SourceTheme <string>      # Source theme JSON to apply the palette to (default: OhMyPosh-Atomic-Custom.json)
-PaletteName <string>      # Palette ID from color-palette-alternatives.json (e.g. nord_frost)
-PaletteObject <object>    # Provide a custom palette object directly instead of PaletteName
-OutputName <string>       # Suffix for output filename (e.g. TokyoNight)
-OutputPath <string>       # Full path to output file (overrides OutputName)
-PalettesFile <string>     # Palette JSON file (default: color-palette-alternatives.json)
-UpdateAccentColor         # Update accent_color to match the palette accent
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
.\scripts\New-ThemeWithPalette.ps1 `
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

#### Basic Usage (cycles official + custom)

```powershell
.\scripts\cycle-themes.ps1
```

#### Only custom themes

```powershell
.\scripts\cycle-themes.ps1 -Custom -Official:$false
```

#### Include palette variants from theme-family folders

```powershell
.\scripts\cycle-themes.ps1 -Custom -Variants
```

#### Control the delay (seconds)

```powershell
.\scripts\cycle-themes.ps1 -Delay 3
```

### Parameters

```powershell
-Official     # Include themes under ./ohmyposh-official-themes
-Custom       # Include this repo's themes
-Variants     # Also include palette variants from theme-family folders
-Delay <int>  # Seconds to display each theme before switching
```

# Press Enter for next, Backspace for previous, Q to quit

# Press Enter to go to next...

# Currently previewing: OhMyPosh-Atomic-Custom.CatppuccinMocha.json

# Like this one? Press S to save

# \[Saved: C:\...\OhMyPosh-Atomic-Custom.CatppuccinMocha.json\]

````

---

## Using Merge-OhMyPoshThemes.ps1

### Purpose

Combines multiple theme configurations into a single theme file.

### Usage

#### Merge Two Themes

```powershell
.\scripts\Merge-OhMyPoshThemes.ps1 `
  -PrimaryTheme "base-theme.json" `
  -SecondaryTheme "accent-theme.json" `
  -OutputPath "merged-theme.json"
````

#### Merge Multiple Themes

```powershell
$themes = @(
  "theme1.json",
  "theme2.json",
  "theme3.json"
)

.\scripts\Merge-OhMyPoshThemes.ps1 -ThemeFiles $themes -OutputPath "combined.json"
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
.\scripts\Merge-OhMyPoshThemes.ps1 `
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
.\scripts\pre-upload-validation.ps1 -ThemePath "OhMyPosh-Atomic-Custom-ExperimentalDividers.json"
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
.\scripts\validate-palette.ps1 -PalettePath "color-palette-alternatives.json"
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
.\scripts\Generate-ThemePreviews.ps1 -ThemeFolder ".\atomic"
```

**Creates:** PNG image previews of each theme

#### Advanced Usage

```powershell
.\scripts\Generate-ThemePreviews.ps1 `
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
.\scripts\New-ThemeWithPalette.ps1 `
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
  @{ id = "blue_ocean"; out = "BlueOcean" },
  @{ id = "nord_frost"; out = "NordFrost" },
  @{ id = "dracula_night"; out = "DraculaNight" },
  @{ id = "gruvbox_dark"; out = "GruvboxDark" }
)

foreach ($p in $palettes) {
  Write-Host "Generating: $($p.id)"
  .\scripts\New-ThemeWithPalette.ps1 -PaletteName $p.id -OutputPath ".\output\OhMyPosh-Atomic-Custom.$($p.out).json"
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
.\scripts\New-ThemeWithPalette.ps1 `
  -PalettePath "my-palette.json" `
  -OutputPath "my-theme.json" `
  -ThemeName "My Awesome Theme"

# Step 3: Validate the theme
.\scripts\pre-upload-validation.ps1 -ThemePath "my-theme.json"

# Step 4: Generate preview
.\scripts\Generate-ThemePreviews.ps1 -ThemeFile "my-theme.json"

# Step 5: Test the theme
$env:OHMYPOSH_DEBUG = "false"
oh-my-posh init pwsh --config "my-theme.json" | Invoke-Expression

# Step 6: If happy, save for later
Copy-Item "my-theme.json" ".\atomic\OhMyPosh-Atomic-Custom.MyAwesome.json"

# Step 7: Add to cycling tests
.\scripts\cycle-themes.ps1 -ThemeFolder ".\atomic"
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

## Special Variant Generators

These scripts generate “derived” theme files from the main **ExperimentalDividers** theme.

### Make-NoShellIntegration.ps1

Generates:
- `OhMyPosh-Atomic-Custom-ExperimentalDividers.NoShellIntegration.json`

```powershell
.\scripts\Make-NoShellIntegration.ps1
```

### Make-FishVariant.ps1

Generates:
- `OhMyPosh-Atomic-Custom-ExperimentalDividers.Fish.json`

Why it exists:
- Fish does not reliably support cursor-positioned right-aligned prompt blocks rendered inside the left prompt.
- This script moves the right-aligned “top bar” segments into the `rprompt` so fish renders them via `fish_right_prompt`, and disables cursor positioning.

It also preserves your Fish-only tweaks (segment order/selection + per-segment overrides) by reading the existing Fish file and re-applying those customizations during regeneration.

```powershell
.\scripts\Make-FishVariant.ps1
```

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
- See [THEME-GENERATOR-README.md](./THEME-GENERATOR-README.md)
