# 🔗 Integration Guides

## Table of Contents

1. [VS Code Integration](#vs-code-integration)
2. [Windows Terminal Integration](#windows-terminal-integration)
3. [Git Bash Integration](#git-bash-integration)
4. [WSL Integration](#wsl-integration)
5. [iTerm2 Integration](#iterm2-integration)
6. [Other Terminal Emulators](#other-terminal-emulators)
7. [IDE Integration](#ide-integration)
8. [Remote/SSH Integration](#remotessh-integration)

---

## VS Code Integration

### Step 1: Configure Terminal Appearance

Open VS Code settings (Ctrl+,) and search for "terminal":

```json
{
  // Terminal font configuration
  "terminal.integrated.fontFamily": "\"FiraCode Nerd Font\", \"JetBrains Mono Nerd Font\", monospace",
  "terminal.integrated.fontSize": 12,
  "terminal.integrated.lineHeight": 1.3,
  "terminal.integrated.fontWeightBold": "600",

  // Terminal behavior
  "terminal.integrated.enableBell": false,
  "terminal.integrated.enableMultiLinePasting": true,
  "terminal.integrated.smoothScrolling": true,

  // Color integration
  "terminal.ansi16BitColors": true,
  "terminal.integrated.inheritEnv": true
}
```

### Step 2: Configure Terminal Profiles

Add Oh My Posh initialization to terminal profiles:

#### PowerShell Profile

```json
{
  "terminal.integrated.profiles.windows": {
    "PowerShell": {
      "source": "PowerShell",
      "icon": "terminal-powershell",
      "overrideName": true,
      "args": [
        "-NoExit",
        "-Command",
        "oh-my-posh init pwsh --config 'C:\\path\\to\\theme.json' | Invoke-Expression"
      ]
    }
  },
  "terminal.integrated.defaultProfile.windows": "PowerShell"
}
```

#### Bash Profile (Linux/macOS/WSL)

```json
{
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "bash",
      "args": ["--init-file", "~/.bashrc"],
      "overrideName": true
    }
  },
  "terminal.integrated.defaultProfile.linux": "bash"
}
```

### Step 3: Sync Color Theme (Optional)

VS Code can use a matching color theme:

1. Install theme from VS Code Extensions:
   - Search for "Dracula" or your preferred theme
   - Install matching Oh My Posh theme version

2. Configure in settings.json:
   ```json
   {
     "workbench.colorTheme": "Dracula",
     "workbench.iconTheme": "material-icon-theme"
   }
   ```

### Step 4: Test Configuration

1. Open integrated terminal in VS Code (Ctrl+`)
2. Verify prompt displays with colors
3. Check icons rendering properly
4. Test git branch display if in repo

### Tips for VS Code Terminal

- **Open multiple terminals**: Click "+" button in terminal panel
- **Split terminals**: Click split icon
- **Navigate terminals**: Alt+Arrow keys
- **Maximize terminal**: Click maximize icon
- **Kill terminal**: Click trash icon

### Common VS Code Issues

**Problem: Terminal not using custom profile**

Solution: Close terminal tab and reopen (Ctrl+`)

**Problem: Colors look wrong**

Solution:
1. Check `workbench.colorTheme` setting
2. Try disabling other color themes
3. Verify Nerd Font is installed

**Problem: Slow terminal startup**

Solution:
1. Reduce Oh My Posh complexity
2. Profile with `$env:OHMYPOSH_DEBUG = $true`
3. Move expensive initialization outside -Command

---

## Windows Terminal Integration

### Step 1: Install or Update Windows Terminal

```powershell
# Install or update via WinGet
winget install Microsoft.WindowsTerminal
winget upgrade Microsoft.WindowsTerminal
```

### Step 2: Access Settings

- Click dropdown menu (v) in Windows Terminal
- Select "Settings" or press Ctrl+,
- Opens settings.json

### Step 3: Configure PowerShell Profile

Add or modify PowerShell profile in `settings.json`:

```json
{
  "profiles": {
    "defaults": {
      "fontFace": "FiraCode Nerd Font",
      "fontSize": 11,
      "fontWeight": "normal",
      "useAcrylic": true,
      "acrylicOpacity": 0.85
    },
    "list": [
      {
        "name": "PowerShell",
        "source": "Windows.Terminal.PowershellCore",
        "hidden": false,
        "startingDirectory": "%USERPROFILE%",
        "commandline": "pwsh.exe",
        "icon": "ms-appx:///ProfileIcons/PowerShell_{9ACB9455-CA41-5AF7-950F-6BACA7E80194}.png"
      }
    ]
  },
  "schemes": [
    {
      "name": "Atomic Enhanced",
      "background": "#1E1E1E",
      "foreground": "#D4D4D4",
      "cursorColor": "#00BCD4",
      "selectionBackground": "#264F78",
      "black": "#000000",
      "blue": "#0080FF",
      "brightBlack": "#808080",
      "brightBlue": "#00B7FF",
      "brightCyan": "#00F5FF",
      "brightGreen": "#00FF00",
      "brightMagenta": "#FF00FF",
      "brightRed": "#FF3D3D",
      "brightWhite": "#FFFFFF",
      "brightYellow": "#FFD600",
      "cyan": "#00D4FF",
      "green": "#00C853",
      "magenta": "#D946EF",
      "red": "#FF0000",
      "white": "#E0E0E0",
      "yellow": "#FFD600"
    }
  ],
  "defaultProfile": "{574e775e-4f2a-5b96-ac1e-a2962a402336}"
}
```

### Step 4: Customize Appearance

```json
{
  "appearance": {
    "theme": "dark",
    "acrylic": true,
    "useAcrylicInTabRow": true,
    "tabWidthMode": "equal"
  },
  "colorScheme": "Atomic Enhanced",
  "bellStyle": "none",
  "showTabsInTitleBar": true
}
```

### Step 5: Add Keyboard Shortcuts (Optional)

```json
{
  "keybindings": [
    {
      "command": "sendInput",
      "keys": ["ctrl+alt+n"],
      "input": "New-Item -ItemType Directory -Name 'test'"
    }
  ]
}
```

### Windows Terminal Advanced Configuration

#### Multiple PowerShell Versions

```json
{
  "profiles": {
    "list": [
      {
        "name": "PowerShell 7 (Current)",
        "commandline": "pwsh.exe",
        "source": "Windows.Terminal.PowershellCore"
      },
      {
        "name": "Windows PowerShell 5.1",
        "commandline": "powershell.exe",
        "hidden": false
      }
    ]
  }
}
```

#### Startup Directory

```json
{
  "profiles": {
    "defaults": {
      "startingDirectory": "%USERPROFILE%\\Projects"  // Start in Projects folder
    }
  }
}
```

#### Custom Icons

```json
{
  "profiles": {
    "list": [
      {
        "name": "PowerShell",
        "icon": "ms-appx:///ProfileIcons/PowerShell_{guid}.png"
        // Or custom file path:
        // "icon": "file:///C:\\path\\to\\icon.png"
      }
    ]
  }
}
```

---

## Git Bash Integration

### Step 1: Install Git for Windows

```powershell
winget install Git.Git
# or
choco install git
```

### Step 2: Verify Oh My Posh Installation

```bash
# Inside Git Bash
oh-my-posh --version
```

If not installed, install via WinGet first.

### Step 3: Configure ~/.bashrc

```bash
# Open or create ~/.bashrc
nano ~/.bashrc
```

Add:

```bash
# ========== Oh My Posh Configuration ==========

# Initialize Oh My Posh
eval "$(oh-my-posh init bash --config ~/path/to/theme.json)"

# Optional aliases
alias ll='ls -la'
alias grep='grep --color=auto'
alias cat='cat'

# ========== End Configuration ==========
```

### Step 4: Test in Git Bash

```bash
# Launch Git Bash
bash

# Verify prompt initialized
echo $PS1
```

### Git Bash Limitations

⚠️ **Note:** Git Bash has limited ANSI support compared to modern terminals

| Feature | Status | Notes |
|---------|--------|-------|
| Colors | ⚠️ Limited | Some color codes not rendered |
| Icons | ✅ Works | Nerd Font icons display |
| Git status | ✅ Full | Works well |
| Performance | ✅ Good | Generally fast |

### Recommendation

For best experience, use Windows Terminal with WSL instead of Git Bash.

---

## WSL Integration

### Step 1: Install WSL2 and Linux Distribution

```powershell
# In PowerShell (Administrator)
wsl --install -d Ubuntu
wsl --set-default-version 2
```

### Step 2: Install Oh My Posh in WSL

```bash
# Inside WSL terminal
curl -s https://ohmyposh.dev/install.sh | bash -s
```

### Step 3: Configure ~/.bashrc or ~/.zshrc

```bash
# For Bash
nano ~/.bashrc

# For Zsh
nano ~/.zshrc
```

Add:

```bash
eval "$(oh-my-posh init bash --config ~/path/to/theme.json)"
```

### Step 4: Configure Windows Terminal for WSL

Windows Terminal automatically detects WSL. To customize:

```json
{
  "profiles": {
    "list": [
      {
        "name": "Ubuntu",
        "commandline": "wsl.exe -d Ubuntu",
        "startingDirectory": "//wsl$/Ubuntu/home/username",
        "icon": "ms-appx:///ProfileIcons/Ubuntu_{guid}.png"
      }
    ]
  }
}
```

### WSL Tips

- **Directory shortcuts**: `\\wsl$\Ubuntu\home\username` in Windows Explorer
- **File sync**: `/mnt/c/Users/username` to access Windows files from WSL
- **Performance**: WSL2 recommended over WSL1
- **Font sharing**: Windows Terminal font applies to WSL

---

## iTerm2 Integration

### Step 1: Install oh-my-posh via Homebrew

```bash
brew install oh-my-posh
```

### Step 2: Configure ~/.zshrc

```bash
nano ~/.zshrc
```

Add:

```bash
eval "$(oh-my-posh init zsh --config ~/path/to/theme.json)"
```

### Step 3: Configure iTerm2 Appearance

1. **iTerm2 > Preferences > Profiles > Text**
   - Font: Select "FiraCode Nerd Font" or similar
   - Size: 12-14pt
   - Antialias: ✓ checked
   - Ligatures: ✓ checked

2. **iTerm2 > Preferences > Profiles > Colors**
   - Color presets: Import custom scheme
   - Transparency: 10-20% optional

3. **iTerm2 > Preferences > Appearance**
   - Theme: Automatic or Dark
   - Status bar location: Bottom (optional)

### iTerm2 Advanced Configuration

#### Background Image (Optional)

```
Profiles > Window > Background image
- Select image file
- Set transparency/blending
```

#### Custom Color Scheme

Create theme file and import:
```
Profiles > Colors > Load Presets > Import
```

---

## Other Terminal Emulators

### Alacritty (Linux/macOS)

1. Install:
   ```bash
   cargo install alacritty
   # or
   brew install alacritty
   ```

2. Configure `~/.config/alacritty/alacritty.yml`:
   ```yaml
   font:
     family: FiraCode Nerd Font
     size: 12.0

   colors:
     primary:
       background: "#1e1e1e"
       foreground: "#d4d4d4"
   ```

3. Add to shell config:
   ```bash
   eval "$(oh-my-posh init bash --config ~/theme.json)"
   ```

### Kitty (Linux/macOS)

1. Install:
   ```bash
   curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
   ```

2. Configure `~/.config/kitty/kitty.conf`:
   ```
   font_family FiraCode Nerd Font
   font_size 12
   ```

3. Add to shell config:
   ```bash
   eval "$(oh-my-posh init bash --config ~/theme.json)"
   ```

### Terminator (Linux)

1. Install:
   ```bash
   sudo apt-get install terminator
   ```

2. Configure `~/.config/terminator/config`:
   ```
   [profiles]
     [[default]]
       font = FiraCode Nerd Font 11
   ```

### GNOME Terminal (Linux)

1. Open Settings
2. Profiles > Default > Text
3. Choose "Noto Nerd Font" or similar
4. Add to `~/.bashrc`:
   ```bash
   eval "$(oh-my-posh init bash --config ~/theme.json)"
   ```

---

## IDE Integration

### JetBrains IDEs (IntelliJ, PyCharm, WebStorm)

1. **Settings > Tools > Terminal**
   - Font: FiraCode Nerd Font
   - Shell path: `pwsh.exe` (Windows) or `/bin/bash` (macOS/Linux)

2. **Run with shell config**
   - Shell integration automatically enabled
   - Oh My Posh will initialize from `.bashrc` or profile

3. **Verify**
   - Open terminal tab in IDE
   - Check that prompt displays correctly

### Visual Studio (C#)

1. **Tools > Options > Terminal**
   - Default terminal: Git Bash or Windows Terminal

2. **External terminal**
   - Use Windows Terminal with configured profiles

---

## Remote/SSH Integration

### Basic SSH Setup

```bash
# On remote server
ssh user@remote.host

# Install Oh My Posh
curl -s https://ohmyposh.dev/install.sh | bash -s

# Configure shell
eval "$(oh-my-posh init bash --config ~/theme.json)"
```

### Persistent SSH Configuration

```bash
# Add to ~/.bashrc on remote
eval "$(oh-my-posh init bash --config ~/theme.json)"

# Or use environment variable
eval "$(oh-my-posh init bash --config $HOME/.config/ohmyposh/theme.json)"
```

### SSH with Local Theme

Copy theme to remote:

```bash
# From local machine
scp ./OhMyPosh-Atomic-Custom.json user@remote.host:~/.config/ohmyposh/

# On remote, use it
eval "$(oh-my-posh init bash --config ~/.config/ohmyposh/OhMyPosh-Atomic-Custom.json)"
```

### Terminal-Multiplexer Integration

#### tmux

Add to `~/.tmux.conf`:

```
# Ensure colors pass through
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color:RGB"

# Run Oh My Posh in shell
set -g status off  # Disable tmux status bar if using Oh My Posh
```

#### GNU Screen

Add to `~/.screenrc`:

```
term screen-256color
```

---

## Summary: Integration Checklist

### For Each Environment

- [ ] Terminal emulator installed and latest version
- [ ] Nerd Font installed and configured
- [ ] Oh My Posh installed and in PATH
- [ ] Shell profile configured with Oh My Posh init
- [ ] Colors displaying correctly
- [ ] Icons rendering with no boxes/corruption
- [ ] Performance acceptable (< 300ms)
- [ ] Theme tested in that specific environment

### Quick Tests

```bash
# Test in new terminal
oh-my-posh --version
# Should display version

# Test prompt rendering
echo "✓ Ready"
# Should display check mark

# Check shell type
echo $SHELL
# Should show your shell path
```

---

## Troubleshooting Integration Issues

### Problem: Oh My Posh not initializing

**Solution:**
1. Verify installation: `which oh-my-posh`
2. Check shell config file loaded: `source ~/.bashrc`
3. Verify init line in config: `grep oh-my-posh ~/.bashrc`

### Problem: Wrong colors in IDE terminal

**Solution:**
1. Check IDE terminal settings
2. Verify TERM variable: `echo $TERM` (should be `xterm-256color`)
3. Test with basic prompt to isolate issue

### Problem: Performance different across terminals

**Solution:**
1. Profile with `$env:OHMYPOSH_DEBUG = $true`
2. Check for different segment configurations per terminal
3. Verify caching enabled in all environments

---

## References

- [VS Code Integrated Terminal Docs](https://code.visualstudio.com/docs/editor/integrated-terminal)
- [Windows Terminal Documentation](https://docs.microsoft.com/windows/terminal/)
- [Oh My Posh Installation Guide](https://ohmyposh.dev/docs/installation/)
- [WSL Official Documentation](https://docs.microsoft.com/windows/wsl/)
