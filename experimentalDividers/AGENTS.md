# Generated ExperimentalDividers Variants

## Scope

These instructions apply to `experimentalDividers/`.

## Rules

- Files in this folder are generated palette-only overlays that extend `OhMyPosh-Atomic-Custom-ExperimentalDividers.json`, never `OhMyPosh-Atomic-Custom.json`.
- The root ExperimentalDividers source is the complete Original theme; this folder must not contain `*.Original.json`.
- Do not hand-edit these JSON files for shared behavior, segment layout, tooltip, or palette-key changes.
- Make source changes in the root ExperimentalDividers theme or `color-palette-alternatives.json`, then regenerate.
- Root helper variants are not in this folder; keep these root files synchronized separately when the canonical theme changes:
  - `OhMyPosh-Atomic-Custom-ExperimentalDividers.Fish.json`
  - `OhMyPosh-Atomic-Custom-ExperimentalDividers.NoShellIntegration.json`
  - `OhMyPosh-Atomic-Custom-ExperimentalDividers.NoNetwork.json`
  - `OhMyPosh-Atomic-Custom-ExperimentalDividers.Extended.json`
  - `OhMyPosh-Atomic-Custom-ExperimentalDividers.ColorCycle.json`

## Regeneration

For this folder only:

```pwsh
pwsh ./scripts/Generate-ExperimentalDividers.ps1 -Force -SkipRootVariants
```

For the full ExperimentalDividers family:

```pwsh
pwsh ./scripts/Generate-ExperimentalDividers.ps1 -Force
pwsh ./scripts/Make-FishVariant.ps1
pwsh ./scripts/Make-NoShellIntegration.ps1
pwsh ./scripts/Make-NoNetwork.ps1 -SourceTheme ./OhMyPosh-Atomic-Custom-ExperimentalDividers.json
pwsh ./scripts/Make-ExtendedVariant.ps1
pwsh ./scripts/Make-ColorCycleVariant.ps1 -Source ./OhMyPosh-Atomic-Custom-ExperimentalDividers.json
```

## Validation

```pwsh
pwsh ./scripts/Test-Themes.ps1
pwsh ./scripts/Test-Themes.ps1 -IncludeGenerated
```
