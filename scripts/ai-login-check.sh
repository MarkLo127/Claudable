#!/usr/bin/env bash
set -euo pipefail

RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; NC=$'\033[0m'
ok(){ echo "${GRN}$*${NC}"; }
no(){ echo "${RED}$*${NC}"; }
warn(){ echo "${YLW}$*${NC}"; }

need=()

echo "== Checking CLIs in PATH =="
for c in claude codex gemini qwen cursor-agent; do
  if command -v "$c" >/dev/null 2>&1; then
    echo "  [OK] $c -> $(command -v $c)"
  else
    no  "  [MISS] $c not found"; need+=("$c")
  fi
done
[ ${#need[@]} -gt 0 ] && { no "Missing CLIs: ${need[*]}"; exit 2; }

echo
echo "== Checking interactive-auth readiness (no API keys) =="

ready=1

# Claude：確認可寫 + 嘗試非互動 ping，若提示 /login 表示未登入
for d in /root/.claude/plugins /root/.claude/projects /root/.claude/sessions; do
  mkdir -p "$d" || true
  if [ ! -w "$d" ]; then no "  [Claude] $d not writable"; ready=0; fi
done
echo -n "  [Claude] "
if out=$(claude -p "ping" --output-format text --max-turns 1 2>&1 || true); then
  if echo "$out" | grep -qiE "/login|please log in|authorize"; then
    warn "not logged in. Run: docker compose run --rm -it login claude   （進 REPL 後輸入 /login 完成，然後 /exit）"
    ready=0
  else
    ok "ready"
  fi
else
  no "error running claude"; ready=0
fi

# Gemini：登入後 ~/.config/gemini 會有檔案
echo -n "  [Gemini] "
if [ -d /root/.config/gemini ] && [ -n "$(ls -A /root/.config/gemini 2>/dev/null || true)" ]; then
  ok "ready"
else
  warn "not logged in. Run: docker compose run --rm -it login gemini   （依畫面開連結、貼授權碼）"
  ready=0
fi

# Qwen：登入後 ~/.qwen 會有檔案
echo -n "  [Qwen] "
if [ -d /root/.qwen ] && [ -n "$(ls -A /root/.qwen 2>/dev/null || true)" ]; then
  ok "ready"
else
  warn "not logged in. Run: docker compose run --rm -it login qwen"
  ready=0
fi

# Cursor Agent：通常不需登入；只驗證可執行
echo -n "  [Cursor] "
if command -v cursor-agent >/dev/null 2>&1; then
  ok "ready"
else
  no "not installed"; ready=0
fi

# Codex：若 CLI 需要登入，把狀態存於 ~/.config/openai，否則略過
echo -n "  [Codex] "
if [ -d /root/.config/openai ] && [ -n "$(ls -A /root/.config/openai 2>/dev/null || true)" ]; then
  ok "ready"
else
  warn "not logged in. Run: docker compose run --rm -it login codex"
  # 若你想「未登入也放行」就不要把 ready=0；我先保守擋住
  ready=0
fi

echo
[ "$ready" = "1" ] && { ok "All agents are ready. Proceed!"; exit 0; } \
                   || { no "Some agents are not ready. Finish login then re-run: docker compose up -d"; exit 1; }
