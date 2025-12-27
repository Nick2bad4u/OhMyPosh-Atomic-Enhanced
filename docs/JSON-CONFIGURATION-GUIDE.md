<!-- {% raw %} -->

# 🔍 JSON Structure & Configuration Patterns

## Table of Contents

1. [JSON Basics for Oh My Posh](#json-basics-for-oh-my-posh)
2. [Complete JSON Structure](#complete-json-structure)
3. [Configuration Patterns](#configuration-patterns)
4. [Common JSON Mistakes](#common-json-mistakes)
5. [JSON Validation](#json-validation)
6. [Pattern Library](#pattern-library)

---

## JSON Basics for Oh My Posh

### What is JSON?

JSON (JavaScript Object Notation) is a text format for structured data:

```json
{
 "array": [1, 2, 3], // Array (ordered list)
 "boolean": true, // true/false
 "key": "value", // String value
 "number": 42, // Number
 "object": {
  // Nested object
  "nested_key": "value"
 }
}
```

### Rules for Valid JSON

1. **Curly braces** wrap objects: `{ ... }`
2. **Square brackets** wrap arrays: `[ ... ]`
3. **Keys must be strings** in quotes: `"key"`
4. **Values** can be string, number, boolean, array, object, or null
5. **Commas** separate items (but NOT after last item)
6. **No trailing commas** allowed
7. **String values** use double quotes: `"value"`

### Common JSON Errors

```json
// ❌ ERROR: Trailing comma
{
  "key": "value",
}

// ❌ ERROR: Single quotes
{'key': 'value'}

// ❌ ERROR: Unquoted key
{key: "value"}

// ❌ ERROR: Missing comma
{
  "key1": "value1"
  "key2": "value2"
}

// ✅ CORRECT
{
  "key1": "value1",
  "key2": "value2"
}
```

---

## Complete JSON Structure

### Minimal Valid Theme

```json
{
 "blocks": [
  {
   "alignment": "left",
   "segments": []
  }
 ],
 "version": 3
}
```

### Full Theme Structure

```json
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "version": 3,
  "final_space": true,
  "console_title_template": "{{.Folder}}",
  "console_title": "{{ .Shell }} - {{.Folder}}",
  "accent_color": "#00bcd4",

  "tooltip": {
    "text": "{{.Name}}",
    "background": "transparent",
    "foreground": "#000000"
  },

  "palette": {
    "color_name": "#HEXCODE",
    "another_color": "#HEXCODE"
  },

  "blocks": [
    {
      "alignment": "left",
      "segments": [
        {
          "type": "segment_type",
          "background": "p:color_or_#hex",
          "foreground": "p:color_or_#hex",
          "template": "{{ .Variable }}",
          "style": "powerline|diamond|plain",
          "properties": {},
          "cache": {
            "strategy": "session|folder|windows",
            "duration": "5m"
          }
        }
      ]
    },
    {
      "alignment": "right",
      "segments": [...]
    },
    {
      "alignment": "newline",
      "segments": [...]
    }
  ],

  "transient_prompt": {
    "background": "transparent",
    "foreground": "#HEXCODE",
    "template": "❯ "
  }
}
```

### Property Hierarchy

```
Theme Root
├─ Metadata
│  ├─ $schema
│  ├─ version
│  └─ console_title_template
│
├─ Appearance
│  ├─ final_space
│  ├─ accent_color
│  └─ tooltip
│
├─ Colors
│  └─ palette { }
│
├─ Content
│  └─ blocks [ ]
│     └─ segments [ ]
│        ├─ type
│        ├─ template
│        ├─ style
│        ├─ colors
│        ├─ properties
│        └─ cache
│
└─ Post-Execution
   └─ transient_prompt
```

---

## Configuration Patterns

### Pattern 1: Simple Colored Segment

**Goal:** Single segment with one color and simple output

```json
{
 "background": "p:blue_primary",
 "foreground": "p:white",
 "template": " {{ .Shell }} ",
 "type": "shell"
}
```

**When to use:** Status indicators, static segments

---

### Pattern 2: Conditional Colors

**Goal:** Different colors based on state

```json
{
 "background_templates": [
  "{{ if .Error }}p:red_alert{{ else }}p:green_success{{ end }}"
 ],
 "foreground": "p:white",
 "template": " {{ if .Error }}✗{{ else }}✓{{ end }} ",
 "type": "status"
}
```

**When to use:** Status, errors, environment-specific display

---

### Pattern 3: Cached Version Segment

**Goal:** Show version with caching for performance

```json
{
 "background": "p:green_primary",
 "cache": {
  "strategy": "folder",
  "duration": "30m"
 },
 "foreground": "p:black",
 "template": " ⬢ {{ .Version }} ",
 "type": "node"
}
```

**When to use:** Version checks, language runtimes

---

### Pattern 4: Complex Git Segment

**Goal:** Show git info with multiple indicators

```json
{
 "background": "p:yellow_bright",
 "cache": {
  "strategy": "folder",
  "duration": "5m"
 },
 "foreground": "p:black",
 "properties": {
  "fetch_status": true,
  "fetch_upstream_icon": false,
  "branch_max_length": 25
 },
 "template": " {{ if .UpstreamIcon }}{{ .UpstreamIcon }} {{ end }}{{ .Branch }}{{ if .BranchStatus }} ({{ .BranchStatus }}){{ end }} ",
 "type": "git"
}
```

**When to use:** Git-heavy workflows, showing branch status

---

### Pattern 5: Custom Command

**Goal:** Run custom logic and display result

```json
{
 "background": "p:purple_accent",
 "cache": {
  "strategy": "session",
  "duration": "1s"
 },
 "properties": {
  "shell": "powershell",
  "command": "Get-Date -Format 'HH:mm:ss'"
 },
 "template": "{{ .Output }}",
 "type": "command"
}
```

**When to use:** Custom data, dynamic info

---

### Pattern 6: Multi-Line Prompt

**Goal:** Create left, right, and newline segments

```json
{
 "blocks": [
  {
   "alignment": "left",
   "segments": [{ "type": "shell" }, { "type": "path" }]
  },
  {
   "alignment": "right",
   "segments": [{ "type": "time" }]
  },
  {
   "alignment": "newline",
   "segments": [{ "type": "text", "template": "❯ " }]
  }
 ]
}
```

**When to use:** Complex prompts, information-dense displays

---

### Pattern 7: Transient Prompt

**Goal:** Show simple prompt after command execution

```json
{
 "transient_prompt": {
  "background": "transparent",
  "foreground": "p:accent_color",
  "template": "❯ "
 }
}
```

**When to use:** Reducing visual clutter, faster re-prompts

---

### Pattern 8: Palette with Gradients

**Goal:** Create color variations for transitions

```json
{
 "palette": {
  "blue_bright": "#00E5FF", // 100% brightness
  "blue_normal": "#0080FF", // 50% brightness
  "blue_dim": "#004B99", // 30% brightness

  "blue_sat_high": "#0080FF", // 100% saturation
  "blue_sat_med": "#4DB8DD", // 60% saturation
  "blue_sat_low": "#8FBDD9" // 30% saturation
 }
}
```

**When to use:** Creating elegant color transitions, visual hierarchy

---

## Common JSON Mistakes

### ❌ Mistake 1: Trailing Commas

```json
{
 "segments": [
  { "type": "shell" },
  { "type": "path" } // ❌ Trailing comma here!
 ]
}
```

**Fix:**

```json
{
 "segments": [
  { "type": "shell" },
  { "type": "path" } // ✅ No comma
 ]
}
```

---

### ❌ Mistake 2: Missing Commas

```json
{
  "type": "git"
  "template": "{{ .Branch }}"  // ❌ Missing comma!
}
```

**Fix:**

```json
{
 "template": "{{ .Branch }}", // ✅ Comma added
 "type": "git"
}
```

---

### ❌ Mistake 3: Single Quotes Instead of Double

```json
{
 "template": "...",
 "type": "git" // ❌ Single quotes not allowed
}
```

**Fix:**

```json
{
 "template": "...",
 "type": "git" // ✅ Double quotes
}
```

---

### ❌ Mistake 4: Unquoted Keys

```json
{
 "template": "...",
 "type": "git" // ❌ Key not quoted
}
```

**Fix:**

```json
{
 "template": "...",
 "type": "git" // ✅ Key quoted
}
```

---

### ❌ Mistake 5: Newlines in Strings

```json
{
  "template": "{{ .Branch }}
{{ .Status }}"     // ❌ Can't have real newlines in JSON
}
```

**Fix:**

```json
{
 "template": "{{ .Branch }}\n{{ .Status }}" // ✅ Use \n
}
```

---

### ❌ Mistake 6: Missing Quotes Around Values

```json
{
  "number": 42,          // ✅ OK - numbers don't need quotes
  "boolean": true,       // ✅ OK - booleans don't need quotes
  "string": some text    // ❌ String needs quotes!
}
```

**Fix:**

```json
{
 "boolean": true,
 "number": 42,
 "string": "some text" // ✅ Quoted
}
```

---

### ❌ Mistake 7: Comments (Not Allowed)

```json
{
 // This is a comment - NOT allowed in JSON!
 "template": "{{ .Branch }}",
 "type": "git"
}
```

**Fix:**

```json
{
 "template": "{{ .Branch }}",
 "type": "git"
}
```

**Note:** You can remove comments before uploading, but JSON doesn't officially support them.

---

### ❌ Mistake 8: Incorrect Nesting

```json
{
  "segments": [
    "type": "git"    // ❌ Should be object, not string
  ]
}
```

**Fix:**

```json
{
 "segments": [
  { "type": "git" } // ✅ Proper object
 ]
}
```

---

## JSON Validation

### Online Tools

- **[JSONLint](https://jsonlint.com/)** - Online validator
- **[JSON.parse() tester](https://jsfiddle.net/)** - JavaScript tester

### PowerShell Validation

```powershell
# Test if JSON is valid
function Test-JSON {
    param([string]$FilePath)

    try {
        $json = Get-Content $FilePath | ConvertFrom-Json
        Write-Host "✅ Valid JSON" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Invalid JSON:" -ForegroundColor Red
        Write-Host $_.Exception.Message
        return $false
    }
}

# Usage
Test-JSON "C:\path\to\theme.json"
```

### VS Code Validation

VS Code has built-in JSON validation:

1. Open JSON file in VS Code
2. Look for red squiggles (errors)
3. Hover over error for details
4. Ctrl+Shift+P → "Format Document" to auto-fix

---

## Pattern Library

### Copy-Paste Ready Patterns

#### Pattern: Development Environment

```json
{
 "blocks": [
  {
   "alignment": "left",
   "segments": [
    {
     "type": "shell",
     "background": "p:blue_primary",
     "foreground": "p:white",
     "template": " {{ .Shell }} "
    },
    {
     "type": "path",
     "background": "p:orange_accent",
     "foreground": "p:black",
     "template": "  {{ .Path }} ",
     "properties": { "max_depth": 3 }
    },
    {
     "type": "git",
     "background": "p:yellow_warn",
     "foreground": "p:black",
     "template": " {{ .Branch }} ",
     "cache": { "strategy": "folder", "duration": "5m" },
     "properties": { "fetch_status": false }
    },
    {
     "type": "status",
     "background_templates": [
      "{{ if .Error }}p:red_error{{ else }}p:green_success{{ end }}"
     ],
     "foreground": "p:white",
     "template": " {{ if .Error }}✗{{ else }}✓{{ end }} "
    }
   ]
  },
  {
   "alignment": "newline",
   "segments": [
    {
     "type": "text",
     "template": "❯ ",
     "foreground": "p:blue_primary"
    }
   ]
  }
 ],
 "palette": {
  "blue_primary": "#0080FF",
  "orange_accent": "#FF6B35",
  "yellow_warn": "#FFD600",
  "green_success": "#00C853",
  "red_error": "#FF0000",
  "white": "#FFFFFF",
  "black": "#000000"
 },
 "version": 3
}
```

#### Pattern: Minimal Fast Prompt

```json
{
 "blocks": [
  {
   "segments": [
    {
     "type": "path",
     "background": "p:accent",
     "template": " {{ .Path }} ",
     "properties": { "max_depth": 1 }
    },
    {
     "type": "status",
     "background_templates": [
      "{{ if .Error }}#FF0000{{ else }}#00AA00{{ end }}"
     ],
     "template": " {{ if .Error }}✗{{ else }}✓{{ end }} "
    }
   ]
  }
 ],
 "palette": {
  "accent": "#00BCD4"
 },
 "version": 3
}
```

#### Pattern: Information Dense

```json
{
 "blocks": [
  {
   "alignment": "left",
   "segments": [
    { "type": "shell" },
    { "type": "path" },
    { "type": "git" },
    { "type": "node" },
    { "type": "python" },
    { "type": "status" }
   ]
  },
  {
   "alignment": "right",
   "segments": [{ "type": "time" }, { "type": "battery" }]
  },
  {
   "alignment": "newline",
   "segments": [{ "type": "text", "template": "❯ " }]
  }
 ],
 "version": 3
}
```

---

## Summary

**JSON Structure Checklist:**

- [ ] All strings in double quotes
- [ ] All keys in double quotes
- [ ] Commas between items (not after last)
- [ ] No trailing commas
- [ ] Proper nesting (braces/brackets)
- [ ] All braces/brackets properly closed
- [ ] Valid color formats (#HEXCODE or palette reference)
- [ ] Template syntax correct ({{ .Variable }})

**For Quick Validation:**

1. Paste into [JSONLint](https://jsonlint.com/)
2. Or test with PowerShell: `Get-Content file.json | ConvertFrom-Json`
3. Or use VS Code and look for red squiggles

**For More Help:**

- See [COMPLETE-SEGMENT-REFERENCE.md](./COMPLETE-SEGMENT-REFERENCE.md) for segment options
- See [COLOR-THEORY-GUIDE.md](./COLOR-THEORY-GUIDE.md) for color selection
- See [ADVANCED-CUSTOMIZATION-GUIDE.md](./ADVANCED-CUSTOMIZATION-GUIDE.md) for advanced techniques
<!-- {% endraw %} -->
