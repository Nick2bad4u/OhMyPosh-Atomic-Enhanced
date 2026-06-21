# GitHub Workflow Instructions

## Scope

These instructions apply to `.github/` and its subdirectories.

## Workflow Style

- Keep third-party action references pinned by full commit SHA, with a version comment when known.
- Keep permissions explicit and minimal for each workflow.
- Prefer thin workflows that call repo scripts instead of duplicating validation logic inline.
- For shell snippets, quote GitHub environment files such as `$GITHUB_OUTPUT`, `$GITHUB_ENV`, and `$GITHUB_STEP_SUMMARY`.
- Avoid fragile Bash patterns such as `ls | wc`, unquoted variables, unescaped Markdown backticks in heredocs, and `cat file | head`.
- Treat `pull_request_target` as privileged. Do not add checkout or script execution from untrusted PR content under that event unless the workflow is deliberately designed for it.
- Preserve `step-security/harden-runner` where the surrounding workflow already uses it.

## Validation

Run workflow linting after any workflow or action metadata edit:

```pwsh
actionlint
```

If `actionlint` reports ShellCheck findings that are not applicable to the runner shell or generated script context, verify the claim against the actual workflow before changing behavior.

Use `gh run view` / `gh run list` to inspect pushed CI failures. Pull logs before guessing at a fix.

## Commits

Follow `.github/agent-commit-message-instructions.md` for commit messages.
