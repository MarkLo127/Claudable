#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="claudable"
COMPOSE="docker compose -p ${PROJECT_NAME}"

echo "== AI Login Wizard =="
echo "這個精靈只會在 profile 'auth' 下啟動 login 服務做一次互動登入。"
echo "完成後使用：docker compose up -d  啟動 backend/frontend。"
echo
read -r -p "按 Enter 開始（Ctrl+C 取消）" _

# 先建置 login 映像
${COMPOSE} --profile auth build login

# 跑一次互動登入檢查器（需要 TTY）
${COMPOSE} --profile auth run --rm -it login

echo
echo "✅ 互動登入流程結束。"
echo "接著請啟動服務："
echo "  ${COMPOSE} up -d"