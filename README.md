# claude-setup

Claude Code configuration: global settings, instructions, status line, keybindings,
skills, and plugin/skill manifests.

## Branches

- `personal`: personal machine setup.
- `work`: work machine setup.

The checked-out branch is the active setup. `install.sh` symlinks this repo into
`~/.claude`, so `git checkout work` switches the live configuration immediately.

## Layout

| Path | Linked to |
|---|---|
| `config/settings.json` | `~/.claude/settings.json` |
| `config/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `config/statusline.sh` | `~/.claude/statusline.sh` (`[update icon |] Model \| Effort \| Ctx \| Session`) |
| `config/keybindings.json` | `~/.claude/keybindings.json` |
| `skills/<name>/` | `~/.claude/skills/<name>` |
| `plugins.json` | Marketplaces and plugins, installed with the `claude` CLI |
| `skills.json` | External skills, installed with `npx skills add` |

Claude Code writes some state (for example `feedbackSurveyState`) into
`settings.json`, so those changes show up in this repo.

## Install

Normally run from [terminal_installation](https://github.com/pythonPlant12/terminal_installation),
where this repo is the `ai/claude` submodule. Standalone:

```sh
git clone -b personal git@github.com:pythonPlant12/claude-setup.git
./claude-setup/install.sh
```

Existing files in `~/.claude` are moved to `~/.config_backup_<timestamp>/claude/` before linking.
