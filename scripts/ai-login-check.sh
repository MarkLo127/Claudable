#!/usr/bin/env bash
set -euo pipefail

RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; BLD=$'\033[1m'; NC=$'\033[0m'
ok(){ echo "${GRN}$*${NC}"; }
no(){ echo "${RED}$*${NC}"; }
warn(){ echo "${YLW}$*${NC}"; }

STRICT_CODEX="${STRICT_CODEX:-0}"

need=()

echo "== Checking CLIs in PATH =="
for c in claude codex gemini qwen cursor-agent; do
  if command -v "$c" >/dev/null 2>&1; then
    echo "  [OK] $c -> $(command -v "$c")"
  else
    no  "  [MISS] $c not found"; need+=("$c")
  fi
done
[ ${#need[@]} -gt 0 ] && { no "Missing CLIs: ${need[*]}"; exit 2; }

echo
echo "== Ensuring writable state directories =="
mkdir -p \
  /root/.claude/plugins /root/.claude/projects /root/.claude/sessions \
  /root/.gemini /root/.config/gemini /root/.config/openai /root/.config/cursor-agent \
  /root/.qwen /root/.local/share/cursor-agent || true

ready=1
for d in /root/.claude/plugins /root/.claude/projects /root/.claude/sessions \
         /root/.gemini /root/.config/gemini /root/.config/openai /root/.config/cursor-agent \
         /root/.qwen /root/.local/share/cursor-agent; do
  if [ -w "$d" ]; then
    echo "  [OK] $d writable"
  else
    no  "  [NO] $d not writable"; ready=0
  fi
done

echo
echo "== Checking interactive-auth readiness (no API keys) =="

# Claude：未登入時會提示 /login / authorize / Invalid 等
echo -n "  [Claude] "
if out=$(claude -p "ping" --output-format text --max-turns 1 2>&1 || true); then
  if echo "$out" | grep -qiE "/login|please log in|authorize|invalid|unauthorized"; then
    warn "not logged in. Run: ${BLD}docker compose run --rm -it login claude${NC}（在 REPL 輸入 ${BLD}/login${NC} 完成，然後 ${BLD}/exit${NC}）"
    ready=0
  else
    ok "ready"
  fi
else
  no "error running claude"; ready=0
fi

# Gemini：登入後 ~/.gemini（或 ~/.config/gemini）會有內容
echo -n "  [Gemini] "
if [ -n "$(ls -A /root/.gemini 2>/dev/null || true)" ] || [ -n "$(ls -A /root/.config/gemini 2>/dev/null || true)" ]; then
  ok "ready"
else
  warn "not logged in. Run: ${BLD}docker compose run --rm -it login gemini${NC}（可能要跑兩次；狀態寫在 ${BLD}~/.gemini${NC}）"
  ready=0
fi

# Qwen：登入後 ~/.qwen 會有檔案
echo -n "  [Qwen] "
if [ -n "$(ls -A /root/.qwen 2>/dev/null || true)" ]; then
  ok "ready"
else
  warn "not logged in. Run: ${BLD}docker compose run --rm -it login qwen${NC}"
  ready=0
fi

# Cursor Agent：確認已登入（憑證或狀態檔是否存在）
echo -n "  [Cursor] "
CURSOR_OK=0
if command -v cursor-agent >/dev/null 2>&1; then
  if grep -RqiE 'access_token|refresh_token|auth' /root/.config/cursor-agent 2>/dev/null \
     || grep -RqiE 'access_token|refresh_token|auth' /root/.local/share/cursor-agent 2>/dev/null; then
    CURSOR_OK=1
  fi
  if [ "$CURSOR_OK" = "1" ]; then
    ok "ready"
  else
    warn "not logged in. Run: ${BLD}docker compose run --rm -it login 'cursor-agent login'${NC}；若版本無 login 子命令，直接執行 ${BLD}cursor-agent${NC} 進入登入流程"
    ready=0
  fi
else
  no "not installed"; ready=0
fi

# Codex：預設不擋啟動；STRICT_CODEX=1 時才強制
echo -n "  [Codex] "
if [ -n "$(ls -A /root/.config/openai 2>/dev/null || true)" ]; then
  ok "ready"
else
  if [ "$STRICT_CODEX" = "1" ]; then
    warn "not logged in. Run: ${BLD}docker compose run --rm -it login codex${NC}"
    ready=0
  else
    warn "not logged in (skipping, set STRICT_CODEX=1 to enforce)"
  fi
fi

echo
if [ "$ready" = "1" ]; then
  ok "All agents are ready. Proceed!"
  exit 0
else
  no "Some agents are not ready. Finish login then re-run: ${BLD}docker compose up -d${NC}"
  exit 1
fi
