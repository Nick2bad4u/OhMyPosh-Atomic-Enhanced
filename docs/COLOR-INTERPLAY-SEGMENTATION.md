# 🎨 Color Interplay & Segment Interaction Guide

## Table of Contents

1. [Color Interplay Fundamentals](#color-interplay-fundamentals)
2. [Segment-to-Segment Color Relationships](#segment-to-segment-color-relationships)
3. [Contrast in Multi-Segment Layouts](#contrast-in-multi-segment-layouts)
4. [Color Transitions Between Segments](#color-transitions-between-segments)
5. [Foreground-Background Interactions](#foreground-background-interactions)
6. [Visual Hierarchy Through Color](#visual-hierarchy-through-color)
7. [Analyzing Atomic Enhanced Color Interplay](#analyzing-atomic-enhanced-color-interplay)
8. [Creating Harmonious Multi-Segment Themes](#creating-harmonious-multi-segment-themes)
9. [Advanced Color Blending Techniques](#advanced-color-blending-techniques)
10. [Common Interplay Mistakes](#common-interplay-mistakes)

---

## Color Interplay Fundamentals

Color interplay refers to how multiple colors in a prompt interact visually, influencing readability, hierarchy, and aesthetic appeal.

### The Three Layers of Interplay

```
Layer 1: Segment Internal (foreground on background of ONE segment)
  Example: Green text (#00C853) on Dark Blue background (#001A33)

Layer 2: Segment-to-Segment (color transitions between adjacent segments)
  Example: [Green segment] → [Purple segment] → [Orange segment]

Layer 3: Prompt-to-Shell (entire prompt against terminal background)
  Example: Multi-colored prompt on dark terminal background
```

### Key Principles

1. **Continuity**: Colors flow smoothly without harsh breaks
2. **Contrast**: Sufficient distinction to parse information
3. **Hierarchy**: Important info stands out more than supporting info
4. **Harmony**: All colors feel intentional together
5. **Consistency**: Related information uses related colors

---

## Segment-to-Segment Color Relationships

### Adjacent Color Theory

When segments appear side-by-side, their colors influence each other.

#### Type 1: Complementary Transitions

Segments with opposite hues (180° apart):

```
[Blue segment: #2196F3]  [Orange segment: #FF9100]
     ↑                            ↑
  Hue: 210°                   Hue: 30° (opposite)

Visual effect: High contrast, energetic, can be jarring
Use when: Drawing attention to important transitions
```

**Atomic Enhanced Example:**

- Git branch (blue) → Status (orange/red) = Attention-grabbing
- Good for error states

#### Type 2: Analogous Transitions

Segments with adjacent hues (30-60° apart):

```
[Green segment: #4CAF50]  [Cyan segment: #00BCD4]
      ↑                           ↑
   Hue: 135°                  Hue: 180° (adjacent)

Visual effect: Smooth, professional, cohesive
Use when: Related information or default state
```

**Atomic Enhanced Example:**

- Path (orange) → Git (yellow-gold) = Natural flow
- Good for most prompts

#### Type 3: Monochromatic Transitions

Segments using different values of same hue:

```
[Dark blue: #001A4D]  [Light blue: #87CEEB]
      ↑                      ↑
   HSL(240°,100%,15%)    HSL(240°,100%,80%)

Visual effect: Unified, professional, minimal
Use when: Creating elegant, cohesive themes
```

**Atomic Enhanced Example:**

- All blues with varying brightness
- Creates a "blue theme" feel

### The 60-30-10 Rule for Multi-Segment Prompts

Adapted from interior design:

```
60% = Dominant color (usually one type across multiple segments)
      Example: Neutral grays, dark backgrounds

30% = Secondary color (accent, appears in 1-2 segments)
      Example: Primary accent color (cyan in Atomic)

10% = Highlight color (draws attention to single critical segment)
      Example: Red for errors, green for success
```

**Practical Application:**

```json
{
 "palette": {
  "neutral": "#505050", // 60% - background/base
  "accent": "#00BCD4", // 30% - primary cyan
  "success": "#00C853", // 10% - success state
  "error": "#FF0000" // 10% - error state
 }
}
```

---

## Contrast in Multi-Segment Layouts

### Segment Chain Contrast

When segments flow horizontally, maintain contrast:

```
BAD - Low contrast between segments:
┌─────────────┐┌──────────────┐┌──────────────┐
│ #FF5733 on  ││ #FF6B35 on   ││ #FF7F39 on   │
│ #1A1A1A     ││ #1A1A1A      ││ #1A1A1A      │
└─────────────┘└──────────────┘└──────────────┘
Similar colors blur together - hard to see divisions

GOOD - High contrast between segments:
┌──────────────┐┌──────────────┐┌──────────────┐
│ #FF5733 on   ││ #00BCD4 on   ││ #FFD600 on   │
│ #1A1A1A      ││ #1A1A1A      ││ #1A1A1A      │
└──────────────┘└──────────────┘└──────────────┘
Different hues are clearly distinct
```

### Contrast Matrix

Calculate contrast ratios between adjacent segments:

```
Segment A (Foreground) | Segment B (Foreground) | Contrast Ratio | Assessment
─────────────────────────────────────────────────────────────────────────────
#FFFFFF (white)        | #000000 (black)        | 21:1           | ✅ Perfect
#00C853 (green)        | #FF5733 (orange)       | 8:1            | ✅ Excellent
#2196F3 (blue)         | #FFD600 (yellow)       | 10:1           | ✅ Excellent
#808080 (gray)         | #909090 (gray)         | 1.2:1          | ❌ Too low
```

### The "Readability Circle"

For each segment, adjacent segments should be outside the circle:

```
        Red Zone (< 3:1) - Hard to read
            ┌─────────────┐
            │   Segment   │
            │   Core      │
            │   Color     │  ← Maintain 3:1 minimum
            │  #2196F3    │     contrast with neighbors
            │             │
            └─────────────┘

        Green Zone (> 3:1) - Clear & readable
            All adjacent colors here
```

---

## Color Transitions Between Segments

### Transition Types

#### Type 1: Powerline Transitions

Using directional symbols to bridge colors:

```
[Blue: #2196F3] → [Orange: #FF9100]
                 ↑
         Transition symbol

The symbol:
- Often colored same as first segment
- Creates visual flow
- Guides eye to next segment
```

**Implementation:**

```json
{
 "leading_diamond": "",
 "style": "powerline",
 "trailing_diamond": ""
}
```

#### Type 2: Diamond Transitions

Using enclosed symbols for visual separation:

```
[Blue: #2196F3] ◊ [Orange: #FF9100]
                ↑
        Divider segment
        Colored to blend both
```

**Implementation:**

```json
{
 "leading_diamond": "◊",
 "style": "diamond",
 "trailing_diamond": "◊"
}
```

#### Type 3: Gradient Transitions

Using intermediate colors to bridge far hues:

```
[Blue #2196F3] → [Purple #9C27B0] → [Orange #FF9100]
      ↓              ↓                    ↓
   Hue 210°      Hue 270°             Hue 30°

60° steps = smoother transition than direct jump
```

**Palette Strategy:**

```json
{
 "palette": {
  "blue_primary": "#2196F3", // Hue 210°
  "blue_purple": "#7B68EE", // Hue 250° (bridge)
  "purple_accent": "#9C27B0", // Hue 270°
  "purple_orange": "#E67E22", // Hue 20° (bridge)
  "orange_accent": "#FF9100" // Hue 30°
 }
}
```

### Perceptual Transition Smoothness

```
Very Smooth (< 30° hue difference):
├─ Green → Cyan (45° difference) ✅ Excellent
├─ Blue → Purple (60° difference) ✅ Good
└─ Orange → Red (20° difference) ✅ Excellent

Moderate (30-90° hue difference):
├─ Cyan → Blue (90° difference) ⚠️ Acceptable
├─ Green → Yellow (60° difference) ⚠️ Acceptable
└─ Red → Orange (30° difference) ⚠️ Acceptable

Jarring (> 90° hue difference):
├─ Red → Cyan (180° difference) ❌ High energy
├─ Blue → Yellow (120° difference) ❌ Vibrant
└─ Green → Red (150° difference) ❌ Clashing
```

---

## Foreground-Background Interactions

### The Separation Principle

Foreground color must "pop" from background:

```
WCAG Minimum Contrast: 4.5:1 (AA standard)
WCAG Enhanced: 7:1 (AAA standard)

Calculation:
Contrast = (Lighter Luminance + 0.05) / (Darker Luminance + 0.05)

Example: White text on dark blue
─────────────────────────────────
Lighter (white): Luminance = 1.0
Darker (blue #001A4D): Luminance = 0.05
Contrast = (1.0 + 0.05) / (0.05 + 0.05) = 10.5:1 ✅ Excellent
```

### Common FG-BG Pairings in Atomic Enhanced

```
Segment Type    | FG Color   | BG Color      | Contrast | Rating
──────────────────────────────────────────────────────────────
Shell           | White      | Blue Primary  | 10:1     | ✅ AAA
Path            | Black      | Orange        | 8:1      | ✅ AAA
Git Success     | Black      | Green         | 10:1     | ✅ AAA
Git Modified    | Black      | Yellow        | 19:1     | ✅ AAA
Error Status    | White      | Red           | 5:1      | ✅ AA
```

### Dynamic FG-BG Selection

Automatically choose FG color based on BG brightness:

```powershell
# If background is dark, use light foreground
# If background is light, use dark foreground

function Get-OptimalForeground {
    param([string]$HexBG)

    # Calculate luminance
    $r = [int]::Parse($HexBG.Substring(1,2), "HexNumber")
    $g = [int]::Parse($HexBG.Substring(3,2), "HexNumber")
    $b = [int]::Parse($HexBG.Substring(5,2), "HexNumber")

    $luminance = 0.2126 * ($r/255) + 0.7152 * ($g/255) + 0.0722 * ($b/255)

    # Return light text for dark BG, dark text for light BG
    return if ($luminance -lt 0.5) { "#FFFFFF" } else { "#000000" }
}

# Usage
Get-OptimalForeground -HexBG "#2196F3"  # Returns #FFFFFF (light text)
Get-OptimalForeground -HexBG "#FFD600"  # Returns #000000 (dark text)
```

---

## Visual Hierarchy Through Color

### Hierarchy Levels

```
Level 1: Critical Information
├─ Most saturated colors
├─ Highest contrast
├─ Brightest values
└─ Example: Error states (red), git status (when changed)

Level 2: Primary Information
├─ Medium saturation
├─ Good contrast
├─ Readable brightness
└─ Example: File path, current branch

Level 3: Secondary Information
├─ Lower saturation
├─ Lower contrast
├─ Muted values
└─ Example: Status indicators, timestamps

Level 4: Background/Tertiary
├─ Minimal saturation
├─ Very low contrast
├─ Dark values
└─ Example: Terminal background, neutral areas
```

### Saturation-Based Hierarchy

```json
{
 "palette": {
  "critical": "#FF0000", // Hue 0°, Saturation 100% - Screams for attention
  "primary": "#00BCD4", // Hue 180°, Saturation 100% - Clear focus
  "secondary": "#4DB8DD", // Hue 180°, Saturation 60% - Supportive
  "tertiary": "#8FBDD9", // Hue 180°, Saturation 30% - Background
  "muted": "#B8D4E0" // Hue 180°, Saturation 15% - Barely visible
 }
}
```

### Value-Based Hierarchy (Brightness)

```
Critical:    Bright values (80-100%) = High attention
Primary:     Medium values (50-80%)  = Normal attention
Secondary:   Low values (30-50%)     = Low attention
Tertiary:    Very low (10-30%)       = Barely noticeable

Example with Blues:
─────────────────────
Navy (#001A4D):        10% brightness → Background
Dark Blue (#0057A5):   20% brightness → Secondary
Blue (#0080FF):        50% brightness → Primary
Light Blue (#87CEEB):  80% brightness → Critical/Highlight
```

---

## Analyzing Atomic Enhanced Color Interplay

### The Original Palette Flow

```
Shell          Path           Git            Status         Time
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ Blue     │  │ Orange   │  │ Yellow   │  │ Red/     │  │ Cyan     │
│ #0080FF  │  │ #FF6B35  │  │ #FFD600  │  │ Green    │  │ #00BCD4  │
└──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘
    ↓              ↓              ↓              ↓             ↓
Hue: 210°    Hue: 15°       Hue: 48°       Hue: 0°/120°   Hue: 180°
```

### Interplay Analysis

**Positive Aspects:**

- ✅ Blue → Orange = 195° difference (Striking but intentional)
- ✅ Orange → Yellow = 30° difference (Smooth, warm transition)
- ✅ Yellow → Red/Green = Semantic (clear status meaning)
- ✅ Cyan accent bridges back to cool tones

**Considerations:**

- ⚠️ Large hue jumps demand attention (good for distinct segments)
- ⚠️ Warm color concentration (orange-yellow-red area)
- ⚠️ Cyan appears isolated (provides cool balance)

### Distance Matrix

Hue distances between consecutive Atomic Enhanced segments:

```
Blue (210°) → Orange (15°) = 195° (or 165° the short way) = Large gap ✅
Orange (15°) → Yellow (48°) = 33° = Small gap ✅
Yellow (48°) → Red/Green (0°/120°) = Varies = Semantic
Green (120°) → Cyan (180°) = 60° = Medium gap ✅
Cyan (180°) → Blue (210°) = 30° = Small gap ✅
```

---

## Creating Harmonious Multi-Segment Themes

### Step 1: Choose Primary Accent

```
Decision: Cool vs Warm
├─ Cool (Blue, Cyan, Purple): Professional, calm
├─ Warm (Red, Orange, Yellow): Energetic, warm
└─ Mixed: Balanced, modern
```

### Step 2: Define Segment Colors

```
Shell:     Primary + Darkened
Path:      Accent color (often orange or tan)
Git:       Primary accent
Status:    Semantic (green/red) or gradient
Time:      Secondary accent
```

### Step 3: Calculate Hue Distances

```powershell
# Calculate hue distance
function Get-HueDistance {
    param([int]$Hue1, [int]$Hue2)

    $diff = [Math]::Abs($Hue1 - $Hue2)
    $distance = [Math]::Min($diff, 360 - $diff)

    return @{
        Difference = $diff
        ShortestPath = $distance
        Smoothness = if ($distance -lt 30) { "Very Smooth" }
                    elseif ($distance -lt 90) { "Smooth" }
                    elseif ($distance -lt 180) { "Moderate" }
                    else { "Contrasting" }
    }
}

Get-HueDistance -Hue1 210 -Hue2 15  # Blue to Orange
# Result: Difference=195, ShortestPath=165, Smoothness=Contrasting ✅
```

### Step 4: Build Palette with Relationships

```json
{
 "palette": {
  "primary": "#0080FF", // Hue 210° (blue)
  "primary_dim": "#004B99", // Same hue, 50% brightness
  "primary_light": "#87CEEB", // Same hue, 80% brightness

  "accent": "#FF6B35", // Hue 15° (orange) - 195° from primary
  "accent_muted": "#CC5219", // Same hue, darker
  "accent_light": "#FFB399", // Same hue, lighter

  "status_success": "#00C853", // Hue 120° (green) - semantic
  "status_error": "#FF0000", // Hue 0° (red) - semantic
  "status_warning": "#FFD600", // Hue 48° (yellow) - semantic

  "neutral_light": "#FFFFFF",
  "neutral_dark": "#1A1A1A"
 }
}
```

---

## Advanced Color Blending Techniques

### Technique 1: Saturation Blending

Gradually reduce saturation across segments for calming effect:

```
100% Saturation: #FF6B35 (Pure orange)
 ↓
 80% Saturation: #F27B4F
 ↓
 60% Saturation: #E98B69
 ↓
 40% Saturation: #DF9B83
 ↓
 20% Saturation: #D5AB9D
 ↓
  0% Saturation: #CCCCCC (Gray)

Visual effect: Progressive toning down from bright to muted
Use when: Creating elegant, professional gradients
```

### Technique 2: Value Blending (Brightness)

```
100% Value: #FF6B35 (Bright orange)
  ↓
 80% Value: #CC5629
  ↓
 60% Value: #99411D
  ↓
 40% Value: #662B11
  ↓
 20% Value: #330D06
  ↓
  0% Value: #000000 (Black)

Visual effect: Progressive darkening
Use when: Creating depth or subtle transitions
```

### Technique 3: Complementary Blending

Bridge complementary colors through intermediate hues:

```
Blue (#2196F3, Hue 210°)
  ↓ [Add 30°]
Cyan-Blue (#00CED1, Hue 181°)
  ↓ [Add 30°]
Cyan (#00FFFF, Hue 180°)
  ↓ [Add 30°]
Cyan-Green (#00FF7F, Hue 150°)
  ↓ [Add 30°]
Green (#00FF00, Hue 120°)
  ...
Orange (#FF9100, Hue 30°)

Result: Smooth rainbow transition from blue to orange
```

---

## Common Interplay Mistakes

### ❌ Mistake 1: Too Many Colors

**Problem:** Each segment different color with no relationship

```json
{
 "palette": {
  "segment1": "#FF0000", // Random
  "segment2": "#00FF00", // Random
  "segment3": "#0000FF", // Random
  "segment4": "#FFFF00", // Random
  "segment5": "#FF00FF" // Random
 }
}
```

**Effect:** Visual chaos, no harmony

**Fix:** Base all on single hue family or intentional relationships

```json
{
 "palette": {
  "primary": "#0080FF", // Hue 210° (base)
  "secondary": "#00BCD4", // Hue 180° (analogous)
  "accent": "#FFD600", // Hue 48° (complementary)
  "success": "#00C853", // Hue 120° (semantic)
  "error": "#FF0000" // Hue 0° (semantic)
 }
}
```

### ❌ Mistake 2: Insufficient Contrast Between Segments

**Problem:** Adjacent segments blur together

```
[#FF6B35 on #1A1A1A] [#FF7F39 on #1A1A1A] [#FF9939 on #1A1A1A]
  Orange-Red            Orange               Orange-Yellow

Similar hues → No clear division
```

**Fix:** Use complementary or significantly different hues

```
[#FF6B35 on #1A1A1A] [#00BCD4 on #1A1A1A] [#FFD600 on #1A1A1A]
  Orange               Cyan                  Yellow

Clear hue differences → Segments distinct
```

### ❌ Mistake 3: Foreground-Background Mismatch

**Problem:** Low contrast between text and background

```
#CCCCCC (light gray) text on #999999 (medium gray) background
Contrast: 1.5:1 ❌ Too low (need 4.5:1 minimum)
Result: Hard to read
```

**Fix:** Ensure WCAG AA minimum

```
#FFFFFF (white) text on #2196F3 (blue) background
Contrast: 10:1 ✅ Excellent
Result: Crystal clear
```

### ❌ Mistake 4: Clashing Color Psychology

**Problem:** Colors convey wrong emotional meaning

```
"error": "#00FF00"    // Green = usually means OK, not error!
"success": "#FF0000"  // Red = usually means error, not success!
```

**Fix:** Use semantic colors consistently

```
"success": "#00C853"  // Green = go, positive
"error": "#FF0000"    // Red = stop, negative
"warning": "#FFD600"  // Yellow = caution
```

### ❌ Mistake 5: Ignoring Terminal Background

**Problem:** Theme colors chosen without terminal background in mind

```
Theme designed with #1A1A1A (dark) background assumed
But user has #FFFFFF (light) terminal background
Result: Colors appear washed out, low contrast
```

**Fix:** Test on both dark and light backgrounds

```
"light_mode_bg": "#FFFFFF",
"dark_mode_bg": "#1A1A1A",

// Adjust colors for both:
"text_light": "#000000",  // For light backgrounds
"text_dark": "#FFFFFF"    // For dark backgrounds
```

---

## Quick Reference: Color Interplay Checklist

- [ ] Adjacent segments have > 3:1 luminance difference
- [ ] Foreground-background contrast ≥ 4.5:1 (WCAG AA)
- [ ] Hue distances between segments calculated and appropriate
- [ ] Color relationships intentional (not random)
- [ ] Saturation levels support visual hierarchy
- [ ] Brightness creates depth and focus
- [ ] Colors test well on terminal's background
- [ ] Semantic colors (red=error, green=success) used correctly
- [ ] Maximum 5-7 distinct hues in palette
- [ ] Transitions between segments smooth or intentionally striking

---

## Summary

Color interplay is about:

✅ **Relationships** - Colors relate to each other intentionally
✅ **Contrast** - Sufficient distinction between elements
✅ **Harmony** - All colors feel like they belong together
✅ **Hierarchy** - Important info stands out
✅ **Consistency** - Similar meanings use similar colors

For more details on individual colors, see [COLOR-THEORY-GUIDE.md](./COLOR-THEORY-GUIDE.md).
For palette creation guidance, see [CREATING-CUSTOM-PALETTES.md](#creating-custom-palettes) (if exists).
