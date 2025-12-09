# 🚀 OhMyPosh Atomic Enhanced

[![GitHub stars](https://img.shields.io/github/stars/Nick2bad4u/OhMyPosh-Atomic-Enhanced?style=social)](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced) [![GitHub issues](https://img.shields.io/github/issues/Nick2bad4u/OhMyPosh-Atomic-Enhanced)](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/issues) [![License: UnLicense](https://img.shields.io/badge/License-UnLicense-yellow.svg)](https://opensource.org/licenses/UnLicense) [![Oh My Posh](https://img.shields.io/badge/Oh%20My%20Posh-Compatible-blue)](https://ohmyposh.dev/) [![DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced)

This repository provides a custom theme configuration for [Oh My Posh](https://ohmyposh.dev/), a cross-platform prompt theming engine for shells like PowerShell, Bash, and Zsh. Inspired by the AtomicBit theme, this project aims to deliver a visually rich, highly informative, and developer-friendly prompt experience. It is designed for users who want a modern, customizable shell prompt with enhanced status indicators, dynamic segments, and consistent appearance across Windows, Linux, and macOS terminals.

Whether you're a developer or power user, this theme helps you work faster and smarter by making your shell prompt more informative and visually appealing.

<figure>
  <img src="https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/assets/WinTerminal.png" alt="Windows Terminal themed prompt screenshot" width="900">
  <figcaption><strong>Windows Terminal</strong> showcasing the Atomic Enhanced Oh My Posh prompt with left/right blocks, git status, and dynamic battery/system info.</figcaption>
</figure>

<figure>
  <img src="https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/assets/WinTerminal-ExperimentalDividers.png" alt="Windows terminal themed prompt screenshot showing Experimental Dividers" width="900">
  <figcaption><strong>Windows Terminal</strong> showcasing the Atomic Enhanced Oh My Posh prompt with experimental dividers enabled. (Recommended)</figcaption>
</figure>

<a id="how-the-ohmyposh-custom-theme-works"></a>

## 📑 Table of Contents

- [How the OhMyPosh Custom Theme Works](#how-the-ohmyposh-custom-theme-works)
  - [Theme Structure](#theme-structure)
    - [Left-Aligned Prompt](#left-aligned-prompt)
    - [Right-Aligned Prompt (same-line; alignment: "right")](#right-aligned-prompt)
    - [Right Prompt (explicit `rprompt` block)](#right-prompt-explicit-rprompt-block)
    - [Newline Block](#newline-block)
- [Key Features](#key-features)
- [Oh-My-Posh Installation](#oh-my-posh-installation)
- [How to Use](#how-to-use)
- [Advanced Customization](#advanced-customization)
- [Documentation](#documentation)
  - [Using Palette Entries](#using-palette-entries)
- [Theme Styles](#theme-styles)
- [Theme Gallery](#theme-gallery)

## 🧩 How the OhMyPosh Custom Theme Works

See: [General Configuration](https://ohmyposh.dev/docs/configuration/general) • [Theme Files](https://ohmyposh.dev/docs/themes) • Segment Docs (example: [Git](https://ohmyposh.dev/docs/segments/scm/git))

> [NOTE] This theme is highly customizable--feel free to tweak colors and segments! 🚀

This theme is a highly customized configuration for [Oh My Posh](https://ohmyposh.dev/), designed to provide a visually rich, informative, and efficient prompt for your shell. It leverages advanced features of Oh My Posh, including segment styling, dynamic templates, mapped locations, and tooltips for various development environments.

<a id="theme-structure"></a>

### 🧱 Theme Structure

Docs: JSON Schema (section: [Validation](https://ohmyposh.dev/docs/configuration/general#json-schema-validation)) · [Block Config](https://ohmyposh.dev/docs/configuration/block) · [Segment Config](https://ohmyposh.dev/docs/configuration/segment)

- **Schema**: The theme uses the official Oh My Posh theme schema for validation and compatibility.
- **Accent Color**: Sets a primary accent color for visual consistency.
- **Blocks**: The prompt is divided into multiple blocks, each with its own alignment (left, right, or newline) and segments.

<a id="left-aligned-prompt"></a>

#### ◀️ Left-Aligned Prompt

Relevant segments: [shell](https://ohmyposh.dev/docs/segments/system/shell) · [root](https://ohmyposh.dev/docs/segments/system/root) · [path](https://ohmyposh.dev/docs/segments/system/path) · [git](https://ohmyposh.dev/docs/segments/scm/git) · [executiontime](https://ohmyposh.dev/docs/segments/system/executiontime) · [status](https://ohmyposh.dev/docs/segments/system/status)

Contains segments for:

- **Shell Info 🐚**: Displays shell name and version, with mapped names for common shells.
- **Root Status 🔐**: Highlights if running as administrator/root.
- **Path 📁**: Shows the current directory, with custom icons and mapped locations for quick recognition (e.g., "UW" for Uptime-Watcher repo, icons for Desktop/Documents/Downloads).
- **Git 🌿**: Shows branch, status, and upstream info, with color changes based on git state.
- **Execution Time ⏱️**: Displays how long the last command took to run.
- **Status ✅/❌**: Indicates success or error of the last command.

<a id="right-aligned-prompt"></a>

#### ▶️ Right-Aligned Prompt (same-line; alignment: "right")

Relevant segments: [sysinfo](https://ohmyposh.dev/docs/segments/system/sysinfo) · [os](https://ohmyposh.dev/docs/segments/system/os) · [time](https://ohmyposh.dev/docs/segments/system/time) · [weather/owm](https://ohmyposh.dev/docs/segments/web/owm) · [battery](https://ohmyposh.dev/docs/segments/system/battery) · [node](https://ohmyposh.dev/docs/segments/package-managers/node) · [npm](https://ohmyposh.dev/docs/segments/package-managers/npm) · [java](https://ohmyposh.dev/docs/segments/lang/java) · [python](https://ohmyposh.dev/docs/segments/lang/python) · [dotnet](https://ohmyposh.dev/docs/segments/lang/dotnet) · [upgrade](https://ohmyposh.dev/docs/segments/system/upgrade) · [gitversion](https://ohmyposh.dev/docs/segments/scm/gitversion)

Contains segments for:

- **System Info 🧮**: CPU, memory, and disk usage, with dynamic coloring.
- **OS Info 🖥️**: Shows the operating system and WSL status.
- **Time 🕒**: Current date and time, with customizable format.
- **Weather ☀️**: Displays current temperature using OpenWeatherMap (OWM), with units and timeout settings.
- **Battery 🔋**: Shows battery status and state, with color changes for charging/discharging/full.
- **Runtime badges & package managers ⚙️**: Shows runtime details for Node, Java, Python, .NET and package manager badges (npm/pnpm/yarn), useful in developer workflows.
- **Upgrade & Tooling Notices ⚠️**: The `upgrade` segment shows whether tool or theme updates are available.
- **GitVersion (slimfat)**: In the `slimfat` family, `gitversion` displays version metadata for project release or tagged versions.

<a id="right-prompt-explicit-rprompt-block"></a>

#### ➡️ Right Prompt (explicit `rprompt` block)

Relevant segments: [promptcounter](https://ohmyposh.dev/docs/configuration/templates) · [upgrade](https://ohmyposh.dev/docs/segments/system/upgrade) · [root](https://ohmyposh.dev/docs/segments/system/root) · [copilot](#copilot) (experimental, rprompt)

Contains segments for:

- **Prompt Count #️⃣**: Shows the number of prompts in the session.
- **Upgrade Notice ⬆️**: Indicates if Oh My Posh can be upgraded.
- **Root Status ⚡**: Quick root indicator.
- **Copilot gauge 🤖 (experimental)**: Shows Copilot premium quota and percent remaining in the `rprompt` block when integration is available.

Note: Some segments may appear as 'alignment: right' (same-line right-aligned) or in an explicit `rprompt` block depending on the theme family. For example, `copilot` appears as an `rprompt`-type segment in `experimentalDividers`, while runtime badges (`node`, `npm`, `java`, `python`, etc.) are frequently in `alignment: right` blocks across families.

<a id="newline-block"></a>

#### ⤵️ Newline Block

Relevant segments: [text](https://ohmyposh.dev/docs/segments/system/text) (decorative line) · [session](https://ohmyposh.dev/docs/segments/system/session) · [status](https://ohmyposh.dev/docs/segments/system/status)

Contains segments for:

- **Decorative Line ─**: Visual separator for prompt clarity.
- **Session Info 👤**: Shows username and SSH session status.
- **Status ✅/❌**: Indicates command status with icons.

<a id="key-features"></a>

### ✨ Key Features

Docs: [Templates](https://ohmyposh.dev/docs/configuration/templates) · [Mapped Locations](https://ohmyposh.dev/docs/segments/system/path#mapped-locations) · Caching (section removed: see [General Config](https://ohmyposh.dev/docs/configuration/general) for related settings) · Styles & Separators (see [General Config](https://ohmyposh.dev/docs/configuration/general)) · [Tooltips](https://ohmyposh.dev/docs/configuration/tooltips)

- **Dynamic Templates 🧬**: Many segments use Go template syntax to display context-aware information (e.g., git status, shell name, mapped locations).
- **Mapped Locations 🗺️**: Custom folder names/icons for frequently used paths, making navigation easier.
- **Segment Styling 💎**: Uses "diamond" and "powerline" styles for modern, visually appealing separators and backgrounds.
- **Caching ⚡**: Segments cache their data for performance, with customizable durations and strategies (e.g., session, folder).
- **Tooltips 💡**: Provides quick info for common tools (React, TypeScript, Node, Java, Git, etc.) when detected in the current folder.
- **HTTP tooltips & enrichment 🛰️**: Several tooltips use the `http` segment to fetch metadata about packages, versions, and remote services. Common examples included in the themes:
  - React, TypeScript, Vite, Playwright & Vitest (fetching npm registry versions)
  - Prettier, Axios, Zod and other packages used as small badges/tooltips
  - IP lookups via `ipify` (IPv4/IPv6) for quick network visibility
  - GitVersion & Git metadata via HTTP or local lookups (Slimfat)
    Tooltips are defined per-theme and may vary across variants.
- **Status and Error Handling 🚦**: Segments change color and icons based on command success, errors, or git state.
- **Customization 🎯**: Nearly every aspect (colors, icons, templates, widths) can be adjusted to fit your workflow and preferences.

<a id="per-family-segment-highlights"></a>

### 📦 Per-Family Segment Highlights

Some segments are specific to certain theme families; the main custom families are: `experimentalDividers`, `OhMyPosh-Atomic-Custom` (atomic custom), `1_shell`, `slimfat`, `atomicBit`, and `cleanDetailed`.

- Experimental Dividers (highlight): `copilot` — An interactive Copilot gauge showing premium quota/percent (shown when a Copilot premium API or status is available) and it lives in an `rprompt` block; HTTP tooltips, npm/node/java runtime badges are often right-aligned same-line segments. Experimental Dividers also include rich HTTP tooltips and IP lookups (ipify).
- Atomic Custom: Common runtime badges and package checks (`node`, `npm`, `java`, `upgrade`) used for everyday project contexts.
- Slimfat: Focused on compact displays and additional project/runtime segments like `gitversion`, `project`, and Windows-specific `winreg` info.
- AtomicBit: Developer-focused segments for language and platform tooling — `angular`, `aurelia`, `aws`, `kubectl`, `nx`, `dart`, `go`, `julia`, `rust`, `ruby`, and others; these appear mostly in this family.

If you need a segment added to README that’s used only by an official theme (not one of the custom families), let me know and I’ll add a note under “Official Families” instead.

<details>
<a id="detailed-segment-index-by-family"></a>
<summary>📋 Detailed Segment Index (by family)</summary>

Below is a convenience index showing which segments are used in each family of themes. This helps contributors see at a glance which segments are available in a family and which are exclusive.

<a id="experimental-dividers"></a>

### experimentalDividers

- `battery`
- `connection`
- `copilot`
- `executiontime`
- `git`
- `gitversion`
- `http`
- `ipify`
- `java`
- `node`
- `npm`
- `os`
- `owm`
- `path`
- `project`
- `python`
- `react`
- `root`
- `session`
- `shell`
- `status`
- `sysinfo`
- `text`
- `time`
- `upgrade`
- `winreg`

<a id="atomic-custom"></a>

### atomicCustom

- `battery`
- `connection`
- `executiontime`
- `git`
- `gitversion`
- `http`
- `ipify`
- `java`
- `node`
- `npm`
- `os`
- `owm`
- `path`
- `project`
- `python`
- `react`
- `root`
- `session`
- `shell`
- `status`
- `sysinfo`
- `text`
- `time`
- `upgrade`
- `winreg`

<a id="1-shell"></a>

### 1_shell

- `battery`
- `connection`
- `executiontime`
- `git`
- `gitversion`
- `http`
- `ipify`
- `java`
- `node`
- `os`
- `path`
- `project`
- `python`
- `react`
- `root`
- `session`
- `shell`
- `status`
- `sysinfo`
- `text`
- `time`
- `upgrade`
- `winreg`

<a id="slimfat"></a>

### slimfat

- `battery`
- `connection`
- `dotnet`
- `executiontime`
- `git`
- `gitversion`
- `http`
- `ipify`
- `java`
- `node`
- `os`
- `path`
- `project`
- `python`
- `react`
- `root`
- `session`
- `shell`
- `status`
- `sysinfo`
- `text`
- `time`
- `upgrade`
- `winreg`

<a id="atomicbit"></a>

### atomicBit

- `angular`
- `aurelia`
- `aws`
- `azfunc`
- `battery`
- `connection`
- `dart`
- `dotnet`
- `executiontime`
- `git`
- `gitversion`
- `go`
- `http`
- `ipify`
- `java`
- `julia`
- `kubectl`
- `node`
- `nx`
- `os`
- `owm`
- `path`
- `project`
- `python`
- `react`
- `root`
- `ruby`
- `rust`
- `session`
- `shell`
- `status`
- `sysinfo`
- `text`
- `time`
- `upgrade`
- `winreg`

<a id="clean-detailed"></a>

### cleanDetailed

- `battery`
- `connection`
- `executiontime`
- `git`
- `gitversion`
- `http`
- `ipify`
- `java`
- `node`
- `os`
- `path`
- `project`
- `python`
- `react`
- `root`
- `session`
- `shell`
- `status`
- `sysinfo`
- `text`
- `time`
- `upgrade`
- `winreg`

</details>

<a id="oh-my-posh-installation"></a>

### 📦 Oh-My-Posh Installation

Docs: Installation: [Windows](https://ohmyposh.dev/docs/installation/windows) · [macOS](https://ohmyposh.dev/docs/installation/macos) · [Linux](https://ohmyposh.dev/docs/installation/linux) · [Fonts](https://ohmyposh.dev/docs/installation/fonts) · [Customize](https://ohmyposh.dev/docs/installation/customize)

1. [Windows](https://ohmyposh.dev/docs/installation/windows)
2. [Linux](https://ohmyposh.dev/docs/installation/linux)
3. [MacOS](https://ohmyposh.dev/docs/installation/macos)

<a id="how-to-use"></a>

### 🛠️ How to Use

1. **Quick Start (from GitHub URL):** You can use the theme directly from the GitHub repository without downloading it:

```pwsh
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/OhMyPosh-Atomic-Custom.json" | Invoke-Expression
```

2. **Local Setup:** Copy the theme JSON (`OhMyPosh-Atomic-Custom.json`) to your system. Set your shell to use this theme with Oh My Posh:

```pwsh
oh-my-posh init pwsh --config "<path-to>/OhMyPosh-Atomic-Custom.json" | Invoke-Expression
```

Customize mapped locations, icons, and colors as needed in the JSON file.

<a id="advanced-customization"></a>

### 🧪 Advanced Customization

Docs: [Segment Config](https://ohmyposh.dev/docs/configuration/segment) · [Templates Guide](https://ohmyposh.dev/docs/configuration/templates) · [Palette & Colors](https://ohmyposh.dev/docs/configuration/colors) · [Tooltips](https://ohmyposh.dev/docs/configuration/tooltips)

- **Segment Properties**: Each segment type (shell, path, git, etc.) has its own properties for fine-tuning behavior and appearance.
- **Templates**: Use Go template expressions to display dynamic info (see [Oh My Posh docs](https://ohmyposh.dev/docs/configuration/templates)).
- **Tooltips**: Add or modify tooltips for your favorite tools and languages.

For more details, see the [Oh My Posh documentation](https://ohmyposh.dev/docs/).

<a id="documentation"></a>

## 📚 Documentation

For comprehensive guides, configuration options, and troubleshooting, refer to the official Oh My Posh documentation at [https://ohmyposh.dev/docs](https://ohmyposh.dev/docs).

<details>
<a id="palette-color-groups"></a>
<summary>🎨 Palette & Color Groups</summary>

The theme centralizes all colors in a `palette` so segments and templates stay consistent and easy to tweak. Colors are grouped by functional intent rather than pure hue. Use `p:<key>` anywhere a color is accepted (foreground/background, templates like `<p:key>` or `<p:fg,p:bg>`).

| Group                                                  | Key                                                    | Description                                                   |
| ------------------------------------------------------ | ------------------------------------------------------ | ------------------------------------------------------------- |
| Core / Base                                            | `accent`                                               | Primary accent and prompt line markers.                       |
| `black`, `white`                                       | Base monochrome anchors.                               |
| Blues (Shell / Time / Info)                            | `blue_primary`                                         | Shell segment background & transient prompt color.            |
| `blue_time`                                            | Time and connection segments.                          |
| `blue_tooltip`                                         | Tooltip foreground accents.                            |
| `windows_blue`                                         | Windows registry/version segment.                      |
| `python_blue`                                          | Python runtime background.                             |
| `navy_text`                                            | Dark readable foreground on bright yellows.            |
| Purples (Session / Branch State / Execution)           | `purple_session`                                       | Session username & debug banners.                             |
| `purple_ahead`                                         | Git ahead/behind highlighting.                         |
| `purple_exec`                                          | Execution time segment.                                |
| `violet_project`                                       | Project/workspace segment.                             |
| Reds & Pinks (Errors / Alerts)                         | `red_alert`                                            | Root/admin & error emphasis.                                  |
| `red_deleted`                                          | Git deleted files counter.                             |
| `maroon_error`                                         | Error status background.                               |
| `pink_error_line`                                      | Error line symbol in multiline prompts.                |
| `pink_status_fail`                                     | Failure state in status templates.                     |
| Oranges (Path / Battery / Java / General Warm Accents) | `orange`                                               | Path and tooltip path segment.                                |
| `orange_unmerged`                                      | Git unmerged count.                                    |
| `orange_battery`                                       | Battery base color.                                    |
| `java_orange`                                          | Java version tooltip.                                  |
| Yellows (Attention / Status / Update)                  | `yellow_bright`                                        | Git base background & root foreground; high-attention blocks. |
| `yellow_modified`                                      | Git modified files.                                    |
| `yellow_git_changed`                                   | Git working/staging changed blend.                     |
| `yellow_update`                                        | Upgrade notification segment.                          |
| `yellow_root_alt`                                      | Alt root indicator (rprompt).                          |
| `yellow_discharging`                                   | Battery discharging state.                             |
| Greens (Success / Health / Battery / Helpers)          | `green_added`                                          | Git added files.                                              |
| `green_ahead`                                          | Combined ahead/behind git state.                       |
| `green_full`                                           | Battery full state.                                    |
| `green_success`                                        | Command success background template.                   |
| `green_help`                                           | Help / generic info text badge.                        |
| `green_valid_line`                                     | Valid line symbol.                                     |
| `green_charging`                                       | Battery charging state.                                |
| Cyans                                                  | `cyan_renamed`                                         | Git renamed files count.                                      |
| `cyan_status_fg`                                       | Status indicator foreground (multiline tail).          |
| Magenta                                                | `magenta_copied`                                       | Git copied files count.                                       |
| Weather / Misc                                         | `pink_weather`                                         | Weather segment background.                                   |
| Grays (Neutral/UI Framing)                             | `gray_os`                                              | OS segment background.                                        |
| `gray_os_fg`                                           | OS / neutral text foreground & reused for subtle text. |
| `gray_untracked`                                       | Git untracked file count.                              |
| `gray_prompt_count_bg`                                 | Prompt count background.                               |
| `gray_prompt_count_fg`                                 | Prompt count foreground.                               |
| `gray_path_fg`                                         | Path tooltip foreground & neutral dark text.           |
| Language / Tool Specific                               | `node_green`                                           | Node.js / package manager tooltip background.                 |
| `python_yellow`                                        | Python secondary (logo yellow).                        |

</details>

<a id="using-palette-entries"></a>

### Using Palette Entries

Examples:

```jsonc
"foreground": "p:accent"
"background": "p:blue_primary"
"template": "<p:green_success> OK </><p:red_alert> ERR </>"
"background_templates": ["{{ if .Error }}p:maroon_error{{ end }}"]
```

This structure lets you retheme quickly: adjust a palette value once and every segment using it updates automatically.

The included [`validate-palette.ps1`](./validate-palette.ps1) script (located in the root of this repository) checks that every `p:<key>` reference in the config matches a palette entry. It also reports any unused palette keys.

> [!WARNING] Always run the validation script after changes to avoid palette mismatches! ⚠️

**Note:** Requires PowerShell 7 or later. No external modules are needed; the script uses only built-in PowerShell features.

**Note:** Run the following command from the repository root to ensure correct results.

Run it (from repo root):

```pwsh
pwsh ./validate-palette.ps1
```

Exit codes:

- `0` clean (no missing/unused)
- `2` missing references
- `3` only unused keys

After making changes to the palette or theme configuration, run this script to ensure all palette references are valid and unused keys are reported--helping keep your configuration clean and error-free.

<a id="theme-styles"></a>

## 🎨 Theme Styles

This repository includes **5 unique theme styles**, each available in **24 color palettes** (120 total themes):

### 🚀 OhMyPosh Atomic Custom

The flagship theme with comprehensive features:

- Multi-line layout with left and right blocks

- Extensive git status with visual indicators

- Language/framework detection (Node, Python, .NET, Java, Go, Rust, Angular, React, etc.)

- System info (memory, CPU, battery)

- Weather integration

- Custom path mapping with smart icons

- Execution time and status tracking

### ✨ 1_shell Enhanced

A sleek single-line theme based on the official 1_shell:

- Clean, compact design

- Git integration with status colors

- Session info and OS detection

- Smart path display with mapped locations

- Battery status with color indicators

### 🎯 Slimfat Enhanced

Two-line compact theme with modern styling:

- OS icon with session info

- Enhanced git status on primary line

- Language segments (Node, Python, .NET)

- Time display and battery status

- Clean execution time and status on second line

### 📦 AtomicBit Enhanced

Box-style technical theme:

- Bracketed session display

- Path with smart location mapping

- Multiple language support

- OS info and battery status

- Git status on separate line

- Compact technical aesthetic

### 🧹 Clean-Detailed Enhanced

Minimalist clean theme with essential info:

- OS and shell information

- System memory statistics

- Execution time tracking

- Enhanced git with upstream icons

- Time and root indicators

- Smart path with mapped locations

---

<a id="theme-gallery"></a>

## 🎨 Theme Gallery

All themes are available in multiple color palettes. Choose the one that fits your style!

### 🌈 Experimental Dividers Variants (NEW)

<a id="copilot"></a>
**Copilot gauge (experimental):** The Experimental Dividers family includes an optional Copilot segment that displays the Copilot premium gauge and percent remaining on the right prompt. This segment requires Copilot integration and is intentionally only included in the experimental family as a demo of more advanced, context-aware telemetry.

<table>
<tr>
<td align="center" width="50%">
<h4>AmberSunset</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.AmberSunset.png" alt="AmberSunset theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>BlueOcean</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.BlueOcean.png" alt="BlueOcean theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>CatppuccinMocha</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.CatppuccinMocha.png" alt="CatppuccinMocha theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>CherryMint</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.CherryMint.png" alt="CherryMint theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>ChristmasCheer</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.ChristmasCheer.png" alt="ChristmasCheer theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>DraculaNight</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.DraculaNight.png" alt="DraculaNight theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>EasterPastel</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.EasterPastel.png" alt="EasterPastel theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>FireIce</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.FireIce.png" alt="FireIce theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>ForestEmber</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.ForestEmber.png" alt="ForestEmber theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>GreenMatrix</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.GreenMatrix.png" alt="GreenMatrix theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>GruvboxDark</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.GruvboxDark.png" alt="GruvboxDark theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>HalloweenSpooky</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.HalloweenSpooky.png" alt="HalloweenSpooky theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>LavenderPeach</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.LavenderPeach.png" alt="LavenderPeach theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>MidnightGold</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.MidnightGold.png" alt="MidnightGold theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>MonokaiPro</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.MonokaiPro.png" alt="MonokaiPro theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>NordFrost</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.NordFrost.png" alt="NordFrost theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>Original</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.Original.png" alt="Original theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>PinkParadise</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.PinkParadise.png" alt="PinkParadise theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>PurpleReign</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.PurpleReign.png" alt="PurpleReign theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>RainbowBright</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.RainbowBright.png" alt="RainbowBright theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>RedAlert</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.RedAlert.png" alt="RedAlert theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>SolarizedDark</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.SolarizedDark.png" alt="SolarizedDark theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>TealCyan</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.TealCyan.png" alt="TealCyan theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>TokyoNight</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom-ExperimentalDividers.TokyoNight.png" alt="TokyoNight theme preview" width="100%">
</td>
</tr>
</table>
### 🚀 OhMyPosh Atomic Custom Variants

<table>
<tr>
<td align="center" width="50%">
<h4>AmberSunset</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.AmberSunset.png" alt="AmberSunset theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>BlueOcean</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.BlueOcean.png" alt="BlueOcean theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>CatppuccinMocha</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.CatppuccinMocha.png" alt="CatppuccinMocha theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>CherryMint</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.CherryMint.png" alt="CherryMint theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>ChristmasCheer</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.ChristmasCheer.png" alt="ChristmasCheer theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>DraculaNight</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.DraculaNight.png" alt="DraculaNight theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>EasterPastel</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.EasterPastel.png" alt="EasterPastel theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>FireIce</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.FireIce.png" alt="FireIce theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>ForestEmber</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.ForestEmber.png" alt="ForestEmber theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>GreenMatrix</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.GreenMatrix.png" alt="GreenMatrix theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>GruvboxDark</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.GruvboxDark.png" alt="GruvboxDark theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>HalloweenSpooky</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.HalloweenSpooky.png" alt="HalloweenSpooky theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>LavenderPeach</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.LavenderPeach.png" alt="LavenderPeach theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>MidnightGold</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.MidnightGold.png" alt="MidnightGold theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>MonokaiPro</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.MonokaiPro.png" alt="MonokaiPro theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>NordFrost</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.NordFrost.png" alt="NordFrost theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>Original</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.Original.png" alt="Original theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>Original</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.Original.png" alt="Original theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>PinkParadise</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.PinkParadise.png" alt="PinkParadise theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>PurpleReign</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.PurpleReign.png" alt="PurpleReign theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>RainbowBright</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.RainbowBright.png" alt="RainbowBright theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>RedAlert</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.RedAlert.png" alt="RedAlert theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>SolarizedDark</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.SolarizedDark.png" alt="SolarizedDark theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>TealCyan</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.TealCyan.png" alt="TealCyan theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>TokyoNight</h4>
<img src="assets/theme-previews/OhMyPosh-Atomic-Custom.TokyoNight.png" alt="TokyoNight theme preview" width="100%">
</td>
</tr>
</table>

### ✨ 1_shell-Enhanced Variants

<table>
<tr>
<td align="center" width="50%">
<h4>AmberSunset</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.AmberSunset.png" alt="AmberSunset theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>BlueOcean</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.BlueOcean.png" alt="BlueOcean theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>CatppuccinMocha</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.CatppuccinMocha.png" alt="CatppuccinMocha theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>CherryMint</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.CherryMint.png" alt="CherryMint theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>ChristmasCheer</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.ChristmasCheer.png" alt="ChristmasCheer theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>DraculaNight</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.DraculaNight.png" alt="DraculaNight theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>EasterPastel</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.EasterPastel.png" alt="EasterPastel theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>FireIce</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.FireIce.png" alt="FireIce theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>ForestEmber</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.ForestEmber.png" alt="ForestEmber theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>GreenMatrix</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.GreenMatrix.png" alt="GreenMatrix theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>GruvboxDark</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.GruvboxDark.png" alt="GruvboxDark theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>HalloweenSpooky</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.HalloweenSpooky.png" alt="HalloweenSpooky theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>LavenderPeach</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.LavenderPeach.png" alt="LavenderPeach theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>MidnightGold</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.MidnightGold.png" alt="MidnightGold theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>MonokaiPro</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.MonokaiPro.png" alt="MonokaiPro theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>NordFrost</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.NordFrost.png" alt="NordFrost theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>Original</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.Original.png" alt="Original theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>PinkParadise</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.PinkParadise.png" alt="PinkParadise theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>PurpleReign</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.PurpleReign.png" alt="PurpleReign theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>RainbowBright</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.RainbowBright.png" alt="RainbowBright theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>RedAlert</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.RedAlert.png" alt="RedAlert theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>SolarizedDark</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.SolarizedDark.png" alt="SolarizedDark theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>TealCyan</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.TealCyan.png" alt="TealCyan theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>TokyoNight</h4>
<img src="assets/theme-previews/1_shell-Enhanced.omp.TokyoNight.png" alt="TokyoNight theme preview" width="100%">
</td>
</tr>
</table>

### 🎯 Slimfat-Enhanced Variants

<table>
<tr>
<td align="center" width="50%">
<h4>AmberSunset</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.AmberSunset.png" alt="AmberSunset theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>BlueOcean</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.BlueOcean.png" alt="BlueOcean theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>CatppuccinMocha</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.CatppuccinMocha.png" alt="CatppuccinMocha theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>CherryMint</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.CherryMint.png" alt="CherryMint theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>ChristmasCheer</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.ChristmasCheer.png" alt="ChristmasCheer theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>DraculaNight</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.DraculaNight.png" alt="DraculaNight theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>EasterPastel</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.EasterPastel.png" alt="EasterPastel theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>FireIce</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.FireIce.png" alt="FireIce theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>ForestEmber</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.ForestEmber.png" alt="ForestEmber theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>GreenMatrix</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.GreenMatrix.png" alt="GreenMatrix theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>GruvboxDark</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.GruvboxDark.png" alt="GruvboxDark theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>HalloweenSpooky</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.HalloweenSpooky.png" alt="HalloweenSpooky theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>LavenderPeach</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.LavenderPeach.png" alt="LavenderPeach theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>MidnightGold</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.MidnightGold.png" alt="MidnightGold theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>MonokaiPro</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.MonokaiPro.png" alt="MonokaiPro theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>NordFrost</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.NordFrost.png" alt="NordFrost theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>Original</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.Original.png" alt="Original theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>PinkParadise</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.PinkParadise.png" alt="PinkParadise theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>PurpleReign</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.PurpleReign.png" alt="PurpleReign theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>RainbowBright</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.RainbowBright.png" alt="RainbowBright theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>RedAlert</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.RedAlert.png" alt="RedAlert theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>SolarizedDark</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.SolarizedDark.png" alt="SolarizedDark theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>TealCyan</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.TealCyan.png" alt="TealCyan theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>TokyoNight</h4>
<img src="assets/theme-previews/slimfat-Enhanced.omp.TokyoNight.png" alt="TokyoNight theme preview" width="100%">
</td>
</tr>
</table>

### 📦 AtomicBit-Enhanced Variants

<table>
<tr>
<td align="center" width="50%">
<h4>AmberSunset</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.AmberSunset.png" alt="AmberSunset theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>BlueOcean</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.BlueOcean.png" alt="BlueOcean theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>CatppuccinMocha</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.CatppuccinMocha.png" alt="CatppuccinMocha theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>CherryMint</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.CherryMint.png" alt="CherryMint theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>ChristmasCheer</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.ChristmasCheer.png" alt="ChristmasCheer theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>DraculaNight</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.DraculaNight.png" alt="DraculaNight theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>EasterPastel</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.EasterPastel.png" alt="EasterPastel theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>FireIce</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.FireIce.png" alt="FireIce theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>ForestEmber</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.ForestEmber.png" alt="ForestEmber theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>GreenMatrix</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.GreenMatrix.png" alt="GreenMatrix theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>GruvboxDark</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.GruvboxDark.png" alt="GruvboxDark theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>HalloweenSpooky</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.HalloweenSpooky.png" alt="HalloweenSpooky theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>LavenderPeach</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.LavenderPeach.png" alt="LavenderPeach theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>MidnightGold</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.MidnightGold.png" alt="MidnightGold theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>MonokaiPro</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.MonokaiPro.png" alt="MonokaiPro theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>NordFrost</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.NordFrost.png" alt="NordFrost theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>Original</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.Original.png" alt="Original theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>PinkParadise</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.PinkParadise.png" alt="PinkParadise theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>PurpleReign</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.PurpleReign.png" alt="PurpleReign theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>RainbowBright</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.RainbowBright.png" alt="RainbowBright theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>RedAlert</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.RedAlert.png" alt="RedAlert theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>SolarizedDark</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.SolarizedDark.png" alt="SolarizedDark theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>TealCyan</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.TealCyan.png" alt="TealCyan theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>TokyoNight</h4>
<img src="assets/theme-previews/atomicBit-Enhanced.omp.TokyoNight.png" alt="TokyoNight theme preview" width="100%">
</td>
</tr>
</table>

### 🧹 Clean-Detailed-Enhanced Variants

<table>
<tr>
<td align="center" width="50%">
<h4>AmberSunset</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.AmberSunset.png" alt="AmberSunset theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>BlueOcean</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.BlueOcean.png" alt="BlueOcean theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>CatppuccinMocha</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.CatppuccinMocha.png" alt="CatppuccinMocha theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>CherryMint</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.CherryMint.png" alt="CherryMint theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>ChristmasCheer</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.ChristmasCheer.png" alt="ChristmasCheer theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>DraculaNight</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.DraculaNight.png" alt="DraculaNight theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>EasterPastel</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.EasterPastel.png" alt="EasterPastel theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>FireIce</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.FireIce.png" alt="FireIce theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>ForestEmber</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.ForestEmber.png" alt="ForestEmber theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>GreenMatrix</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.GreenMatrix.png" alt="GreenMatrix theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>GruvboxDark</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.GruvboxDark.png" alt="GruvboxDark theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>HalloweenSpooky</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.HalloweenSpooky.png" alt="HalloweenSpooky theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>LavenderPeach</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.LavenderPeach.png" alt="LavenderPeach theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>MidnightGold</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.MidnightGold.png" alt="MidnightGold theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>MonokaiPro</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.MonokaiPro.png" alt="MonokaiPro theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>NordFrost</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.NordFrost.png" alt="NordFrost theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>Original</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.Original.png" alt="Original theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>PinkParadise</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.PinkParadise.png" alt="PinkParadise theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>PurpleReign</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.PurpleReign.png" alt="PurpleReign theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>RainbowBright</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.RainbowBright.png" alt="RainbowBright theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>RedAlert</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.RedAlert.png" alt="RedAlert theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>SolarizedDark</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.SolarizedDark.png" alt="SolarizedDark theme preview" width="100%">
</td>
</tr>
<tr>
<td align="center" width="50%">
<h4>TealCyan</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.TealCyan.png" alt="TealCyan theme preview" width="100%">
</td>
<td align="center" width="50%">
<h4>TokyoNight</h4>
<img src="assets/theme-previews/clean-detailed-Enhanced.omp.TokyoNight.png" alt="TokyoNight theme preview" width="100%">
</td>
</tr>
</table>

### 🎯 Quick Install

To use any theme, copy the command for your preferred variant:

```pwsh
# Replace <THEME_FOLDER> and <THEME_FILE> with the desired theme names
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/<THEME_FOLDER>/<THEME_FILE>" | Invoke-Expression
```

**Theme File Naming Convention:**

- OhMyPosh-Atomic-Custom.<Palette>.json - Flagship comprehensive theme

- 1_shell-Enhanced.omp.<Palette>.json - Single-line sleek theme

- slimfat-Enhanced.omp.<Palette>.json - Two-line compact theme

- \atomicBit-Enhanced.omp.<Palette>.json - Box-style technical theme

- clean-detailed-Enhanced.omp.<Palette>.json - Minimalist clean theme

**Examples:**

```pwsh
# Atomic Custom with Nord Frost palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/atomic/OhMyPosh-Atomic-Custom.NordFrost.json" | Invoke-Expression

# 1_shell Enhanced with Tokyo Night palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/1_shell-Enhanced.omp.TokyoNight.json" | Invoke-Expression

# Slimfat Enhanced with Dracula Night palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/slimfat/slimfat-Enhanced.omp.DraculaNight.json" | Invoke-Expression

# AtomicBit Enhanced with Gruvbox Dark palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/atomicBit/atomicBit-Enhanced.omp.GruvboxDark.json" | Invoke-Expression

# Clean-Detailed Enhanced with Catppuccin Mocha palette
oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/main/cleanDetailed/clean-detailed-Enhanced.omp.CatppuccinMocha.json" | Invoke-Expression
```

**Available Palettes:**

- **Original** - Your current vibrant tech theme

- **Nord Frost** - Arctic cool tones

- **Gruvbox Dark** - Warm retro earth tones

- **Dracula Night** - Bold purple/pink

- **Tokyo Night** - Modern neon blues

- **Monokai Pro** - Classic neon colors

- **Solarized Dark** - Eye-friendly

- **Catppuccin Mocha** - Soft pastels

- **Forest Ember** - Deep greens with amber

- **Pink Paradise** - Vibrant pink/magenta 💗

- **Purple Reign** - Royal purples 👑

- **Red Alert** - Fiery reds/oranges 🔥

- **Blue Ocean** - Deep ocean blues 🌊

- **Green Matrix** - Matrix-inspired greens 💚

- **Amber Sunset** - Warm sunset tones 🌅

- **Teal Cyan** - Electric teals ⚡

- **Rainbow Bright** - Vibrant rainbow colors 🌈

- **Christmas Cheer** - Festive holiday colors 🎄

- **Halloween Spooky** - Spooky Halloween theme 🎃

- **Easter Pastel** - Soft pastel Easter colors 🐰

- **Fire & Ice** - Dual-tone red/orange and blue/cyan ❄️🔥

- **Midnight Gold** - Deep navy blue and gold ⭐

- **Cherry Mint** - Cherry red and mint green 🍒

- **Lavender Peach** - Soft lavender and warm peach 🍑

---
