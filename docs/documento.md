---
title: "Manejo de Scripts: Liberación y Despliegue Continuo"
subtitle: "Caso de estudio: API REST de Tienda en Línea"
author: "IRVIN ISAEL MARTINEZ ALEJO"
---

# 1. Caso de estudio

Una tienda en línea necesita publicar cambios de su API de productos (Node.js/Express) de forma rápida y segura. Hoy los despliegues son manuales, tardan horas y han provocado caídas del servicio. Se requiere automatizar la liberación y el despliegue continuo con pruebas automáticas, un entorno previo a producción y monitoreo.

# 2. Justificación del flujo de trabajo (pipeline)

El pipeline se implementa con **GitHub Actions** y tiene cuatro etapas encadenadas. Si una falla, las siguientes no se ejecutan.

| Etapa | Qué hace | Justificación |
|---|---|---|
| 1. Pruebas (CI) | Instala dependencias y ejecuta pruebas unitarias en cada push y pull request | Detecta errores en minutos, antes de que lleguen a otros entornos |
| 2. Construcción | Genera una imagen Docker versionada con el SHA del commit y la publica en GitHub Container Registry | Un único artefacto inmutable se promueve entre entornos; así lo probado es lo desplegado |
| 3. Liberación | Crea el entorno de liberación (staging) con Docker Compose y ejecuta pruebas de humo y de latencia | Valida el artefacto en un entorno parecido a producción antes de exponerlo a clientes |
| 4. Despliegue (CD) | Con aprobación manual, despliega a producción por SSH, verifica el healthcheck y revierte si falla | Reduce el riesgo; el rollback automático limita el tiempo de indisponibilidad |

**Beneficios:** menor tiempo de entrega, despliegues repetibles, trazabilidad (cada versión se liga a un commit), menos errores humanos y recuperación rápida ante fallos.

# 3. Entorno requerido

| Componente | Requisito |
|---|---|
| Repositorio y CI/CD | GitHub con GitHub Actions y GitHub Environments (`staging`, `production`) |
| Registro de imágenes | GitHub Container Registry (ghcr.io) |
| Entorno de liberación | Runner de GitHub (ubuntu-latest) con Docker y Docker Compose; levanta API, Prometheus y Grafana |
| Entorno de producción | Servidor Linux (Ubuntu 22.04, 1 vCPU, 1 GB RAM mínimo) con Docker, Docker Compose y acceso SSH |
| Aplicación | Node.js 20, Express, prom-client |
| Monitoreo | Prometheus (métricas y alertas) y Grafana (tableros) |
| Secretos | `PROD_HOST`, `PROD_USER`, `PROD_SSH_KEY` configurados en el entorno `production` |

# 4. Niveles de servicio acordados (SLA / SLO)

| Indicador | Objetivo |
|---|---|
| Disponibilidad mensual | 99.5 % (máximo aproximado de 3.6 h de caída al mes) |
| Latencia p95 de la API | menor a 500 ms |
| Tasa de errores 5xx | menor a 1 % de las peticiones |
| Tiempo de despliegue (commit a producción, sin contar aprobación) | menor a 15 minutos |
| Tiempo de recuperación (rollback) | menor a 5 minutos |
| Frecuencia de despliegue | al menos uno por semana |

# 5. Métricas para el monitoreo de la aplicación

La API expone el endpoint `/metrics` en formato Prometheus.

| Métrica | Fuente | Propósito |
|---|---|---|
| `up` | Prometheus | Disponibilidad del servicio |
| `http_request_duration_seconds` (histograma) | Aplicación | Latencia p50/p95/p99 y tasa de peticiones |
| Tasa de respuestas 5xx / total | Aplicación | Tasa de errores |
| `process_cpu_seconds_total` | prom-client | Consumo de CPU |
| `process_resident_memory_bytes` | prom-client | Consumo de memoria |
| `nodejs_eventloop_lag_seconds` | prom-client | Saturación del proceso Node.js |
| Duración y resultado del pipeline | GitHub Actions | Métricas de entrega (frecuencia y tasa de fallos) |

**Alertas** (archivo `monitoring/alerts.yml`): API caída por más de 1 min (crítica), latencia p95 mayor a 500 ms por 5 min (advertencia) y errores 5xx mayores al 1 % por 5 min (crítica).

# 6. Parámetros de configuración de las herramientas

| Herramienta | Parámetro | Valor |
|---|---|---|
| GitHub Actions | Disparadores | push y pull request a `main` |
| GitHub Actions | Runner | ubuntu-latest |
| GitHub Actions | Node | 20 |
| GitHub Environments | `staging` | sin aprobación |
| GitHub Environments | `production` | aprobación manual obligatoria |
| Docker | Imagen base | `node:20-alpine`, usuario no root |
| Docker | Healthcheck | cada 15 s, timeout 3 s, 3 reintentos |
| Docker | Etiqueta de imagen | SHA corto del commit |
| Compose (staging) | Puertos | API 3001, Prometheus 9090, Grafana 3002 |
| Compose (producción) | Límites | 0.5 CPU, 256 MB RAM, `restart: always` |
| Prometheus | Intervalo de scrape | 15 s, objetivo `api:3000/metrics` |
| Despliegue | Espera de salud | 20 intentos cada 3 s; si falla, rollback |
| Pruebas de humo | Umbral de latencia | 500 ms por petición |

# 7. Herramienta de liberación continua configurada y vinculada al entorno

El archivo `.github/workflows/ci-cd.yml` define el pipeline. La vinculación con el entorno de despliegue se hace así:

1. El job `release` usa el entorno `staging` y ejecuta `scripts/setup-release-env.sh` para crear el entorno de liberación.
2. El job `deploy` usa el entorno `production`, que exige aprobación y guarda los secretos de conexión al servidor.
3. El job `deploy` copia los archivos al servidor por SCP y ejecuta `scripts/deploy.sh` por SSH, con la imagen versionada generada en la etapa de construcción.

**Evidencia sugerida para la entrega:** captura de la pestaña *Actions* con las cuatro etapas en verde, captura de *Settings > Environments* y captura del tablero de Grafana o de `/metrics`.

# 8. Estructura del repositorio

| Ruta | Contenido |
|---|---|
| `.github/workflows/ci-cd.yml` | Scripts del flujo de trabajo (pipeline) |
| `scripts/setup-release-env.sh`, `docker-compose.release.yml`, `monitoring/` | Generación del entorno de liberación |
| `tests/unit/`, `tests/smoke/smoke-test.sh` | Pruebas unitarias y pruebas en el entorno de liberación |
| `scripts/deploy.sh`, `docker-compose.prod.yml` | Generación del despliegue y rollback |
| `app/` | Código de la API y su Dockerfile |
