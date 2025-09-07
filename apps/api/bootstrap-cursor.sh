#!/usr/bin/env bash
# 保持 cursor-agent 在 PATH 中可用；不做登入，只是幫 backend 拉起來
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/opt/venv/bin:$PATH"

# 若 cursor-agent 安裝在 versions 目錄，建立一次性 symlink
if ! command -v cursor-agent >/dev/null 2>&1; then
  if compgen -G "$HOME/.local/share/cursor-agent/versions/*/cursor-agent" >/dev/null; then
    v=$(ls -1 "$HOME/.local/share/cursor-agent/versions" | sort -V | tail -1)
    ln -sf "$HOME/.local/share/cursor-agent/versions/$v/cursor-agent" /usr/local/bin/cursor-agent || true
  fi
fi

exec "$@"