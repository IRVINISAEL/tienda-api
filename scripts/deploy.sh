#!/usr/bin/env bash
# Despliegue a producción con rollback automático. Uso: IMAGE=... APP_VERSION=... ./scripts/deploy.sh
set -euo pipefail
export IMAGE="${IMAGE:?}" APP_VERSION="${APP_VERSION:?}"
FILE=docker-compose.prod.yml
PREV=$(docker inspect --format '{{.Config.Image}}' "$(docker compose -f $FILE ps -q api 2>/dev/null | head -1)" 2>/dev/null || true)

echo ">> Desplegando $IMAGE"
docker compose -f $FILE pull api
docker compose -f $FILE up -d --remove-orphans

for i in $(seq 1 20); do
  if curl -fs http://localhost/health >/dev/null; then echo "Despliegue exitoso"; exit 0; fi
  sleep 3
done

echo "Healthcheck falló. Haciendo rollback a: ${PREV:-ninguna}"
if [ -n "$PREV" ]; then IMAGE="$PREV" docker compose -f $FILE up -d; fi
exit 1
