# Oh My Posh Theme Palette Generator Scripts

Powerful PowerShell scripts to quickly generate Oh My Posh theme variants with different color palettes.

## 📁 Files

- **`New-ThemeWithPalette.ps1`** - Generate a single theme with a specific palette
- **`Generate-AllThemes.ps1`** - Batch generate themes for all available palettes
- **`color-palette-alternatives.json`** - Collection of themed color palettes
- **`COLOR-PALETTES-GUIDE.md`** - Visual guide to all available palettes

## 🚀 Quick Start

### Generate a Single Theme

```powershell
# Generate Tokyo Night theme
.\New-ThemeWithPalette.ps1 -PaletteName "tokyo_night" -OutputName "TokyoNight" -UpdateAccentColor

# Generate Nord Frost theme
.\New-ThemeWithPalette.ps1 -PaletteName "nord_frost" -UpdateAccentColor

# Generate with custom palette object
$myPalette = @{
    accent = "#ff0000"
    blue_primary = "#0000ff"
    # ... more colors
}
.\New-ThemeWithPalette.ps1 -PaletteObject $myPalette -OutputName "CustomTheme"
```

### Generate ALL Themes at Once

```powershell
# Generate all themes with updated accent colors
.\Generate-AllThemes.ps1 -UpdateAccentColor

# Force overwrite existing files
.\Generate-AllThemes.ps1 -UpdateAccentColor -Force

# Exclude specific palettes
.\Generate-AllThemes.ps1 -ExcludePalettes @("original", "test_palette")
```

## 📋 Script Parameters

### New-ThemeWithPalette.ps1

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `-SourceTheme` | String | Source theme JSON file | `OhMyPosh-Atomic-Custom.json` |
| `-PaletteName` | String | Palette name from JSON file | (Required) |
| `-PaletteObject` | Object | Custom palette hashtable | (Alternative to PaletteName) |
| `-OutputName` | String | Name suffix for output file | Auto-generated from palette name |
| `-OutputPath` | String | Full output file path | Auto-generated |
| `-PalettesFile` | String | JSON file with palettes | `color-palette-alternatives.json` |
| `-UpdateAccentColor` | Switch | Update root accent_color | `$false` |

### Generate-AllThemes.ps1

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `-SourceTheme` | String | Source theme JSON file | `OhMyPosh-Atomic-Custom.json` |
| `-PalettesFile` | String | JSON file with palettes | `color-palette-alternatives.json` |
| `-OutputDirectory` | String | Output directory for themes | Same as source |
| `-UpdateAccentColor` | Switch | Update root accent_color | `$false` |
| `-ExcludePalettes` | String[] | Palettes to skip | `@()` |
| `-Force` | Switch | Overwrite existing files | `$false` |

## 🎨 Available Palettes

The `color-palette-alternatives.json` file includes these beautiful palettes:

1. **original** - Your current vibrant tech theme
2. **nord_frost** - Arctic-inspired cool tones
3. **gruvbox_dark** - Warm retro earth tones
4. **dracula_night** - Dark with vibrant purple/pink
5. **tokyo_night** - Modern neon blues and purples
6. **monokai_pro** - Classic Monokai neon colors
7. **solarized_dark** - Scientific eye-strain reduction
8. **catppuccin_mocha** - Soothing pastel colors
9. **forest_ember** - Deep greens with amber accents

See `COLOR-PALETTES-GUIDE.md` for visual previews and detailed descriptions.

## 📝 Examples

### Example 1: Generate One Theme

```powershell
# Generate a Dracula-themed variant
.\New-ThemeWithPalette.ps1 -PaletteName "dracula_night" -UpdateAccentColor

# Output: OhMyPosh-Atomic-Custom.DraculaNight.json
```

### Example 2: Generate All Themes

```powershell
# Generate complete collection
.\Generate-AllThemes.ps1 -UpdateAccentColor -Force

# Creates:
# - OhMyPosh-Atomic-Custom.Original.json
# - OhMyPosh-Atomic-Custom.NordFrost.json
# - OhMyPosh-Atomic-Custom.GruvboxDark.json
# - OhMyPosh-Atomic-Custom.DraculaNight.json
# - OhMyPosh-Atomic-Custom.TokyoNight.json
# - OhMyPosh-Atomic-Custom.MonokaiPro.json
# - OhMyPosh-Atomic-Custom.SolarizedDark.json
# - OhMyPosh-Atomic-Custom.CatppuccinMocha.json
# - OhMyPosh-Atomic-Custom.ForestEmber.json
```

### Example 3: Custom Source and Output

```powershell
# Use different source theme
.\New-ThemeWithPalette.ps1 `
    -SourceTheme "MyCustomTheme.json" `
    -PaletteName "tokyo_night" `
    -OutputPath "C:\Themes\Tokyo.json" `
    -UpdateAccentColor
```

### Example 4: Create Custom Palette

```powershell
# Define your own colors
$oceanPalette = @{
    accent = "#00bcd4"
    blue_primary = "#2196f3"
    blue_time = "#03a9f4"
    green_success = "#4caf50"
    red_alert = "#f44336"
    # ... (include all 67 color keys)
}

# Generate theme with custom palette
.\New-ThemeWithPalette.ps1 `
    -PaletteObject $oceanPalette `
    -OutputName "Ocean" `
    -UpdateAccentColor
```

## 🔧 Using Your New Themes

### Test a Theme (Temporary)

```powershell
# Test Tokyo Night theme in current session
oh-my-posh init pwsh --config '.\OhMyPosh-Atomic-Custom.TokyoNight.json' | Invoke-Expression
```

### Set Permanently

Add to your PowerShell profile (`$PROFILE`):

```powershell
# Add this line to your profile
oh-my-posh init pwsh --config 'C:\Path\To\OhMyPosh-Atomic-Custom.TokyoNight.json' | Invoke-Expression
```

Edit your profile:
```powershell
notepad $PROFILE
```

### Switch Themes with a Function

Add to your profile for easy theme switching:

```powershell
function Set-OhMyPoshTheme {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Original','NordFrost','GruvboxDark','DraculaNight','TokyoNight','MonokaiPro','SolarizedDark','CatppuccinMocha','ForestEmber')]
        [string]$Theme
    )

    $themePath = "C:\Path\To\Themes\OhMyPosh-Atomic-Custom.$Theme.json"
    oh-my-posh init pwsh --config $themePath | Invoke-Expression
}

# Usage:
# Set-OhMyPoshTheme -Theme TokyoNight
# Set-OhMyPoshTheme -Theme NordFrost
```

## 🎯 Adding New Palettes

To add your own palette to the collection:

1. Open `color-palette-alternatives.json`
2. Add a new entry under `"palettes"`:

```json
{
  "palettes": {
    "my_custom": {
      "name": "My Custom Theme",
      "description": "A unique theme with custom colors",
      "palette": {
        "accent": "#your-color",
        "axios_yellow": "#your-color",
        "black": "#your-color",
        // ... all 67 color keys
      }
    }
  }
}
```

3. Generate the theme:
```powershell
.\New-ThemeWithPalette.ps1 -PaletteName "my_custom" -UpdateAccentColor
```

## 📊 Palette Color Keys

Your theme requires these 67 color keys (all must be defined):

```
accent, axios_yellow, black, blue_primary, blue_time, blue_tooltip,
chart_teal, cyan_renamed, electron_red, eslint_purple, gray_os,
gray_os_fg, gray_path_fg, gray_prompt_count_bg, gray_prompt_count_fg,
gray_untracked, green_added, green_ahead, green_charging, green_full,
green_help, green_success, green_valid_line, ipify_purple,
ipify_purple_v6, java_blue, java_orange, magenta_copied, maroon_error,
navy_text, node_green, npm_yellow, npm_dark, orange, orange_battery,
orange_unmerged, pink_error_line, pink_status_fail, pink_storybook,
pink_weather, playwright_teal, prettier_yellow, prettier_black,
purple_ahead, purple_exec, purple_session, python_blue, python_yellow,
react_cyan, red_alert, red_deleted, tailwind_cyan, teal_sysinfo,
typescript_blue, typescript_eslint_pink, vite_yellow, vitest_green,
violet_project, white, windows_blue, yellow_bright, yellow_discharging,
yellow_git_changed, yellow_modified, yellow_root_alt, yellow_update,
zustand_purple
```

## 🛠️ Troubleshooting

### "Source theme file not found"
- Ensure you're in the correct directory
- Or provide full path: `-SourceTheme "C:\Full\Path\To\Theme.json"`

### "Palette not found"
- Check spelling (use underscores: `tokyo_night` not `tokyo-night`)
- Run `Get-Content color-palette-alternatives.json | ConvertFrom-Json | Select-Object -ExpandProperty palettes | Get-Member -MemberType NoteProperty` to list available palettes

### "Failed to parse JSON"
- Verify your JSON syntax
- Use a JSON validator like https://jsonlint.com/

### Colors don't look right in terminal
- Ensure your terminal supports true color (24-bit)
- Try different terminal opacity settings
- Some colors look different in light vs dark environments

## 💡 Tips

- **Test before committing**: Try themes temporarily before setting permanently
- **Time of day matters**: Colors look different in daylight vs artificial light
- **Terminal opacity**: Transparent backgrounds affect color perception
- **Multiple variants**: Keep 2-3 favorites for different moods/times
- **Backup originals**: Keep your original theme file safe

## 📚 Related Files

- `OhMyPosh-Atomic-Custom.json` - Your base theme
- `color-palette-alternatives.json` - Palette definitions
- `COLOR-PALETTES-GUIDE.md` - Visual palette guide
- Generated themes: `OhMyPosh-Atomic-Custom.*.json`

## 🤝 Contributing

To add new palettes to the collection:

1. Design your palette with all 67 colors
2. Add to `color-palette-alternatives.json`
3. Run `.\Generate-AllThemes.ps1 -Force` to regenerate all themes
4. Share your palette with the community!

## 📄 License

MIT License - Feel free to use, modify, and share!

---

**Made with 💙 by GitHub Copilot**

Happy theming! 🎨✨
