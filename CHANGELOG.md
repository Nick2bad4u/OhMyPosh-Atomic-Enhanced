<!-- markdownlint-disable -->
<!-- eslint-disable markdown/no-missing-label-refs -->

<!-- {% raw %} -->

# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

[[c109e54](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/c109e54ded21e29ff1e453ca5e916c0d38b6d5df)...
[f41b596](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/f41b5968bee7cbf0fbda1e3fc0eecfe1ec3bd216)]
([compare](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/compare/c109e54ded21e29ff1e453ca5e916c0d38b6d5df...f41b5968bee7cbf0fbda1e3fc0eecfe1ec3bd216))

### ✨ Features

- ✨ [feat] Add new themes and refactor generation script

This commit introduces a significant update to the theme generation process and expands the available theme collection.

✨ **[feat] New Themes Added**

- Introduces several new Oh My Posh themes, each with a unique color palette:
  - `CherryMint` 🍒
  - `ChristmasCheer` 🎄
  - `EasterPastel` 🥚
  - `FireIce` 🔥🧊
  - `HalloweenSpooky` 🎃
  - `LavenderPeach` 🍑
  - `MidnightGold` 🌙
  - `RainbowBright` 🌈

🚜 **[refactor] Theme Generation Script**

- Updates the `Generate-AllThemes.ps1` script to support processing multiple source theme files instead of just one.
  - This allows for greater flexibility in generating theme variants from different base templates.
- Moves all generated `1_shell` themes into a dedicated `1_shell/` subdirectory for better organization.

🎨 **[style] Palette Standardization**

- Alphabetizes the color palette keys within all existing theme JSON files.
- Adds missing color keys like `cyan_renamed` to ensure consistency across all themes.

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(71e686d)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/71e686df7962b2a3f607c6ac9fcb3e798b6ddba3)

- ✨ [feat] Add a collection of new oh-my-posh themes

This commit introduces eleven new themes for the 'oh-my-posh' shell prompt, providing a wide range of aesthetic choices for the user's terminal.

✨ [feat] New Themes Added:

- Adds a base "Enhanced" theme template which includes a rich, two-line prompt layout, detailed segments for git, system info, and execution time, and an extensive set of interactive tooltips.
- Introduces eleven distinct color palette variations based on this template:
  - `AmberSunset` 🌅: Warm, sunset-inspired oranges and yellows.
  - `BlueOcean` 🌊: Cool and calming shades of blue.
  - `CatppuccinMocha` ☕: The popular, soothing Catppuccin Mocha palette.
  - `DraculaNight` 🧛: The classic dark theme with vibrant pinks and purples.
  - `ForestEmber` 🌲: Earthy greens and warm ember tones.
  - `GreenMatrix` 📟: A retro, digital green-on-black style.
  - `GruvboxDark` 📦: The much-loved Gruvbox dark color scheme.
  - `MonokaiPro` 💻: A theme based on the Monokai Pro editor colors.
  - `NordFrost` ❄️: Cool, arctic blues from the Nord color palette.
  - `Original` 🎨: A diverse and colorful default palette.
  - `PinkParadise` 🌸: A bright and playful pink-dominant theme.

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(41837ec)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/41837ec382fb7c85c07b6849ebd476921f3bca58)

- ✨ [feat] Add image.settings.json and preview PNG for Atomic theme
- Add image.settings.json with colors, font paths, author, background color and cursor used for image generation/preview
- Add OhMyPosh-Atomic-Cust.png preview asset

🎨 [style] Enhance OhMyPosh-Atomic-Custom.json: mappings, segments, palette and caching

- Add terminal_background and finalize structural keys (cycle, extends, palettes)
- Expand and reorder mapped_locations with emoji-labeled shortcuts and Windows path mappings; dedupe and improve labels for clearer folder display
- Introduce npm, node and java segments (templates, version fetching, min_width, and style) and insert them into prompt blocks
- Increase cache durations and set session strategies where appropriate (battery 30s→60m, path cache 1h, consistent session strategy); bump ipify http_timeout to 5000ms
- Extend palette with colors required by new segments and add shell_names plus additional user/host mappings; minor reformatting for readability

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(2eabaf4)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/2eabaf45a7051330bc08c20edb20fd31e025856a)

- ✨ [feat] Add two enhanced Oh My Posh themes (1_shell-Enhanced, atomicBit-Enhanced)
- Add 1_shell-Enhanced.omp.json: new multi-block theme with diamond/plain styles, left/right/newline prompt layout, enriched segments (session, time, git, path, status, sysinfo, battery, shell, executiontime, connection, project, winreg, text, root, python, node, java) and customized templates/icons
- Add extensive tooltips and http/ipify checks (react, typescript, vite, vitest, playwright, tailwindcss, zustand, chart.js, electron, storybook, axios, zod, prettier, typescript-eslint, eslint) with caching and improved properties
- Add mapped_locations and maps for user/host/folder shortcuts, plus palette, transient/secondary prompts, console title template, YAML schema and version 3 compatibility
- Add ohmyposh-official-themes/themes/atomicBit-Enhanced.omp.json: compact/plain variant of the theme tailored for official themes folder; includes left/right/newline blocks, many language/tool segments (node, python, java, dotnet, go, rust, dart, angular, aurelia, nx, julia, ruby, azfunc, aws, kubectl), sysinfo, battery, time, git, executiontime and status segments
- Tune defaults and properties across both themes: caching durations, http timeouts, icons, execution time formatting, memory/disk/cpu templates, prompt styling and improved platform fallbacks
- Add patch for pwsh bleed, enable cursor positioning and include helpful tips/commands for many segments to aid discoverability

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(357be79)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/357be7973988937550a346f74e6a30e325b18ef1)

- ✨ [feat] Add Merge-OhMyPoshThemes.ps1 to generate themed custom Oh My Posh themes
- Adds a PowerShell utility that applies visual styling from official themes to a custom theme "harness"
- Implements color helpers (hex parsing, hue/brightness, adjust, contrast), color pool extraction and palette mapping
- Derives primary/secondary/accent colors, builds a themed palette, and maps custom palette keys to suitable colors
- Merges segment/tooltips styling, preserves custom structure/settings, and adds missing prompt types with themed cues
- Supports single-file or directory processing (-ProcessAll) and writes merged Custom-<theme>.omp.json outputs

🧹 [chore] Remove legacy OhMyPosh-Cyberpunk.json and OhMyPosh-Wave.json

- Delete hard-coded theme JSONs now superseded by the new merge workflow
- Reduce duplication and centralize theme styling generation via Merge-OhMyPoshThemes.ps1

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(2d6d6cf)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/2d6d6cf12baac1ce4046490e2c1e9c6d94e446b1)

- ✨ [feat] Adds theme previewing scripts

Adds PowerShell scripts for previewing and cycling through Oh-My-Posh themes.

- ✨ [feat] Introduces `cycle-themes.ps1` to cycle through available themes, displaying each for a set duration, allowing users to preview themes in real-time.
  - Includes logic to load both official and custom themes, providing a comprehensive preview experience.
  - Implements command-line parameters to filter themes by type (official or custom) and adjust the display duration.
  - Adds error handling to gracefully exit if no themes are found and inform users about missing official themes.
  - 🎨 Integrates a visual display that shows the theme name and path during cycling including padding for a consistent look.
  - 🛑 Provides instructions to stop the theme preview with `Ctrl+C`.

- ✨ [feat] Creates `preview-themes.ps1` for interactively previewing themes, allowing users to step through themes one by one or jump to a specific theme.
  - Includes logic to load both official and custom themes, providing a comprehensive preview experience.
  - Adds command-line parameters to filter themes by type (official or custom).
  - Adds error handling to gracefully exit if no themes are found.
  - 🖱️ Implements interactive navigation using `Read-Host` to take `Enter` key to move to the next theme or `Q` key to quit.
  - 🔢 Allows users to input a number to jump to a specific theme
  - 🎨 Uses `oh-my-posh print preview` to display the theme.

- ✨ [feat] Introduces `theme-functions.ps1` to encapsulate theme previewing functions and aliases, streamlining theme management.
  - Includes functions to show all, custom, and official themes, enhancing usability.
  - Creates aliases for quick access to theme previewing commands (e.g., `themes`, `mythemes`, `official-themes`).
  - Exports the theme preview functions and aliases for use in PowerShell profiles, enabling persistent access.

- 🧹 [chore] Updates `ohmyposh-official-themes/themes/schema.json` to reference the correct schema URL and remove schema content.
  - Removes all schema definitions.
  - ✅ Keeps the schema version.
  - 💾 Creates a backup file of the original schema.

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(9eb36ac)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/9eb36ac8be6115943123162ad7d4f68319abcd6e)

- ✨ [feat] Adds new themes

Adds three new themes for oh-my-posh: Cyberpunk, Dracula, and Wave.

- ✨ Introduces "Cyberpunk" theme
  - 🎨 Implements a futuristic, neon-themed prompt
  - 🖥️ Shows OS, shell, root status, path, git branch, execution time, and status
  - 🔋 Includes system information like CPU load, memory usage, time, and battery status
  - 👤 Displays SSH session information
- ✨ Introduces "Dracula" theme
  - 🎨 Implements a dark, visually distinct prompt
  - 🖥️ Shows OS, shell, root status, path, git branch, execution time, and status
  - 🔋 Includes system information like CPU load, memory usage, and time
  - 👤 Displays SSH session information
- ✨ Introduces "Wave" theme
  - 🎨 Implements a wave-themed prompt with distinct colors
  - 🖥️ Shows OS, shell, root status, path, git branch, execution time, and status
  - 🔋 Includes system information like CPU load, memory usage, and time
  - 👤 Displays SSH session information

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(92f30bd)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/92f30bdb321f855a50f338a25d24adcbf50985a5)

- ✨ [feat] Enhance directory segment with agnoster style and color cycling

- Updates directory display to use 'agnoster_short' style for improved readability.
- Adds directory length, depth limits, and color cycling for clearer navigation context.
- Introduces custom folder formatting and visual separation options.
- Improves OS segment with explicit Windows 11 labeling for better user clarity.

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(ff6b259)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/ff6b259fe9f4fc8488472857b91fe8279d3f0b63)

### 🛡️ Security

- Merge pull request #3 from step-security-bot/chore/GHA-240455-stepsecurity-remediation

[StepSecurity] Apply security best practices [`(56c2020)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/56c2020416ae4931685856847e3218161a728f7d)

- [StepSecurity] Apply security best practices

Signed-off-by: StepSecurity Bot <bot@stepsecurity.io> [`(e186d72)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/e186d72ab84caa23fbed3535df48e29ccb6bccc4)

- Merge pull request #1 from step-security-bot/chore/GHA-150258-stepsecurity-remediation

[StepSecurity] Apply security best practices [`(33c614b)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/33c614b14f2864c052585f506e305b31c15f77cb)

- [StepSecurity] Apply security best practices

Signed-off-by: StepSecurity Bot <bot@stepsecurity.io> [`(026cb62)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/026cb621362deee10e869461b68119e7d718b34d)

### 🛠️ Other Changes

- Revise Dependabot settings for GitHub Actions

Updated Dependabot configuration for GitHub Actions to include cooldown, schedule, assignees, and labels. [`(93cbac7)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/93cbac710cf9634e5ffa431e80b63f18465013bd)

- Merge commit 'd17c2af9f14bf02cb7419231cf0bccb74cb5cfbe' as 'ohmyposh-official-themes' [`(1924536)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/192453675fbb06ed062262a98cd3e55a19661176)

- Squashed 'ohmyposh-official-themes/' content from commit f65456e6

git-subtree-dir: ohmyposh-official-themes
git-subtree-split: f65456e6de3b90d11332e3e05459b4427dda8dd7 [`(d17c2af)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/d17c2af9f14bf02cb7419231cf0bccb74cb5cfbe)

- Update README with image and theme details [`(eacb7a2)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/eacb7a27d4a62415b632e6b8eaa82e14cef02932)

- Initial commit [`(c109e54)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/c109e54ded21e29ff1e453ca5e916c0d38b6d5df)

### 📝 Documentation

- 📝 [docs] Improve theme docs and install steps; update color

- Updates documentation for clarity and usability, adding installation instructions for multiple platforms and improving quick start guidance.
- Refines formatting and structure for better readability, including consistent image embedding and list styles.
- Adjusts a segment foreground color for improved visual contrast.

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(93e6533)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/93e65333ed1479f37c41c52d6bb1397d5a3a9a24)

- 📝 [docs] Expand README with detailed theme overview

- Provides comprehensive documentation for the custom Oh My Posh theme, outlining its structure, segment features, visual enhancements, and usage steps.
- Highlights advanced customization options, dynamic templates, mapped locations, and integration details to help users better understand and tailor the prompt to their workflow.

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(9e547bc)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/9e547bc903f14312e8f235bcd2bb309ae4729b2b)

### 🎨 Styling

- 🎨 [style] Reformat theme JSON and improve segments for readability and consistency

- 🎨 [style] Reformat arrays/objects to multiline (exclude_folders, include_folders, background_templates, status_template, tips, iterm_features, etc.) for consistent styling
- ✨ [feat] Add revamped battery segment:
  - dynamic background_templates for Charging/Discharging/Full
  - 30s session cache, min_width, powerline/diamond layout and better icons (charged/charging/discharging/not_charging)
  - improved template to show icon/percentage or error
- ✨ [feat] Update OS segment:
  - set platform icons for linux/macos/windows (, , )
  - switch style to diamond and normalize spacing in template
- 🎨 [style] Standardize diamonds/powerline symbols and leading/trailing_diamond across tooltip/http and other segments
- 🧹 [chore] Remove duplicate/old battery block and tidy related templates (fix spacing, move templates to consistent format)

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(1c1ef8f)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/1c1ef8fb01a937d9c7ccb9eca669009538f1c700)

- 🎨 [style] Emphasize weather icon in OWM segment
- Update owm template to include <b>󰖐</b> before {{.Temperature}}{{.UnitIcon}}, making the weather icon bold for better visibility in the prompt

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(f09d43e)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/f09d43ebfcca1e52f122ada5b76b2e2be38f9cb9)

- 🎨 [style] Refactor color palette structure and enhance tooltip configurations
- Moved color palette definition to a more organized structure
- Added new tooltips for various HTTP methods with version display
- Updated prompt templates for improved readability and styling

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(9964329)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/996432995122ca8758049c800bb6545e74648af2)

- 🎨 [style] Format JSON arrays for readability and consistency

- Reformats multiline arrays and objects to improve readability and maintain consistent JSON style throughout configuration.
- Enhances maintainability by making edits and diffs clearer, especially for lists of tips and properties.

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(d2bc565)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/d2bc5655a0198ada8f07141e9055407e646c30e0)

- 🎨 [style] Refines prompt colors and powerline effects

- Harmonizes foreground and background colors for improved readability and session distinction.
- Removes unused color variables and updates templates for better clarity and consistency.
- Adjusts powerline inversion settings to achieve a more cohesive visual flow.
- Updates terminal screenshots to reflect current prompt appearance.

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(ba9e550)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/ba9e550a53a2a9ff31aee184dd7ccdc1e940d8bc)

- 🎨 [style] Refactors theme config for palette-driven colors and enhanced docs

- Shifts to a centralized palette for all color usage in the prompt config, enabling easier theme customization and consistency across segments.
- Updates all segment definitions to reference palette keys, improving readability and maintainability.
- Expands documentation with detailed usage instructions, color palette table, screenshots, and palette validation guidance for users.
- Adds a PowerShell script for validating palette usage, helping prevent config errors and unused keys.
- Includes new terminal screenshots for Windows and VS Code to illustrate cross-platform appearance.
- Improves template structure, segment styling, and mapped location handling for a more informative and visually rich prompt.

Addresses modern developer workflows by making theme updates safer, faster, and more transparent.

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(609016d)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/609016d07854c3f564c8046cbac596e5f4716ea7)

### 🧹 Chores

- 🧹 [chore] Add Jekyll \_config.yml to configure GitHub Pages site
- 🧹 [chore] Add remote_theme: pages-themes/hacker@v0.2.0
- 📝 [docs] Set site metadata: title, description, url
- 🧹 [chore] Enable Jekyll plugins: jekyll-sitemap, jekyll-seo-tag, jekyll-paginate, jekyll-feed, jekyll-archives, jekyll-language-plugin, jekyll-algolia, jekyll-mentions, jekyll-admin, jekyll-loading-lazy

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(f41b596)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/f41b5968bee7cbf0fbda1e3fc0eecfe1ec3bd216)

- _(website)_ Remove Docusaurus website and all related assets [`(443c4bd)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/443c4bd011c4bbea4979e56c8bcc192cc15df755)

- 🧹 [chore] Add sync-official-themes.ps1 to update official Oh-My-Posh themes
- Add PowerShell script ./sync-official-themes.ps1 that pulls the official themes subtree (ohmyposh-themes -> ohmyposh-official-themes) using `git subtree pull --prefix=ohmyposh-official-themes ... --squash`
- Print progress and outcome messages, show themes folder location and count JSON themes on successful update
- Print failure message with guidance to commit local changes when the subtree pull fails

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(70c0eb2)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/70c0eb2bf936853bc2104f8ed49d851f468a5914)

- 🧹 [chore] Refactor and enhance project configuration

- ⬆️ Updates dependencies and improves configuration files for enhanced project maintainability and performance.

- ⚙️ Refactors `.pre-commit-config.yaml` to improve readability and structure by using the correct syntax for defining hooks.
  - This change ensures that pre-commit hooks are correctly configured and executed, maintaining code quality and consistency.

- ✨ Enhances `OhMyPosh-Atomic-Custom.json` theme for a more informative and visually appealing terminal prompt.
  - ⚡ Enables async loading to improve prompt responsiveness.
  - 📍 Adds more comprehensive `mapped_locations` with regex support, providing more context-aware path shortening in the prompt.
  - 🎨 Updates the display of React, TypeScript, Vite, Vitest, Playwright, Tailwind CSS, Zustand, Chart.js, Electron, Storybook, Axios, Zod, Prettier, TypeScript-ESLint, and ESLint versions in the prompt to be more visually distinct and informative by bolding them and adding icons.
  - 🌐 Adds IPv6 address display to the prompt for more complete network information.
  - ⏱️ Increases cache duration for some segments to reduce API calls and improve performance.
  - ➕ Adds pre-upload validation script (`pre-upload-validation.ps1`) to ensure theme file integrity and validity before deployment.
    - ✅ Checks JSON syntax and validates palette key usage.
    - 🧪 Includes test assertions to verify theme configuration.
    - 🚀 Attempts to load the theme with Oh My Posh to ensure compatibility.
  - 🧪 Introduces `test_OhMyPosh-Atomic-Custom.json` for comprehensive testing of theme configurations.
    - ✅ Includes tests for schema validation, version validation, color validation, blocks structure, segment configurations, palette colors, tooltips, transient prompt, cache configuration, min width validation, maps configuration, upgrade configuration, console title template, final space configuration, and various line configurations.
  - 👷 Updates GitHub workflow files (`dependency-review.yml`, `scorecards.yml`) to use string literals for names and cron schedules, improving readability and consistency.

Signed-off-by: Nick2bad4u <20943337+Nick2bad4u@users.noreply.github.com> [`(01e94c3)`](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/commit/01e94c3b4907c3c026223bbce71ea690fad8aced)

## Contributors

Thanks to all the [contributors](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/graphs/contributors) for their hard work!

## License

This project is licensed under the [UnLicense](https://github.com/Nick2bad4u/OhMyPosh-Atomic-Enhanced/blob/main/LICENSE)
_This changelog was automatically generated with [git-cliff](https://github.com/orhun/git-cliff)._

<!-- {% endraw %} -->
