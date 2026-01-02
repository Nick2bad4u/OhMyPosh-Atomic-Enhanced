<!-- {% raw %} -->

# 🆘 Comprehensive Troubleshooting Guide

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Color & Display Issues](#color--display-issues)
3. [Font & Glyph Problems](#font--glyph-problems)
4. [Performance Issues](#performance-issues)
5. [Shell-Specific Issues](#shell-specific-issues)
6. [Platform-Specific Issues](#platform-specific-issues)
7. [Integration Issues](#integration-issues)
8. [Configuration Problems](#configuration-problems)
9. [Advanced Diagnostics](#advanced-diagnostics)

---

## Quick Diagnostics

### Step 1: Verify Oh My Posh Installation

```powershell
# Check if Oh My Posh is installed
Get-Command oh-my-posh

# Check version
oh-my-posh --version

# Test basic functionality
oh-my-posh get shell
```

**If command not found:**

- Install Oh My Posh: https://ohmyposh.dev/docs/installation/windows
- Verify it's in PATH: `$env:PATH -split ';'`

### Step 2: Validate Theme File

```powershell
# Validate JSON syntax
$theme = Get-Content ".\OhMyPosh-Atomic-Custom.json" | ConvertFrom-Json

# Check palette references
$palette = $theme.palette
$paletteKeys = $palette.PSObject.Properties | ForEach-Object { $_.Name }
Write-Host "Palette keys: $($paletteKeys.Count)"
```

### Step 3: Test Theme in Clean Session

```powershell
# Launch new PowerShell window without profile
powershell -NoProfile

# Inside new session, initialize theme
oh-my-posh init pwsh --config ".\OhMyPosh-Atomic-Custom.json" | Invoke-Expression

# If this works, issue is in profile configuration
```

---

## Color & Display Issues

### Problem: Colors Not Displaying (All Black/White)

**Cause:** Terminal not configured for ANSI colors or theme using unsupported color format.

**Solutions:**

1. **Check Terminal Color Support**

   ```powershell
   # Display color capability
   $env:COLORTERM
   $env:TERM

   # Should show: truecolor, 24bit, or 256color
   ```

2. **Enable ANSI Escape Sequence Support (Windows)**

   ```powershell
   # In PowerShell 6+, ANSI support is automatic
   # For Windows PowerShell 5.1, may need Windows Terminal

   # Check if running Windows Terminal
   if ($env:WT_SESSION) {
       Write-Host "Running in Windows Terminal"
   }
   ```

3. **Test Direct Color Output**

   ```powershell
   $esc = [char]27
   $reset = "$esc[0m"

   # Test 16-color
   Write-Host "$esc[31mRed text$reset"

   # Test 256-color
   Write-Host "$esc[38;5;196mRed text (256)$reset"

   # Test Truecolor
   Write-Host "$esc[38;2;255;0;0mRed text (RGB)$reset"
   ```

4. **Switch to Basic 16-Color Mode**
   ```powershell
   # Modify theme temporarily to use only basic colors
   # Replace palette with:
   "palette": {
       "red": "#FF0000",
       "green": "#00FF00",
       "blue": "#0000FF"
   }
   ```

### Problem: Wrong Colors Displayed

**Cause:** Terminal color interpretation differs from theme expectations.

**Solutions:**

1. **Check Terminal Color Scheme**
   - Windows Terminal: Settings > Appearance > Color scheme
   - VS Code: Integrated terminal uses editor theme
   - Verify scheme matches theme design intent

2. **Generate Theme for Your Terminal**

   ```powershell
   # Test different palettes to find best match
   .\scripts\New-ThemeWithPalette.ps1 -PaletteName "nord_frost"
   .\scripts\New-ThemeWithPalette.ps1 -PaletteName "dracula_night"
   ```

3. **Manually Adjust Palette Colors**

   ```powershell
   # Extract palette
   $theme = Get-Content "OhMyPosh-Atomic-Custom.json" | ConvertFrom-Json

   # Modify specific colors
   $theme.palette.blue_primary = "#0080FF"

   # Save modified theme
   $theme | ConvertTo-Json -Depth 100 | Set-Content "Modified.json"
   ```

### Problem: Colors Flickering or Blinking

**Cause:** Segment refresh too frequent or caching not working.

**Solutions:**

1. **Increase Cache Duration**

   ```json
   {
    "cache": {
     "strategy": "folder",
     "duration": "10m"
    },
    "type": "git"
   }
   ```

2. **Reduce Refresh-Rate Segments**

   ```json
   {
    "cache": {
     "duration": "1s"
    },
    "type": "time"
   }
   ```

3. **Disable Non-Essential Segments**
   Remove segments that update frequently but aren't critical.

---

## Font & Glyph Problems

### Problem: Strange Characters/Boxes Instead of Icons

**Cause:** Terminal not using a Nerd Font or font doesn't include required glyphs.

**Solutions:**

1. **Install a Nerd Font**
   - Download from [nerdfonts.com](https://nerdfonts.com)
   - Recommended: Noto Nerd Font, FiraCode Nerd Font, JetBrains Mono Nerd Font

   **Windows:**

   ```powershell
   # Download font
   # Right-click .ttf file > Install
   # Or use WinGet:
   winget install "Nerd Font" -e
   ```

   **macOS:**

   ```bash
   brew tap homebrew/cask-fonts
   brew install --cask font-noto-nerd-font
   ```

   **Linux:**

   ```bash
   # Fedora
   sudo dnf install noto-fonts-nerd

   # Ubuntu/Debian
   sudo apt-get install fonts-noto-nerd
   ```

2. **Configure Terminal to Use Nerd Font**
   - **Windows Terminal**: Settings > Appearance > Font face
   - **VS Code**: settings.json:
     ```json
     {
      "terminal.integrated.fontFamily": "\"FiraCode Nerd Font\""
     }
     ```
   - **PowerShell Profile**:
     ```powershell
     # Some terminals read from console font
     # Windows Terminal: Settings UI
     ```

3. **Test Font Installation**

   ```powershell
   # Display test string with Nerd Font glyphs
   Write-Host "⬢ ⚡ 🐍 ☸ 📦 🔧"

   # If you see boxes, font not installed correctly
   ```

4. **Fallback to Basic Icons**
   ```json
   {
    "template": "{{ .Name }} [{{ .Branch }}]" // No icons
   }
   ```

### Problem: Misaligned or Overlapping Text

**Cause:** Terminal font rendering or character width calculation issues.

**Solutions:**

1. **Use Monospace Font Exclusively**
   - Ensure selected font is monospaced
   - Proportional fonts break prompt alignment

2. **Test Font Rendering**

   ```powershell
   # Display aligned text
   $text = "█████████████████████"
   Write-Host $text
   Write-Host $text  # Should align exactly
   ```

3. **Adjust Template Spacing**
   ```json
   {
    "template": "{{ .Content }}" // Remove extra spaces
   }
   ```

---

## Performance Issues

### Problem: Prompt Displays Slowly / Hangs

**Cause:** Expensive segment calculations or missing caching configuration.

**Solutions:**

1. **Identify Slow Segment**

   ```powershell
   # Enable debug output
   $env:OHMYPOSH_DEBUG = $true

   # Reload prompt and check which segment is slow
   & $profile

   # Disable debug
   $env:OHMYPOSH_DEBUG = $false
   ```

2. **Implement Aggressive Caching**

   ```json
   {
    "cache": {
     "strategy": "folder",
     "duration": "5m" // Cache for 5 minutes
    },
    "type": "git"
   }
   ```

3. **Disable Slow Segments Temporarily**

   ```json
   {
    "properties": { "command": "expensive_script.ps1" },
    "template": "", // Hide temporarily
    "type": "command"
   }
   ```

4. **Profile Segment Performance**
   ```powershell
   $sw = [System.Diagnostics.Stopwatch]::StartNew()
   oh-my-posh get shell
   $sw.Elapsed.TotalMilliseconds  # Should be < 100ms
   ```

### Problem: High CPU Usage

**Cause:** Segments running expensive commands frequently.

**Solutions:**

1. **Reduce Update Frequency**

   ```json
   {
    "cache": {
     "strategy": "session",
     "duration": "10m"
    }
   }
   ```

2. **Disable Weather Segment** (Often expensive)

   ```json
   {
    "template": "", // Disable
    "type": "owm"
   }
   ```

3. **Remove Upstream Git Status** (Network-dependent)

   ```json
   {
    "properties": {
     "fetch_status": false,
     "fetch_upstream_icon": false
    },
    "type": "git"
   }
   ```

4. **Optimize Custom Commands**

   ```powershell
   # ❌ SLOW: Reading entire directory
   Get-ChildItem -Recurse | Measure-Object

   # ✅ FAST: Only check current directory
   Get-ChildItem | Measure-Object
   ```

---

## Shell-Specific Issues

### PowerShell 5.1 (Windows PowerShell)

**Problem: Oh My Posh not initializing**

**Solution:**

```powershell
# Windows PowerShell doesn't support ANSI codes well
# Use Windows Terminal instead (free from Microsoft Store)

# Or use module approach:
# https://ohmyposh.dev/docs/installation/windows#installation
```

### PowerShell 7+ (pwsh)

**Problem: Theme not applied after profile loads**

**Solution:**

```powershell
# Check profile location
$PROFILE  # Defaults to C:\Users\{user}\Documents\PowerShell\profile.ps1

# Add to profile:
oh-my-posh init pwsh --config $env:POSH_THEMES_PATH\OhMyPosh-Atomic-Custom.json | Invoke-Expression

# Reload profile
& $profile
```

### Git Bash / MINGW64

**Problem: Theme not displaying or git segment not working**

**Solution:**

```bash
# Add to ~/.bashrc
eval "$(oh-my-posh init bash --config ~/path/to/theme.json)"

# Git Bash may need explicit PATH
export PATH="$PATH:/c/Program Files/Oh\ My\ Posh"
```

### WSL (Windows Subsystem for Linux)

**Problem: Colors not displaying in WSL terminal**

**Solution:**

```bash
# WSL1: May not support ANSI colors well
# WSL2: Full support with Windows Terminal

# Verify in WSL:
echo $TERM
# Should show: xterm-256color or better

# Install Oh My Posh in WSL:
curl -s https://ohmyposh.dev/install.sh | bash -s
```

---

## Platform-Specific Issues

### Windows Issues

**Problem: Command not found when running from PowerShell**

**Solution:**

```powershell
# Install via WinGet (modern method)
winget install JanDeDobbeleer.OhMyPosh

# Or manually add to PATH
$ohMyPosh = "C:\Program Files\oh-my-posh\bin"
[Environment]::SetEnvironmentVariable(
    "PATH",
    [Environment]::GetEnvironmentVariable("PATH") + ";$ohMyPosh",
    [EnvironmentVariableTarget]::User
)

# Verify
oh-my-posh --version
```

**Problem: Long paths cause slow performance**

**Solution:**

```json
{
 "properties": {
  "max_depth": 2,
  "truncation_mode": "start"
 },
 "type": "path"
}
```

### macOS Issues

**Problem: Brew install of Oh My Posh not in PATH**

**Solution:**

```bash
# Brew installs to specific location
eval "$(oh-my-posh init zsh)"

# Or add to .zshrc:
export PATH="/opt/homebrew/bin:$PATH"
```

**Problem: Font rendering issues in iTerm2**

**Solution:**

```
iTerm2 Preferences > Profiles > Text > Font
- Select "Noto Nerd Font" or similar
- Enable "Use Ligatures"
```

### Linux Issues

**Problem: Theme works in GUI terminal but not SSH**

**Solution:**

```bash
# SSH terminal may be limited
# Set TERM variable:
export TERM=xterm-256color

# Add to ~/.bashrc or ~/.zshrc
ssh -t user@host "TERM=xterm-256color bash"
```

**Problem: Slow performance over SSH**

**Solution:**

```json
{
 "cache": {
  "strategy": "session",
  "duration": "10m"
 },
 "properties": {
  "fetch_status": false // Disable expensive operations
 }
}
```

---

## Integration Issues

### VS Code Integrated Terminal

**Problem: Colors wrong or not showing**

**Solutions:**

1. **Check Terminal Color Theme**
   - Command Palette > Preferences: Open Settings (JSON)
   - Check `"workbench.colorTheme"`

2. **Configure Terminal Font**

   ```json
   {
    "terminal.integrated.enableBell": false,
    "terminal.integrated.fontFamily": "\"FiraCode Nerd Font\"",
    "terminal.integrated.fontSize": 12
   }
   ```

3. **Use Windows Terminal Profile in VS Code**
   ```json
   {
    "terminal.external.windowsExec": "wt.exe",
    "terminal.integrated.defaultProfile.windows": "PowerShell"
   }
   ```

### Windows Terminal

**Problem: Changes not applying**

**Solutions:**

1. **Save and Reload**
   - Settings > Save (Ctrl+S)
   - Close and reopen terminal

2. **Modify settings.json Directly**
   ```json
   {
    "profiles": {
     "defaults": {
      "font": {
       "face": "FiraCode Nerd Font",
       "size": 11
      }
     }
    }
   }
   ```

---

## Configuration Problems

### Problem: Theme File Not Found

**Solutions:**

```powershell
# Use absolute path
oh-my-posh init pwsh --config "C:\full\path\theme.json"

# Use $env variable
$env:POSH_THEME = "C:\Users\{user}\Documents\theme.json"
oh-my-posh init pwsh --config $env:POSH_THEME
```

### Problem: Invalid JSON in Theme File

**Solutions:**

```powershell
# Validate JSON
try {
    $theme = Get-Content "theme.json" | ConvertFrom-Json
    Write-Host "JSON is valid"
} catch {
    Write-Host "JSON error: $_"
}

# Use online JSON validator
# https://jsonlint.com/
```

### Problem: Palette Key Referenced But Not Defined

**Solutions:**

```powershell
# Run validation script
.\scripts\validate-palette.ps1

# Check for typos
$theme = Get-Content "theme.json" | ConvertFrom-Json
$missing = $theme | Select-String "p:[a-z_]*" -AllMatches | ForEach-Object { $_.Matches.Value }
```

---

## Advanced Diagnostics

### Enable Debug Logging

```powershell
# Enable Oh My Posh debug
$env:OHMYPOSH_DEBUG = $true

# Reload
& $profile

# Output will show timing for each segment
```

### Performance Profiling

```powershell
# Measure prompt generation time
$sw = [System.Diagnostics.Stopwatch]::StartNew()
oh-my-posh print primary
$sw.Elapsed.TotalMilliseconds

# Goal: < 300ms
```

### Check All Environment Variables

```powershell
# Variables Oh My Posh checks
$env:POSH_THEME
$env:OHMYPOSH_DEBUG
$env:WT_SESSION
$env:TERM
$env:COLORTERM

# Terminal info
$PSVersionTable.OS
```

### Test Individual Segments

```powershell
# Parse theme and test each segment
$theme = Get-Content "theme.json" | ConvertFrom-Json

foreach ($block in $theme.blocks) {
    foreach ($segment in $block.segments) {
        Write-Host "Testing: $($segment.type)"
        oh-my-posh get segment --template $segment.template --type $segment.type
    }
}
```

### Create Debug Configuration

```json
{
 "blocks": [
  {
   "alignment": "left",
   "segments": [
    {
     "type": "shell",
     "background": "#FF0000",
     "foreground": "#FFFFFF",
     "template": "SHELL"
    }
   ]
  }
 ],
 "final_space": true,
 "version": 3
}
```

If this simple config works, issue is with segment properties.

---

## Getting Help

### Provide Diagnostic Information

When asking for help, include:

```powershell
# Collect diagnostic info
$diag = @{
    "oh-my-posh version" = oh-my-posh --version
    "PowerShell version" = $PSVersionTable.PSVersion
    "Platform" = $PSVersionTable.OS
    "Terminal" = $env:WT_SESSION ?? $env:TERM
    "Theme file" = Get-Content "theme.json" -Raw
}

$diag | ConvertTo-Json
```

### Common Resources

- **Oh My Posh Docs**: https://ohmyposh.dev/docs
- **Issues/Bug Reports**: https://github.com/JanDeDobbeleer/oh-my-posh/issues
- **Nerd Fonts**: https://nerdfonts.com
- **ANSI Escape Codes**: https://en.wikipedia.org/wiki/ANSI_escape_code

---

## Quick Reference Checklist

- [ ] Oh My Posh installed and in PATH
- [ ] Theme JSON validates (no syntax errors)
- [ ] Terminal supports ANSI colors
- [ ] Nerd Font installed and configured
- [ ] PowerShell profile runs without errors
- [ ] Segments render with correct colors
- [ ] Performance acceptable (< 300ms)
- [ ] All custom palettes defined
- [ ] Cache strategy configured

---

## Summary

Common issue categories:

1. **Installation**: Ensure Oh My Posh properly installed
2. **Colors**: Check terminal color mode and theme palette
3. **Fonts**: Install and configure Nerd Font
4. **Performance**: Cache aggressively, disable expensive segments
5. **Shell/Platform**: Use appropriate Oh My Posh for your environment
6. **Configuration**: Validate JSON, check palette references

Most issues fall into one of these categories. Follow the relevant section for your specific problem.

<!-- {% endraw %} -->
