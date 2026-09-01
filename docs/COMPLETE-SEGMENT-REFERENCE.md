<!-- {% raw %} -->

# 📋 Complete Segment & Configuration Reference

## Table of Contents

1. [Segment Overview](#segment-overview)
2. [All Segment Types](#all-segment-types)
3. [Segment Properties Reference](#segment-properties-reference)
4. [Template Functions & Variables](#template-functions--variables)
5. [Palette & Colors Reference](#palette--colors-reference)
6. [Block Configuration](#block-configuration)
7. [Common Configurations](#common-configurations)
8. [Segment Combinations](#segment-combinations)
9. [Troubleshooting by Segment](#troubleshooting-by-segment)

---

## Segment Overview

### What are Segments?

Segments are individual components that make up your prompt. Each segment displays specific information and can be configured independently.

### Segment Lifecycle

```
┌─────────────┐
│ 1. Trigger  │ ← When should this segment run?
└──────┬──────┘
       │
       ↓
┌─────────────────────┐
│ 2. Check Cache      │ ← Is cached data available?
└──────┬──────────────┘
       │
       ├─→ YES ──→ Use cached data
       │
       └─→ NO  ──→ Execute segment logic
                     │
                     ↓
              ┌─────────────────┐
              │ 3. Collect Data │ ← Get info
              └────────┬────────┘
                       │
                       ↓
              ┌─────────────────┐
              │ 4. Template     │ ← Format output
              └────────┬────────┘
                       │
                       ↓
              ┌─────────────────┐
              │ 5. Style        │ ← Apply colors
              └────────┬────────┘
                       │
                       ↓
              ┌─────────────────┐
              │ 6. Render       │ ← Display
              └─────────────────┘
```

---

## All Segment Types

### System Information Segments

#### `shell`

Displays the current shell name and version.

```json
{
 "background": "p:blue_primary",
 "foreground": "p:white",
 "properties": {
  "mapped_names": {
   "pwsh": "PowerShell",
   "bash": "Bash",
   "zsh": "Zsh"
  }
 },
 "template": " {{ .Shell }} ",
 "type": "shell"
}
```

**Variables:**

- `{{ .Shell }}` - Shell name (pwsh, bash, zsh, etc.)
- `{{ .Version }}` - Shell version

**Common Uses:**

- Identify which shell you're using
- Visual indicator in multi-shell environments

---

#### `path`

Displays the current working directory.

```json
{
 "background": "p:orange_accent",
 "foreground": "p:black",
 "properties": {
  "style": "folder",
  "max_depth": 3,
  "folder_separator_icon": "/",
  "home_icon": "~",
  "read_only_icon": "🔒",
  "truncation_mode": "start",
  "truncated_indicator": "...",
  "mapped_locations": {
   "C:\\Users\\{user}\\Documents": "📄 Docs",
   "C:\\Users\\{user}\\Desktop": "🖥️ Desktop",
   "/home/user/projects": "💼 Projects"
  }
 },
 "template": "  {{ .Path }} ",
 "type": "path"
}
```

**Variables:**

- `{{ .Path }}` - Current path (formatted per properties)
- `{{ .FullPath }}` - Absolute path
- `{{ .ReadOnly }}` - 0 or 1 if directory is read-only

**Properties:**

- `style`: `folder|letter|mixed` - How to display path
- `max_depth`: Number - Maximum directory depth to show
- `truncation_mode`: `start|end|middle` - Where to truncate
- `mapped_locations`: Object - Custom names for paths

**Common Uses:**

- Show where you are in file system
- Highlight important directories with icons
- Reduce visual clutter with truncation

---

#### `git`

Displays git repository information and status.

```json
{
 "background": "p:yellow_bright",
 "foreground": "p:black",
 "options": {
  "branch_template": "{{ trunc 25 .Branch }}"
 },
 "style": "powerline",
 "template": " {{ .UpstreamIcon }}{{ .HEAD }}{{ if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} {{ .Working.String }}{{ end }}{{ if .Staging.Changed }} {{ .Staging.String }}{{ end }} ",
 "type": "git"
}
```

**Variables:**

- `{{ .HEAD }}` - Formatted branch, tag, or detached-HEAD context
- `{{ .UpstreamIcon }}` - Icon derived from the upstream remote
- `{{ .BranchStatus }}` - Ahead/behind relationship to the upstream branch
- `{{ .Working }}` - Unstaged and untracked worktree status
- `{{ .Staging }}` - Staged status
- `{{ .WorktreeCount }}` - Number of linked Git worktrees

**Fetching behavior:**

Oh My Posh v31 fetches optional Git data only when a template references the corresponding field. For example, `.Working` or `.Staging` enables local-status collection, `.BranchStatus` enables ahead/behind data, `.UpstreamIcon` enables upstream metadata, and `.WorktreeCount` enables worktree counting. Use `branch_template` to format or truncate the branch name.

**Common Uses:**

- Show git branch you're on
- Indicate uncommitted changes
- Display upstream status (+/- commits)

---

#### `status`

Displays the exit status of the previous command.

```json
{
 "background_templates": [
  "{{ if .Error }}p:red_alert{{ else }}p:green_success{{ end }}"
 ],
 "foreground": "p:white",
 "properties": {
  "always_show": false,
  "ignore_error": false
 },
 "template": " {{ if .Error }}✗{{ else }}✓{{ end }} ",
 "type": "status"
}
```

**Variables:**

- `{{ .Code }}` - Exit code number
- `{{ .Error }}` - Error message/code (if error)
- `{{ .Success }}` - Boolean, true if successful

**Properties:**

- `always_show`: Boolean - Show even on success
- `ignore_error`: Boolean - Hide on specific errors

**Common Uses:**

- Immediate visual feedback on command success/failure
- Shows exit codes for debugging

---

#### `time`

Displays current date and time.

```json
{
 "background": "p:purple_accent",
 "foreground": "p:white",
 "properties": {
  "time_format": "15:04:05",
  "hide_if_nonzero_exit_code": false
 },
 "template": " 🕒 {{ .CurrentDate | date \"15:04\" }} ",
 "type": "time"
}
```

**Variables:**

- `{{ .CurrentDate }}` - Current timestamp

**Date Format Syntax** (Go template):

```
15:04:05 = HH:MM:SS (24-hour)
3:04:05PM = HH:MM:SS (12-hour)
Jan 02 = Month Day
Monday = Day name
2006 = Year
```

**Common Uses:**

- Show current time
- Track command timing
- Performance monitoring

---

#### `battery`

Displays battery status and percentage.

```json
{
 "background_templates": [
  "{{ if lt .Percentage 20 }}p:red_alert{{ else if lt .Percentage 50 }}p:yellow{{ else }}p:green{{ end }}"
 ],
 "properties": {
  "display_as_percentage": true,
  "charging_icon": "⚡",
  "discharging_icon": "🔋"
 },
 "template": " {{ if lt .Percentage 10 }}🪫{{ else }}🔋{{ end }} {{ .Percentage }}% ",
 "type": "battery"
}
```

**Variables:**

- `{{ .Percentage }}` - Battery percentage (0-100)
- `{{ .State }}` - Charging state
- `{{ .IsCharging }}` - Boolean

**Common Uses:**

- Monitor battery on laptops
- See charging status

---

#### `executiontime`

Displays how long the last command took.

```json
{
 "background": "p:cyan_accent",
 "foreground": "p:black",
 "properties": {
  "threshold": 2000,
  "style": "plain"
 },
 "template": " ⏱️  {{ .FormattedMs }} ",
 "type": "executiontime"
}
```

**Variables:**

- `{{ .FormattedMs }}` - Time (e.g., "5.23s")
- `{{ .Ms }}` - Raw milliseconds
- `{{ .Seconds }}` - Seconds

**Properties:**

- `threshold`: Number - Only show if exceeds (milliseconds)

**Common Uses:**

- Performance monitoring
- Identify slow commands
- Track workflow speed

---

### Version Segment Types

These show version info for runtimes in current directory:

#### `node`

```json
{ "template": " ⬢ {{ .Version }} ", "type": "node" }
```

#### `python`

```json
{ "template": " 🐍 {{ .Version }} ", "type": "python" }
```

#### `ruby`

```json
{ "template": " 💎 {{ .Version }} ", "type": "ruby" }
```

#### `go`

```json
{ "template": " 🐹 {{ .Version }} ", "type": "go" }
```

#### `rust`

```json
{ "template": " 🦀 {{ .Version }} ", "type": "rust" }
```

**Common Pattern:**

```json
{
 "background": "p:node_green",
 "cache": {
  "strategy": "folder",
  "duration": "30m"
 },
 "template": " ⬢ {{ .Version }} ",
 "type": "node"
}
```

---

### System Resource Segments

#### `sysinfo`

Displays CPU, memory, and disk usage.

```json
{
 "background": "p:blue_primary",
 "cache": {
  "strategy": "session",
  "duration": "5s"
 },
 "template": " CPU: {{ .CPUPercentage }}% | RAM: {{ .Memory }}% ",
 "type": "sysinfo"
}
```

---

#### `os`

Displays operating system and WSL status.

```json
{
 "background": "p:gray",
 "template": " {{ .Icon }} {{ .OS }}{{ if .WSL }} (WSL){{ end }} ",
 "type": "os"
}
```

---

### Advanced Segments

#### `command`

Executes custom command and displays output.

```json
{
 "cache": {
  "strategy": "session",
  "duration": "5s"
 },
 "properties": {
  "shell": "powershell",
  "command": "Get-Date -Format 'HH:mm'",
  "parse": true
 },
 "template": "{{ .Output }}",
 "type": "command"
}
```

---

#### `env`

Displays environment variable value.

```json
{
 "properties": {
  "var_name": "ENVIRONMENT"
 },
 "template": " ENV: {{ .Env.ENVIRONMENT }} ",
 "type": "env"
}
```

---

#### `text`

Displays static text or custom template.

```json
{
 "foreground": "p:accent",
 "template": " → ",
 "type": "text"
}
```

---

## Segment Properties Reference

### Universal Segment Properties

All segments support:

```json
{
 // Colors
 "background": "p:palette_key|#hexcolor|transparent",
 "background_templates": [
  "{{ if condition }}p:color1{{ else }}p:color2{{ end }}"
 ],

 // Performance
 "cache": {
  "strategy": "session|folder|windows",
  "duration": "5m",
  "skip_cache": false
 },

 "foreground": "p:palette_key|#hexcolor",
 "leading_diamond": "◆",
 // Type-specific
 "properties": {
  "key": "value"
 },
 // Styling
 "style": "powerline|diamond|plain",
 // Content
 "template": "{{ .Variable }}",

 "trailing_diamond": "◆",

 "type": "segment_type"
}
```

### Style Types

| Style | Symbol | Example | Use Case |
| --- | --- | --- | --- |
| `powerline` | ` ` | Modern, clean | Default choice |
| `diamond` | `◆` | Enclosed | Accent segments |
| `plain` | Nothing | Text only | Simple separators |

---

## Template Functions & Variables

### Common Template Functions

```
{{ if condition }}    ... {{ else }}    ... {{ end }}
{{ with .Variable }} ... {{ end }}
{{ range .Array }} ... {{ end }}
{{ .Variable | upper }}
{{ .Variable | lower }}
{{ .Variable | title }}
{{ len .String }}
{{ eq .Value "text" }}
{{ contains .String "substring" }}
```

### Variables Available

```
{{ .Shell }}              // Current shell
{{ .Path }}               // Current directory
{{ .Branch }}             // Git branch
{{ .Version }}            // Version info
{{ .Error }}              // Last error
{{ .Env.VAR_NAME }}       // Environment variable
{{ .CurrentDate }}        // Current time
{{ .OS }}                 // Operating system
```

### Common Patterns

**Conditional Icon:**

```json
"template": "{{ if .Error }}❌{{ else }}✅{{ end }}"
```

**Conditional Color:**

```json
"background_templates": [
  "{{ if .Error }}p:red{{ else if eq .Value 0 }}p:green{{ else }}p:yellow{{ end }}"
]
```

**Optional Content:**

```json
"template": "{{ if .Branch }}({{ .Branch }}){{ end }}"
```

---

## Palette & Colors Reference

### Defining Colors

```json
{
 "palette": {
  "accent": "#00BCD4", // Hex color
  "blue_primary": "#0080FF",
  "red_alert": "#FF0000"
 }
}
```

### Using Colors

```json
{
 "background": "#FFFFFF", // Direct hex
 "background_templates": [
  "{{ if .Error }}p:red_alert{{ else }}p:accent{{ end }}"
 ],
 "foreground": "p:accent" // Reference palette
}
```

### Color Values

```
#RRGGBB format where each is 00-FF (0-255 decimal)

#FF0000 = Red (255, 0, 0)
#00FF00 = Green (0, 255, 0)
#0000FF = Blue (0, 0, 255)
#FFFFFF = White (255, 255, 255)
#000000 = Black (0, 0, 0)
#808080 = Gray (128, 128, 128)
```

### Converting Colors

```powershell
# Hex to RGB
function Convert-HexToRGB {
    param([string]$Hex)
    $Hex = $Hex -replace '^#', ''
    @{
        R = [Convert]::ToInt32($Hex.Substring(0, 2), 16)
        G = [Convert]::ToInt32($Hex.Substring(2, 2), 16)
        B = [Convert]::ToInt32($Hex.Substring(4, 2), 16)
    }
}

# RGB to Hex
function Convert-RGBToHex {
    param([int]$R, [int]$G, [int]$B)
    "#{0:X2}{1:X2}{2:X2}" -f $R, $G, $B
}
```

---

## Block Configuration

### Block Levels

```json
{
  "version": 3,
  "palette": { ... },
  "blocks": [
    {
      "type": "prompt",
      "alignment": "left|right|rprompt|newline",
      "segments": [ ... ]
    }
  ]
}
```

### Alignment Options

- `left` - Primary prompt line, left-aligned
- `right` - Same line as left, but right-aligned
- `rprompt` - Right prompt (may overflow)
- `newline` - New prompt line

### Example Multi-Line Prompt

```json
{
 "blocks": [
  {
   "alignment": "left",
   "segments": [{ "type": "shell" }, { "type": "path" }, { "type": "git" }]
  },
  {
   "alignment": "right",
   "segments": [{ "type": "time" }, { "type": "battery" }]
  },
  {
   "alignment": "newline",
   "segments": [{ "type": "text", "template": "❯ " }]
  }
 ]
}
```

---

## Common Configurations

### Minimal (Fast) Prompt

```json
{
 "blocks": [
  {
   "segments": [{ "type": "text", "template": "❯ " }]
  }
 ],
 "version": 3
}
```

**Performance:** ~5-10ms

### Quick Prompt (Very Fast)

```json
{
 "blocks": [
  {
   "segments": [
    { "type": "shell" },
    { "type": "path", "properties": { "max_depth": 2 } },
    { "type": "status" }
   ]
  }
 ]
}
```

**Performance:** ~30-50ms

### Balanced Prompt (Good Performance)

```json
{
 "blocks": [
  {
   "segments": [
    { "type": "shell" },
    { "type": "path" },
    {
     "type": "git",
     "style": "plain",
     "template": " {{ .HEAD }} ",
     "cache": { "strategy": "folder", "duration": "5m" }
    },
    { "type": "status" }
   ]
  }
 ]
}
```

**Performance:** ~80-150ms

### Full-Featured Prompt

```json
{
  "blocks": [
    {"alignment": "left", "segments": [...]},
    {"alignment": "right", "segments": [...]},
    {"alignment": "newline", "segments": [...]}
  ]
}
```

**Performance:** ~150-300ms (acceptable)

---

## Segment Combinations

### Development Environment

```json
{
 "segments": [
  { "type": "path" },
  { "type": "git" },
  { "type": "node" },
  { "type": "python" },
  { "type": "status" }
 ]
}
```

### DevOps/Cloud

```json
{
 "segments": [
  { "type": "shell" },
  { "type": "path" },
  { "type": "env", "properties": { "var_name": "ENVIRONMENT" } },
  { "type": "status" }
 ]
}
```

### System Monitoring

```json
{
 "segments": [{ "type": "sysinfo" }, { "type": "battery" }, { "type": "time" }]
}
```

---

## Troubleshooting by Segment

### Segment Not Showing

**Check:**

1. Template is not empty: `"template": ""` hides segment
2. Cache not disabled: `"skip_cache": true` may hide
3. Properties are correct for segment type

**Fix:**

```json
{
 "cache": { "skip_cache": false },
 "template": " {{ .Branch }} ", // Not empty
 "type": "git"
}
```

### Segment Colors Wrong

**Check:**

1. Palette color exists: `"p:nonexistent"` fails
2. Contrast sufficient for readability
3. Terminal supports 256+ colors

**Fix:**

```json
{
 "background": "p:blue_primary",
 "foreground": "p:white" // Verify exists in palette
}
```

### Segment Slow

**Check:**

1. Cache configured correctly
2. Not fetching unnecessary data
3. No expensive command segment

**Fix:**

```json
{
 "type": "git",
 "style": "plain",
 "cache": {
  "strategy": "folder",
  "duration": "5m" // Cache for 5 minutes
 },
 "template": " {{ .HEAD }} "
}
```

The `.HEAD`-only template avoids status and upstream probes. Add `.Working`, `.Staging`, `.BranchStatus`, or `.UpstreamIcon` only when that information is worth its runtime cost.

---

## Quick Reference Table

| Need | Segment Type | Key Property |
| --- | --- | --- |
| Show shell name | `shell` | — |
| Show directory | `path` | `max_depth` |
| Show git info | `git` | Template fields such as `.HEAD`, `.Working`, and `.BranchStatus` |
| Show success/fail | `status` | `always_show` |
| Show time | `time` | `time_format` |
| Show version | `node | python | etc` | — |
| Show resources | `sysinfo` | — |
| Show battery | `battery` | `display_as_percentage` |
| Run custom | `command` | `command` |
| Show variable | `env` | `var_name` |

---

## Summary

**Key Concepts:**

✅ Segments are independent components
✅ Each segment has type, template, styling
✅ Templates use Go syntax with variables
✅ Cache improves performance
✅ Properties vary by segment type
✅ Colors use palette references
✅ Blocks arrange segments on prompt lines

For detailed segment information, check official Oh My Posh docs: https://ohmyposh.dev/docs/segments/

<!-- {% endraw %} -->
