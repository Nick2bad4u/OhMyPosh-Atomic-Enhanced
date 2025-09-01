# OhMyPosh-Atomic-Enhanced

Repo for a custom OhMyPosh config inspired by AtomicBit

![image](https://github.com/user-attachments/assets/8bec1ab8-10f0-48f2-81c1-c0b4c16c6fce)

## How the OhMyPosh Custom Theme Works

This theme is a highly customized configuration for [Oh My Posh](https://ohmyposh.dev/), designed to provide a visually rich, informative, and efficient prompt for your shell. It leverages advanced features of Oh My Posh, including segment styling, dynamic templates, mapped locations, and tooltips for various development environments.

### Theme Structure

- **Schema**: The theme uses the official Oh My Posh theme schema for validation and compatibility.
- **Accent Color**: Sets a primary accent color for visual consistency.
- **Blocks**: The prompt is divided into multiple blocks, each with its own alignment (left, right, or newline) and segments.

#### Left-Aligned Prompt

Contains segments for:

- **Shell Info**: Displays shell name and version, with mapped names for common shells.
- **Root Status**: Highlights if running as administrator/root.
- **Path**: Shows the current directory, with custom icons and mapped locations for quick recognition (e.g., "UW" for Uptime-Watcher repo, icons for Desktop/Documents/Downloads).
- **Git**: Shows branch, status, and upstream info, with color changes based on git state.
- **Execution Time**: Displays how long the last command took to run.
- **Status**: Indicates success or error of the last command.

#### Right-Aligned Prompt

Contains segments for:

- **System Info**: CPU, memory, and disk usage, with dynamic coloring.
- **OS Info**: Shows the operating system and WSL status.
- **Time**: Current date and time, with customizable format.
- **Weather**: Displays current temperature using OpenWeatherMap (OWM), with units and timeout settings.
- **Battery**: Shows battery status and state, with color changes for charging/discharging/full.

#### Right Prompt (RPROMPT)

Contains segments for:

- **Prompt Count**: Shows the number of prompts in the session.
- **Upgrade Notice**: Indicates if Oh My Posh can be upgraded.
- **Root Status**: Quick root indicator.

#### Newline Block

Contains segments for:

- **Decorative Line**: Visual separator for prompt clarity.
- **Session Info**: Shows username and SSH session status.
- **Status**: Indicates command status with icons.

### Key Features

- **Dynamic Templates**: Many segments use Go template syntax to display context-aware information (e.g., git status, shell name, mapped locations).
- **Mapped Locations**: Custom folder names/icons for frequently used paths, making navigation easier.
- **Segment Styling**: Uses "diamond" and "powerline" styles for modern, visually appealing separators and backgrounds.
- **Caching**: Segments cache their data for performance, with customizable durations and strategies (e.g., session, folder).
- **Tooltips**: Provides quick info for common tools (React, Python, Node, Java, Git, etc.) when detected in the current folder.
- **Status and Error Handling**: Segments change color and icons based on command success, errors, or git state.
- **Customization**: Nearly every aspect (colors, icons, templates, widths) can be adjusted to fit your workflow and preferences.

### Oh-My-Posh Installation

1. [Windows](https://ohmyposh.dev/docs/installation/windows)
2. [Linux](https://ohmyposh.dev/docs/installation/linux)
3. [MacOS](https://ohmyposh.dev/docs/installation/macos)

### How to Use

1. **Quick Start (from GitHub URL):** You can use the theme directly from the GitHub repository without downloading it:

  ```pwsh
  oh-my-posh init pwsh --config "https://raw.githubusercontent.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/refs/heads/main/OhMyPosh-Atomic-Custom.json" | Invoke-Expression
  ```

2. **Local Setup:** Copy the theme JSON (`OhMyPosh-Atomic-Custom.json`) to your system. Set your shell to use this theme with Oh My Posh:

  ```pwsh
  oh-my-posh init pwsh --config "<path-to>/OhMyPosh-Atomic-Custom.json" | Invoke-Expression
  ```

  Customize mapped locations, icons, and colors as needed in the JSON file.

### Advanced Customization

- **Segment Properties**: Each segment type (shell, path, git, etc.) has its own properties for fine-tuning behavior and appearance.
- **Templates**: Use Go template expressions to display dynamic info (see [Oh My Posh docs](https://ohmyposh.dev/docs/configuration/templates)).
- **Tooltips**: Add or modify tooltips for your favorite tools and languages.

For more details, see the [Oh My Posh documentation](https://ohmyposh.dev/docs/).
