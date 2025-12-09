# ❓ FAQ & Tips & Tricks

## Frequently Asked Questions

### General Questions

#### Q: What is OhMyPosh Atomic Enhanced?

**A:** It's an enhanced fork/variant of the Oh My Posh prompt with carefully curated Atomic-themed color palettes and optimized segment configurations. It provides beautiful, professional-looking shell prompts for Windows PowerShell, Bash, and Zsh.

#### Q: Is it free?

**A:** Yes! All themes are completely free and open-source. The project is maintained on GitHub and available to everyone.

#### Q: Does it work on Windows, macOS, and Linux?

**A:** Yes! We provide cross-platform support with specific setup guides for each platform. See [CROSS-PLATFORM-SETUP-GUIDE.md](./CROSS-PLATFORM-SETUP-GUIDE.md).

#### Q: Is this just for the prompt?

**A:** Primarily yes, but you can also apply the color schemes to your entire terminal emulator for a cohesive look.

---

### Installation & Setup

#### Q: I installed Oh My Posh but the theme isn't showing up

**A:** You need to:

1. Install the theme file
2. Initialize it in your shell profile
3. Reload your shell

See [Quick Start Guide](./QUICK-START-GUIDE.md) for step-by-step instructions.

#### Q: Where do I put the theme file?

**A:** Anywhere convenient. Common locations:

- Windows: `C:\Users\{username}\Documents\OhMyPosh\themes\`
- macOS/Linux: `~/.config/ohmyposh/themes/`
- Or keep it in the cloned repository

#### Q: My Nerd Font isn't installing

**A:**

1. Verify you're downloading from [nerdfonts.com](https://nerdfonts.com)
2. Extract the .ttf files
3. Install by double-clicking or using system font manager
4. Set terminal to use the font (not just named "Nerd Font")
5. Restart terminal after installing

---

### Customization

#### Q: How do I change just the colors?

**A:** Edit the `palette` section of the JSON theme:

```json
{
  "palette": {
    "accent": "#YOUR_COLOR_HERE",
    "blue_primary": "#ANOTHER_COLOR"
  }
}
```

Use [color.adobe.com](https://color.adobe.com) to find colors you like.

#### Q: Can I customize individual segments?

**A:** Yes! Each segment in `blocks` has a `template` property you can modify:

```json
{
  "type": "git",
  "template": "{{ .Branch }} ({{ .UpstreamIcon }})"
}
```

See [ADVANCED-CUSTOMIZATION-GUIDE.md](./ADVANCED-CUSTOMIZATION-GUIDE.md).

#### Q: How do I create a completely custom theme?

**A:** Use the included `New-ThemeWithPalette.ps1` script:

```powershell
.\New-ThemeWithPalette.ps1 -PaletteName "my_custom" -BaseTheme "original"
```

Or manually create a JSON file following the Oh My Posh schema.

#### Q: Can I mix and match segments from different themes?

**A:** Absolutely! The segments are independent. Copy the `blocks` section from one theme and `palette` from another:

```json
{
  "version": 3,
  "palette": {
    // From theme 1
  },
  "blocks": [
    // From theme 2
  ]
}
```

---

### Performance

#### Q: My prompt is slow

**A:** See [PERFORMANCE-OPTIMIZATION-GUIDE.md](./PERFORMANCE-OPTIMIZATION-GUIDE.md)

Quick fixes:

1. Enable caching:

   ```json
   "cache": {"strategy": "folder", "duration": "5m"}
   ```

2. Disable `fetch_status`:

   ```json
   "properties": {"fetch_status": false}
   ```

3. Remove unnecessary segments

#### Q: Why is git status so slow?

**A:** Large repositories take time to check status. Solutions:

1. **Disable status checking entirely:**

   ```json
   { "type": "git", "properties": { "fetch_status": false } }
   ```

2. **Cache aggressively:**

   ```json
   { "cache": { "duration": "10m" } }
   ```

3. **Optimize repository:**
   - Add paths to `.gitignore`
   - Run `git gc` to optimize repository

#### Q: The weather segment is slow

**A:** It makes API calls. Solution:

- Disable it: `"template": ""` (empty template hides segment)
- Or cache it: `"duration": "30m"` (cache for 30 minutes)
- Or remove it entirely from your config

---

### Display Issues

#### Q: Colors look wrong

**A:**

1. Check terminal color scheme matches theme
2. Verify terminal supports 256-color or truecolor
3. Try different terminal emulator (Windows Terminal recommended)
4. Check `$COLORTERM` environment variable

#### Q: Seeing boxes instead of icons

**A:**

1. Nerd Font not installed - see [TROUBLESHOOTING-GUIDE.md](./TROUBLESHOOTING-GUIDE.md#font--glyph-problems)
2. Terminal not using Nerd Font
3. Font file corrupted - reinstall it

#### Q: Prompt wrapping to multiple lines

**A:**

1. Reduce path depth:

   ```json
   { "type": "path", "properties": { "max_depth": 2 } }
   ```

2. Simplify path display
3. Disable unnecessary segments

#### Q: Colors are different every time I open terminal

**A:** Likely caused by:

1. Terminal color scheme changing
2. Oh My Posh version different
3. Theme file in different location

Solution: Use absolute paths in shell config:

```powershell
oh-my-posh init pwsh --config "C:\full\path\to\theme.json"
```

---

### Troubleshooting

#### Q: Theme worked yesterday but not today

**A:** Try:

1. Reload shell: `& $profile` (PowerShell) or `source ~/.bashrc` (Bash)
2. Restart terminal completely
3. Reinstall Oh My Posh: `winget upgrade JanDeDobbeleer.OhMyPosh`
4. Check for profile errors: `Test-Path $PROFILE` then open it

#### Q: Works in VS Code but not Windows Terminal

**A:** VS Code terminal and Windows Terminal are different. Ensure:

1. Windows Terminal has Nerd Font configured
2. PowerShell profile runs in both places
3. Theme file path is absolute (not relative)

#### Q: SSH prompt is different from local

**A:** Remote host has different Oh My Posh version or config. Solutions:

1. Install same Oh My Posh version on remote
2. Copy theme file to remote
3. Use cached/simplified segments on remote

---

## Tips & Tricks

### Pro Tips

#### Tip 1: Use Transient Prompt for Cleaner History

After command execution, show minimal prompt:

```json
{
  "transient_prompt": {
    "background": "transparent",
    "foreground": "p:accent",
    "template": "❯ ",
    "type": "prompt"
  }
}
```

#### Tip 2: Different Prompt for Admin/Root

Detect elevated privileges:

```json
{
  "template": "{{ if .Root }}🔒{{ else }}{{ .Path }}{{ end }}"
}
```

#### Tip 3: Show Exit Code on Errors

Display previous command's result:

```json
{
  "type": "status",
  "background": "red",
  "properties": {
    "template": "✗ {{ .Code }}",
    "always_show": false
  }
}
```

#### Tip 4: Create Theme Variants for Different Use Cases

- **Work theme:** Professional, minimal distractions
- **Dev theme:** Full information, all segments
- **SSH theme:** Performance-optimized, minimal network calls
- **Interview theme:** Simple, impressive, but not overwhelming

#### Tip 5: Use PowerShell Aliases for Themes

```powershell
# In profile
function Use-WorkTheme {
    oh-my-posh init pwsh --config "$HOME\themes\work.json" | Invoke-Expression
}

function Use-DevTheme {
    oh-my-posh init pwsh --config "$HOME\themes\dev.json" | Invoke-Expression
}

# Usage
Use-WorkTheme
```

---

### Customization Tips

#### Tip 1: Match Your Terminal Color Scheme

After choosing a theme, update your terminal's color scheme to match:

```json
{
  "schemes": [
    {
      "name": "Atomic Enhanced Custom",
      "background": "#1E1E1E",
      "foreground": "#D4D4D4"
      // ... rest of colors
    }
  ]
}
```

#### Tip 2: Create Color Aliases

In your palette, create semantic names:

```json
{
  "palette": {
    "accent": "#00BCD4",
    "success": "#00C853",
    "warning": "#FFD600",
    "error": "#FF0000",
    "info": "#2196F3",
    "neutral": "#757575"
  }
}
```

Then use them:

```json
{
  "template": "{{ .Branch }}",
  "foreground": "p:accent"
}
```

#### Tip 3: Conditional Formatting

Show different info based on conditions:

```json
{
  "template": "{{ if .VirtualEnv }}🐍 {{ .VirtualEnv }}{{ end }} {{ .Version }}"
}
```

#### Tip 4: Dynamic Text Based on Exit Code

```json
{
  "type": "status",
  "template": "{{ if eq .Code 0 }}✓{{ else }}✗ {{ .Code }}{{ end }}"
}
```

---

### Performance Tips

#### Tip 1: Progressive Enhancement

Start with a simple, fast prompt:

```json
{
  "blocks": [
    {
      "segments": [
        { "type": "shell" },
        { "type": "path" },
        { "type": "status" }
      ]
    }
  ]
}
```

Then add segments as needed:

```json
{
  "blocks": [
    {
      "segments": [
        { "type": "shell" },
        { "type": "path" },
        { "type": "git" }, // Add git
        { "type": "node" }, // Add version managers
        { "type": "status" }
      ]
    }
  ]
}
```

#### Tip 2: Debug First

Enable debugging to identify slow segments:

```powershell
$env:OHMYPOSH_DEBUG = "true"
& $profile
# Look at timing output
```

#### Tip 3: Cache Aggressively

For most users, 5-10 minute caching is fine:

```json
{
  "cache": {
    "strategy": "folder",
    "duration": "5m" // Good balance
  }
}
```

---

### Integration Tips

#### Tip 1: Visual Differentiation

Use different segments for different environments:

```json
{
  "template": "{{ if eq .Env \"PROD\" }}⚠️ PROD{{ else }}DEV{{ end }}"
}
```

#### Tip 2: SSH Indicator

Show when connected via SSH:

```json
{
  "template": "{{ if env \"SSH_CONNECTION\" }}[SSH] {{ end }}{{ .Path }}"
}
```

#### Tip 3: Virtual Environment Display

For Python developers:

```json
{
  "type": "python",
  "properties": {
    "display_mode": "files",
    "template": "🐍 {{ .Version }} ({{ .Venv }})"
  }
}
```

#### Tip 4: Git Worktrees

If using git worktrees:

```json
{
  "type": "git",
  "properties": {
    "fetch_worktree_count": true
  },
  "template": "{{ .Branch }} ({{ .WorktreeCount }} worktrees)"
}
```

---

### Visual Enhancement Tips

#### Tip 1: Separator Lines

Add visual separation between segments:

```json
{
  "template": "{{ .Path }} | {{ .Branch }}"
}
```

Or use Unicode:

```json
{
  "template": "{{ .Path }} • {{ .Branch }} • {{ .Status }}"
}
```

#### Tip 2: Icons for Sections

Group related information:

```json
{
  "template": "📁 {{ .Path }} | 🔧 {{ .Command }} | ✅ {{ .Status }}"
}
```

#### Tip 3: Padding for Alignment

Use spaces or Unicode for visual alignment:

```json
{
  "template": "{{ .Path | padright 40 }} {{ .Branch }}"
}
```

#### Tip 4: Color Gradient

Use progressively darker/lighter colors for related segments:

```json
{
  "palette": {
    "accent_100": "#00E5FF",
    "accent_80": "#26D4FF",
    "accent_60": "#4DC4FF",
    "accent_40": "#75B4FF",
    "accent_20": "#9DA4FF"
  }
}
```

---

### Workflow Tips

#### Tip 1: Theme for Each Project

Different projects might benefit from different themes:

```powershell
# Project-specific profile snippet
if ($PWD -like "*DevOps*") {
    oh-my-posh init pwsh --config "work.json" | Invoke-Expression
} elseif ($PWD -like "*PersonalProjects*") {
    oh-my-posh init pwsh --config "dev.json" | Invoke-Expression
}
```

#### Tip 2: Time-Based Theme Switching

Change theme based on time of day:

```powershell
$hour = (Get-Date).Hour
if ($hour -ge 17) {
    # After work
    $theme = "relaxed.json"
} else {
    # During work
    $theme = "work.json"
}
oh-my-posh init pwsh --config $theme | Invoke-Expression
```

#### Tip 3: Theme for Specific Hosts

When SSH'ing to different servers:

```bash
case $HOSTNAME in
  server1)
    THEME="production.json"
    ;;
  server2)
    THEME="staging.json"
    ;;
  *)
    THEME="default.json"
    ;;
esac

eval "$(oh-my-posh init bash --config ~/$THEME)"
```

#### Tip 4: Backup Your Configuration

Keep backups of customized themes:

```powershell
# Create backup
Copy-Item "OhMyPosh-Atomic-Custom.json" "OhMyPosh-Atomic-Custom.backup.json"

# Version with Git
git add *.json
git commit -m "Backup custom theme configuration"
```

---

## Common Problems & Solutions

### Table of Quick Fixes

| Problem                | Cause                    | Solution                   |
| ---------------------- | ------------------------ | -------------------------- |
| Slow prompt            | Uncached segments        | Add `"cache"` config       |
| Wrong colors           | Terminal scheme mismatch | Change terminal theme      |
| Boxes instead of icons | No Nerd Font             | Install from nerdfonts.com |
| Theme not applying     | Not initialized          | Run `& $profile`           |
| Git status missing     | `fetch_status: false`    | Set to `true`              |
| Colors flickering      | Frequent refreshes       | Increase cache duration    |
| Wrapping text          | Too many segments        | `max_depth: 2` on path     |

### Troubleshooting Flowchart

```
Issue: Prompt looks wrong
    │
    ├─→ Display incorrect?
    │   ├─→ Icons boxes? → Install Nerd Font
    │   └─→ Colors wrong? → Change terminal scheme
    │
    ├─→ Information missing?
    │   ├─→ Git missing? → Check fetch_status
    │   └─→ Version missing? → Enable version segment
    │
    └─→ Performance poor?
        ├─→ Slow on git? → Cache git status
        └─→ Slow overall? → Remove unnecessary segments
```

---

## Quick Reference

### Most Common Modifications

**Show only current directory (not full path):**

```json
{ "type": "path", "properties": { "max_depth": 1 } }
```

**Hide a segment:**

```json
{ "type": "git", "template": "" }
```

**Disable git status checking:**

```json
{ "type": "git", "properties": { "fetch_status": false } }
```

**Add spacing between segments:**

```json
{ "template": " | {{ .Content }} | " }
```

**Change segment colors:**

```json
{
  "type": "git",
  "background": "#FF0000",
  "foreground": "#FFFFFF"
}
```

---

## Additional Resources

- 📖 [Official Oh My Posh Docs](https://ohmyposh.dev/)
- 🎨 [Color Picker Tool](https://htmlcolorcodes.com/)
- 🔍 [JSON Validator](https://jsonlint.com/)
- 💬 [GitHub Issues](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/issues)
- 📚 [Our Comprehensive Guides](./README.md)

---

## Share Your Customizations

Found a great customization? Share it!

1. Fork the repository
2. Add your theme to the appropriate folder
3. Create a pull request
4. Or share in the GitHub Discussions

---

## Still Have Questions?

1. Check [TROUBLESHOOTING-GUIDE.md](./TROUBLESHOOTING-GUIDE.md)
2. Review [ADVANCED-CUSTOMIZATION-GUIDE.md](./ADVANCED-CUSTOMIZATION-GUIDE.md)
3. See [PERFORMANCE-OPTIMIZATION-GUIDE.md](./PERFORMANCE-OPTIMIZATION-GUIDE.md)
4. Open an [issue on GitHub](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/issues)

We're here to help! 🎉
