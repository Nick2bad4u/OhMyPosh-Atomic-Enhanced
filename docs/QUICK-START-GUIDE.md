# 🚀 Quick Start Guide

**Get a beautiful Oh My Posh Atomic Enhanced prompt in 5 minutes!**

## Prerequisites Checklist

Before starting, you'll need:

- [ ] PowerShell 7+ (Windows) OR Bash/Zsh (macOS/Linux)
- [ ] Administrator access (for first-time setup)
- [ ] Internet connection

---

## Step 1: Install Oh My Posh (2 minutes)

### Windows

```powershell
# Open PowerShell as Administrator and run:
winget install JanDeDobbeleer.OhMyPosh
```

### macOS

```bash
# Install via Homebrew
brew install oh-my-posh
```

### Linux

```bash
# Install via package manager or direct download
# Ubuntu/Debian:
sudo apt-get install oh-my-posh

# Fedora:
sudo dnf install oh-my-posh

# Arch:
yay -S oh-my-posh

# Or universal installer:
curl -s https://ohmyposh.dev/install.sh | bash -s
```

**Verify installation:**

```powershell
oh-my-posh --version
# Output: 18.x.x (or similar)
```

---

## Step 2: Install a Nerd Font (2 minutes)

The prompt uses special characters that require a **Nerd Font**.

### Option A: Recommended - FiraCode Nerd Font

1. Go to [nerdfonts.com](https://www.nerdfonts.com/)
2. Download "FiraCode Nerd Font"
3. Extract the `.zip` file
4. Install all `.ttf` files:
   - **Windows:** Double-click each .ttf file → Click "Install"
   - **macOS:** Double-click each .ttf file → Click "Install Font"
   - **Linux:** Copy .ttf files to `~/.local/share/fonts/` then run `fc-cache -fv`

### Option B: Alternative Fonts

Any Nerd Font will work. Popular alternatives:

- JetBrains Mono Nerd Font
- Meslo Nerd Font
- Ubuntu Mono Nerd Font

### Verify Font Installation

See special characters display:

```powershell
Write-Host "✓ ✗ → ← ↑ ↓ 🔧 ⚡"
# Should display: ✓ ✗ → ← ↑ ↓ 🔧 ⚡
```

If you see boxes instead, the font isn't installed or selected. See [TROUBLESHOOTING-GUIDE.md](./TROUBLESHOOTING-GUIDE.md#fonts--glyphs).

---

## Step 3: Configure Your Shell (1 minute)

### For PowerShell

1. **Open PowerShell profile:**

   ```powershell
   notepad $PROFILE
   ```

2. **Add this line at the bottom:**

   ```powershell
   oh-my-posh init pwsh --config "$env:PROGRAMFILES\oh-my-posh\themes\atomic.omp.json" | Invoke-Expression
   ```

3. **Save the file (Ctrl+S)**

4. **Reload profile:**
   ```powershell
   & $PROFILE
   ```

### For Bash/Zsh (macOS/Linux)

1. **Edit your shell config:**

   ```bash
   # For Bash
   nano ~/.bashrc

   # For Zsh
   nano ~/.zshrc
   ```

2. **Add this line at the bottom:**

   ```bash
   eval "$(oh-my-posh init bash --config ~/path/to/OhMyPosh-Atomic-Custom.json)"
   # or for Zsh:
   eval "$(oh-my-posh init zsh --config ~/path/to/OhMyPosh-Atomic-Custom.json)"
   ```

3. **Save and exit** (Ctrl+O, Enter, Ctrl+X)

4. **Reload:**
   ```bash
   source ~/.bashrc
   # or
   source ~/.zshrc
   ```

---

## Step 4: Configure Your Terminal's Font (1 minute)

The prompt requires the terminal to use the Nerd Font.

### Windows Terminal

1. **Open Windows Terminal Settings** (Ctrl+,)
2. **Go to: Settings → Profiles → PowerShell**
3. **Under "Appearance" tab:**
   - Find "Font face"
   - Select "FiraCode Nerd Font" (or your font)
4. **Click "Save"**

### VS Code

1. **Open settings.json** (Ctrl+Shift+P → "settings.json")
2. **Add or update:**
   ```json
   {
     "terminal.integrated.fontFamily": "FiraCode Nerd Font"
   }
   ```
3. **Save**

### macOS Terminal/iTerm2

1. **Go to Preferences → Profiles → Text**
2. **Set Font:** Click "Change" → Select your Nerd Font
3. **Apply**

### GNOME Terminal (Linux)

1. **Edit → Preferences → Unnamed Profile**
2. **Uncheck "Use system font"**
3. **Select your Nerd Font**

---

## Step 5: Verify Installation (Done!)

Close your terminal completely and open a new window.

**You should see:**

```
❯
```

With your current directory, git branch (if in a repo), and exit status.

**If you don't see the prompt:**

- Reload shell: `& $PROFILE` (PowerShell) or `source ~/.bashrc` (Bash)
- Or restart terminal completely

---

## 🎉 Success!

Your Oh My Posh Atomic Enhanced prompt is ready!

### What You Get

The prompt displays:

- ✅ Current directory with icons for different file types
- ✅ Git branch and status (if in a git repository)
- ✅ Exit status of last command (✓ or ✗)
- ✅ Execution time for long commands
- ✅ Custom color scheme

### Next Steps

Want to customize further?

1. **Change the theme:** See [ADVANCED-CUSTOMIZATION-GUIDE.md](./ADVANCED-CUSTOMIZATION-GUIDE.md)
2. **Optimize for speed:** See [PERFORMANCE-OPTIMIZATION-GUIDE.md](./PERFORMANCE-OPTIMIZATION-GUIDE.md)
3. **Add to other tools:** See [INTEGRATION-GUIDES.md](./INTEGRATION-GUIDES.md)
4. **Create custom colors:** See [COLOR-THEORY-GUIDE.md](./COLOR-THEORY-GUIDE.md)

---

## Troubleshooting

### Prompt doesn't show

**Try:**

1. Close terminal completely, open new window
2. Reload: `& $PROFILE` (PowerShell) or `source ~/.bashrc` (Bash)
3. Check path is correct: `oh-my-posh --version`

### Icons are boxes

**The font didn't install properly:**

1. Download font again from [nerdfonts.com](https://www.nerdfonts.com/)
2. Install to system fonts
3. Restart terminal
4. Set terminal to use the font

### Colors look wrong

**Terminal color scheme issue:**

1. Your terminal might have a different color scheme
2. Update terminal colors to match theme
3. Or switch to a different color scheme

### Still stuck?

See [TROUBLESHOOTING-GUIDE.md](./TROUBLESHOOTING-GUIDE.md) for more help or [FAQ-AND-TIPS-TRICKS.md](./FAQ-AND-TIPS-TRICKS.md) for common questions.

---

## Common Commands

Once installed, useful commands:

```powershell
# Show current configuration
oh-my-posh config

# List all built-in themes
oh-my-posh config list

# Change theme
oh-my-posh init pwsh --config "path/to/theme.json" | Invoke-Expression

# Debug mode
$env:OHMYPOSH_DEBUG = "true"
& $PROFILE
```

---

## System Requirements

| Component  | Windows                      | macOS    | Linux    |
| ---------- | ---------------------------- | -------- | -------- |
| PowerShell | 7.0+                         | —        | —        |
| Bash/Zsh   | —                            | Included | Included |
| Oh My Posh | Latest                       | Latest   | Latest   |
| Nerd Font  | Required                     | Required | Required |
| Terminal   | Windows Terminal recommended | iTerm2+  | Any      |

---

## File Locations

| Item         | Windows                           | macOS                              | Linux                          |
| ------------ | --------------------------------- | ---------------------------------- | ------------------------------ |
| Shell Config | `$PROFILE`                        | `~/.zshrc` or `~/.bashrc`          | `~/.bashrc` or `~/.zshrc`      |
| Themes       | `Program Files\oh-my-posh\themes` | `/usr/local/opt/oh-my-posh/themes` | `/usr/share/oh-my-posh/themes` |
| Custom       | Anywhere                          | Anywhere                           | Anywhere                       |

---

## What's Different About Atomic Enhanced?

The Atomic Enhanced theme includes:

- ✨ Carefully selected color palettes (16+ variants)
- ⚡ Performance-optimized segment configuration
- 🎨 Modern, professional appearance
- 🔄 Git status with custom icons
- 📁 Directory structure display
- ⏱️ Execution time display
- 🔍 Search-friendly indicators

---

## Customization Teaser

You can customize:

```json
{
  "segments": [
    {
      "type": "path",
      "style": "powerline",
      "foreground": "p:accent"
    },
    {
      "type": "git",
      "style": "powerline",
      "properties": {
        "fetch_status": true
      }
    }
  ],
  "palette": {
    "accent": "#00BCD4",
    "success": "#00C853"
  }
}
```

Learn more in [ADVANCED-CUSTOMIZATION-GUIDE.md](./ADVANCED-CUSTOMIZATION-GUIDE.md)

---

## Need More Help?

| Question             | Resource                                                                 |
| -------------------- | ------------------------------------------------------------------------ |
| How do I customize?  | [ADVANCED-CUSTOMIZATION-GUIDE.md](./ADVANCED-CUSTOMIZATION-GUIDE.md)     |
| Why is it slow?      | [PERFORMANCE-OPTIMIZATION-GUIDE.md](./PERFORMANCE-OPTIMIZATION-GUIDE.md) |
| It looks wrong       | [TROUBLESHOOTING-GUIDE.md](./TROUBLESHOOTING-GUIDE.md)                   |
| Common questions     | [FAQ-AND-TIPS-TRICKS.md](./FAQ-AND-TIPS-TRICKS.md)                       |
| Platform-specific    | [CROSS-PLATFORM-SETUP-GUIDE.md](./CROSS-PLATFORM-SETUP-GUIDE.md)         |
| Use with my IDE/tool | [INTEGRATION-GUIDES.md](./INTEGRATION-GUIDES.md)                         |

---

**Congratulations on setting up Oh My Posh Atomic Enhanced! 🎊**

Enjoy your beautiful new shell prompt!

Questions? Open an issue on [GitHub](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/issues).
