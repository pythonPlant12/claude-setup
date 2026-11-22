---
name: skills-used
description: >
  Footer format for the "Skills used" line that ends every reply. Apply on
  every turn, with or without skills, so the user sees which skills and MCP
  tools ran.
---

# Skills used footer

End every reply with one final line:

```
Skills used: <skill>, <skill> | MCP: <server.tool>, <server.tool>
```

Rules:
- Skills: each skill you invoked with the Skill tool, with the exact name you
  passed (`find-gaps`, `superpowers:brainstorming`), plus each skill a hook
  injected into this turn, written as `hook:<name>` (the `name:` from its
  frontmatter).
- MCP: each MCP tool you called, as `<server>.<tool>` taken from the tool id
  `mcp__<server>__<tool>` (`claude_ai_Atlassian.getJiraIssue`).
- Nothing used: `Skills used: none | MCP: none`.
- Each name once. Slash commands do not count.
- Keep the line last. Nothing after it.

A Stop hook (`~/.claude/hooks/skills-used.py`) checks the line against the
transcript and asks for a corrected line when it is missing or wrong. Write
it correctly the first time to avoid the extra turn.
