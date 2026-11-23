# Tienda API: CI/CD con GitHub Actions y Docker

Ver `docs/documento.md` para la justificación, SLAs, métricas y parámetros.

## Uso rápido
1. Crea un repositorio en GitHub y sube este contenido a la rama `main`.
2. En Settings > Environments crea `staging` y `production` (en `production` activa Required reviewers).
3. En `production` agrega los secretos `PROD_HOST`, `PROD_USER`, `PROD_SSH_KEY`.
4. Haz un push: el pipeline corre solo.
5. Prueba local: `docker build -t tienda-api:local app && IMAGE=tienda-api:local ./scripts/setup-release-env.sh && ./tests/smoke/smoke-test.sh`
