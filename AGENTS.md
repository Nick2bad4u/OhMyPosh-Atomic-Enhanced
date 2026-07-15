# Repository Instructions

## Scope

These instructions apply to the whole repository unless a more specific `AGENTS.md` exists in a subdirectory.

## Project Shape

This repo ships enhanced Oh My Posh theme JSON files, generated palette extensions, PowerShell tooling, documentation, GitHub workflows, and preview assets.

Primary source files live at the repo root:

- `OhMyPosh-Atomic-Custom-ExperimentalDividers.json` is the independent canonical source for ExperimentalDividers prompt structure, tooltips, and behavior.
- `OhMyPosh-Atomic-Custom.json`, `1_shell-Enhanced.omp.json`, `slimfat-Enhanced.omp.json`, `atomicBit-Enhanced.omp.json`, and `clean-detailed-Enhanced.omp.json` are base templates for the generated families.
- `color-palette-alternatives.json` is the palette source.
- `starship-atomic-enhanced.toml` is shipped as an extra config asset.

Generated palette-only `extends` overlays live in:

- `atomic/`
- `1_shell/`
- `slimfat/`
- `atomicBit/`
- `cleanDetailed/`
- `experimentalDividers/`

Each folder contains 37 non-original color overlays. The corresponding complete, non-extended Original theme lives at the repository root; `*.Original.json` files do not belong in family folders. Each overlay must extend its own family root, especially ExperimentalDividers from `OhMyPosh-Atomic-Custom-ExperimentalDividers.json`, never from `OhMyPosh-Atomic-Custom.json`.

Do not hand-edit generated overlays when the same change belongs in a root source theme or palette file. Regenerate instead.

## Editing Rules

- Keep JSON valid and parseable by PowerShell `ConvertFrom-Json`; duplicate keys are treated as failures.
- Preserve Oh My Posh template syntax exactly. Be careful with Go template blocks such as `{{ ... }}` and palette references such as `p:accent`.
- Preserve environment-variable based secret handling. Do not add hard-coded API keys, tokens, usernames, or placeholder secret files.
- Network-capable segments and tooltips must use HTTPS, reasonable timeouts, and cache settings where the repo validation expects them.
- Use palette entries for theme colors instead of introducing one-off hex values unless the surrounding file already uses direct colors for that exact purpose.
- Keep generated root helper variants in sync when changing the canonical ExperimentalDividers theme:
  - `OhMyPosh-Atomic-Custom-ExperimentalDividers.Fish.json`
  - `OhMyPosh-Atomic-Custom-ExperimentalDividers.NoShellIntegration.json`
  - `OhMyPosh-Atomic-Custom-ExperimentalDividers.NoNetwork.json`
- Preserve `<!-- {% raw %} -->` / `<!-- {% endraw %} -->` protection in Markdown files that contain Oh My Posh template examples.
- Do not edit files under `ohmyposh-official-themes/` as if they are first-party source.
- Avoid broad formatting churn in generated JSON unless regeneration is the requested work.

## Common Workflows

After editing an ExperimentalDividers root theme or helper behavior:

```pwsh
pwsh ./scripts/Generate-ExperimentalDividers.ps1 -Force
pwsh ./scripts/Make-FishVariant.ps1
pwsh ./scripts/Make-NoShellIntegration.ps1
pwsh ./scripts/Make-NoNetwork.ps1 -SourceTheme ./OhMyPosh-Atomic-Custom-ExperimentalDividers.json
```

For full palette generation:

```pwsh
pwsh ./scripts/Generate-AllThemes.ps1 -Force
pwsh ./scripts/Generate-ExperimentalDividers.ps1 -Force
```

For an offline variant:

```pwsh
pwsh ./scripts/Make-NoNetwork.ps1 -SourceTheme ./OhMyPosh-Atomic-Custom-ExperimentalDividers.json
```

For previews:

```pwsh
pwsh ./scripts/Generate-ThemePreviews.ps1 -Force
```

## Validation

Run the narrowest useful validation for the files touched, and widen when generation or shared behavior changes.

Core gates:

```pwsh
pwsh ./scripts/Test-Themes.ps1
pwsh ./scripts/Pre-Upload-Validation.ps1
pwsh ./scripts/Validate-Palette.ps1 -ConfigPath ./OhMyPosh-Atomic-Custom-ExperimentalDividers.json
```

Generated variant gate:

```pwsh
pwsh ./scripts/Test-Themes.ps1 -IncludeGenerated
```

Workflow gate:

```pwsh
actionlint
```

Whitespace gate:

```pwsh
git diff --check
```

If a broad generated validation exposes an unrelated pre-existing failure, keep the task scoped, report the exact failing file/segment, and still run a focused validation for the files you changed.

## Commit Style

Follow `.github/agent-commit-message-instructions.md` when committing. The repository expects commit subjects that start with an emoji and bracketed type, such as `📝 [docs] Add repository agent instructions`.
