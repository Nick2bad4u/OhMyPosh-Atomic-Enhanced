# 🎨 Quick Reference - Theme Generator

## Generate One Theme

```powershell
.\scripts\New-ThemeWithPalette.ps1 -PaletteName "tokyo_night" -UpdateAccentColor
```

## Generate ALL Themes

```powershell
.\scripts\Generate-AllThemes.ps1 -UpdateAccentColor -Force
```

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

- `-UpdateAccentColor` - Update root accent color
- `-Force` - Overwrite existing files
- `-OutputName "CustomName"` - Custom output name
- `-SourceTheme "path.json"` - Different source

## Files

- `scripts/New-ThemeWithPalette.ps1` - Single theme generator
- `scripts/Generate-AllThemes.ps1` - Batch generator
- `scripts/Generate-ThemePreviews.ps1` - Preview image generator
- `color-palette-alternatives.json` - Palette library
- `THEME-GENERATOR-README.md` - Full documentation
- `COLOR-PALETTES-GUIDE.md` - Visual palette guide
