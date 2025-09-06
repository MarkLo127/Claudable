#!/usr/bin/env bash
set -euo pipefail
proj="claudable"

echo "[*] Contexts:"
docker context ls || true
# 若需要可手動： docker context use orbstack  或  docker context use default

echo "[1/4] Compose down (with orphans)…"
docker compose -p "$proj" down --remove-orphans || true

echo "[2/4] Remove containers still using ${proj}_* volumes…"
for v in $(docker volume ls -q | grep "^${proj}_"); do
  ids=$(docker ps -a --filter volume="$v" -q)
  if [ -n "$ids" ]; then
    for id in $ids; do
      docker rm -fv "$id" || true
    done
  fi
done

echo "[3/4] Prune stopped/created containers…"
docker container prune -f || true

echo "[4/4] Remove ${proj}_* volumes…"
docker volume rm $(docker volume ls -q | grep "^${proj}_") || true

echo "✅ Done."
