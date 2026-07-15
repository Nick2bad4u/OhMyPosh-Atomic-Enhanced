# Generated 1_shell Theme Variants

## Scope

These instructions apply to `1_shell/`.

## Rules

- Files in this folder are generated palette-only overlays that extend `1_shell-Enhanced.omp.json`.
- The root source is the complete Original theme; this folder must not contain `*.Original.json`.
- Do not hand-edit these JSON files for shared behavior, segment layout, tooltip, or palette-key changes.
- Make source changes in the root template or `color-palette-alternatives.json`, then regenerate.
- If a task explicitly targets one generated variant, explain why the change should remain variant-specific.

## Regeneration

From the repo root:

```pwsh
pwsh ./scripts/Generate-AllThemes.ps1 -Force
```

## Validation

```pwsh
pwsh ./scripts/Test-Themes.ps1 -IncludeGenerated
```
