#!/usr/bin/env bash
set -euo pipefail
echo "== AI Login Wizard =="
echo "將依序處理互動登入：Claude → Gemini → Qwen → Codex →（Cursor Agent僅驗證）"
read -p "按 Enter 開始（Ctrl+C 取消）" _

# Claude：進 REPL，手動輸入 /login 完成（完成後 /exit）
docker compose run --rm -it login bash -lc 'echo "在 REPL 輸入 /login 完成驗證，完成後 /exit"; claude || true'
read -p "Claude 完成後按 Enter 繼續" _

# Gemini：會顯示 URL 與要你貼回授權碼
docker compose run --rm -it login bash -lc 'gemini || true'
read -p "Gemini 完成後按 Enter 繼續" _

# Qwen：依 CLI 指示完成
docker compose run --rm -it login bash -lc 'qwen || true'
read -p "Qwen 完成後按 Enter 繼續" _

# Codex：依 CLI 指示完成（若需要）
docker compose run --rm -it login bash -lc 'codex || true'
read -p "Codex 完成後按 Enter 繼續" _

# Cursor Agent：一般不需登入；顯示版本確認可用
docker compose run --rm -it login bash -lc 'cursor-agent --version || true'

# 最終檢查，OK 才啟動整套服務
if docker compose run --rm login bash -lc '/usr/local/bin/ai-login-check.sh'; then
  echo "✅ 登入完成，啟動服務 ..."
  docker compose up -d
else
  echo "❌ 仍有未就緒的代理，請依提示完成登入後再重試。"
  exit 1
fi
