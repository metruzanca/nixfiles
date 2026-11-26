# AGENTS.md

If the user asks to make changes to this system, note that there is a Nix configuration at `~/nixfiles` — the system is managed declaratively from there (edit the modules and `make switch`), not by editing files by hand.

## Rules

- Use conventional commits (`feat:`, `fix:`, `chore:`, ...) and commit in small, frequent increments.
- never leave uncommitted changes
