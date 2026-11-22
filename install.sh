#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
SKILLS_DIR="$SCRIPT_DIR/skills"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$(mktemp -d "$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)_XXXXXX")/claude"
CLAUDE_CASK="claude-code@latest"
OMO_REPOSITORY="https://github.com/mrzhbr/Oh_my_OpenClaude.git"
OMO_REF="5c1fb2142ad4436f0fa7349c3db191ad1b1d50b0"
OMO_MARKETPLACE_DIR="$CLAUDE_DIR/plugins/omo-marketplace"
OMO_DIR="$OMO_MARKETPLACE_DIR/omo"
ASD_REPOSITORY="https://github.com/danyuchn/asd-ste100-skill.git"
ASD_REF="32511c6992ecb5f1971e46a2943f2e6adceedafe"
ASD_DIR="$CLAUDE_DIR/skills/asd-ste100"

log() {
  printf '\n==> %s\n' "$1"
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  log "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    printf 'Homebrew installation did not add brew to PATH.\n' >&2
    exit 1
  fi
}

install_claude() {
  log "Installing Claude Code from Homebrew"
  if brew list --cask claude-code >/dev/null 2>&1; then
    brew uninstall --cask claude-code
  fi

  if ! brew list --cask "$CLAUDE_CASK" >/dev/null 2>&1; then
    # Old installer versions can leave these Claude Code binaries outside Homebrew tracking.
    rm -f "$(brew --prefix)/bin/claude"
    brew install --cask "$CLAUDE_CASK"
  else
    brew upgrade --cask "$CLAUDE_CASK" >/dev/null 2>&1 || true
  fi

  CLAUDE_BIN="$(brew --prefix)/bin/claude"
  if [[ ! -x "$CLAUDE_BIN" ]] || ! "$CLAUDE_BIN" --version >/dev/null 2>&1; then
    printf 'Claude Code CLI is unavailable after installation.\n' >&2
    exit 1
  fi

  if command -v bun >/dev/null 2>&1; then
    bun remove -g @anthropic-ai/claude-code >/dev/null 2>&1 || true
  fi
  rm -f "$HOME/.bun/bin/claude"
}

# Symlink $1 (a repo file or directory) to $2 under ~/.claude. The repo stays
# the source of truth, so edits on either side are the same file, and
# switching the repo branch (personal/work) switches the live config.
link_into_claude() {
  local source="$1" target="$2" relative
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    return
  fi
  if [[ -e "$target" || -L "$target" ]]; then
    relative="${target#"$CLAUDE_DIR"/}"
    mkdir -p "$BACKUP_DIR/$(dirname "$relative")"
    mv "$target" "$BACKUP_DIR/$relative"
  fi
  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
}

install_config() {
  log "Linking Claude Code configuration"
  mkdir -p "$BACKUP_DIR" "$CLAUDE_DIR"
  local file
  # statusline.sh: [update icon |] Model | Effort | Ctx | Session (statusLine in settings.json).
  for file in settings.json statusline.sh CLAUDE.md keybindings.json; do
    link_into_claude "$CONFIG_DIR/$file" "$CLAUDE_DIR/$file"
  done
  rm -f "$CLAUDE_DIR/commands/disable-caveman.md"
}

install_skills() {
  log "Linking Claude Code skills"
  local skill
  for skill in "$SKILLS_DIR"/*/; do
    skill="${skill%/}"
    link_into_claude "$skill" "$CLAUDE_DIR/skills/$(basename "$skill")"
  done
}

# Third-party skills listed in skills.json, installed by the skills CLI into
# ~/.agents/skills and linked into ~/.claude/skills.
install_external_skills() {
  log "Installing external skills"
  local name source
  while IFS=$'\t' read -r name source; do
    if [[ -e "$CLAUDE_DIR/skills/$name" ]]; then
      continue
    fi
    npx -y skills add "$source" --skill "$name" --agent claude-code --global --yes
  done < <(python3 -c 'import json,sys; [print(f"{k}\t{v}") for k, v in json.load(open(sys.argv[1])).items()]' "$SCRIPT_DIR/skills.json")
}

# Marketplaces and user-scope plugins listed in plugins.json, via the claude CLI.
install_plugins() {
  log "Installing Claude Code plugins"
  local known installed name source plugin
  known="$(claude plugin marketplace list --json 2>/dev/null || echo '[]')"
  while IFS=$'\t' read -r name source; do
    if ! python3 -c 'import json,sys; sys.exit(sys.argv[1] not in {m["name"] for m in json.load(sys.stdin)})' "$name" <<<"$known"; then
      claude plugin marketplace add "$source" || printf 'Marketplace %s not added; continuing.\n' "$name" >&2
    fi
  done < <(python3 -c 'import json,sys; [print(f"{k}\t{v}") for k, v in json.load(open(sys.argv[1]))["marketplaces"].items()]' "$SCRIPT_DIR/plugins.json")

  installed="$(claude plugin list --json 2>/dev/null || echo '[]')"
  for plugin in $(python3 -c 'import json,sys; print(" ".join(json.load(open(sys.argv[1]))["plugins"]))' "$SCRIPT_DIR/plugins.json"); do
    if ! python3 -c 'import json,sys; sys.exit(sys.argv[1] not in {p["id"] for p in json.load(sys.stdin)})' "$plugin" <<<"$installed"; then
      claude plugin install "$plugin" || printf 'Plugin %s not installed; continuing.\n' "$plugin" >&2
    fi
  done
}

install_caveman() {
  log "Installing Caveman for Claude Code"
  if ! command -v caveman >/dev/null 2>&1; then
    npm install -g @caveman-ai/cli
  fi
}

# Serena is not used. OMO ships it as an MCP server (.mcp.json), /init-deep
# writes it into project .mcp.json files, and agents/commands mention it.
strip_serena_from_omo() {
  python3 - "$@" <<'PY'
import json, pathlib, re, sys

for root in map(pathlib.Path, sys.argv[1:]):
    mcp = root / ".mcp.json"
    if mcp.is_file():
        servers = json.loads(mcp.read_text())
        if servers.pop("serena", None) is not None:
            mcp.write_text(json.dumps(servers, indent=2) + "\n")

    init_deep = root / "commands/init-deep.md"
    if init_deep.is_file():
        text = init_deep.read_text()
        text = text.replace(" and auto-configure Serena MCP for LSP support", "")
        text = text.replace(", and auto-configure Serena MCP if the project has language server support", "")
        text = re.sub(r'^\s*"mcp__plugin_omo_serena__\*",\n', "", text, flags=re.M)
        text = re.sub(r"^### Step 3: Auto-Configure Serena MCP\n.*?(?=^### Step 4)", "", text, flags=re.M | re.S)
        init_deep.write_text(text)

    for name in ("agents/hephaestus.md", "agents/oracle.md", "commands/refactor.md", "hooks/keyword_detector.py"):
        path = root / name
        if path.is_file():
            text = path.read_text()
            text = re.sub(r"^If Serena MCP is available.*?\n\n", "", text, flags=re.M | re.S)
            text = re.sub(r"^.*Serena.*\n", "", text, flags=re.M)
            path.write_text(text)
PY
}

remove_serena() {
  log "Removing Serena"
  local roots=("$OMO_DIR" "$CLAUDE_DIR/plugins/omo")
  local cached
  for cached in "$CLAUDE_DIR"/plugins/cache/omo-marketplace/omo/*/; do
    [[ -d "$cached" ]] && roots+=("${cached%/}")
  done
  strip_serena_from_omo "${roots[@]}"

  if command -v uv >/dev/null 2>&1 && uv tool list 2>/dev/null | grep -q '^serena-agent '; then
    uv tool uninstall serena-agent
  fi
  rm -rf "$HOME/.serena"
}

install_omo() {
  log "Installing Oh My OpenClaude"
  local temporary_directory
  temporary_directory="$(mktemp -d)"

  git clone "$OMO_REPOSITORY" "$temporary_directory/omo"
  git -C "$temporary_directory/omo" checkout --detach "$OMO_REF"

  mkdir -p "$CLAUDE_DIR/plugins" "$BACKUP_DIR/plugins"
  if [[ -e "$OMO_MARKETPLACE_DIR" || -L "$OMO_MARKETPLACE_DIR" ]]; then
    mv "$OMO_MARKETPLACE_DIR" "$BACKUP_DIR/plugins/omo-marketplace"
  fi
  mkdir -p "$OMO_MARKETPLACE_DIR/.claude-plugin"
  ditto "$temporary_directory/omo" "$OMO_DIR"
  strip_serena_from_omo "$OMO_DIR"
  cp "$CONFIG_DIR/omo-marketplace.json" "$OMO_MARKETPLACE_DIR/.claude-plugin/marketplace.json"
  "$CLAUDE_BIN" plugin marketplace remove omo-marketplace --scope user >/dev/null 2>&1 || true
  if ! "$CLAUDE_BIN" plugin marketplace add "$OMO_MARKETPLACE_DIR" --scope user; then
    restore_omo
    return 1
  fi
  "$CLAUDE_BIN" plugin uninstall omo@omo-marketplace >/dev/null 2>&1 || true
  if ! "$CLAUDE_BIN" plugin install omo@omo-marketplace --scope user --yes; then
    restore_omo
    return 1
  fi
  rm -rf "$temporary_directory"
}

install_asd_skill() {
  log "Installing ASD-STE100 skill"
  local temporary_directory
  temporary_directory="$(mktemp -d)"

  git clone "$ASD_REPOSITORY" "$temporary_directory/asd-ste100"
  git -C "$temporary_directory/asd-ste100" checkout --detach "$ASD_REF"

  mkdir -p "$CLAUDE_DIR/skills" "$BACKUP_DIR/skills"
  if [[ -e "$ASD_DIR" || -L "$ASD_DIR" ]]; then
    mv "$ASD_DIR" "$BACKUP_DIR/skills/asd-ste100"
  fi
  ditto "$temporary_directory/asd-ste100" "$ASD_DIR"
  rm -rf "$temporary_directory"
}

log "Claude setup branch: $(git -C "$SCRIPT_DIR" branch --show-current 2>/dev/null || true)"
ensure_homebrew
install_claude
install_config
install_skills
install_external_skills
install_plugins
remove_serena
install_caveman

printf '\nClaude Code setup complete. Claude uses normal technical prose and loads ASD-STE100 when its triggers match.\n'
