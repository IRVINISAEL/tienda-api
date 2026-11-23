#!/usr/bin/env bash
# Pruebas en el entorno de liberación. Uso: smoke-test.sh http://localhost:3001
set -euo pipefail
BASE="${1:-http://localhost:3001}"
fail=0
check() { # nombre, comando
  if eval "$2" >/dev/null 2>&1; then echo "OK   $1"; else echo "FAIL $1"; fail=1; fi
}
check "health responde 200"        "curl -fs $BASE/health"
check "productos devuelve JSON"    "curl -fs $BASE/api/productos | grep -q nombre"
check "metrics disponible"         "curl -fs $BASE/metrics | grep -q http_request_duration_seconds"
# Prueba de latencia: SLA p95 < 500 ms (se mide con 20 peticiones)
check "latencia < 500ms" '
  for i in $(seq 1 20); do
    t=$(curl -o /dev/null -s -w "%{time_total}" '"$BASE"'/api/productos)
    awk -v t="$t" "BEGIN{exit !(t<0.5)}" || exit 1
  done'
exit $fail
