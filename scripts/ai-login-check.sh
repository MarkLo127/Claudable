#!/usr/bin/env bash
set -Eeuo pipefail

# ====== 可調參數 ======
: "${STRICT_CLAUDE:=0}"     # 1=Claude 未檢出登入就視為失敗並阻擋；0=僅警示
: "${STRICT_CODEX:=0}"      # 1=Codex 未登入阻擋；0=僅警示
: "${GEMINI_MAX_RUNS:=2}"   # Gemini 最高自動啟動次數（處理「Please restart」）
: "${LOGIN_ROOT:=/tmp/ai-login}"  # 本次登入流程的暫存記號目錄
mkdir -p "$LOGIN_ROOT"

# ====== 共用：UI & 工具 ======
title() { printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }
ok()    { printf '  \033[32m[OK]\033[0m %s\n' "$*"; }
warn()  { printf '  \033[33m[WARN]\033[0m %s\n' "$*"; }
err()   { printf '  \033[31m[ERR]\033[0m %s\n' "$*"; }
press_enter() { read -rp $'\n(按 Enter 繼續)… '; }

# 檢查路徑可寫
need_writable() {
  local d; for d in "$@"; do
    if [[ ! -d "$d" ]]; then mkdir -p "$d" 2>/dev/null || true; fi
    if [[ ! -w "$d" ]]; then err "$d 不可寫（請確認 volume 映射）"; return 1; fi
  done
}

# ====== 各家 CLI 的「登入檢測」函式（盡量無侵入 & 穩健） ======
is_claude_ready() {
  # 沒 API key 的情況下，Claude Code CLI 沒有標準的 OAuth 憑證檔。
  # 我們用「是否能在 ~/.claude/* 寫入 & 目錄非空」＋「是否曾開啟過會話檔」做近似檢測。
  local base="$HOME/.claude"
  [[ -w "$base" ]] || return 1
  # 有 plugins/sessions/projects 任一非空就視為使用中（避免無限重啟）
  shopt -s nullglob
  local any=( "$base"/sessions/* "$base"/projects/* "$base"/plugins/* )
  (( ${#any[@]} > 0 )) && return 0
  return 1
}

is_gemini_ready() {
  # 新版把狀態寫在 ~/.gemini；有檔且可寫即視為已初始化（OAuth 完成後會落檔）
  local g1="$HOME/.gemini" g2="$HOME/.config/gemini"
  [[ -w "$g1" && -n "$(ls -A "$g1" 2>/dev/null || true)" ]] && return 0
  [[ -w "$g2" && -n "$(ls -A "$g2" 2>/dev/null || true)" ]] && return 0
  return 1
}

is_qwen_ready() {
  # 常見檔：~/.qwen/*（例如 dashscope 憑證或設定）
  local q="$HOME/.qwen"
  [[ -w "$q" && -n "$(ls -A "$q" 2>/dev/null || true)" ]] && return 0
  return 0   # Qwen 多為即用即登，預設不阻擋
}

is_codex_ready() {
  local o="$HOME/.config/openai"
  [[ -w "$o" && -n "$(ls -A "$o" 2>/dev/null || true)" ]] && return 0
  return 1
}

is_cursor_ready() {
  # 安裝＋資料夾可寫視為 ready（目前無交互式 OAuth）
  local c="$HOME/.local/share/cursor-agent"
  command -v cursor-agent >/dev/null 2>&1 && [[ -w "$c" ]] && return 0
  return 1
}

# ====== 開始前：確認所有狀態目錄可寫 ======
title "Ensuring writable state directories"
need_writable \
  "$HOME/.claude/plugins" "$HOME/.claude/projects" "$HOME/.claude/sessions" \
  "$HOME/.gemini" "$HOME/.config/gemini" "$HOME/.config/openai" "$HOME/.config/cursor-agent" \
  "$HOME/.qwen" "$HOME/.local/share/cursor-agent"
ok "路徑可寫已確認"

# ====== 逐一處理登入 ======

# 1) Claude — 只啟一次；/exit 後不會自動再開；檢測失敗則視參數決定是否阻擋
title "Claude（/login 完成後 /exit；不會重複開啟）"
if [[ ! -f "$LOGIN_ROOT/claude.once" ]]; then
  touch "$LOGIN_ROOT/claude.once"
  claude || true
else
  warn "Claude 已開啟過本回合，略過重啟"
fi

if is_claude_ready; then
  ok "Claude 就緒"
else
  warn "Claude 尚未檢出登入（可能僅尚未建立任何會話檔）。"
  if [[ "$STRICT_CLAUDE" == "1" ]]; then
    err "STRICT_CLAUDE=1：阻擋後續服務啟動。請執行 /login 後再 /exit。"
    exit 1
  else
    warn "將不阻擋啟動（STRICT_CLAUDE=0）。可隨時 docker compose exec backend claude 補登。"
  fi
fi
press_enter

# 2) Gemini — 自動最多啟動 $GEMINI_MAX_RUNS 次（處理「Please restart」）；直到檢出 ~/.gemini 有檔
title "Gemini（自動處理需重啟的流程）"
if ! is_gemini_ready; then
  i=1
  while (( i <= GEMINI_MAX_RUNS )); do
    printf "  啟動 Gemini 第 %d 次…\n" "$i"
    gemini || true
    if is_gemini_ready; then
      ok "Gemini 就緒"
      break
    fi
    ((i++))
  done
fi
if ! is_gemini_ready; then
  warn "Gemini 仍未檢出完成，請再次執行 gemini 並完成瀏覽器授權；完成後重跑本檢查器。"
  exit 1
fi
press_enter

# 3) Qwen — 一次到位
title "Qwen（必要時會顯示登入連結）"
if ! is_qwen_ready; then
  qwen || true
fi
ok "Qwen 就緒（或無需登入）"
press_enter

# 4) Codex（OpenAI）— 預設不強制
title "Codex（OpenAI；預設不強制）"
if ! is_codex_ready; then
  codex || true
fi
if is_codex_ready; then ok "Codex 就緒"; else warn "Codex 未檢出登入（STRICT_CODEX=$STRICT_CODEX）"; fi
press_enter

# 5) Cursor Agent — 驗證即可
title "Cursor Agent（驗證）"
if ! is_cursor_ready; then
  cursor-agent || true
fi
if is_cursor_ready; then ok "Cursor Agent 就緒"; else warn "Cursor Agent 未就緒（檢查安裝/路徑）"; fi

# ====== 最終總結 ======
title "最終檢查"
pass=1

if is_claude_ready; then ok "Claude OK"; else
  if [[ "$STRICT_CLAUDE" == "1" ]]; then err "Claude 未就緒（STRICT_CLAUDE=1）"; pass=0; else warn "Claude 未就緒（略過）"; fi
fi

if is_gemini_ready;  then ok "Gemini OK";  else err "Gemini 未就緒";  pass=0; fi
if is_qwen_ready;    then ok "Qwen OK";    else err "Qwen 未就緒";    pass=0; fi
if is_cursor_ready;  then ok "Cursor OK";  else err "Cursor 未就緒";  pass=0; fi
if is_codex_ready;   then ok "Codex OK";   else
  if [[ "$STRICT_CODEX" == "1" ]]; then err "Codex 未就緒（STRICT_CODEX=1）"; pass=0; else warn "Codex 未就緒（略過）"; fi
fi

if (( pass )); then
  ok "所有必要代理就緒。可啟動 backend/frontend。"
  exit 0
else
  err "仍有未就緒項目，請依上面提示完成登入後再重試。"
  exit 1
fi
