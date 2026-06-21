# Official Theme Snapshot Instructions

## Scope

These instructions apply to `ohmyposh-official-themes/`.

## Rules

- Treat this subtree as a snapshot/reference copy of upstream Oh My Posh themes.
- Do not apply custom Atomic Enhanced behavior here unless the task explicitly asks to update the snapshot or compare against upstream.
- Prefer syncing with `scripts/Sync-Official-Themes.ps1` over manual edits.
- Keep local custom themes in the repo root or generated family folders, not in this snapshot.

## Validation

After changing this subtree, run the command that made the change and verify JSON/YAML parsing for any touched files. If the change affects merged custom output, run:

```pwsh
pwsh ./scripts/Test-Themes.ps1
```
