#!/usr/bin/env bash
set -euo pipefail

# 顏色
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; Z='\033[0m'

say() { echo -e "$@"; }
ok()  { say "${G}$*${Z}"; }
warn(){ say "${Y}$*${Z}"; }
err() { say "${R}$*${Z}"; }

HOME="${HOME:-/root}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

# 判斷是否在 TTY（非 TTY 時不要啟動互動 REPL）
IS_TTY=0
if [ -t 0 ] && [ -t 1 ]; then IS_TTY=1; fi

# 檢查各 CLI 可執行檔
have(){ command -v "$1" >/dev/null 2>&1; }

ready_gemini() {
  # 任何一處有檔案就視為已登入
  if [ -d "$HOME/.gemini" ] && [ -n "$(ls -A "$HOME/.gemini" 2>/dev/null || true)" ]; then return 0; fi
  if [ -d "$XDG_CONFIG_HOME/gemini" ] && [ -n "$(ls -A "$XDG_CONFIG_HOME/gemini" 2>/dev/null || true)" ]; then return 0; fi
  return 1
}
ready_cursor() {
  local d1="$HOME/.local/share/cursor-agent"
  local d2="$XDG_CONFIG_HOME/cursor-agent"
  if [ -d "$d1" ] && [ -n "$(ls -A "$d1" 2>/dev/null || true)" ]; then return 0; fi
  if [ -d "$d2" ] && [ -n "$(ls -A "$d2" 2>/dev/null || true)" ]; then return 0; fi
  return 1
}
ready_qwen() {
  local d1="$HOME/.qwen"; local d2="$HOME/.dashscope"
  if [ -d "$d1" ] && [ -n "$(ls -A "$d1" 2>/dev/null || true)" ]; then return 0; fi
  if [ -d "$d2" ] && [ -n "$(ls -A "$d2" 2>/dev/null || true)" ]; then return 0; fi
  return 1
}
# Claude/Codex 無「免金鑰」可驗證的登入狀態，僅顯示一次提示即略過
ready_claude() { return 1; }
ready_codex()  { return 1; }

say "${B}== AI Login Checker ==${Z}"
say "流程：Claude → Gemini → Qwen → Codex → Cursor"
echo

say "== Checking CLIs in PATH =="
for c in claude gemini qwen codex cursor-agent; do
  if have "$c"; then ok "  [OK] $c -> $(command -v $c)"; else err "  [MISS] $c"; fi
done
echo

# --- Claude（只啟動一次，純提示） ---
if have claude; then
  warn "─── Claude（只啟動一次；/exit 結束返回本檢查器）"
  if [ "$IS_TTY" -eq 1 ]; then
    claude || true
  else
    warn "（非互動模式，略過啟動）"
  fi
else
  warn "（未安裝 claude，跳過）"
fi
echo

# --- Gemini：最多自動重試 2 次以出現授權連結 ---
if have gemini; then
  if ready_gemini; then
    ok "─── Gemini 已就緒"
  else
    warn "─── Gemini（會自動嘗試啟動最多兩次以顯示授權流程）"
    if [ "$IS_TTY" -eq 1 ]; then
      gemini || true
      if ! ready_gemini; then gemini || true; fi
    else
      warn "（非互動模式，略過啟動）"
    fi
    if ready_gemini; then ok "Gemini 登入完成"; else warn "Gemini 尚未檢出登入"; fi
  fi
else
  warn "（未安裝 gemini，跳過）"
fi
echo

# --- Qwen：開啟 CLI 一次，讓它跑自己的登入流程 ---
if have qwen; then
  if ready_qwen; then
    ok "─── Qwen 已就緒"
  else
    warn "─── Qwen（開啟一次 CLI；完成後 /quit）"
    if [ "$IS_TTY" -eq 1 ]; then qwen || true; else warn "（非互動模式，略過啟動）"; fi
    if ready_qwen; then ok "Qwen 登入完成"; else warn "Qwen 尚未檢出登入"; fi
  fi
else
  warn "（未安裝 qwen，跳過）"
fi
echo

# --- Codex：提示即可（你目前不強制） ---
if have codex; then
  warn "─── Codex（僅提示，可在 REPL 內 /quit；未強制）"
  if [ "$IS_TTY" -eq 1 ]; then codex || true; fi
else
  warn "（未安裝 codex，跳過）"
fi
echo

# --- Cursor Agent：若未就緒就呼叫一次 login ---
if have cursor-agent; then
  if ready_cursor; then
    ok "─── Cursor Agent 已就緒"
  else
    warn "─── Cursor Agent（會執行一次 login）"
    if [ "$IS_TTY" -eq 1 ]; then cursor-agent login || cursor-agent || true; else warn "（非互動模式，略過啟動）"; fi
    if ready_cursor; then ok "Cursor Agent 登入完成"; else warn "Cursor Agent 尚未檢出登入"; fi
  fi
else
  warn "（未安裝 cursor-agent，跳過）"
fi
echo

say "== 最終檢查 =="
ok  "  狀態目錄可寫："
for d in \
  "$HOME/.claude/plugins" \
  "$HOME/.claude/projects" \
  "$HOME/.claude/sessions" \
  "$HOME/.gemini" \
  "$XDG_CONFIG_HOME/gemini" \
  "$XDG_CONFIG_HOME/openai" \
  "$XDG_CONFIG_HOME/cursor-agent" \
  "$HOME/.qwen" \
  "$HOME/.local/share/cursor-agent"
do
  mkdir -p "$d" 2>/dev/null || true
  if [ -w "$d" ]; then ok "    [OK] $d"; else warn "    [RO] $d"; fi
done
echo

READY_MSGS=()
[ "$(ready_gemini;  echo $?)" = "0" ] && READY_MSGS+=("Gemini")
[ "$(ready_qwen;   echo $?)" = "0" ] && READY_MSGS+=("Qwen")
[ "$(ready_cursor; echo $?)" = "0" ] && READY_MSGS+=("Cursor")

if [ "${#READY_MSGS[@]}" -gt 0 ]; then
  ok "就緒：${READY_MSGS[*]}"
else
  warn "尚未檢出任何互動登入完成（Claude/Codex 不強制）。"
fi

# 只要不是在互動 TTY（例如被誤啟動於 up -d）就直接退出 0，避免卡住
if [ "$IS_TTY" -eq 0 ]; then
  ok "非互動模式：僅檢查並退出。"
fi

exit 0