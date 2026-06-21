# Documentation Instructions

## Scope

These instructions apply to `docs/`.

## Documentation Style

- Keep docs task-oriented and consistent with the existing guide structure.
- Preserve relative links and update `docs/DOCUMENTATION-INDEX.md` when adding, renaming, or removing documentation pages.
- Keep commands copy-pasteable from the repository root unless the surrounding section clearly says otherwise.
- Use fenced code blocks with the correct language tag, especially `pwsh`, `powershell`, `json`, `jsonc`, `yaml`, and `fish`.
- If a page includes Oh My Posh Go templates such as `{{ if ... }}`, protect them from GitHub Pages/Jekyll Liquid processing. Use existing raw wrappers or escaped braces as documented in `docs/GITHUB-PAGES-LIQUID.md`.
- Do not document unsupported schema fields or undocumented behavior as fact. If the repo does not validate or use it, keep it out.
- Keep security/privacy notes accurate: network-capable segments can call external services, and credentials should come from environment variables.

## Validation

For Markdown-only edits, run:

```pwsh
git diff --check -- docs
```

For docs that change commands, theme behavior, generated previews, or README-linked paths, run the relevant script or validation command from the root instructions.
