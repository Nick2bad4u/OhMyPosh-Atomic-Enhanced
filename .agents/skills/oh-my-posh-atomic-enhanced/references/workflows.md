# Task workflows

Run commands from the repository root with PowerShell 7 or later. Inspect generator parameters before adding flags or changing sources.

## ExperimentalDividers structure or shared behavior

1. Edit `OhMyPosh-Atomic-Custom-ExperimentalDividers.json`.
2. Validate the canonical config before broad regeneration.
3. Regenerate overlays and every root helper:

```pwsh
pwsh ./scripts/Generate-ExperimentalDividers.ps1 -Force
pwsh ./scripts/Make-FishVariant.ps1
pwsh ./scripts/Make-NoShellIntegration.ps1
pwsh ./scripts/Make-NoNetwork.ps1 -SourceTheme ./OhMyPosh-Atomic-Custom-ExperimentalDividers.json
pwsh ./scripts/Make-ExtendedVariant.ps1
pwsh ./scripts/Make-ColorCycleVariant.ps1 -Source ./OhMyPosh-Atomic-Custom-ExperimentalDividers.json
pwsh ./scripts/Make-GradientVariant.ps1
pwsh ./scripts/Make-GradientRampsVariant.ps1
pwsh ./scripts/Make-GradientRampsAutoShadeVariant.ps1
```

Do not run the parameterless ColorCycle generator for an ExperimentalDividers-only change; that target belongs to Atomic Custom.

## Atomic Custom or another family source

Edit the root family theme, then regenerate its palette overlays through the repository's family generator:

```pwsh
pwsh ./scripts/Generate-AllThemes.ps1 -Force
```

If `OhMyPosh-Atomic-Custom.json` changed, also refresh its ColorCycle helper:

```pwsh
pwsh ./scripts/Make-ColorCycleVariant.ps1
```

Review all five families after shared generator changes because their root sources remain independent.

## Palette changes

After editing `color-palette-alternatives.json`, regenerate all six families:

```pwsh
pwsh ./scripts/Generate-AllThemes.ps1 -Force
pwsh ./scripts/Generate-ExperimentalDividers.ps1 -Force
```

Run palette validation and inspect representative overlays from every family for correct `extends` targets and palette-only content.

## Helper-specific changes

Change the matching file under `scripts/variants/` or the matching `Make-*Variant.ps1`, then run only that helper generator first. Compare the result with its canonical root source and ensure the generated file did not become its own input. Widen to all helpers only when shared helper machinery changed.

## Preview changes

Oh My Posh v30.0.0 or later must be on `PATH`.

1. Run the focused export contract:

```pwsh
pwsh ./scripts/Test-ThemePreviewExport.ps1
```

2. Regenerate the full SVG gallery and README:

```pwsh
pwsh ./scripts/Generate-ThemePreviews.ps1 -Force
```

3. Rerun `Test-ThemePreviewExport.ps1` to verify committed-gallery count, valid SVG documents, all root-theme previews, and one-to-one README references.
4. Visually inspect representative outputs from each width family, especially ExperimentalDividers, Clean Detailed, gradients, and a generated `extends` overlay.

## Validation matrix

For a focused root theme or helper change:

```pwsh
pwsh ./scripts/Test-Themes.ps1
pwsh ./scripts/Pre-Upload-Validation.ps1
pwsh ./scripts/Validate-Palette.ps1 -ConfigPath ./OhMyPosh-Atomic-Custom-ExperimentalDividers.json
```

For generated overlays or shared generators:

```pwsh
pwsh ./scripts/Test-Themes.ps1 -IncludeGenerated
pwsh ./scripts/Pre-Upload-Validation.ps1
pwsh ./scripts/Validate-Palette.ps1
```

For preview changes, add:

```pwsh
pwsh ./scripts/Test-ThemePreviewExport.ps1
```

For `.github/` workflow changes, add:

```pwsh
actionlint
```

For PowerShell script changes, run PSScriptAnalyzer when available and classify existing warnings separately from new findings. Finish every change with:

```pwsh
git diff --check
```

If a broad gate exposes an unrelated pre-existing failure, record the exact file and diagnostic, keep the change scoped, and still prove the focused path.
