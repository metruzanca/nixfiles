# Global OpenCode Rules

These rules apply to every OpenCode session on this machine.

## Herdr sessions

- At the start of a session, check whether `HERDR_ENV=1`.
- When running inside Herdr, load and follow the `herdr` skill before using
  Herdr commands or controlling panes, tabs, workspaces, or other agents.
- Prefer `--current`, an explicit ID, or a unique agent name. Do not infer
  Herdr IDs from sidebar order.
- Use `--no-focus` for background work unless the user asks to change focus.
- Do not close or stop Herdr resources that this session did not create unless
  the user explicitly asks.

Do not launch Herdr merely to perform a normal coding task. If `HERDR_ENV` is
not set, do not inspect or control the Herdr session.
