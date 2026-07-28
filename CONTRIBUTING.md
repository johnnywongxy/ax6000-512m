# Contributing

## Before opening a PR

- Run `bash scripts/tests/prune-releases.test.sh` if you touched `scripts/prune-releases.sh`.
- The **Lint** workflow runs `actionlint`, `shellcheck`, and `yamllint` on PRs — fix issues rather than disabling checks.

## Commit messages

Conventional commits — `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`, `ci:`.

## Coding style

- Bash scripts: `set -euo pipefail`, source `scripts/lib/log.sh`, two-space indent.
- YAML: two-space indent, no trailing whitespace.
