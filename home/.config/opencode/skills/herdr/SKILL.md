---
name: herdr
description: Control Herdr terminal workspaces, tabs, panes, and recognized coding agents. Use only when running inside Herdr and the user asks to inspect or control Herdr.
---

# Herdr

Herdr is a persistent terminal workspace manager. It calls project-level
containers **workspaces**, layouts **tabs**, and terminals **panes**.

## Safety

Before any Herdr command, verify the caller is inside Herdr:

```bash
test "${HERDR_ENV:-}" = 1
```

If this fails, stop. Do not launch `herdr` or inspect another Herdr session.

## Operating rules

- Run `herdr --help` or the relevant command group when syntax is uncertain.
- Discover live resources with `herdr workspace list`, `herdr tab list`,
  `herdr pane list`, or `herdr agent list`.
- Use IDs returned by Herdr. Never guess IDs from examples or sidebar order.
- Use `--current` for the caller's pane when supported.
- Use `--no-focus` for background work unless focus changes are requested.
- Do not stop the server or close resources you did not create without explicit
  user authorization.

For workspace naming requests, also load `herdr-workspace-naming`.
