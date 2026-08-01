# Asset Instructions

## Scope

These instructions apply to `assets/`.

## Rules

- Keep preview filenames matched to theme filenames so README gallery links stay valid.
- Treat `assets/theme-previews/*.svg` as generated output from `scripts/Generate-ThemePreviews.ps1`; change the generator, recorded preview data, or settings instead of hand-editing individual SVGs.
- Do not replace real prompt screenshots with decorative or unrelated images.
- Do not restore legacy gallery PNGs. Review SVG dimensions and file sizes, and visually inspect representative outputs from every width family before committing.
- Keep every parsed root theme and generated family overlay represented exactly once in both `assets/theme-previews/` and the README gallery.
- `assets/TerminalIconsColorThemes/` contains supporting theme assets; preserve PowerShell data file syntax for `.psd1` files.

## Regeneration

From the repo root:

```pwsh
pwsh ./scripts/Generate-ThemePreviews.ps1 -Force
```

## Validation

For `.psd1` edits:

```pwsh
pwsh -NoProfile -Command "Import-PowerShellDataFile -Path './assets/TerminalIconsColorThemes/dracula.psd1' | Out-Null"
```

For preview changes, inspect the generated images and run:

```pwsh
pwsh ./scripts/Test-ThemePreviewExport.ps1
git diff --check -- README.md docs assets
```
