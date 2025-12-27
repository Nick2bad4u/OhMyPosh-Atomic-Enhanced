# 🎨 Color Theory & Palette Design Guide

## Table of Contents

1. [Color Theory Fundamentals](#color-theory-fundamentals)
2. [Color Models & Spaces](#color-models--spaces)
3. [Palette Design Principles](#palette-design-principles)
4. [Accessibility & Contrast](#accessibility--contrast)
5. [Psychological Color Effects](#psychological-color-effects)
6. [Analyzing Atomic Enhanced Palettes](#analyzing-atomic-enhanced-palettes)
7. [Creating Custom Palettes](#creating-custom-palettes)
8. [Testing & Validation](#testing--validation)
9. [Common Palette Mistakes](#common-palette-mistakes)

---

## Color Theory Fundamentals

### The Color Wheel

The traditional color wheel organizes colors by hue relationships:

```
        Yellow
           |
    Yellow-Green - Green - Green-Cyan
           |                  |
           |    COOL COLORS  |
    Orange - - - - - - - - Cyan
           |    WARM COLORS |
           |                  |
    Red-Orange - Red - Red-Magenta
           |
        Magenta
```

### Primary Color Relationships

| Relationship | Definition | Example |
| --- | --- | --- |
| **Complementary** | Opposite colors on wheel | Red ↔ Cyan |
| **Analogous** | Adjacent colors (30-60°) | Red, Red-Orange, Orange |
| **Triadic** | Three equally spaced colors | Red, Green, Blue |
| **Tetradic (Square)** | Four equally spaced colors | Red, Yellow, Cyan, Blue |
| **Monochromatic** | Single hue, varied brightness | Navy, Blue, Light Blue |

### Hue, Saturation, Value (HSV)

Every color can be described using three dimensions:

```
Hue (0-360°)
  ↓
  Red (0°) → Yellow (60°) → Green (120°) → Cyan (180°) → Blue (240°) → Magenta (300°)

Saturation (0-100%)
  ↓
  0% = Grayscale (no color) ────────── 100% = Pure color (intense)

Value/Brightness (0-100%)
  ↓
  0% = Black ────────────────────────── 100% = Brightest
```

### Example: Understanding a Color

Color: `#FF6B9D` (Pink)

Converting to HSV:

- **Hue**: ~330° (Red-Magenta region)
- **Saturation**: 80% (Fairly vivid)
- **Value**: 100% (Bright)

---

## Color Models & Spaces

### RGB (Red, Green, Blue)

The standard for digital displays. Each channel: 0-255 or 0-100%.

```
RGB(255, 0, 0)    = Pure Red
RGB(0, 255, 0)    = Pure Green
RGB(0, 0, 255)    = Pure Blue
RGB(255, 255, 0)  = Yellow (Red + Green)
RGB(0, 255, 255)  = Cyan (Green + Blue)
RGB(255, 0, 255)  = Magenta (Red + Blue)
```

### Hex Color Notation

Hexadecimal representation of RGB values:

```
#RRGGBB

#FF0000 = Red (255, 0, 0)
#00FF00 = Green (0, 255, 0)
#0000FF = Blue (0, 0, 255)
#FFFFFF = White (255, 255, 255)
#000000 = Black (0, 0, 0)
```

### HSL (Hue, Saturation, Lightness)

More intuitive for designers than RGB:

```
HSL(0°, 100%, 50%)    = Red
HSL(120°, 100%, 50%)  = Green
HSL(240°, 100%, 50%)  = Blue
HSL(0°, 0%, 50%)      = Gray (no saturation)
HSL(0°, 100%, 100%)   = White (full lightness)
HSL(0°, 100%, 0%)     = Black (no lightness)
```

### Conversion Guide

```
RGB to Hex:
  #RRGGBB where RR, GG, BB are hex values (00-FF)

RGB to HSL:
  H = hue angle (0-360°)
  S = saturation (0-100%)
  L = lightness (0-100%)

Example: RGB(255, 100, 50) → HSL(15°, 100%, 60%)
```

---

## Palette Design Principles

### 1. Establish Primary Accent

Choose a dominant color that defines the theme's character:

**Atomic Enhanced Examples:**

- **Original**: Cyan (`#00bcd4`) - Tech/modern
- **Nord Frost**: Light Blue (`#88C0D0`) - Cool/calm
- **Tokyo Night**: Purple-Blue (`#7aa2f7`) - Modern/trendy
- **Dracula**: Purple (`#bd93f9`) - Bold/artistic

### 2. Create Supporting Colors

Build around your primary accent:

```
Primary: #00bcd4 (Cyan)
  ├── Complementary: #D4A300 (Orange-Gold)
  ├── Analogous Left: #009BCD (Blue-Cyan)
  ├── Analogous Right: #00D4B4 (Cyan-Green)
  └── Split-Complementary: #D46400, #FF00B4
```

### 3. Develop a Base/Background

Choose a base that provides contrast for all foreground colors:

**Considerations:**

- Dark mode: Grays from #0A0A0A to #3A3A3A
- Light mode: Grays from #F5F5F5 to #E8E8E8
- High contrast recommended for accessibility

### 4. Create Status Colors

Semantic colors for common states:

| State | Typical Color | Alternative |
| --- | --- | --- |
| Success | Green (`#00C853`) | Lime (`#76FF03`) |
| Error | Red (`#FF0000`) | Orange-Red (`#FF3D00`) |
| Warning | Yellow (`#FFD600`) | Orange (`#FF9100`) |
| Info | Blue (`#2196F3`) | Cyan (`#00E5FF`) |
| Neutral | Gray (`#757575`) | Taupe (`#795548`) |

### 5. Ensure Visual Harmony

All colors should feel intentional together:

```
Good Harmony:
  Primary: #FF6B9D (Pink)
  Secondary: #6BCB77 (Green)
  Accent: #4D96FF (Blue)
  Background: #2D2D44 (Dark Gray-Blue)
  ✓ Colors relate to each other harmoniously

Bad Harmony:
  Colors scattered randomly with no relationship
  ✗ Looks chaotic and unprofessional
```

---

## Accessibility & Contrast

### WCAG Contrast Ratios

Web Content Accessibility Guidelines define minimum contrast:

| Level | Ratio | Use Case |
| --- | --- | --- |
| **AA** | 4.5:1 | Normal text (minimum standard) |
| **AAA** | 7:1 | Enhanced accessibility |
| **Large Text** | 3:1 | Larger text can use lower ratio |

### Calculating Contrast Ratio

```
Contrast Ratio = (Lighter Luminance + 0.05) / (Darker Luminance + 0.05)

Where Luminance is calculated as:
  L = 0.2126 * R + 0.7152 * G + 0.0722 * B
  (RGB values normalized 0-1)
```

### Testing Tools

- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Contrast Ratio](https://contrast-ratio.com/)
- Browser DevTools: Color picker with contrast indicator

### Examples: Testing Contrasts

```
✅ GOOD: White text (#FFFFFF) on dark blue (#001A4D)
  Contrast: 18:1 (Excellent)

✅ GOOD: Black text (#000000) on light yellow (#FFFF99)
  Contrast: 10:1 (Excellent)

⚠️ CAUTION: Light gray (#CCCCCC) on white (#FFFFFF)
  Contrast: 1.15:1 (Too low for text)

❌ BAD: Red (#FF0000) on dark red (#990000)
  Contrast: 2.1:1 (Too low, poor distinction)
```

### Atomic Enhanced Contrast Analysis

**Original Theme Analysis:**

| Foreground | Background | Contrast | Level |
| --- | --- | --- | --- |
| White | Blue Primary | 10:1+ | ✅ AAA |
| Black | Yellow | 19:1 | ✅ AAA |
| Light Gray | Dark Gray | 4.5:1 | ✅ AA |
| Green | Dark Gray | 8:1 | ✅ AAA |
| Red | Dark Gray | 5:1 | ✅ AA |

---

## Psychological Color Effects

Colors evoke emotional responses and associations:

### Red

- **Emotion**: Energy, urgency, passion
- **Association**: Alert, warning, stop
- **Use Case**: Error states, important notifications
- **Note**: Use sparingly to maintain urgency

### Green

- **Emotion**: Success, growth, calm
- **Association**: Safe, go, complete
- **Use Case**: Success indicators, positive states
- **Note**: Universally positive

### Blue

- **Emotion**: Trust, calm, professional
- **Association**: Technology, water, sky
- **Use Case**: Primary interface elements
- **Note**: Safe choice for tech themes

### Yellow

- **Emotion**: Warning, optimism, energy
- **Association**: Caution, happiness
- **Use Case**: Warnings, accents
- **Note**: High saturation can be fatiguing

### Purple

- **Emotion**: Creativity, luxury, mystery
- **Association**: Imagination, elegance
- **Use Case**: Artistic themes, secondary accents
- **Note**: Modern and trendy

### Cyan

- **Emotion**: Modern, tech-forward, cool
- **Association**: Technology, future
- **Use Case**: Primary accent (Atomic's choice)
- **Note**: Professional and energetic

---

## Analyzing Atomic Enhanced Palettes

### Original Palette Structure

```json
{
 "palette": {
  "accent": "#00bcd4", // Primary cyan
  "blue_primary": "#0080FF", // Tech blue
  "green_success": "#00C853", // Success green
  "yellow_bright": "#FFD600", // Warning yellow
  "red_alert": "#FF0000", // Error red
  "white": "#FFFFFF", // Text (light)
  "black": "#000000", // Text (dark)
  "gray_dim": "#808080" // Subtle elements
 }
}
```

### Color Purpose Matrix

| Color | Primary Use | Secondary Use | Psychological Effect |
| --- | --- | --- | --- |
| Cyan (`#00bcd4`) | Dividers, accents | Path segment | Modern, tech-forward |
| Blue (`#0080FF`) | Git info, primary segments | Time display | Trustworthy, professional |
| Green (`#00C853`) | Status success | Environment | Positive, safe |
| Yellow (`#FFD600`) | Warnings, git branches | Status messages | Alert, attention |
| Red (`#FF0000`) | Error states | Status alerts | Urgent, stop |
| White/Gray | Text on dark | Readable | Clean, professional |

### Palette Balance Analysis

**Distribution:**

- 1 dominant accent (Cyan) - 40%
- 2 secondary colors (Blue, Yellow) - 30%
- 2 status colors (Green, Red) - 20%
- 2 neutral colors (White, Gray) - 10%

This distribution creates:

- ✅ Visual hierarchy
- ✅ Clear semantic meaning
- ✅ Balanced variety
- ✅ Professional appearance

---

## Creating Custom Palettes

### Step 1: Define Your Concept

```
Example: "Warm Sunset Theme"
- Primary accent: Orange-red
- Secondary: Deep purple
- Success: Warm gold
- Error: Deep red
- Background: Dark brown
```

### Step 2: Select Primary Accent

Start with your defining color:

```
Warm Sunset Accent: #FF6B35 (Orange-Red)
  - Hue: 15°
  - Saturation: 100%
  - Value: 100%
```

### Step 3: Generate Complementary Colors

Use color theory:

```
Primary: #FF6B35 (Hue 15°)

Complementary (opposite):
  Hue: 15° + 180° = 195°
  Result: #35BDFF (Cyan-Blue)

Analogous (±30°):
  Left: 15° - 30° = -15° (345°)  → #FF3535 (Red)
  Right: 15° + 30° = 45°         → #FF9535 (Orange)
```

### Step 4: Create Extended Palette

```json
{
 "palette": {
  "accent": "#FF6B35", // Primary
  "accent_secondary": "#FF9535", // Analogous right
  "accent_complement": "#35BDFF", // Complementary

  "blue_primary": "#6B7FFF", // Secondary
  "green_success": "#FFD700", // Warm gold
  "yellow_bright": "#FFA500", // Orange
  "red_alert": "#CC0000", // Deep red

  "white": "#F5F5F5", // Light text
  "black": "#1A1A1A", // Dark text
  "background": "#3D2817" // Dark brown
 }
}
```

### Step 5: Validate & Test

```powershell
# Test contrast ratios
# Test in theme
# Test across multiple terminals
# Get feedback
```

---

## Testing & Validation

### Contrast Testing Script

```powershell
function Test-ColorContrast {
    param(
        [string]$ForegroundHex,
        [string]$BackgroundHex
    )

    # Convert hex to RGB
    $fg_r = [int]::Parse($ForegroundHex.Substring(1,2), "HexNumber")
    $fg_g = [int]::Parse($ForegroundHex.Substring(3,2), "HexNumber")
    $fg_b = [int]::Parse($ForegroundHex.Substring(5,2), "HexNumber")

    $bg_r = [int]::Parse($BackgroundHex.Substring(1,2), "HexNumber")
    $bg_g = [int]::Parse($BackgroundHex.Substring(3,2), "HexNumber")
    $bg_b = [int]::Parse($BackgroundHex.Substring(5,2), "HexNumber")

    # Calculate relative luminance
    $fgLum = 0.2126 * ($fg_r/255) + 0.7152 * ($fg_g/255) + 0.0722 * ($fg_b/255)
    $bgLum = 0.2126 * ($bg_r/255) + 0.7152 * ($bg_g/255) + 0.0722 * ($bg_b/255)

    # Calculate contrast ratio
    $lighter = [Math]::Max($fgLum, $bgLum)
    $darker = [Math]::Min($fgLum, $bgLum)
    $contrast = ($lighter + 0.05) / ($darker + 0.05)

    # Determine compliance
    $aa = $contrast -ge 4.5
    $aaa = $contrast -ge 7

    return @{
        Contrast = [Math]::Round($contrast, 2)
        AA = $aa
        AAA = $aaa
    }
}

# Example usage
$test = Test-ColorContrast -ForegroundHex "#FFFFFF" -BackgroundHex "#000000"
Write-Host "Contrast: $($test.Contrast):1"
Write-Host "AA Level: $($test.AA)"
Write-Host "AAA Level: $($test.AAA)"
```

### Visual Testing Checklist

- [ ] All text colors readable on their backgrounds
- [ ] Icon colors distinguishable from text
- [ ] Segment separators visible
- [ ] Status colors clearly differentiated
- [ ] No color ambiguity between states
- [ ] Comfortable to view for extended periods
- [ ] Colors consistent across different terminals
- [ ] Theme works for color-blind users (test with simulator)

### Color Blindness Testing

Use tools like:

- [Color Oracle](https://colororacle.org/) - Desktop simulator
- [Coblis](https://www.color-blindness.com/coblis-color-blindness-simulator/) - Online
- [Accessible Colors](https://accessible-colors.com/) - Web checker

Test for:

- Protanopia (Red-blind)
- Deuteranopia (Green-blind)
- Tritanopia (Blue-blind)
- Monochromacy (Complete color blindness)

---

## Common Palette Mistakes

### ❌ Mistake 1: Too Many Colors

**Problem:** Overwhelming visual noise, no clear hierarchy

**Good:**

```
Palette: 8-12 colors (manageable)
  - 1 dominant accent
  - 2-3 secondary colors
  - 2-3 status colors
  - 2-3 neutral colors
```

**Bad:**

```
Palette: 50+ colors (chaotic)
  - Each segment a different color
  - No visual coherence
  - Difficult to parse
```

### ❌ Mistake 2: Insufficient Contrast

**Problem:** Text unreadable, accessibility issues

**Good:**

```
✅ Light text on dark background: #FFFFFF on #000000 (contrast: 21:1)
✅ High saturation text on low saturation background
```

**Bad:**

```
❌ Light gray text on light background: #CCCCCC on #FFFFFF (contrast: 1.15:1)
❌ Low saturation colors on similar background
```

### ❌ Mistake 3: Inconsistent Semantics

**Problem:** Colors don't match expected meanings

**Good:**

```
✅ Green = Success/OK
✅ Red = Error/Alert
✅ Yellow = Warning
✅ Blue = Info/Neutral
```

**Bad:**

```
❌ Red = Success (confusing)
❌ Green = Error (misleading)
❌ Colors don't follow conventions
```

### ❌ Mistake 4: Clashing Colors

**Problem:** Colors feel uncomfortable together

**Good:**

```
✅ Harmonious palette: Colors related through color theory
✅ Similar saturation levels
✅ Balanced value distribution
```

**Bad:**

```
❌ Random colors: No relationship
❌ Mixed saturation: Some dull, some vivid
❌ Poor value balance: Too much dark or too much light
```

### ❌ Mistake 5: Ignoring Terminal Limitations

**Problem:** Colors look different on different terminals

**Good:**

```
✅ Use standard web colors
✅ Test on multiple terminal emulators
✅ Provide fallback colors
```

**Bad:**

```
❌ Rely on specific terminal's color palette
❌ Don't test before publishing
❌ Assume all terminals render RGB the same
```

---

## Palette Comparison: Atomic Variants

### Warm Palettes

- **Gruvbox**: Earth tones, retro feel
- **Forest Ember**: Deep greens, warm accents
- **Amber Sunset**: Orange/gold, warm transition

### Cool Palettes

- **Nord Frost**: Arctic blues, professional
- **Tokyo Night**: Modern blues, neon accents
- **Dracula Night**: Purple/pink, bold

### Neutral Palettes

- **Original**: Balanced cyan/blue mix
- **Monokai Pro**: Classic, tried-and-tested
- **Solarized Dark**: Scientific, optimized for eyes

---

## Summary: Palette Design Principles

1. ✅ **Start with a concept** - Define theme's personality
2. ✅ **Choose a primary accent** - 40% of color identity
3. ✅ **Add supporting colors** - 30% secondary/tertiary
4. ✅ **Include status colors** - 20% semantic meaning
5. ✅ **Maintain neutrals** - 10% readability
6. ✅ **Ensure contrast** - WCAG AA minimum (4.5:1)
7. ✅ **Test extensively** - Multiple terminals, color blindness
8. ✅ **Document reasoning** - Why each color was chosen

---

## Resources

- [Adobe Color Wheel](https://color.adobe.com/)
- [Color Psychology](https://en.wikipedia.org/wiki/Color_psychology)
- [WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [HSL/HSV Visualization](https://www.rapidtables.com/web/color/hsl.html)
- [Color Blindness Simulator](https://colororacle.org/)

For more information on the Atomic Enhanced palettes, see [COLOR-PALETTES-GUIDE.md](./COLOR-PALETTES-GUIDE.md).
