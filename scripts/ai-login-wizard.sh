#!/usr/bin/env bash
set -Eeuo pipefail

# 讓你可以覆寫專案名稱
: "${COMPOSE_PROJECT_NAME:=claudable}"

echo "== AI Login Wizard =="
echo "將在 login 容器內啟動互動檢查器（Claude→Gemini→Qwen→Codex→Cursor）。"
echo "提示：Claude 只會啟動一次；Gemini 會自動重啟最多兩次以顯示授權連結。"
read -rp $'\n按 Enter 開始（Ctrl+C 取消）'

# 先確保映射目錄存在（避免 EROFS）
mkdir -p \
  apps/api \
  data \
  # 以下是 host 端不一定需要存在，但建一下更穩妥
  /tmp/claudable-host-placeholder >/dev/null 2>&1 || true

# 檢查必要 volumes 是否在 compose 中（尤其是 ~/.gemini）
# 這裡不硬性解析 YAML，僅提示；真正的映射以 compose 為準
echo -e "\n[檢查] 請確認 docker-compose.yaml 有映射：gemini_home:/root/.gemini、gemini_state:/root/.config/gemini、claude_* 等。"

# 進容器跑檢查器（互動）
docker compose -p "$COMPOSE_PROJECT_NAME" run --rm -it \
  -e STRICT_CLAUDE="${STRICT_CLAUDE:-0}" \
  -e STRICT_CODEX="${STRICT_CODEX:-0}" \
  -e GEMINI_MAX_RUNS="${GEMINI_MAX_RUNS:-2}" \
  login /usr/local/bin/ai-login-check.sh

status=$?
if [[ $status -eq 0 ]]; then
  echo -e "\n✅ 互動登入完成，可啟動服務："
  echo "   docker compose -p $COMPOSE_PROJECT_NAME up -d"
else
  echo -e "\n❌ 尚未全部完成登入；可修正後重跑本嚮導。"
fi
exit $status
