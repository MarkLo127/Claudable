#!/usr/bin/env bash
set -euo pipefail

# 確保 PATH 有 venv & ~/.local/bin
export PATH="/opt/venv/bin:/root/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# 若 cursor-agent 尚未安裝到卷，安裝一次
if ! ls -d /root/.local/share/cursor-agent/versions/* >/dev/null 2>&1; then
  echo "[bootstrap] Installing cursor-agent ..."
  curl -fsS https://cursor.com/install | bash
fi

# 建立 symlink
mkdir -p /root/.local/bin
latest_bin="$(ls -d /root/.local/share/cursor-agent/versions/*/cursor-agent 2>/dev/null | sort | tail -n1 || true)"
if [ -n "${latest_bin}" ]; then
  ln -sf "${latest_bin}" /root/.local/bin/cursor-agent
  echo "[bootstrap] cursor-agent -> ${latest_bin}"
else
  echo "[bootstrap] WARN: cursor-agent binary not found"
fi

# 顯示可用 CLI（除錯用）
for c in claude codex qwen gemini cursor-agent; do
  if command -v "$c" >/dev/null 2>&1; then
    echo "[bootstrap] $c: $( "$c" --version 2>&1 || true )"
  else
    echo "[bootstrap] $c: not found"
  fi
done

# 啟動 uvicorn
exec "$@"