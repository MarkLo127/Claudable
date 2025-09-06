#!/usr/bin/env bash
set -euo pipefail

echo "== AI Login Wizard (auto-retry) =="
echo "將依序處理互動登入：Claude → Gemini → Qwen → Codex → Cursor Agent"
read -p "按 Enter 開始（Ctrl+C 取消）" _

run_i() { docker compose run --rm -it login bash -lc "$* || true"; }
check() { docker compose run --rm login bash -lc "$*"; }

echo
echo "─── Claude"
# 先檢查是否已可用；若未登入，打開 REPL 讓你 /login，直到可用
until check 'out=$(claude -p "ping" --output-format text --max-turns 1 2>&1 || true); ! echo "$out" | grep -qiE "/login|please log in|authorize|invalid|unauthorized"'; do
  echo "提示：在 REPL 輸入 /login 完成瀏覽器驗證，完成後 /exit"
  run_i 'claude'
done
echo "✅ Claude 就緒"

echo
echo "─── Gemini（會自動重試，因為常需要跑兩次才出現連結）"
until check '[ -n "$(ls -A /root/.config/gemini 2>/dev/null || true)" ]'; do
  run_i 'gemini'
  # 有些版本第一次只讓你選 1) Login with Google；第二次才給連結
  # 這裡直接再跑一次互動流程；若仍未登入，until 會再循環
done
echo "✅ Gemini 就緒"

echo
echo "─── Qwen"
until check '[ -n "$(ls -A /root/.qwen 2>/dev/null || true)" ]'; do
  run_i 'qwen'
done
echo "✅ Qwen 就緒"

echo
echo "─── Codex（可選）"
# 若你完全不使用 Codex，可把下面兩行註解掉
if ! check '[ -n "$(ls -A /root/.config/openai 2>/dev/null || true)" ]'; then
  run_i 'codex'
fi
echo "ℹ️  Codex 登入狀態將在最終檢查顯示（預設不強制）"

echo
echo "─── Cursor Agent（通常不需登入，僅驗證可執行）"
run_i 'cursor-agent --version || true'

echo
echo "== 最終檢查 =="
if check '/usr/local/bin/ai-login-check.sh'; then
  echo "✅ 登入完成，啟動服務 ..."
  docker compose up -d
else
  echo "❌ 仍有未就緒的代理，請依提示完成登入後再重試。"
  exit 1
fi

echo
echo "─── Cursor Agent"
# 直到偵測到憑證才結束
until docker compose run --rm login bash -lc \
  'grep -RqiE "access_token|refresh_token|auth" /root/.config/cursor-agent 2>/dev/null || \
   grep -RqiE "access_token|refresh_token|auth" /root/.local/share/cursor-agent 2>/dev/null'; do
  # 若支援 login 子命令，優先用；否則直接執行 cursor-agent 讓它彈登入
  if docker compose run --rm login bash -lc "cursor-agent --help 2>/dev/null | grep -qi login"; then
    docker compose run --rm -it login bash -lc 'cursor-agent login || true'
  else
    docker compose run --rm -it login bash -lc 'cursor-agent || true'
  fi
done
echo "✅ Cursor Agent 就緒"
