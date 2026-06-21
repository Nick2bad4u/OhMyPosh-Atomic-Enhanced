# Asset Instructions

## Scope

These instructions apply to `assets/`.

## Rules

- Keep preview filenames matched to theme filenames so README gallery links stay valid.
- Treat `assets/theme-previews/` images as generated output from `scripts/Generate-ThemePreviews.ps1` unless the task explicitly asks for a manual image replacement.
- Do not replace real prompt screenshots with decorative or unrelated images.
- Keep binary changes intentional and review image dimensions/file sizes before committing.
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
git diff --check -- README.md docs assets
```
