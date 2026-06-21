# Script Instructions

## Scope

These instructions apply to `scripts/`.

## PowerShell Style

- Target PowerShell 7 or later.
- Keep scripts runnable from the repo root and from their own directory.
- Resolve relative paths against the repo root or `$PSScriptRoot`; do not assume the caller's current location unless the script explicitly documents that requirement.
- Use `Set-StrictMode` only if the script already supports it; otherwise prefer `$ErrorActionPreference = 'Stop'` and explicit validation.
- Use `-LiteralPath` for known filesystem paths and user-supplied paths whenever possible.
- Avoid external modules unless the script documents the dependency and the workflow installs it.
- Preserve existing parameter names where workflows or docs call them.
- Do not write secrets into generated theme files. Keep integrations environment-variable based.

## Generation Contracts

- `Generate-AllThemes.ps1` is the broad generator for the main theme families.
- `Generate-ExperimentalDividers.ps1` writes `experimentalDividers/*.json` from `OhMyPosh-Atomic-Custom-ExperimentalDividers.json`.
- `Make-FishVariant.ps1`, `Make-NoShellIntegration.ps1`, and `Make-NoNetwork.ps1` write root helper variants.
- `Normalize-Palettes.ps1` can rewrite `color-palette-alternatives.json`; review the diff carefully after running it.
- `Generate-ThemePreviews.ps1` writes images under `assets/theme-previews/` and may update README gallery content.

When changing generator behavior, run it against a small representative input first, then run the repo validation scripts before trusting the generated diff.

## Validation

For script changes, run the most relevant command:

```pwsh
pwsh ./scripts/Test-Themes.ps1
pwsh ./scripts/Pre-Upload-Validation.ps1
pwsh ./scripts/Validate-Palette.ps1
```

For generator changes that affect variants:

```pwsh
pwsh ./scripts/Generate-AllThemes.ps1 -Force
pwsh ./scripts/Generate-ExperimentalDividers.ps1 -Force
pwsh ./scripts/Test-Themes.ps1 -IncludeGenerated
```

For workflow-facing script changes, also run:

```pwsh
actionlint
```
