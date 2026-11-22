#!/bin/sh
# Claude Code status line, installed to ~/.claude/statusline.sh:
#   [󰚰 | ]Model: Opus 5.5 | Effort: high | Ctx: 333K/1M | 5h: 23% | 7d: 41% | Session: 1h 05m
# The update icon shows only when Homebrew has a newer claude-code@latest
# than the running version. Reads the status line JSON on stdin.

input=$(cat)

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
latest_file="$cache_dir/latest-version"
stamp_file="$cache_dir/checked"

# Refresh the latest cask version in the background, at most every 6 hours.
# All output is detached so Claude Code does not wait for the request.
if [ ! -f "$stamp_file" ] || [ -n "$(find "$stamp_file" -mmin +360 2>/dev/null)" ]; then
  mkdir -p "$cache_dir" && touch "$stamp_file"
  (
    version=$(curl -fsS --max-time 10 https://formulae.brew.sh/api/cask/claude-code@latest.json | jq -r '.version // empty')
    [ -n "$version" ] && printf '%s\n' "$version" > "$latest_file.tmp" && mv "$latest_file.tmp" "$latest_file"
  ) </dev/null >/dev/null 2>&1 &
fi

line=$(printf '%s' "$input" | jq -r '
  def tokens:
    if . >= 1000000 then "\((. / 100000 | round) / 10)M"
    elif . >= 1000 then "\(. / 1000 | round)K"
    else tostring end;
  # Wall-clock time since the session started.
  def duration:
    (. / 1000 | floor) as $s
    | if $s >= 3600 then "\($s / 3600 | floor)h \($s % 3600 / 60 | floor | if . < 10 then "0\(.)" else tostring end)m"
      elif $s >= 60 then "\($s / 60 | floor)m"
      else "\($s)s" end;
  # Subscription usage; absent for API-key auth and before the first response.
  def percent: if . == null then "-" else "\(round)%" end;
  (.context_window.current_usage // {}) as $u
  | (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) as $used
  | "Model: \(.model.display_name // "-") | Effort: \(.effort.level // "-") | Ctx: \($used | tokens)/\(.context_window.context_window_size // 0 | tokens) | 5h: \(.rate_limits.five_hour.used_percentage | percent) | 7d: \(.rate_limits.seven_day.used_percentage | percent) | Session: \(.cost.total_duration_ms // 0 | duration)"
')

current=$(printf '%s' "$input" | jq -r '.version // empty')
latest=$(cat "$latest_file" 2>/dev/null)
if [ -n "$current" ] && [ -n "$latest" ] && [ "$current" != "$latest" ] &&
  [ "$(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -1)" = "$latest" ]; then
  # nf-md-update (Nerd Font), in the terminal theme's yellow.
  line="$(printf '\033[33m\xf3\xb0\x9a\xb0\033[0m') | $line"
fi

printf '%s\n' "$line"
