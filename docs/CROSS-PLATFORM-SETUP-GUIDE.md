# 🌍 Complete Cross-Platform Setup Guide

## Table of Contents

1. [Overview](#overview)
2. [Windows Setup](#windows-setup)
3. [macOS Setup](#macos-setup)
4. [Linux Setup](#linux-setup)
5. [WSL (Windows Subsystem for Linux)](#wsl-windows-subsystem-for-linux)
6. [Git Bash & MinGW](#git-bash--mingw)
7. [Docker & Remote Environments](#docker--remote-environments)
8. [Troubleshooting Cross-Platform Issues](#troubleshooting-cross-platform-issues)

---

## Overview

The OhMyPosh Atomic Enhanced themes are designed to work across Windows, macOS, and Linux. This guide provides step-by-step instructions for each platform, accounting for differences in package managers, terminal emulators, and shell configurations.

### Prerequisites (All Platforms)

- PowerShell 7+ OR Bash/Zsh (depending on platform)
- Administrator access (for initial installation)
- Internet connection
- Optional: Git for version control

### Platform Comparison

| Aspect | Windows | macOS | Linux |
| --- | --- | --- | --- |
| Default Shell | PowerShell | Bash/Zsh | Bash |
| Package Manager | WinGet/Chocolatey | Homebrew | apt/dnf/pacman |
| Terminal Emulator | Windows Terminal | iTerm2/Terminal.app | GNOME/Konsole |
| Font Installation | Settings GUI | System Preferences | Font Manager |
| Config Location | `$PROFILE` | `~/.bashrc`, `~/.zshrc` | `~/.bashrc`, `~/.zshrc` |
| Color Support | ✅ Excellent | ✅ Excellent | ✅ Excellent |

---

## Windows Setup

### Step 1: Install Oh My Posh

#### Method A: Using WinGet (Recommended)

```powershell
# Open PowerShell as Administrator
winget install JanDeDobbeleer.OhMyPosh -s winget

# Verify installation
oh-my-posh --version
```

#### Method B: Using Chocolatey

```powershell
# Open PowerShell as Administrator
choco install oh-my-posh

# Verify installation
oh-my-posh --version
```

#### Method C: Manual Installation

```powershell
# Download latest release
$LatestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases/latest"
$AssetUrl = $LatestRelease.assets | Where-Object { $_.name -like "*windows*x64*" } | Select-Object -First 1 | ForEach-Object { $_.browser_download_url }

# Download and extract
Invoke-WebRequest -Uri $AssetUrl -OutFile "$env:TEMP\oh-my-posh.exe"
Move-Item "$env:TEMP\oh-my-posh.exe" "C:\Program Files\oh-my-posh\bin\oh-my-posh.exe"

# Add to PATH
[Environment]::SetEnvironmentVariable(
    "PATH",
    $env:PATH + ";C:\Program Files\oh-my-posh\bin",
    [EnvironmentVariableTarget]::User
)
```

### Step 2: Install a Nerd Font

#### Option A: Using Windows Terminal Settings (Easiest)

1. Open Windows Terminal
2. Settings > Appearance
3. Choose "Font face": Select a Nerd Font from the dropdown
4. Recommended fonts: "Noto Nerd Font", "FiraCode Nerd Font", "JetBrains Mono Nerd Font"

#### Option B: Manual Font Installation

```powershell
# Download Noto Nerd Font
$FontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.0/Noto.zip"
Invoke-WebRequest -Uri $FontUrl -OutFile "$env:TEMP\Noto.zip"

# Extract
Expand-Archive -Path "$env:TEMP\Noto.zip" -DestinationPath "$env:TEMP\Noto"

# Install (copies to Fonts folder)
$Fonts = 0x14
$Shell = New-Object -ComObject Shell.Application
$FontsFolder = $Shell.Namespace($Fonts)

foreach ($Font in Get-ChildItem "$env:TEMP\Noto" -Filter "*.ttf") {
    $FontsFolder.CopyHere($Font.FullName)
}
```

#### Option C: Using Chocolatey

```powershell
# Install a Nerd Font via Chocolatey
choco install nerd-fonts-noto

# After installation, restart terminal and select the font
```

### Step 3: Install Windows Terminal (Highly Recommended)

```powershell
# Modern way - Microsoft Store
winget install Microsoft.WindowsTerminal

# Or via PowerShell
# https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701
```

### Step 4: Configure PowerShell Profile

```powershell
# Check if profile exists
Test-Path $PROFILE

# If not, create it
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force
}

# Open profile in editor
notepad $PROFILE
# Or: code $PROFILE (if VS Code installed)
```

Add the following to your profile:

```powershell
# ========== Oh My Posh Configuration ==========

# Initialize Oh My Posh with Atomic Enhanced theme
oh-my-posh init pwsh --config "C:\path\to\OhMyPosh-Atomic-Custom.json" | Invoke-Expression

# Alternative: Use from GitHub
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/OhMyPosh-Atomic-Custom.json" | Invoke-Expression

# Optional: Add useful aliases
Set-Alias -Name ll -Value Get-ChildItem -Force
Set-Alias -Name grep -Value Select-String -Force
Set-Alias -Name cat -Value Get-Content -Force

# ========== End Oh My Posh Configuration ==========
```

### Step 5: Reload Profile

```powershell
# Apply changes
& $PROFILE

# Verify it's working
echo "Profile loaded successfully!"
```

### Step 6: Windows Terminal Configuration (Optional)

Create custom profile in Windows Terminal settings:

```json
{
 "profiles": {
  "defaults": {
   "fontFace": "FiraCode Nerd Font",
   "fontSize": 11,
   "useAcrylic": true,
   "acrylicOpacity": 0.85
  },
  "list": [
   {
    "name": "PowerShell",
    "commandline": "pwsh.exe",
    "startingDirectory": "%USERPROFILE%",
    "icon": "ms-appx:///ProfileIcons/PowerShell_{9ACB9455-CA41-5AF7-950F-6BACA7E80194}.png"
   }
  ]
 },
 "schemes": [
  {
   "name": "AtomicEnhanced",
   "background": "#1E1E2E",
   "foreground": "#CDD6F4"
  }
 ]
}
```

### Verification Checklist (Windows)

- [ ] `oh-my-posh --version` shows version number
- [ ] `oh-my-posh get shell` returns "pwsh"
- [ ] Nerd Font installed and displaying icons
- [ ] Profile loads without errors
- [ ] Prompt displays with colors

---

## macOS Setup

### Step 1: Install Homebrew (If Not Already Installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Verify installation
brew --version
```

### Step 2: Install Oh My Posh

```bash
# Install via Homebrew
brew install oh-my-posh

# Or install latest formula version
brew install oh-my-posh --HEAD

# Verify
oh-my-posh --version
```

### Step 3: Install a Nerd Font

```bash
# Add font repository
brew tap homebrew/cask-fonts

# Install Noto Nerd Font
brew install --cask font-noto-nerd-font

# Or install JetBrains Mono
brew install --cask font-jetbrains-mono-nerd-font

# Verify installation
fc-list | grep "Nerd"
```

### Step 4: Configure Shell

#### For Bash Users

```bash
# Check if .bashrc exists
ls ~/.bashrc

# If not, create it
touch ~/.bashrc

# Add to ~/.bashrc
nano ~/.bashrc
```

Add the following:

```bash
# ========== Oh My Posh Configuration ==========
eval "$(oh-my-posh init bash --config ~/path/to/OhMyPosh-Atomic-Custom.json)"
# Or from GitHub:
eval "$(oh-my-posh init bash --config https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/OhMyPosh-Atomic-Custom.json)"
# ========== End Oh My Posh Configuration ==========
```

#### For Zsh Users (Default on Modern macOS)

```bash
# Check if .zshrc exists
ls ~/.zshrc

# If not, create it
touch ~/.zshrc

# Add to ~/.zshrc
nano ~/.zshrc
```

Add the following:

```bash
# ========== Oh My Posh Configuration ==========
eval "$(oh-my-posh init zsh --config ~/path/to/OhMyPosh-Atomic-Custom.json)"
# ========== End Oh My Posh Configuration ==========
```

### Step 5: Configure Terminal Emulator

#### iTerm2 (Recommended)

1. Download from https://www.iterm2.com/
2. Install
3. Preferences > Profiles > Text > Font
4. Select "FiraCode Nerd Font" or similar
5. Preferences > Profiles > Colors > Color presets (optional)

#### Terminal.app (Built-in)

1. Terminal > Preferences > Profiles > Text
2. Change Font to a Nerd Font
3. Terminal > Preferences > Profiles > Colors (optional)

### Step 6: Reload Shell Configuration

```bash
# For Bash
source ~/.bashrc

# For Zsh
source ~/.zshrc

# Verify
echo "Shell loaded!"
```

### Verification Checklist (macOS)

- [ ] `oh-my-posh --version` works
- [ ] Nerd Font displaying icons correctly
- [ ] Shell configuration loads without errors
- [ ] Prompt showing colors and segments

---

## Linux Setup

### Step 1: Install Oh My Posh

#### Fedora/RHEL

```bash
sudo dnf install oh-my-posh
```

#### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install oh-my-posh
```

#### Arch Linux

```bash
sudo pacman -S oh-my-posh
```

#### Generic Linux (Using Install Script)

```bash
curl -s https://ohmyposh.dev/install.sh | bash -s
```

Verify installation:

```bash
oh-my-posh --version
```

### Step 2: Install a Nerd Font

#### Fedora/RHEL

```bash
sudo dnf install noto-fonts-nerd
```

#### Ubuntu/Debian

```bash
sudo apt-get install fonts-noto-nerd
```

#### Arch Linux

```bash
sudo pacman -S noto-fonts-nerd
```

#### Manual Installation

```bash
# Create fonts directory
mkdir -p ~/.local/share/fonts

# Download font
cd ~/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.0/Noto.zip
unzip Noto.zip

# Update font cache
fc-cache -fv

# Verify
fc-list | grep Noto
```

### Step 3: Configure Shell

#### For Bash Users

```bash
# Add to ~/.bashrc
nano ~/.bashrc
```

Add:

```bash
# ========== Oh My Posh Configuration ==========
eval "$(oh-my-posh init bash --config ~/path/to/OhMyPosh-Atomic-Custom.json)"
# ========== End Oh My Posh Configuration ==========
```

#### For Zsh Users

```bash
# Add to ~/.zshrc
nano ~/.zshrc
```

Add:

```bash
# ========== Oh My Posh Configuration ==========
eval "$(oh-my-posh init zsh --config ~/path/to/OhMyPosh-Atomic-Custom.json)"
# ========== End Oh My Posh Configuration ==========
```

### Step 4: Configure Terminal Emulator

#### GNOME Terminal

1. Open GNOME Terminal preferences
2. Preferences > Profiles > Default > Text
3. Select "Noto Nerd Font" or similar

#### Konsole (KDE)

1. Settings > Edit Current Profile > Appearance
2. Choose "Noto Nerd Font"

#### Terminator

```bash
# Edit ~/.config/terminator/config
[profiles]
  [[default]]
    font = FiraCode Nerd Font 11
```

### Step 5: Reload Configuration

```bash
# For Bash
source ~/.bashrc

# For Zsh
source ~/.zshrc
```

### Verification Checklist (Linux)

- [ ] `oh-my-posh --version` works
- [ ] Nerd Font installed and displaying
- [ ] Shell config loads without errors
- [ ] Colors and icons rendering correctly

---

## WSL (Windows Subsystem for Linux)

### WSL1 vs WSL2

| Aspect | WSL1 | WSL2 |
| --- | --- | --- |
| Architecture | Compatibility layer | Virtual machine |
| Performance | Faster filesystem | Better performance |
| Colors | Limited | Full ANSI support |
| **Recommendation** | Migrate to WSL2 | ✅ Recommended |

### Step 1: Upgrade to WSL2 (Recommended)

```powershell
# In PowerShell (Administrator)
wsl --install

# Or upgrade existing:
wsl --set-default-version 2
wsl --set-version Ubuntu 2
```

### Step 2: Install Linux Distribution

```powershell
# List available distributions
wsl --list --online

# Install Ubuntu (most common)
wsl --install -d Ubuntu

# Or use Microsoft Store
# https://aka.ms/wsl2
```

### Step 3: Install Oh My Posh in WSL

```bash
# Inside WSL Ubuntu terminal
curl -s https://ohmyposh.dev/install.sh | bash -s

# Verify
oh-my-posh --version
```

### Step 4: Install Nerd Font

```bash
# In WSL
sudo apt-get update
sudo apt-get install fonts-noto-nerd

# Verify
fc-list | grep Noto
```

### Step 5: Configure Shell (Same as Linux)

```bash
# Add to ~/.bashrc or ~/.zshrc
eval "$(oh-my-posh init bash --config ~/path/to/theme.json)"
```

### Step 6: Configure Windows Terminal to Use WSL

Windows Terminal automatically detects WSL distributions. To use WSL profile:

1. Windows Terminal Settings > Add a new profile > Choose distribution
2. Or in settings.json:

```json
{
 "profiles": {
  "list": [
   {
    "name": "Ubuntu",
    "commandline": "wsl.exe -d Ubuntu",
    "startingDirectory": "//wsl$/Ubuntu/home/username",
    "icon": "ms-appx:///ProfileIcons/Ubuntu_{9ACB9455-CA41-5AF7-950F-6BACA7E80194}.png"
   }
  ]
 }
}
```

### Verification Checklist (WSL)

- [ ] WSL2 installed and running
- [ ] Linux distribution installed
- [ ] Oh My Posh working in WSL terminal
- [ ] Nerd Font displaying in Windows Terminal
- [ ] Colors showing correctly

---

## Git Bash & MinGW

### Installation & Setup

```bash
# Install Git for Windows (includes Git Bash)
# https://gitforwindows.org/

# Or via WinGet
winget install Git.Git

# Verify
git --version
bash --version
```

### Configure Oh My Posh in Git Bash

```bash
# Open ~/.bashrc
nano ~/.bashrc

# Add configuration
eval "$(oh-my-posh init bash --config ~/path/to/theme.json)"
```

### Limitations

- ⚠️ Limited ANSI support compared to Windows Terminal
- ⚠️ Some segments may not work properly
- **Recommendation**: Use Windows Terminal with WSL or PowerShell instead

---

## Docker & Remote Environments

### Docker Container Setup

```dockerfile
# Dockerfile
FROM ubuntu:latest

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    fonts-noto \
    zsh

# Install Oh My Posh
RUN curl -s https://ohmyposh.dev/install.sh | bash -s

# Copy theme file
COPY OhMyPosh-Atomic-Custom.json /root/.config/

# Configure shell
RUN echo 'eval "$(oh-my-posh init zsh --config /root/.config/OhMyPosh-Atomic-Custom.json)"' >> /root/.zshrc
```

### SSH Remote Setup

```bash
# On remote host
curl -s https://ohmyposh.dev/install.sh | bash -s

# Add to ~/.bashrc
eval "$(oh-my-posh init bash --config ~/themes/OhMyPosh-Atomic-Custom.json)"

# Connect from local machine
ssh user@remote.host
```

---

## Troubleshooting Cross-Platform Issues

### Problem: Theme Works on One Platform but Not Another

**Cause:** Platform-specific differences in shell or terminal.

**Solutions:**

1. Verify Oh My Posh version matches across platforms
2. Check shell type: `echo $SHELL` (Linux/macOS) vs `$PSVersionTable` (Windows)
3. Ensure Nerd Font installed on all platforms
4. Test with minimal configuration first

### Problem: Colors Different on Each Platform

**Cause:** Terminal color scheme settings different.

**Solutions:**

1. Standardize terminal color scheme across platforms
2. Use explicit RGB colors (Truecolor) in palette
3. Test theme on each platform individually

### Problem: SSH Connection Shows Different Prompt

**Cause:** Remote host has different shell or Oh My Posh configuration.

**Solutions:**

```bash
# Ensure Oh My Posh installed on remote
ssh user@host "which oh-my-posh"

# Set TERM variable
export TERM=xterm-256color

# Or in SSH command
ssh -t user@host "TERM=xterm-256color bash"
```

---

## Platform Feature Comparison

| Feature | Windows | macOS | Linux | WSL2 |
| --- | --- | --- | --- | --- |
| Colors | ✅ Full | ✅ Full | ✅ Full | ✅ Full |
| Icons | ✅ Full | ✅ Full | ✅ Full | ✅ Full |
| Git Status | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| System Info | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Time Display | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Weather | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Performance | Good | Excellent | Excellent | Excellent |
| **Recommended** | Windows Terminal | iTerm2/Zsh | Zsh | WSL2 + Windows Terminal |

---

## Quick Reference: Post-Installation Steps

1. **Verify Installation**

   ```bash
   oh-my-posh --version
   oh-my-posh get shell
   ```

2. **Download Theme**

   ```bash
   # From GitHub
   git clone https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced.git
   cd OhMyPosh-Atomic-Enhanced
   ```

3. **Test Theme**

   ```bash
   # Temporary test
   oh-my-posh init bash --config ./OhMyPosh-Atomic-Custom.json | source
   ```

4. **Configure Shell Permanently**
   - Add initialization line to `.bashrc`, `.zshrc`, or `$PROFILE`

5. **Reload Configuration**
   ```bash
   source ~/.bashrc  # or ~/.zshrc or & $PROFILE
   ```

---

## Summary

✅ All platforms supported
✅ Platform-specific guidance included
✅ Troubleshooting tips provided
✅ Terminal emulator recommendations given
✅ Cloud/remote environment support

For platform-specific issues, refer to the [Troubleshooting Guide](./TROUBLESHOOTING-GUIDE.md).
