---
name: disable-ui-skill
description: Disable the ui-design skill until /enable-ui-skill is run.
disable-model-invocation: true
---

Run this command with the Bash tool:

```bash
mkdir -p "$HOME/.local/state/claude" && touch "$HOME/.local/state/claude/ui-skill-disabled"
```

The `ui-design` skill is now disabled for this session and for future
sessions. Do not load or apply the `ui-design` skill until the user runs
`/enable-ui-skill`. Confirm this to the user in one line.
