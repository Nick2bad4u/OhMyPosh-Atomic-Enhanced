# 🎨 Quick Reference - Theme Generator

## Generate One Theme

```powershell
.\scripts\New-ThemeWithPalette.ps1 -PaletteName "tokyo_night" -UpdateAccentColor
```

## Generate ALL Themes

```powershell
.\scripts\Generate-AllThemes.ps1 -UpdateAccentColor -Force
.\scripts\Generate-ExperimentalDividers.ps1 -Force
```

The six root files are the complete Original themes. Generation writes 37 palette-only `extends` overlays per family folder and never creates `*.Original.json` there.

## Generate Standalone Helper Variants

```powershell
.\scripts\Make-ExtendedVariant.ps1
.\scripts\Make-ColorCycleVariant.ps1
.\scripts\Make-ColorCycleVariant.ps1 -Source .\OhMyPosh-Atomic-Custom-ExperimentalDividers.json
```

Extended and ColorCycle are rebuilt from their canonical root source. Variant-specific data lives under `scripts/variants/`.

## Generate Preview Images & Update README

```powershell
.\scripts\Generate-ThemePreviews.ps1 -Force
```

## Test a Theme (Temporary)

```powershell
oh-my-posh init pwsh --config '.\atomic\OhMyPosh-Atomic-Custom.TokyoNight.json' | Invoke-Expression
```

## Available Palettes

- `original` - Vibrant tech (cyan)
- `nord_frost` - Cool Arctic blues
- `gruvbox_dark` - Warm earth tones
- `dracula_night` - Bold purple/pink
- `tokyo_night` - Neon blues
- `monokai_pro` - Classic neon
- `solarized_dark` - Eye-friendly
- `catppuccin_mocha` - Soft pastels
- `forest_ember` - Deep greens

## Common Options

- `-UpdateAccentColor` - Add a palette-specific `accent_color` override
- `-BaseUrl ''` - Generate overlays with relative local `extends` paths instead of the raw GitHub base URL
- `-Force` - Overwrite existing files
- `-OutputName "CustomName"` - Custom output name
- `-SourceTheme "path.json"` - Different source

## Files

- `scripts/New-ThemeWithPalette.ps1` - Single theme generator
- `scripts/Generate-AllThemes.ps1` - Batch generator
- `scripts/Make-ExtendedVariant.ps1` - ExperimentalDividers Extended generator
- `scripts/Make-ColorCycleVariant.ps1` - Atomic/ExperimentalDividers ColorCycle generator
- `scripts/Generate-ThemePreviews.ps1` - Preview image generator
- `color-palette-alternatives.json` - Palette library
- `THEME-GENERATOR-README.md` - Full documentation
- `COLOR-PALETTES-GUIDE.md` - Visual palette guide
