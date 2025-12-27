<!-- {% raw %} -->

# 🔧 Advanced Theme Customization Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Theme Structure Deep Dive](#theme-structure-deep-dive)
3. [Segment Customization](#segment-customization)
4. [Template Expressions](#template-expressions)
5. [Custom Icons & Symbols](#custom-icons--symbols)
6. [Color Manipulation](#color-manipulation)
7. [Advanced Block Layouts](#advanced-block-layouts)
8. [Creating Custom Segments](#creating-custom-segments)
9. [Performance Tuning](#performance-tuning)
10. [Best Practices](#best-practices)

---

## Introduction

While the OhMyPosh Atomic Enhanced themes come pre-configured and visually complete, true mastery requires understanding how to modify and extend them. This guide covers advanced customization techniques that go beyond changing color palettes.

### What You'll Learn

- Modifying existing segments for different information
- Writing complex template expressions
- Creating entirely new segments
- Optimizing themes for your specific workflow
- Integrating custom scripts and commands

---

## Theme Structure Deep Dive

### JSON Schema Overview

Every Oh My Posh theme follows a defined JSON schema. Understanding this structure is essential for modifications.

```json
{
 "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
 "accent_color": "#00bcd4",
 "blocks": [
  // Prompt layout blocks
 ],
 "console_title": "{{ .Shell }} - {{.Folder}}",
 "console_title_template": "{{.Folder}}",
 "final_space": true,
 "palette": {
  // Color definitions
 },
 "tooltip": {
  "text": "{{.Name}}",
  "background": "transparent",
  "foreground": "#000000"
 },
 "transient_prompt": {
  // Optional simplified prompt after execution
 },
 "version": 3
}
```

### Key Top-Level Properties

| Property | Purpose | Example |
| --- | --- | --- |
| `$schema` | Validation & IDE support | Official schema URL |
| `version` | Schema version for Oh My Posh | `3` (current) |
| `final_space` | Trailing space in prompt | `true` or `false` |
| `console_title_template` | Terminal tab/window title | `"{{.Folder}}"` |
| `accent_color` | Primary accent hue (not palette) | `"#00bcd4"` |
| `palette` | Color definitions object | `{...}` |
| `blocks` | Array of prompt line blocks | `[{...}]` |
| `transient_prompt` | Quick re-prompt display | Optional `{...}` |

### Block Structure

```json
{
 "alignment": "left|right|rprompt|newline",
 "segments": [
  {
   "type": "segment_type",
   "background": "p:palette_key|#hexcolor",
   "foreground": "p:palette_key|#hexcolor",
   "template": "template_string",
   "properties": {},
   "style": "powerline|diamond|plain",
   "leading_diamond": "◊",
   "trailing_diamond": "◊",
   "cache": {
    "strategy": "session|folder|windows",
    "duration": "5m",
    "skip_cache": false
   }
  }
 ],
 "vertical_offset": 0
}
```

---

## Segment Customization

### Common Segment Types

Oh My Posh provides numerous built-in segment types. Each type accepts different properties and templates.

#### Path Segment

Displays the current working directory with customizable format.

```json
{
 "background": "p:blue_primary",
 "foreground": "p:white",
 "properties": {
  "style": "folder",
  "max_depth": 3,
  "folder_separator_icon": "/",
  "home_icon": "~",
  "hide_root_location": false,
  "read_only_icon": "🔒",
  "truncation_mode": "start",
  "truncated_indicator": "....",
  "mapped_locations": {
   "C:\\Users\\YourName\\Documents": "📄 Docs",
   "C:\\Users\\YourName\\Desktop": "🖥️ Desktop",
   "/home/user/projects": "💼 Projects"
  }
 },
 "style": "powerline",
 "template": " {{ .Path }} ",
 "type": "path"
}
```

**Customization Options:**

```json
{
 "properties": {
  "style": "mixed|folder|letter",
  "max_depth": 2,
  "folder_separator_icon": " > ",
  "home_icon": "⌂",
  "read_only_icon": "  ",
  "truncation_mode": "start|end|middle",
  "truncated_indicator": "…",
  "mapped_locations": {
   "/home/user/dev": "🔧 Dev",
   "C:\\code": "📝 Code"
  }
 }
}
```

#### Git Segment

Shows git status with detailed information.

```json
{
 "background": "p:yellow_bright",
 "foreground": "p:black",
 "properties": {
  "fetch_status": true,
  "fetch_upstream_icon": true,
  "branch_max_length": 25,
  "truncation_symbol": "…",
  "fetch_worktree_count": false,
  "windows_registry": false
 },
 "style": "powerline",
 "template": " {{ .Branch }} ",
 "type": "git"
}
```

**Advanced Git Template:**

```json
{
 "template": "{{ if .UpstreamIcon }}{{ .UpstreamIcon }} {{ end }}{{ .Branch }}{{ if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .RepositoryStatus }} {{ .RepositoryStatus }}{{ end }}"
}
```

#### Status Segment

Indicates success/failure of last command.

```json
{
 "background": "p:green_success",
 "background_templates": [
  "{{ if .Error }}p:maroon_error{{ else }}p:green_success{{ end }}"
 ],
 "foreground": "p:black",
 "leading_diamond": "◊",
 "style": "diamond",
 "template": " {{ if .Error }}✗{{ else }}✓{{ end }} ",
 "trailing_diamond": "◊",
 "type": "status"
}
```

#### Custom Shell Variables Segment

Display any environment variable or command output.

```json
{
 "background": "p:blue_primary",
 "cache": {
  "strategy": "session",
  "duration": "1h"
 },
 "foreground": "p:white",
 "properties": {
  "var_name": "CUSTOM_VAR"
 },
 "template": " {{ .Env.CUSTOM_VAR }} ",
 "type": "env"
}
```

#### Command Segment (Advanced)

Execute custom commands and display results.

```json
{
 "background": "p:purple_session",
 "cache": {
  "strategy": "session",
  "duration": "2s"
 },
 "foreground": "p:white",
 "properties": {
  "shell": "powershell",
  "command": "Get-Date -Format 'HH:mm:ss'",
  "parse": true,
  "parse_separator": ":"
 },
 "template": "{{ .Output }}",
 "type": "command"
}
```

#### Language Version Segments

Display runtime versions for Node, Python, etc.

```json
{
 "background": "p:node_green",
 "cache": {
  "strategy": "folder",
  "duration": "5m"
 },
 "foreground": "p:black",
 "properties": {
  "fetch_version": true
 },
 "style": "powerline",
 "template": " ⬢ {{ .Full }} ",
 "type": "node"
}
```

---

## Template Expressions

### Basics

Oh My Posh uses Go template syntax (similar to Handlebars). Templates appear in the `template` property and `background_templates` array.

#### Simple Variable Substitution

```json
{
 "template": "User: {{ .User }}" // Output: User: john
}
```

#### Conditional Logic

```json
{
 "template": "{{ if .Error }}✗ Failed{{ else }}✓ Success{{ end }}"
}
```

#### Loops (Arrays)

```json
{
 "template": "{{ range .Items }}{{ . }}{{ end }}"
}
```

### Advanced Template Patterns

#### Multi-Part Templates with Fallbacks

```json
{
 "template": "{{ if .Version }}{{ .Name }} {{ .Version }}{{ else }}{{ .Name }}{{ end }}"
}
```

#### Color Blending in Templates

```json
{
 "template": "<#00bcd4>Cyan</>{{ .Content }}<#ff0000>Red</>"
}
```

#### Complex Conditional State

```json
{
 "template": "{{ if or .Error .Detached }}{{ if .Detached }}(detached){{ else }}(error){{ end }}{{ else }}{{ .Branch }}{{ end }}",
 "type": "git"
}
```

#### Conditional Spacing

```json
{
 "template": "{{ if .Value }} {{ .Value }} {{ else }}(empty){{ end }}"
}
```

#### Background Based on Condition

```json
{
 "background_templates": [
  "{{ if eq .ExitCode 0 }}p:green_success{{ else }}p:red_alert{{ end }}"
 ]
}
```

### Built-In Template Functions

| Function | Purpose | Example |
| --- | --- | --- |
| `eq` | Equals comparison | `{{ if eq .Shell "pwsh" }}PowerShell{{ end }}` |
| `ne` | Not equals | `{{ if ne .User "root" }}Regular User{{ end }}` |
| `gt` | Greater than | `{{ if gt .Memory 80 }}High Memory{{ end }}` |
| `lt` | Less than | `{{ if lt .Memory 20 }}Low Memory{{ end }}` |
| `and` | Logical AND | `{{ if and .Error .Warning }}Both{{ end }}` |
| `or` | Logical OR | `{{ if or .Error .Warning }}Either{{ end }}` |
| `not` | Logical NOT | `{{ if not .Error }}Success{{ end }}` |
| `len` | Length of string | `{{ if gt (len .Text) 5 }}Long{{ end }}` |
| `contains` | String contains | `{{ if contains .Path "node_modules" }}Has deps{{ end }}` |
| `split` | Split string | `{{ index (split .Path "/") 0 }}` |
| `join` | Join array | `{{ join (split .Path "/") "-" }}` |
| `title` | Capitalize | `{{ title .Name }}` |
| `lower` | Lowercase | `{{ lower .Text }}` |
| `upper` | Uppercase | `{{ upper .Text }}` |

### Practical Template Examples

#### Status Segment with Icons

```json
{
 "template": "{{ if .Error }}❌ {{ .Error.Message }}{{ else }}✅{{ end }}",
 "type": "status"
}
```

#### Git with Upstream Status

```json
{
 "template": "{{ if .UpstreamIcon }}{{ .UpstreamIcon }} {{ end }}{{ .Branch }}{{ if .BranchStatus }} ({{ .BranchStatus }}){{ end }}",
 "type": "git"
}
```

#### Path with Dynamic Truncation

```json
{
 "template": "{{ if gt (len .Path) 40 }}...{{ substr .Path -35 }}{{ else }}{{ .Path }}{{ end }}",
 "type": "path"
}
```

#### Environment Indicator

```json
{
 "properties": {
  "var_name": "ENVIRONMENT"
 },
 "template": "{{ if .Env.DEVELOPMENT }}[DEV]{{ else if .Env.STAGING }}[STAGING]{{ else }}[PROD]{{ end }}",
 "type": "env"
}
```

---

## Custom Icons & Symbols

### Icon Strategy

Icons add visual richness to prompts while reducing text verbosity.

#### Built-in Icon Libraries

Oh My Posh includes collections of pre-designed icons:

- **Powerline symbols**: ` `
- **Nerd Font icons**: Various glyphs
- **Unicode symbols**: ✓ ✗ ◆ ⬢ ⬡

#### Using Icons in Templates

```json
{
 "template": "⎇ {{ .Branch }}",
 "type": "git"
}
```

#### Conditional Icons Based on State

```json
{
 "template": "{{ if .Error }}󰅖 Error{{ else }}󰄬 Success{{ end }}",
 "type": "status"
}
```

#### Custom Icon Mapping

```json
{
 "template": "{{ if contains .Output 'python' }}🐍 Python{{ else if contains .Output 'node' }}⬢ Node{{ else }}?{{ end }}",
 "type": "command"
}
```

#### Nerd Font Resources

Use sites like [nerdfonts.com](https://nerdfonts.com) to browse available icons:

- DevIcons (dev tools)
- Font Awesome
- Material Design Icons
- Powerline Symbols

#### Example Icons

| Icon | Unicode | Name | Use Case |
| --- | --- | --- | --- |
| ⬢ | U+2B22 | Node.js | JavaScript/TypeScript |
| 🐍 | U+1F40D | Python | Python projects |
| 󰌠 | Custom | Rust | Rust projects |
| ☸ | U+2328 | Kubernetes | K8s contexts |
| 󰔒 | Custom | Lock | Read-only indicator |
| ⚡ | U+26A1 | Electricity | Power/speed indicator |
| 🔧 | U+1F527 | Wrench | Tools/configuration |
| 📦 | U+1F4E6 | Package | Dependencies |

---

## Color Manipulation

### Using the Palette System

The palette centralizes all color definitions, enabling easy theme swaps.

#### Palette Entry Reference Format

```
p:<palette_key>
```

#### Example References

```json
{
 "background": "p:blue_primary",
 "foreground": "p:white"
}
```

#### Defining Custom Palette Entries

```json
{
 "palette": {
  "my_custom_color": "#FF6B9D",
  "my_custom_dark": "#2D1B3D",
  "my_accent": "#00D9FF"
 }
}
```

### Hex Color References

When not using palettes, you can specify colors directly:

```json
{
 "background": "#000000",
 "foreground": "#FFFFFF"
}
```

### Dynamic Colors Based on Conditions

The `background_templates` array allows conditional colors:

```json
{
 "background_templates": [
  "{{ if .Error }}p:red_alert{{ else }}p:green_success{{ end }}"
 ],
 "foreground": "p:white",
 "template": "{{ if .Error }}✗{{ else }}✓{{ end }}",
 "type": "status"
}
```

### Color Blending Techniques

While Oh My Posh doesn't directly support color blending, you can simulate it by:

1. **Using intermediate colors in palette**
2. **Conditional color selection based on context**
3. **Using divider segments with blend colors**

```json
{
 "palette": {
  "red_to_orange": "#FF4500",
  "orange_to_yellow": "#FFB347",
  "yellow_to_green": "#ADFF2F"
 }
}
```

---

## Advanced Block Layouts

### Block Alignment Options

```json
{
 "alignment": "left|right|rprompt|newline"
}
```

- **`left`**: Primary prompt line, left-aligned
- **`right`**: Same line as left, but right-aligned
- **`rprompt`**: Right prompt (may overflow left)
- **`newline`**: New prompt line

### Multi-Line Prompt Example

```json
{
  "blocks": [
    {
      "alignment": "left",
      "segments": [
        { "type": "shell", "..." },
        { "type": "path", "..." }
      ]
    },
    {
      "alignment": "right",
      "segments": [
        { "type": "time", "..." },
        { "type": "battery", "..." }
      ]
    },
    {
      "alignment": "newline",
      "segments": [
        { "type": "text", "template": "❯" }
      ]
    }
  ]
}
```

### Vertical Offset for Alignment

```json
{
  "alignment": "left",
  "vertical_offset": 0,  // 0 = same line as previous, >0 = down, <0 = up
  "segments": [...]
}
```

### Creating Spacers and Dividers

```json
{
 "background": "transparent",
 "properties": {
  "prefix": "",
  "suffix": ""
 },
 "template": " ", // Single space
 "type": "text"
}
```

---

## Creating Custom Segments

### Using the Command Segment for Custom Logic

```json
{
 "background": "p:blue_primary",
 "cache": {
  "strategy": "session",
  "duration": "30s"
 },
 "foreground": "p:white",
 "properties": {
  "shell": "powershell",
  "command": "Get-Process -Name 'notable-app' -ErrorAction SilentlyContinue | Measure-Object | ForEach-Object { $_.Count }",
  "parse": true
 },
 "template": "{{ .Output }}",
 "type": "command"
}
```

### Custom PowerShell Script Segment

Create a PowerShell script that returns information:

```powershell
# File: CustomSegments.ps1

function Get-GitStats {
    $ahead = (git rev-list --count "@{u}..HEAD" 2>/dev/null) || 0
    $behind = (git rev-list --count "HEAD..@{u}" 2>/dev/null) || 0

    if ($ahead -eq 0 -and $behind -eq 0) {
        return ""
    }

    $stats = @()
    if ($ahead -gt 0) { $stats += "↑$ahead" }
    if ($behind -gt 0) { $stats += "↓$behind" }

    return $stats -join " "
}

Get-GitStats
```

Configure in theme:

```json
{
 "properties": {
  "shell": "powershell",
  "command": "&{ . ./CustomSegments.ps1; Get-GitStats }"
 },
 "template": "{{ .Output }}",
 "type": "command"
}
```

### Environment Variable Segment

```json
{
 "background": "p:purple_session",
 "cache": {
  "strategy": "session"
 },
 "foreground": "p:white",
 "properties": {
  "var_name": "ENVIRONMENT"
 },
 "template": "[{{ .Env.ENVIRONMENT }}]",
 "type": "env"
}
```

---

## Performance Tuning

### Segment Caching Strategies

Caching prevents expensive segment evaluations on every prompt.

#### Cache Strategy Types

```json
{
 "cache": {
  "strategy": "session|folder|windows",
  "duration": "5m",
  "skip_cache": false
 }
}
```

- **`session`**: Cache for entire shell session (fastest)
- **`folder`**: Cache per directory (good for git status)
- **`windows`**: Cache per PowerShell window session

#### Duration Format

```
"2s"    // 2 seconds
"5m"    // 5 minutes
"1h"    // 1 hour
```

#### Caching Best Practices

```json
{
  "type": "git",
  "cache": {
    "strategy": "folder",
    "duration": "5m"
  }
},
{
  "type": "time",
  "cache": {
    "strategy": "session",
    "duration": "1s"  // Update every second
  }
},
{
  "type": "command",
  "cache": {
    "strategy": "session",
    "duration": "30s"  // Heavy commands should cache longer
  }
}
```

### Disabling Expensive Segments

If a segment is very slow, consider disabling or replacing it:

```json
{
 "background": "transparent",
 "properties": {
  "command": "..." // Expensive logic disabled
 },
 "template": "", // Empty template = hidden
 "type": "command"
}
```

### Conditional Segment Loading

Load segments only in certain conditions:

```json
{
 "properties": {
  "shell": "powershell",
  "command": "$PSVersionTable.PSVersion.Major"
 },
 "template": "{{ if eq .Shell \"pwsh\" }}⚡{{ end }}",
 "type": "command"
}
```

---

## Best Practices

### 1. Modular Configuration

Separate concerns into distinct segments:

```json
{
 "blocks": [
  {
   "type": "prompt",
   "alignment": "left",
   "segments": [
    { "type": "shell" }, // ① System info
    { "type": "path" }, // ② Location
    { "type": "git" } // ③ VCS status
   ]
  },
  {
   "type": "prompt",
   "alignment": "right",
   "segments": [
    { "type": "time" }, // ④ Clock
    { "type": "battery" } // ⑤ Power
   ]
  }
 ]
}
```

### 2. Consistent Styling

Use palette colors consistently:

```json
{
 "blocks": [
  {
   "segments": [
    {
     "background": "p:bg_primary",
     "foreground": "p:fg_primary"
    }
   ]
  }
 ],
 "palette": {
  "bg_primary": "#1e1e2e",
  "bg_secondary": "#313244",
  "fg_primary": "#cdd6f4"
 }
}
```

### 3. Performance First

Cache aggressively and consider disabling optional segments:

```json
{
 "cache": {
  "strategy": "folder",
  "duration": "5m"
 },
 "properties": {
  "fetch_status": true, // Only when needed
  "fetch_upstream_icon": false // Optional detail
 }
}
```

### 4. Readability

Ensure adequate contrast and spacing:

```json
{
 "background": "p:dark_color",
 "foreground": "p:light_color", // High contrast
 "template": "  {{ .Content }}  " // Breathing room
}
```

### 5. Testing Changes

Test your modifications before deploying:

```powershell
# Test a modified theme
oh-my-posh init pwsh --config './my-modified-theme.json' | Invoke-Expression

# Reload if needed
$ExecutionContext.InvokeCommand.LocationChangedAction = $null
& $profile
```

---

## Summary

Advanced customization allows you to:

✅ Create highly personal prompts
✅ Integrate custom scripts and commands
✅ Optimize for your specific workflow
✅ Reduce visual clutter or add detail
✅ Maintain consistent branding

Key Areas Covered:

1. **Theme Structure**: Understanding JSON schema
2. **Segments**: Customizing built-in segment types
3. **Templates**: Writing dynamic template expressions
4. **Icons**: Adding visual richness
5. **Colors**: Palette system and conditional colors
6. **Layouts**: Multi-line and complex block arrangements
7. **Custom Logic**: Command segments and scripts
8. **Performance**: Caching and optimization
9. **Best Practices**: Professional configuration techniques

For more advanced topics, refer to the [Official Oh My Posh Documentation](https://ohmyposh.dev/docs/configuration/overview).

<!-- {% endraw %} -->
