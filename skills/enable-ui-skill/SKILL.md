---
name: enable-ui-skill
description: Enable the ui-design skill again after /disable-ui-skill.
disable-model-invocation: true
---

Run this command with the Bash tool:

```bash
rm -f "$HOME/.local/state/claude/ui-skill-disabled"
```

The `ui-design` skill is enabled again. Apply it to UI changes from now on.
Confirm this to the user in one line.
