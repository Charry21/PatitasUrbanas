# Desviaciones respecto al preregistro (registradas ANTES de medir)

Estas desviaciones afectan solo a cómo se construye la API. No cambian las hipótesis, los escalones, el script de carga ni el tratamiento de datos del [README](../README.md).

1. **Construcción de la imagen de la API.** El preregistro (§4) preveía construir con la variante `intento-3-ca-entorno-completa/Dockerfile.ca-entorno` del spike S10. En esta sesión ese build falla en `mvn package` porque los contenedores de build no tienen salida a Maven Central (`Unknown host repo.maven.apache.org`). Se hizo así:
   - `mvn -B -DskipTests package` en el host, sobre `app/` sin cambios (SHA-256 del jar en `resultados/entorno.txt`);
   - imagen con [`Dockerfile.runtime`](./Dockerfile.runtime), que es exactamente la etapa final de `app/Dockerfile` (`eclipse-temurin:21-jre` + `app.jar`).
2. **Petición de humo previa.** Antes de la serie se hizo 1 `GET /buscar` y 1 `POST /api/adopciones` para comprobar que la API responde. La fila creada se elimina sola: `ejecutar.sh` reinicia la API al inicio de cada serie y `ddl-auto=create-drop` recrea las tablas vacías.

Sin otras desviaciones al momento de este commit.
