#!/usr/bin/env bash
set -euo pipefail
docker compose -f docker-compose.release.yml down -v
