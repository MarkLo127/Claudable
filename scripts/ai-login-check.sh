#!/usr/bin/env bash
set -euo pipefail

# 參數解析
INTERACTIVE=1
for arg in "$@"; do
  case "$arg" in
    --noninteractive|--check-only|-q)
      INTERACTIVE=0
      ;;
  esac
done
# 若未明確要求互動但無 TTY，則退回非互動
if [ "$INTERACTIVE" -eq 1 ] && { [ ! -t 0 ] || [ ! -t 1 ]; }; then
  INTERACTIVE=0
fi

# 參數（可由環境變數覆寫）
STRICT_CLAUDE="${STRICT_CLAUDE:-0}"
STRICT_CODEX="${STRICT_CODEX:-0}"
GEMINI_MAX_RUNS="${GEMINI_MAX_RUNS:-2}"

echo "== AI Login Checker =="
if [ "$INTERACTIVE" -eq 1 ]; then
  echo "模式：互動（將嘗試開啟各 CLI）"
else
  echo "模式：非互動（僅檢查狀態檔，不開 CLI）"
fi
echo "流程：Claude → Gemini → Qwen → Codex → Cursor"
echo

# 準備可寫目錄
for d in \
  "$HOME/.claude/plugins" "$HOME/.claude/projects" "$HOME/.claude/sessions" \
  "$HOME/.config/gemini" "$HOME/.gemini" "$HOME/.config/openai" \
  "$HOME/.config/cursor-agent" "$HOME/.qwen" "$HOME/.local/share/cursor-agent"
do
  mkdir -p "$d"
done

echo "== Checking CLIs in PATH =="
for c in claude gemini qwen codex cursor-agent; do
  if command -v "$c" >/dev/null 2>&1; then
    echo "  [OK] $c -> $(command -v "$c")"
  else
    echo "  [MISS] $c"
  fi
done
echo

# 小工具：執行一次 CLI（不阻斷）
run_cli() {
  local title="$1"; shift
  local cmd="$*"
  echo "─── $title"
  if [ "$INTERACTIVE" -eq 1 ]; then
    echo "（結束請輸入 /exit 或 Ctrl+C；返回本檢查器會自動繼續）"
    echo
    bash -lc "$cmd" || true
    echo
  else
    echo "（非互動模式：略過啟動 $cmd）"
    echo
  fi
}

# 判定是否有狀態檔
has_any_file() { find "$1" -type f -mindepth 1 -print -quit 2>/dev/null | grep -q .; }

################################
# Claude
################################
run_cli "Claude（只啟動一次）" "claude"
CLAUDE_READY=0
if has_any_file "$HOME/.claude/sessions" || has_any_file "$HOME/.claude/plugins"; then
  echo "✅ Claude ready"
  CLAUDE_READY=1
else
  echo "⚠️  Claude 未檢出登入（稍後總體檢查仍會列出指令）"
fi
echo

################################
# Gemini（常見需要跑兩次）
################################
GEMINI_READY=0
for i in $(seq 1 "$GEMINI_MAX_RUNS"); do
  run_cli "Gemini（第 $i 次）" "gemini"
  if [ -s "$HOME/.gemini/credentials.json" ] \
     || grep -q '"access_token"' "$HOME/.gemini/"* 2>/dev/null \
     || has_any_file "$HOME/.config/gemini"; then
    echo "✅ Gemini ready"
    GEMINI_READY=1
    break
  fi
  echo "… 尚未檢出 Gemini 登入，將再試一次"
  sleep 1
done
if [ "$GEMINI_READY" -eq 0 ]; then
  echo "⚠️  Gemini 未檢出登入"
fi
echo

################################
# Qwen
################################
run_cli "Qwen" "qwen"
QWEN_READY=0
if has_any_file "$HOME/.qwen"; then
  echo "✅ Qwen ready"
  QWEN_READY=1
else
  echo "⚠️  Qwen 未檢出登入"
fi
echo

################################
# Codex（預設不強制）
################################
run_cli "Codex（OpenAI Codex）" "codex"
CODEX_READY=1
if [ "$STRICT_CODEX" = "1" ]; then
  if has_any_file "$HOME/.config/openai"; then
    echo "✅ Codex ready"
  else
    echo "❌ Codex 未檢出登入（STRICT_CODEX=1）"
    CODEX_READY=0
  fi
else
  echo "ℹ️  Codex 狀態不強制，僅顯示"
fi
echo

################################
# Cursor Agent
################################
# 只驗證是否可用與有本地狀態
run_cli "cursor-agent" "cursor-agent"
cursor-agent --version >/dev/null 2>&1 || true
CURSOR_READY=0
if has_any_file "$HOME/.local/share/cursor-agent" || has_any_file "$HOME/.config/cursor-agent"; then
  echo "✅ Cursor Agent ready"
  CURSOR_READY=1
else
  echo "⚠️  Cursor Agent 未檢出登入（可在容器內執行：cursor-agent 或 cursor-agent login）"
fi
echo

################################
# 總結與退出碼
################################
echo "== 最終檢查 =="
echo "  Claude: $([ "$CLAUDE_READY" -eq 1 ] && echo READY || echo NOT-READY)"
echo "  Gemini: $([ "$GEMINI_READY" -eq 1 ] && echo READY || echo NOT-READY)"
echo "  Qwen:   $([ "$QWEN_READY"   -eq 1 ] && echo READY || echo NOT-READY)"
echo "  Codex:  $([ "$CODEX_READY"  -eq 1 ] && echo READY || echo NOT-READY)"
echo "  Cursor: $([ "$CURSOR_READY" -eq 1 ] && echo READY || echo NOT-READY)"
echo

EXIT_CODE=0
if [ "$STRICT_CLAUDE" = "1" ] && [ "$CLAUDE_READY" -eq 0 ]; then EXIT_CODE=1; fi
if [ "$STRICT_CODEX"  = "1" ] && [ "$CODEX_READY"  -eq 0 ]; then EXIT_CODE=1; fi

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "✅ 所需代理已就緒或未強制。你可以啟動 backend/frontend。"
else
  cat <<'MSG'
❌ 仍有未就緒代理。請依下列指令在互動 TTY 內完成後再重試：
  - Claude：docker compose run --rm -it login claude   # REPL 內 /login 完成後 /exit
  - Gemini：docker compose run --rm -it login gemini   # 直到出現授權連結並完成貼碼
  - Qwen：  docker compose run --rm -it login qwen
  - Codex： docker compose run --rm -it login codex
  - Cursor：docker compose run --rm -it login cursor-agent
MSG
fi

exit "$EXIT_CODE"
