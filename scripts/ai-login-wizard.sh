#!/usr/bin/env bash
set -euo pipefail

echo "== AI Login Wizard (Claude 一次、其餘可重試) =="
echo "將依序處理互動登入：Claude → Gemini → Qwen → Codex → Cursor"
read -p "按 Enter 開始（Ctrl+C 取消）" _

run_i() { docker compose run --rm -it login bash -lc "$* || true"; }
check() { docker compose run --rm login bash -lc "$*"; }

NEED_RETRY=0

echo
echo "─── Claude（只開一次 REPL；退出後直接往下）"
echo "提示：在 REPL 內輸入 /login 完成瀏覽器驗證，完成後輸入 /exit 退出"
run_i 'claude'
# 不做循環重啟；只做一次狀態檢查，若未登入則記錄但不打斷後續流程
if ! check 'out=$(claude -p "ping" --output-format text --max-turns 1 2>&1 || true); ! echo "$out" | grep -qiE "/login|please log in|authorize|invalid|unauthorized"'; then
  echo "⚠️  Claude 仍未檢出登入（之後的總體檢查會再確認）。"
  NEED_RETRY=1
else
  echo "✅ Claude 就緒"
fi

echo
echo "─── Gemini（可能需要跑兩次才出現授權連結；會自動重試）"
until check '[ -n "$(ls -A /root/.config/gemini 2>/dev/null || true)" ]'; do
  run_i 'gemini'
done
echo "✅ Gemini 就緒"

echo
echo "─── Qwen（將重試到檢出已登入）"
until check '[ -n "$(ls -A /root/.qwen 2>/dev/null || true)" ]'; do
  run_i 'qwen'
done
echo "✅ Qwen 就緒"

echo
echo "─── Codex（可選；預設不強制）"
if ! check '[ -n "$(ls -A /root/.config/openai 2>/dev/null || true)" ]'; then
  run_i 'codex'
fi
echo "ℹ️  Codex 登入狀態將在最終檢查顯示（預設不強制）"

echo
echo "─── Cursor Agent（將重試到檢出已登入憑證）"
until check 'grep -RqiE "access_token|refresh_token|auth" /root/.config/cursor-agent 2>/dev/null || grep -RqiE "access_token|refresh_token|auth" /root/.local/share/cursor-agent 2>/dev/null'; do
  # 新版多半有 login 子命令；沒有就直接啟動讓它走登入流程
  if check "cursor-agent --help 2>/dev/null | grep -qi login"; then
    run_i 'cursor-agent login'
  else
    run_i 'cursor-agent'
  fi
done
echo "✅ Cursor Agent 就緒"

echo
echo "== 最終檢查 =="
if check '/usr/local/bin/ai-login-check.sh'; then
  echo "✅ 登入完成，啟動服務 ..."
  docker compose up -d
else
  echo "❌ 仍有未就緒的代理。請依提示完成登入後再重試："
  echo "   - Claude：docker compose run --rm -it login claude  # REPL 內 /login、完成後 /exit"
  echo "   - Gemini：docker compose run --rm -it login gemini  # 直到顯示連結並貼授權碼"
  echo "   - Qwen：  docker compose run --rm -it login qwen"
  echo "   - Codex： docker compose run --rm -it login codex"
  echo "   - Cursor：docker compose run --rm -it login 'cursor-agent login'  或直接 'cursor-agent'"
  exit 1
fi
