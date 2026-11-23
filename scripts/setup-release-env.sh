#!/usr/bin/env bash
# Genera el entorno de liberación (staging) con Docker Compose
set -euo pipefail
export IMAGE="${IMAGE:?Define IMAGE (ej. ghcr.io/usuario/tienda-api:sha)}"
export APP_VERSION="${APP_VERSION:-staging}"

echo ">> Levantando entorno de liberación..."
docker compose -f docker-compose.release.yml pull api 2>/dev/null || true
docker compose -f docker-compose.release.yml up -d --remove-orphans

echo ">> Esperando a que la API esté saludable..."
for i in $(seq 1 30); do
  if curl -fs http://localhost:3001/health >/dev/null; then echo "API lista"; exit 0; fi
  sleep 2
done
echo "La API no levantó a tiempo"; docker compose -f docker-compose.release.yml logs api; exit 1
