---
name: oh-my-posh-atomic-enhanced
description: "Maintains and validates canonical themes, ExperimentalDividers variants, palette overlays, v30 SVG previews, PowerShell generators, and CI in the OMP Atomic Enhanced repository. Use this skill when the user requests repository theme, generator, palette, preview, or workflow changes."
---

# Oh My Posh Atomic Enhanced

Use the repository's source-to-generated workflow. Treat the nearest `AGENTS.md` as authoritative; this skill routes the work and keeps the validation proportional.

## Inputs

- `canonical-sources` - Root theme JSON, palette data, variant definitions, preview settings, or workflow files owned by the requested change.
- `generator-scripts` - The inspected `Generate-*` or `Make-*` PowerShell scripts that own derived files.
- `validation-tools` - Repository PowerShell gates, the configured validator MCP, `actionlint`, and `git diff --check` as applicable.

## Outputs

- `generated-artifacts` - Updated family overlays, root helper themes, SVG previews, README gallery content, or other requested repository files.
- `validation-results` - Focused and widened gate outcomes, including any skipped or pre-existing failures.

## Start safely

1. Confirm the working directory is this repository and read every applicable `AGENTS.md` from the root to the target file.
2. Run `git status --short` before editing. Preserve unrelated and user-owned changes in a dirty worktree.
3. Read [references/repository-map.md](references/repository-map.md) before deciding whether a file is canonical, declarative generator input, generated output, or an upstream snapshot.
4. Inspect the relevant generator and validation scripts before changing themes or automation.

## Choose the owning source

- Edit a root family theme for shared structure or behavior in that family.
- Edit `OhMyPosh-Atomic-Custom-ExperimentalDividers.json` for shared ExperimentalDividers behavior.
- Edit `color-palette-alternatives.json` for palette data shared by generated families.
- Edit `scripts/variants/*.variant.json` or the matching `Make-*Variant.ps1` for helper-specific behavior.
- Edit `image.settings.json`, `theme-preview.data.json`, or `Generate-ThemePreviews.ps1` for preview layout, fixture data, or export behavior.
- Do not hand-edit generated family overlays or generated root helper themes when regeneration can express the change.
- Treat `ohmyposh-official-themes/` as an upstream snapshot unless the task explicitly requests a sync.

## Implement and regenerate

Read [references/workflows.md](references/workflows.md), then map `canonical-sources` through the owning `generator-scripts` to `generated-artifacts`. Start with a representative theme when changing generator behavior; widen after the focused output is correct.

Preserve Go templates, palette references, `extends` relationships, and environment-variable secret handling exactly. Prefer palette keys over new one-off colors. Keep network segments on HTTPS with the repository's timeout and cache conventions.

For schema questions, use the configured `oh-my-posh-validator` MCP when available:

- Validate a complete changed config with `validate_config`.
- Validate an isolated new or substantially changed segment with `validate_segment`.
- Still run the repository's PowerShell gates; MCP validation does not prove generation, preview export, or repository invariants.

## Validate proportionally

Use `validation-tools` on `generated-artifacts`: run the focused gate first, then widen according to [references/workflows.md](references/workflows.md) and record `validation-results`. Always finish with `git diff --check`. Review generated diffs for unexpected structure, palette, filename, preview-width, and README-gallery churn.

When Oh My Posh behavior or CLI flags are version-sensitive, verify against the installed CLI and current official documentation. The preview pipeline requires Oh My Posh v30.0.0 or later and exports deterministic SVG from recorded data.

## Handoff boundaries

- Report the files changed, generators run, validation results, and any skipped or pre-existing failures.
- Follow `.github/agent-commit-message-instructions.md` when committing.
- Commit or push only when requested.
- Do not tag, publish, or create a release without explicit authorization in the current request.
