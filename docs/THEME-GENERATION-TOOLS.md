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

The OhMyPosh Atomic Enhanced project includes several PowerShell utilities to
help you:

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

All PowerShell helper scripts live in the **`scripts/`** directory of the
repository.

### Quick Reference

- **`scripts/Generate-AllThemes.ps1`** generates palette extensions for five
  independent roots from the color palettes. It writes to the theme-family
  folders by default or to one requested output folder.
- **`scripts/Generate-ExperimentalDividers.ps1`** generates
  ExperimentalDividers palette extensions in `experimentalDividers/`.
- **`scripts/Make-ExtendedVariant.ps1`** applies the ordered Extended variant
  definition to the ExperimentalDividers root and writes a complete helper.
- **`scripts/Make-ColorCycleVariant.ps1`** applies the shared ColorCycle
  definition to the Atomic Custom or ExperimentalDividers root.
- **`scripts/Make-GradientVariant.ps1`** applies connected two-stop native
  gradients to the ExperimentalDividers root.
- **`scripts/Make-GradientRampsVariant.ps1`** applies connected gradients with
  position-matched full-block ramps to the ExperimentalDividers root.
- **`scripts/Make-GradientRampsAutoShadeVariant.ps1`** adds automatic shading
  to independent entries while retaining the connected ramps.
- **`scripts/New-ThemeWithPalette.ps1`** creates one small palette overlay from
  a root theme and palette.
- **`scripts/cycle-themes.ps1`** activates themes from a selected folder one at
  a time.
- **`scripts/Merge-OhMyPoshThemes.ps1`** preserves a custom structure while
  applying styling from one or more official themes.
- **`scripts/pre-upload-validation.ps1`** validates a theme and reports whether
  it is ready to upload.
- **`scripts/Generate-ThemePreviews.ps1`** creates SVG preview images from theme
  files.
- **`scripts/Set-PaletteVisualDesigns.ps1`** applies curated visible-role ramps
  and synchronizes the Original root themes.
- **`scripts/Test-PaletteVisualQuality.ps1`** verifies all palette designs,
  six-family contrast, and freshness across the 222 overlays.
- **`scripts/sync-official-themes.ps1`** synchronizes the vendored official
  theme repository.
- **`scripts/validate-palette.ps1`** validates palette-key usage in a theme.
- **`scripts/Normalize-Palettes.ps1`** expands every palette to the full keyset
  and writes the normalized palette source.

> Each family has one complete, non-extended Original at the repository root
> and 37 palette-only overlays in its folder. `Generate-AllThemes.ps1` never
> synchronizes independent root themes. ExperimentalDividers is generated
> separately and extends only
> `OhMyPosh-Atomic-Custom-ExperimentalDividers.json`.

---

## Using Generate-AllThemes.ps1

### Generate-AllThemes purpose

Generates small `extends` overlays for every non-original color palette. The
root source files remain the complete Original themes.

### Generate-AllThemes usage

#### Generate-AllThemes basic usage

```powershell
.\scripts\Generate-AllThemes.ps1
```

**What it does:**

- Reads palettes from `color-palette-alternatives.json` (by default)
- Generates color-only overlays for each independent source theme
- Writes 37 overlays into each theme-family folder by default:
  - `./atomic/`
  - `./1_shell/`
  - `./slimfat/`
  - `./atomicBit/`
  - `./cleanDetailed/`

#### Generate-AllThemes advanced usage

```powershell
# Use a custom palettes file
.\scripts\Generate-AllThemes.ps1 `
  -PalettesFile ".\color-palette-alternatives.json" `
  -Force

# Exclude an additional palette (`original` is always skipped)
.\scripts\Generate-AllThemes.ps1 -ExcludePalettes @('test_palette') -Force

# Only generate for some source themes
.\scripts\Generate-AllThemes.ps1 -SourceThemes @(
  'OhMyPosh-Atomic-Custom.json',
  '1_shell-Enhanced.omp.json'
) -Force

# Override output: put ALL generated variants into one directory
.\scripts\Generate-AllThemes.ps1 -OutputDirectory "C:\my-themes" -Force
```

### Generate-AllThemes parameters

```powershell
-SourceThemes <string[]>    # Theme templates to generate from
-PalettesFile <string>      # Palette JSON file
-ExcludePalettes <string[]> # Additional non-original palette IDs to skip
-OutputDirectory <string>   # Write every generated variant to one folder
-BaseUrl <string>           # Extends URL; pass '' for relative local paths
-Force                      # Overwrite existing files
-UpdateAccentColor          # Set accent_color from the palette accent
```

### Generate-AllThemes example workflow

```powershell
# 1. Prepare your palette file
Copy-Item "color-palette-alternatives.json" "my-palette.json"

# 2. Generate all themes from palette
.\scripts\Generate-AllThemes.ps1 -PalettesFile "my-palette.json" -Force

# 3. Check generated files
Get-ChildItem -Path ".\atomic" -Filter "OhMyPosh-Atomic-Custom.*.json"

# 4. Validate roots plus every generated overlay
.\scripts\Test-Themes.ps1 -IncludeGenerated

# 5. Test the theme
oh-my-posh init pwsh `
  --config ".\atomic\OhMyPosh-Atomic-Custom.TokyoNight.json" |
  Invoke-Expression
```

---

## Using New-ThemeWithPalette.ps1

### New-ThemeWithPalette purpose

Creates a **single palette-only theme overlay** from a named palette or a
palette object. The generated file extends the selected source theme instead of
duplicating its blocks and segments.

### New-ThemeWithPalette usage

#### New-ThemeWithPalette basic usage

```powershell
.\scripts\New-ThemeWithPalette.ps1 `
  -PaletteName "tokyo_night" `
  -OutputName "TokyoNight"
```

#### With Template

```powershell
.\scripts\New-ThemeWithPalette.ps1 `
  -SourceTheme "OhMyPosh-Atomic-Custom.json" `
  -PaletteName "nord_frost" `
  -OutputPath ".\atomic\OhMyPosh-Atomic-Custom.NordFrost.json" `
  -UpdateAccentColor
```

### New-ThemeWithPalette parameters

```powershell
-SourceTheme <string>     # Source theme JSON; defaults to Atomic Custom
-PaletteName <string>     # Palette ID, such as nord_frost
-PaletteObject <object>   # Custom palette object instead of PaletteName
-OutputName <string>      # Output filename suffix, such as TokyoNight
-OutputPath <string>      # Full output path; overrides OutputName
-PalettesFile <string>    # Palette JSON source
-ExtendsPath <string>     # Explicit extends value; otherwise derived
-UpdateAccentColor        # Set accent_color from the palette accent
```

### New-ThemeWithPalette example workflow

```powershell
# 1. Create a custom palette object
$palette = @{
    "accent" = "#00BCD4"
    "blue_primary" = "#0080FF"
    "orange_warning" = "#FFD600"
    "maroon_error" = "#FF0000"
    "green_success" = "#00C853"
}

# 2. Create a palette-only overlay
pwsh ./scripts/New-ThemeWithPalette.ps1 `
  -PaletteObject $palette `
  -OutputPath ./local-themes/my-atomic-theme.json `
  -UpdateAccentColor

# 3. Validate the overlay's resolved palette references.
pwsh ./scripts/validate-palette.ps1 `
  -ConfigPath ./local-themes/my-atomic-theme.json

oh-my-posh print primary `
  --config ./local-themes/my-atomic-theme.json `
  --shell pwsh `
  --force
```

---

## Using cycle-themes.ps1

### cycle-themes purpose

Renders available themes one at a time without changing the current shell's
active configuration. The script advances automatically after `-Delay` seconds.

### cycle-themes usage

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

### cycle-themes parameters

```powershell
-Official     # Include themes under ./ohmyposh-official-themes
-Custom       # Include this repo's themes
-Variants     # Also include palette variants from theme-family folders
-Delay <int>  # Seconds to display each theme before switching
```

Press Ctrl+C to stop the automatic cycle.

---

## Using Merge-OhMyPoshThemes.ps1

### Merge-OhMyPoshThemes purpose

Preserves the blocks, tooltips, segment positions, templates, and custom
settings from one custom theme while applying colors and visual styling from an
official Oh My Posh theme. The script writes one merged theme for each official
theme it processes.

### Merge-OhMyPoshThemes usage

#### Apply One Official Theme's Styling

```pwsh
pwsh ./scripts/Merge-OhMyPoshThemes.ps1 `
  -CustomThemePath ./OhMyPosh-Atomic-Custom.json `
  -OfficialThemePath ./ohmyposh-official-themes/themes/dracula.omp.json `
  -OutputPath ./merged-themes
```

This writes `./merged-themes/Custom-dracula.omp.json`.

#### Apply Every Official Theme's Styling

```pwsh
pwsh ./scripts/Merge-OhMyPoshThemes.ps1 `
  -CustomThemePath ./OhMyPosh-Atomic-Custom.json `
  -OfficialThemePath ./ohmyposh-official-themes/themes `
  -OutputPath ./merged-themes `
  -ProcessAll
```

### Merge-OhMyPoshThemes parameters

- `-CustomThemePath <string>`: custom theme whose structure, templates, and
  behavior are preserved.
- `-OfficialThemePath <string>`: one official theme file, or a directory used
  with `-ProcessAll`.
- `-OutputPath <string>`: directory for
  `Custom-<official-theme>.omp.json` files.
- `-ProcessAll`: process every `*.omp.json` file in `OfficialThemePath`.

### Merge-OhMyPoshThemes example workflow

```pwsh
# Preserve the Atomic Custom layout while adopting Dracula's visual styling.
pwsh ./scripts/Merge-OhMyPoshThemes.ps1 `
  -CustomThemePath ./OhMyPosh-Atomic-Custom.json `
  -OfficialThemePath ./ohmyposh-official-themes/themes/dracula.omp.json `
  -OutputPath ./merged-themes

# Render the merged primary prompt without changing the current shell session.
oh-my-posh print primary `
  --config ./merged-themes/Custom-dracula.omp.json `
  --shell pwsh `
  --force
```

---

## Validation Scripts

### pre-upload-validation.ps1

Validates a theme before uploading to ensure it's correct.

#### pre-upload-validation usage

```powershell
.\scripts\pre-upload-validation.ps1 `
  -ThemePath "OhMyPosh-Atomic-Custom-ExperimentalDividers.json" `
  -TestPath "test_OhMyPosh-Atomic-Custom.ExperimentalDividers.json"
```

#### pre-upload-validation checks

- ✅ Valid JSON structure
- ✅ Required fields present
- ✅ Palette colors valid hex format
- ✅ No orphaned references
- ✅ Segment configurations valid

#### Output

```text
✓ JSON structure valid
✓ All required fields present
✓ Color palette valid
✓ 25 segments configured
✓ No errors found
✓ Ready for upload!
```

### validate-palette.ps1

Validates palette-key usage in an Oh My Posh config. It resolves a local
`extends` base, then compares every `p:<key>` reference with the combined
palette definitions.

#### validate-palette usage

```pwsh
pwsh ./scripts/validate-palette.ps1 `
  -ConfigPath ./OhMyPosh-Atomic-Custom.json `
  -ShowAll
```

#### validate-palette checks

- ✅ Config and local extended-base JSON are parseable
- ✅ Every referenced palette key is defined
- ✅ Defined-but-unused keys are reported
- ✅ Optional `-FailOnUnused` enforcement uses a distinct exit code

### Test-PaletteVisualQuality.ps1

Validates the actual palette design contract rather than only checking JSON
shape. It proves that all 38 palettes have curated visible-role colors, tests
every direct/fallback segment pairing across all six roots at a minimum 4.5:1
contrast ratio, and verifies that all 222 generated overlays match the current
palette source.

```pwsh
pwsh ./scripts/Test-PaletteVisualQuality.ps1
```

`Test-Themes.ps1 -IncludeGenerated` runs this gate automatically.

---

## Preview Generation

### Generate-ThemePreviews.ps1

Creates deterministic SVG previews with Oh My Posh v31 or later.

#### Generate-ThemePreviews usage

```pwsh
pwsh ./scripts/Generate-ThemePreviews.ps1 -Force
```

The generator requires the sanitized recorded-v1 `theme-preview.data.json`
fixture and always passes both `--data` and `--data-only`. Every palette
therefore renders with the same shell, repository, Git, system, battery,
weather, and runtime state without probing the live machine, filesystem, Git
repository, or network. It writes SVGs to `assets/theme-previews/`, removes a
theme's superseded PNG only after its SVG succeeds, and refreshes the README
gallery.

`image.settings.json` is repository-owned generator configuration; it is not
passed to Oh My Posh through the removed `--settings` flag. Supported keys map
directly to v31 SVG export flags:

- `background_color` maps to `--background-color` for the canvas fallback.
- `font_family` maps to `--font-family` for the CSS font-family stack.
- `terminal_width` maps to `--terminal-width` for the prompt and canvas width.
- `cell_width` maps to `--cell-width` for the monospace cell advance.
- `line_height` maps to `--line-height` for the row advance.
- `fill_ascent` maps to `--fill-ascent` for optional fill above the baseline.
- `fill_descent` maps to `--fill-descent` for optional fill below the baseline.
- `terminal_width_overrides` applies optional glob-pattern widths after the
  default `terminal_width`.

Unknown or invalid settings fail before any preview is generated. Terminal-width
patterns must match at most once per generated preview. The checked-in widths
follow each family's actual layout: 200 columns for the content-dense
ExperimentalDividers prompt, 120 for Atomic and Slimfat, and 100 for 1_shell,
AtomicBit, and Clean Detailed. The generator discovers every root-level JSON
theme by structure, while ignoring root JSON fixtures and settings that do not
contain theme `blocks` or `extends`. The default CodeNewRoman metrics were
measured from the configured font rather than copied from Oh My Posh's Hack Nerd
Font defaults.

#### Generate-ThemePreviews advanced usage

```pwsh
# Render only selected themes into a review directory without changing README.
pwsh ./scripts/Generate-ThemePreviews.ps1 `
  -ThemePattern @(
    'atomic/OhMyPosh-Atomic-Custom.NordFrost.json',
    'experimentalDividers/OhMyPosh-Atomic-Custom-ExperimentalDividers.NordFrost.json'
  ) `
  -OutputDirectory ./preview-review `
  -SkipReadmeUpdate `
  -Force

# Use a reviewed alternate recorded-v1 fixture.
pwsh ./scripts/Generate-ThemePreviews.ps1 `
  -PreviewData ./fixtures/alternate-preview.data.json `
  -Force
```

Recorded-v1 fixtures have a top-level `"version": 1` marker and wrap every
segment as `{ "enabled": true|false, "data": { ... } }`. Do not replace
`theme-preview.data.json` with unchecked `oh-my-posh config export data` output.
Recorder output can contain local paths, Git identity/remotes, and request URLs
with credentials. Sanitize and review every value before committing it.

The focused compatibility gate renders all three gradient variants and locally
resolved ExperimentalDividers and Clean Detailed `extends` overlays:

```pwsh
pwsh ./scripts/Test-ThemePreviewExport.ps1
```

---

## Color Palette Alternatives

### File Location

`color-palette-alternatives.json`

The hand-reviewed visible-role ramps live in
`scripts/Palette-Visual-Designs.json`. The palette JSON remains the generation
source; use the applicator instead of hand-copying the same role changes into 38
palettes.

### Curated Palette Workflow

```pwsh
# Apply curated role ramps, rebuild divider colors, and synchronize all Originals.
pwsh ./scripts/Set-PaletteVisualDesigns.ps1
pwsh ./scripts/Normalize-Palettes.ps1
pwsh ./scripts/Set-PaletteVisualDesigns.ps1 -SyncRootThemes

# Regenerate all six families and prove coverage, contrast, and freshness.
pwsh ./scripts/Generate-AllThemes.ps1 -Force
pwsh ./scripts/Generate-ExperimentalDividers.ps1 -Force
pwsh ./scripts/Test-PaletteVisualQuality.ps1

# Render the deterministic gallery for visual review.
pwsh ./scripts/Generate-ThemePreviews.ps1 -Force
```

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

```pwsh
# Step 1: Create a custom palette object
$myPalette = @{
    "accent" = "#FF6B6B"
    "blue_primary" = "#4ECDC4"
    "orange_warning" = "#FFE66D"
    "maroon_error" = "#95E1D3"
    "green_success" = "#C7CEEA"
}

# Step 2: Generate a local palette-only overlay
pwsh ./scripts/New-ThemeWithPalette.ps1 `
  -PaletteObject $myPalette `
  -OutputPath ./local-themes/my-theme.json `
  -UpdateAccentColor

# Step 3: Validate the overlay's resolved palette references
pwsh ./scripts/validate-palette.ps1 `
  -ConfigPath ./local-themes/my-theme.json

# Step 4: Generate a review preview without replacing the checked-in README gallery
pwsh ./scripts/Generate-ThemePreviews.ps1 `
  -ThemePattern ./local-themes/my-theme.json `
  -OutputDirectory ./preview-review `
  -SkipReadmeUpdate `
  -Force

# Step 5: Render the primary prompt without changing the current shell session
oh-my-posh print primary `
  --config ./local-themes/my-theme.json `
  --shell pwsh `
  --force
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

These scripts generate complete root helper files from the current canonical
source themes. They do not use the existing generated file as input.

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

- Fish does not reliably support cursor-positioned right-aligned prompt blocks
  rendered inside the left prompt.
- This script moves the right-aligned “top bar” segments into the `rprompt` so
  fish renders them via `fish_right_prompt`, and disables cursor positioning.

It also preserves your Fish-only tweaks (segment order/selection and
per-segment overrides) by reading the existing Fish file and re-applying those
customizations during regeneration.

```powershell
.\scripts\Make-FishVariant.ps1
```

### Make-ExtendedVariant.ps1

Generates
`OhMyPosh-Atomic-Custom-ExperimentalDividers.Extended.json` by cloning
canonical ExperimentalDividers and inserting the ordered VCS segments and
tooltips declared in
`scripts/variants/ExperimentalDividers.Extended.variant.json`.

```powershell
.\scripts\Make-ExtendedVariant.ps1
```

### Make-ColorCycleVariant.ps1

Clones a complete source theme, adds the shared 12-step color cycle, and removes
direct prompt-segment color fields so the top-level cycle controls the rendered
sequence.

```powershell
# Atomic Custom
.\scripts\Make-ColorCycleVariant.ps1

# ExperimentalDividers
.\scripts\Make-ColorCycleVariant.ps1 \`
  -Source .\OhMyPosh-Atomic-Custom-ExperimentalDividers.json
```

### Make-GradientVariant.ps1

Generates `OhMyPosh-Atomic-Custom-ExperimentalDividers.Gradient.json` from the
canonical ExperimentalDividers theme. It gives prompt-block backgrounds
explicit two-stop `linear-gradient(...)` values. Most begin with
`parentBackground` and finish at the segment's configured palette color, so
the previous segment's final rendered stop becomes the next segment's first
stop automatically. The shell and npm entry segments use explicit pairs because
they cannot rely on a previous active background.

Oh My Posh collapses a two-stop gradient below four visible cells to its
configured final stop. To avoid a row of one-cell color jumps, the standard
Gradient definition removes all 30 transition-divider segments. The following
wider content segments inherit the previous active background and perform the
interpolation instead.

Because Oh My Posh does not support gradients on `interactive: true` segments,
the generated variant makes `path-lprompt` and `git-lprompt`
non-interactive; the canonical source is not changed. Tooltips remain solid
because they do not form a dependable adjacent-segment chain.

The repository baseline of Oh My Posh v31.0.0 or newer is required.

```powershell
.\scripts\Make-GradientVariant.ps1

# Test it in the current PowerShell session
oh-my-posh init pwsh \`
  --config .\OhMyPosh-Atomic-Custom-ExperimentalDividers.Gradient.json |
  Invoke-Expression
```

### Make-GradientRampsVariant.ps1

Generates
`OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRamps.json` through the
shared Gradient generator. It keeps the connected two-stop backgrounds and
interactive-segment compatibility changes, but uses nine grouped six-cell ramps
rather than removing every transition divider. It collapses 21 redundant
dividers and retains each group's endpoint as a ramp.

Each retained ramp contains six full-block cells wrapped in
`<background,transparent>`. The foreground keyword resolves to the gradient
color at each text position, so the cells visually merge into their backgrounds
while retaining stable terminal width. This is the smoother alternative; the
standard divider-free Gradient output remains unchanged for side-by-side
testing.

```powershell
.\scripts\Make-GradientRampsVariant.ps1

# Test it in the current PowerShell session
oh-my-posh init pwsh \`
  --config .\OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRamps.json |
  Invoke-Expression
```

### Make-GradientRampsAutoShadeVariant.ps1

Generates
`OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRampsAutoShade.json`
through the shared Gradient generator. It retains the nine connected six-cell
ramps, but uses `dark-gradient(color)` backgrounds for the shell, npm
right-prompt, and separate right-block entries. These are the three places where
`parentBackground` cannot provide a dependable preceding rendered color. All
following segments continue to use
`linear-gradient(parentBackground, ...)`, so their first stop resolves from
the previous segment's final rendered stop.

```powershell
.\scripts\Make-GradientRampsAutoShadeVariant.ps1

# Test it in the current PowerShell session (Oh My Posh v31.0.0+)
oh-my-posh init pwsh \`
  --config \`
    .\OhMyPosh-Atomic-Custom-ExperimentalDividers.GradientRampsAutoShade.json |
  Invoke-Expression
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
