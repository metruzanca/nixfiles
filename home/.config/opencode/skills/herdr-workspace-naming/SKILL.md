---
name: herdr-workspace-naming
description: Rename a Herdr workspace (also called a space) to a relevant project or task label. Use only when the user explicitly asks to rename a Herdr workspace, space, or herder space.
---

# Rename a Herdr Workspace

Herdr calls a project-level container a **workspace**. A workspace owns tabs
and panes; it is not the same thing as a named Herdr session.

## Safety check

Before inspecting or changing Herdr state, verify that this agent is running
inside Herdr:

```bash
test "${HERDR_ENV:-}" = 1
```

If the check fails, stop and tell the user that workspace control is only
available from a Herdr-managed pane. Do not launch `herdr` just to inspect the
session.

## Choose the label

Use the workspace ID from the caller context when available:

```bash
printf '%s\n' "$HERDR_WORKSPACE_ID"
```

If it is empty, list workspaces and ask the user which one to rename:

```bash
herdr workspace list
```

When the user gives an explicit label, preserve it. Otherwise derive one from
the current repository and task:

- Prefer a concise product or repository name plus the active task.
- Include the branch only when it adds useful distinction.
- Use plain words, spaces, and punctuation that are easy to scan in a sidebar.
- Avoid generic labels such as `workspace`, `herdr`, `main`, or `untitled`.
- Keep the label short enough to remain readable in the sidebar.

If the context does not support a confident label, propose one and ask before
mutating the workspace.

## Rename

Use the installed Herdr CLI as the syntax authority. Confirm the target ID and
label immediately before changing state, then run:

```bash
herdr workspace rename "$HERDR_WORKSPACE_ID" "<label>"
```

For a different target, use the ID returned by `herdr workspace list` instead
of guessing it. Do not close, recreate, or rename tabs and panes as a
workaround. Do not rename a workspace the user did not identify or authorize.

After the command succeeds, report the old and new labels. If it fails, show
the error and leave the workspace unchanged.
