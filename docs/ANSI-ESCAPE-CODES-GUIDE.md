<!-- {% raw %} -->
# 🎨 PowerShell ANSI Escape Codes & Terminal Color Guide

## Table of Contents

1. [Introduction](#introduction)
2. [What Are ANSI Escape Codes?](#what-are-ansi-escape-codes)
3. [Basic ANSI Color System](#basic-ansi-color-system)
4. [PowerShell Implementation](#powershell-implementation)
5. [Color Models in Depth](#color-models-in-depth)
6. [Advanced Techniques](#advanced-techniques)
7. [Common Pitfalls & Solutions](#common-pitfalls--solutions)
8. [Integration with Oh My Posh](#integration-with-oh-my-posh)
9. [Performance Considerations](#performance-considerations)

---

## Introduction

Terminal color output is fundamental to modern prompt theming engines like Oh My Posh. This guide explains how ANSI escape codes work in PowerShell, the different color models available, and how to leverage them for creating beautiful, responsive terminal prompts.

### Why This Matters

Understanding ANSI escape codes allows you to:

- Customize terminal appearance at a fundamental level
- Debug color rendering issues in your themes
- Create dynamic, responsive prompt segments
- Work effectively across different terminal emulators and platforms

---

## What Are ANSI Escape Codes?

ANSI escape codes are special character sequences that instruct terminal emulators to perform specific actions, most commonly changing text colors and styles.

### General Format

```
<ESC>[<parameters>m<text>
```

Where:

- `<ESC>` is the escape character (ASCII 27 or `0x1B`)
- `[` is a literal left bracket
- `<parameters>` are numeric codes separated by semicolons
- `m` is the final character indicating a graphics mode command
- `<text>` is the content to which the style applies

### Simple Example

```powershell
$esc = [char]27
Write-Host "${esc}[31mRed Text${esc}[0m"
```

This outputs: `Red Text` (in red color)

Breaking it down:

- `${esc}[31m` - Set foreground color to red (code 31)
- `Red Text` - The actual text to display
- `${esc}[0m` - Reset all attributes

---

## Basic ANSI Color System

ANSI defines a foundational set of 16 colors using 3-bit and 4-bit color codes.

### 16 Standard Colors

The original ANSI palette consists of 8 colors, each available in normal and bright variants:

#### Standard Colors (30-37 for foreground, 40-47 for background)

| Color   | Foreground Code | Background Code | Bright Foreground | Bright Background |
| ------- | --------------- | --------------- | ----------------- | ----------------- |
| Black   | 30              | 40              | 90                | 100               |
| Red     | 31              | 41              | 91                | 101               |
| Green   | 32              | 42              | 92                | 102               |
| Yellow  | 33              | 43              | 93                | 103               |
| Blue    | 34              | 44              | 94                | 104               |
| Magenta | 35              | 45              | 95                | 105               |
| Cyan    | 36              | 46              | 96                | 106               |
| White   | 37              | 47              | 97                | 107               |

### PowerShell Examples: 16 Colors

```powershell
$esc = [char]27

# Standard red foreground on default background
Write-Host "${esc}[31mStandard Red${esc}[0m"

# Bright (high-intensity) green
Write-Host "${esc}[92mBright Green${esc}[0m"

# Black text on yellow background
Write-Host "${esc}[30;43mBlack on Yellow${esc}[0m"

# Bright cyan on black background
Write-Host "${esc}[96;40mBright Cyan on Black${esc}[0m"
```

### Limitations of 16 Colors

- Limited palette for sophisticated themes
- Cannot represent intermediate colors
- Brightness limited to binary: normal or bright
- Colors may vary between terminal emulators

---

## Color Models in Depth

Modern terminals support multiple color models beyond the basic 16 colors. Each model offers different trade-offs between color richness and compatibility.

### 1. 256-Color Extended Palette

The 256-color model provides:

- **16 standard colors** (indices 0-15)
- **216 colors** (indices 16-231) - a 6×6×6 RGB cube
- **24 grayscale colors** (indices 232-255)

#### 256-Color Format

```
ESC[38;5;<color_index>m    (foreground)
ESC[48;5;<color_index>m    (background)
```

#### RGB Cube Calculation

For colors 16-231 (the 6×6×6 cube):

```
index = 16 + (36 × r) + (6 × g) + b
where r, g, b ∈ [0, 5]
```

Each component maps to 0%, 20%, 40%, 60%, 80%, or 100% intensity.

#### PowerShell Examples: 256 Colors

```powershell
$esc = [char]27

# Orange (256-color index ~214)
Write-Host "${esc}[38;5;214mOrange${esc}[0m"

# Dark blue (256-color index ~18)
Write-Host "${esc}[38;5;18mDark Blue${esc}[0m"

# Gray (256-color index ~244)
Write-Host "${esc}[38;5;244mGray${esc}[0m"

# Light green background (256-color index ~157)
Write-Host "${esc}[48;5;157mLight Green Background${esc}[0m"

# Combining colors: dark gray text on light cyan background
Write-Host "${esc}[38;5;240;48;5;195mText on Background${esc}[0m"
```

#### Common 256-Color Index Reference

```powershell
# Useful reference: Generate the 256-color palette
$esc = [char]27
for ($i = 0; $i -lt 256; $i++) {
    $color = "${esc}[38;5;${i}m■${esc}[0m"
    Write-Host -NoNewline $color
    if (($i + 1) % 16 -eq 0) { Write-Host "" }  # Newline every 16 colors
}
```

### 2. 24-Bit True Color (Truecolor/RGB)

The 24-bit model provides the full RGB color space:

- 16,777,216 possible colors (2^24)
- Direct RGB specification
- Full color fidelity for precise themes

#### Truecolor Format

```
ESC[38;2;<r>;<g>;<b>m    (foreground)
ESC[48;2;<r>;<g>;<b>m    (background)
where r, g, b ∈ [0, 255]
```

#### PowerShell Examples: Truecolor

```powershell
$esc = [char]27

# Precise red (RGB: 238, 0, 0)
Write-Host "${esc}[38;2;238;0;0mPrecise Red${esc}[0m"

# Gray (RGB: 140, 140, 140)
Write-Host "${esc}[38;2;140;140;140mGray${esc}[0m"

# Custom purple (RGB: 186, 85, 211)
Write-Host "${esc}[38;2;186;85;211mCustom Purple${esc}[0m"

# White text on dark blue background
Write-Host "${esc}[38;2;255;255;255;48;2;25;25;112mWhite on Dark Blue${esc}[0m"
```

#### Converting Hex to RGB

```powershell
$esc = [char]27

# Convert hex color to RGB
function Convert-HexToRGB {
    param([string]$HexColor)

    # Remove # if present
    $HexColor = $HexColor -replace '^#', ''

    $r = [Convert]::ToInt32($HexColor.Substring(0, 2), 16)
    $g = [Convert]::ToInt32($HexColor.Substring(2, 2), 16)
    $b = [Convert]::ToInt32($HexColor.Substring(4, 2), 16)

    return @{r = $r; g = $g; b = $b}
}

# Example: Convert #FF5733 to RGB and display
$color = Convert-HexToRGB -HexColor "#FF5733"
Write-Host "${esc}[38;2;$($color.r);$($color.g);$($color.b)m#FF5733 Orange${esc}[0m"
```

### Color Model Compatibility

| Terminal         | 16 Colors  | 256 Colors | Truecolor |
| ---------------- | ---------- | ---------- | --------- |
| Windows Terminal | ✅         | ✅         | ✅        |
| VS Code          | ✅         | ✅         | ✅        |
| iTerm2           | ✅         | ✅         | ✅        |
| GNOME Terminal   | ✅         | ✅         | ✅        |
| xterm            | ✅         | ✅         | ❌        |
| cmd.exe          | ⚠️ Limited | ❌         | ❌        |

---

## PowerShell Implementation

### Setting Up Color Variables

The recommended approach is to define color variables once at the start of your script or profile:

```powershell
# Define escape character
$esc = [char]27

# Define colors using the most compatible method (Truecolor)
# Format: ESC[38;2;R;G;Bm for foreground

$colors = @{
    # Common colors
    red         = "$esc[38;2;238;0;0m"
    green       = "$esc[38;2;0;128;0m"
    blue        = "$esc[38;2;0;0;255m"
    yellow      = "$esc[38;2;255;255;0m"
    cyan        = "$esc[38;2;0;255;255m"
    magenta     = "$esc[38;2;255;0;255m"
    white       = "$esc[38;2;255;255;255m"
    black       = "$esc[38;2;0;0;0m"

    # Grayscale
    darkgray    = "$esc[38;2;64;64;64m"
    gray        = "$esc[38;2;128;128;128m"
    lightgray   = "$esc[38;2;192;192;192m"

    # Accent colors (from theme palettes)
    accent      = "$esc[38;2;0;200;200m"
    accent2     = "$esc[38;2;200;0;200m"
}

# Reset code (always include this!)
$reset = "$esc[0m"
```

### Applying Colors to Text

```powershell
# Simple foreground color
Write-Host "$($colors.red)Error occurred$($reset)"

# Background color
Write-Host "$esc[48;2;255;0;0m$esc[38;2;255;255;255mWhite on Red$reset"

# Combining styles: bold + color
Write-Host "$esc[1;38;2;0;255;0mBold Green$reset"

# Multiple colors on one line
Write-Host "$($colors.red)Red$reset $($colors.blue)Blue$reset $($colors.green)Green$reset"
```

### Text Styling Attributes

Beyond colors, ANSI also supports text styling:

| Attribute     | Code | Example                           |
| ------------- | ---- | --------------------------------- |
| Reset all     | 0    | `${esc}[0m`                       |
| Bold/Bright   | 1    | `${esc}[1m`                       |
| Dim           | 2    | `${esc}[2m`                       |
| Italic        | 3    | `${esc}[3m`                       |
| Underline     | 4    | `${esc}[4m`                       |
| Blink         | 5    | `${esc}[5m` (often not supported) |
| Reverse       | 7    | `${esc}[7m`                       |
| Hidden        | 8    | `${esc}[8m`                       |
| Strikethrough | 9    | `${esc}[9m`                       |

#### PowerShell Styling Examples

```powershell
$esc = [char]27
$reset = "$esc[0m"

# Bold text
Write-Host "$esc[1mBold Text$reset"

# Underlined text
Write-Host "$esc[4mUnderlined Text$reset"

# Bold + colored
Write-Host "$esc[1;38;2;255;100;50mBold Orange$reset"

# Dim + colored
Write-Host "$esc[2;38;2;100;100;100mDim Gray$reset"
```

### Common Color Reset Pattern

A critical best practice is always resetting colors and attributes after applying them:

```powershell
$esc = [char]27
$reset = "$esc[0m"

# ❌ BAD: Color bleeds to subsequent output
Write-Host "$esc[31mError: Something failed"
Write-Host "This text is also red!"

# ✅ GOOD: Always reset
Write-Host "$esc[31mError: Something failed$reset"
Write-Host "This text is black/default again"
```

---

## Advanced Techniques

### Conditional Colors Based on State

```powershell
$esc = [char]27
$reset = "$esc[0m"

function Write-StatusMessage {
    param(
        [string]$Message,
        [bool]$IsError = $false
    )

    if ($IsError) {
        $color = "$esc[38;2;255;0;0m"  # Red for errors
    } else {
        $color = "$esc[38;2;0;255;0m"  # Green for success
    }

    Write-Host "$color$Message$reset"
}

# Usage
Write-StatusMessage -Message "Operation successful" -IsError $false
Write-StatusMessage -Message "Operation failed" -IsError $true
```

### Creating Color Gradients in Output

```powershell
$esc = [char]27
$reset = "$esc[0m"

# Create a simple color gradient
function Write-GradientText {
    param(
        [string]$Text,
        [int]$StartR,
        [int]$StartG,
        [int]$StartB,
        [int]$EndR,
        [int]$EndG,
        [int]$EndB
    )

    $chars = $Text.ToCharArray()
    $steps = $chars.Count - 1

    foreach ($i in 0..($chars.Count - 1)) {
        $ratio = if ($steps -eq 0) { 0 } else { $i / $steps }

        $r = [int]($StartR + ($EndR - $StartR) * $ratio)
        $g = [int]($StartG + ($EndG - $StartG) * $ratio)
        $b = [int]($StartB + ($EndB - $StartB) * $ratio)

        Write-Host -NoNewline "$esc[38;2;$r;$g;${b}m$($chars[$i])"
    }
    Write-Host $reset
}

# Example: Rainbow gradient
Write-GradientText -Text "Hello Gradient!" -StartR 255 -StartG 0 -StartB 0 -EndR 0 -EndG 0 -EndB 255
```

### Detecting Terminal Color Capability

```powershell
function Get-TerminalColorCapability {
    # Check environment variables that terminal emulators typically set

    if ($env:COLORTERM -eq "truecolor" -or $env:COLORTERM -eq "24bit") {
        return "Truecolor"
    }

    if ($env:TERM -like "*256color*") {
        return "256-color"
    }

    if ($PSVersionTable.Platform -eq "Win32NT") {
        # Windows Terminal and modern Windows console support truecolor
        if ($env:WT_SESSION -or $env:TERM_PROGRAM -eq "vscode") {
            return "Truecolor"
        }
    }

    # Fallback
    return "16-color"
}

$capability = Get-TerminalColorCapability
Write-Host "Terminal color capability: $capability"
```

---

## Common Pitfalls & Solutions

### Pitfall 1: Variable Name Collision with Color Variables

When using color variables in strings, PowerShell can misinterpret variable boundaries.

```powershell
$esc = [char]27
$gray = "$esc[38;2;128;128;128m"

# ❌ WRONG: PowerShell thinks variable is ${gray}P
$output = "$gray P^*^T"  # Outputs nothing!

# ✅ CORRECT: Use $reset between variable and following letter
$reset = "$esc[0m"
$output = "$gray P^*^T$reset"

# Alternative: Use braces to delimit variable name
$output = "${gray}P^*^T"  # Only works if P is not a valid variable name continuation
```

### Pitfall 2: Backtick Escape Sequence Issues

Backticks in strings can be misinterpreted by PowerShell's escape mechanism.

```powershell
$esc = [char]27
$reset = "$esc[0m"

# ❌ WRONG: backtick `b gets interpreted as backspace escape
$output = "${gray}Box`bug`message$reset"  # Outputs: "ox" (missing b's!)

# ✅ CORRECT: Double backticks for literal backticks
$output = "${gray}Box``bug``message$reset"

# Better approach: Define special characters as variables
$tick = '`'
$output = "${gray}Box${tick}bug${tick}message$reset"
```

### Pitfall 3: Dollar Sign Escaping

Literal dollar signs need escaping in double-quoted strings.

```powershell
$esc = [char]27
$reset = "$esc[0m"

# ❌ WRONG: $$ tries to access variable $$
$price = "$${esc}[32m5.99$reset"

# ✅ CORRECT: Escape each dollar sign with backtick
$price = "`$`$${esc}[32m5.99$reset"

# Or use single quotes (no variable expansion)
$price = '$$' + "${esc}[32m5.99$reset"
```

### Pitfall 4: Terminal Not Supporting Truecolor

Some older terminals fall back to 16-color mode when receiving truecolor codes.

```powershell
# Graceful degradation: Try truecolor first, fallback to 256-color
function Write-ColorText {
    param(
        [string]$Text,
        [int]$R,
        [int]$G,
        [int]$B,
        [int]$ColorIndex256 = 7  # White by default
    )

    $esc = [char]27
    $reset = "$esc[0m"

    if ($env:COLORTERM -eq "truecolor" -or $env:COLORTERM -eq "24bit") {
        # Use truecolor
        Write-Host "$esc[38;2;$R;$G;${B}m$Text$reset"
    } else {
        # Fallback to 256-color
        Write-Host "$esc[38;5;${ColorIndex256}m$Text$reset"
    }
}

Write-ColorText -Text "Adaptive Color" -R 255 -G 0 -B 0 -ColorIndex256 196
```

### Pitfall 5: Forgetting to Reset

Color/style codes persist until explicitly reset or terminal is cleared.

```powershell
$esc = [char]27
$reset = "$esc[0m"
$red = "$esc[38;2;255;0;0m"

# ❌ BAD: Red color persists
Write-Host "${red}Important Error!"
Write-Host "This is also red (unintended)"

# ✅ GOOD: Always reset
Write-Host "${red}Important Error$reset"
Write-Host "This is back to normal"
```

---

## Integration with Oh My Posh

Oh My Posh abstracts away direct ANSI code management through its JSON configuration system, but understanding the underlying mechanics helps in customization.

### How Oh My Posh Uses ANSI Codes

1. **Palette Definition**: Colors in the `palette` section are stored as hex values
2. **Segment Rendering**: Segments apply palette colors through ANSI codes
3. **Template Processing**: Templates use palette references (`p:colorname`)
4. **Output Rendering**: Final prompt output includes all necessary ANSI codes

### Example: Oh My Posh Palette Section

```json
{
  "palette": {
    "red_alert": "#ff0000",
    "green_success": "#00ff00",
    "blue_primary": "#0000ff"
  },
  "blocks": [
    {
      "type": "prompt",
      "alignment": "left",
      "segments": [
        {
          "type": "status",
          "foreground": "p:green_success",
          "background": "p:blue_primary",
          "template": " {{ if .Error }}✗{{ else }}✓{{ end }} "
        }
      ]
    }
  ]
}
```

When rendered, this produces ANSI escape sequences equivalent to:

```
\033[38;2;0;255;0m\033[48;2;0;0;255m ✓ \033[0m
```

### Testing Color Rendering in Your Theme

```powershell
# Extract and test a theme's palette
$theme = Get-Content "OhMyPosh-Atomic-Custom.json" | ConvertFrom-Json
$palette = $theme.palette

$esc = [char]27
$reset = "$esc[0m"

# Display all colors in the palette
foreach ($color in $palette.PSObject.Properties) {
    $hex = $color.Value
    $r = [Convert]::ToInt32($hex.Substring(1, 2), 16)
    $g = [Convert]::ToInt32($hex.Substring(3, 2), 16)
    $b = [Convert]::ToInt32($hex.Substring(5, 2), 16)

    Write-Host -NoNewline "$esc[38;2;$r;$g;${b}m■ $($color.Name): $hex"
    Write-Host $reset
}
```

---

## Performance Considerations

### Efficiency Best Practices

1. **Pre-compute color codes**: Define once, reuse many times
2. **Minimize ANSI sequences**: Each sequence has small overhead
3. **Use segment caching**: Oh My Posh caches segment output

```powershell
# ❌ INEFFICIENT: Recalculating colors on each call
function Write-ErrorMessage {
    param([string]$Message)
    $esc = [char]27
    Write-Host "$esc[38;2;255;0;0m$Message$esc[0m"
}

# ✅ EFFICIENT: Pre-compute colors
$esc = [char]27
$red = "$esc[38;2;255;0;0m"
$reset = "$esc[0m"

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "$red$Message$reset"
}
```

### Rendering Performance

Terminal rendering of ANSI codes is generally fast, but consider:

- **Network latency**: SSH sessions can be slow with heavy ANSI output
- **Terminal update rate**: Some older terminals redraw slowly
- **Output size**: Excessive ANSI codes increase data volume

---

## Summary

Understanding ANSI escape codes and their implementation in PowerShell allows you to:

- ✅ Create visually rich terminal prompts
- ✅ Debug color rendering issues
- ✅ Customize Oh My Posh themes at a fundamental level
- ✅ Build portable, cross-platform terminal applications
- ✅ Optimize performance for various environments

**Key Takeaways:**

1. Always reset styles/colors after use
2. Use Truecolor (24-bit) for best results, with fallbacks
3. Pre-compute color codes for efficiency
4. Be aware of variable name collisions in strings
5. Escape backticks and dollar signs in strings
6. Test your colors in your target terminal emulator

For more information, see the [ANSI/VT100 Escape Sequence Reference](https://en.wikipedia.org/wiki/ANSI_escape_code).
<!-- {% endraw %} -->
