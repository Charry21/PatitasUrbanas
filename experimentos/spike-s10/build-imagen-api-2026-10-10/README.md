# Build de la imagen Docker de la API (2026-10-10)

Evidencia nueva. No modifica ni sustituye ningún archivo existente de `experimentos/spike-s10/`.
Este documento registra lo observado; no emite veredicto.

## Entorno

- Contenedor Linux en la nube (Ubuntu 24.04.5 LTS, kernel 6.18.44, x86_64). **No es Windows/WSL2.**
- Docker Engine cliente y servidor 29.8.2 (API 1.56), containerd v2.3.6, runc 1.5.1, almacenamiento con el snapshotter de containerd. Detalle en `docker-version.txt` y `docker-info.txt`.
- Daemon iniciado a mano (`dockerd`) con `registry-mirrors: ["https://mirror.gcr.io"]`, porque Docker Hub limitó la tasa de descargas en una sesión anterior.
- La salida HTTPS del entorno pasa por un proxy que reemplaza el TLS (intercepción) con CA propias del entorno.
- Commit base: `3e56742` (main). Rama de trabajo: `claude/project-thread-hlv246`.

## Parte A: construcción de la imagen

| Intento | Dockerfile | Comando | Resultado |
|---|---|---|---|
| 1 | `app/Dockerfile` original | `intento-1-dockerfile-original/comando-build.txt` | **Falla**, exit 1, 16 s |
| 2 | Variante `Dockerfile.ca-proxy` (original + `agent-proxy-ca.crt`) | `intento-2-ca-proxy/comando-build.txt` | **Falla**, exit 1, 4 s |
| 3 | Variante `Dockerfile.ca-entorno` (original + CA de `/usr/local/share/ca-certificates`) | `intento-3-ca-entorno-completa/comando-build.txt` | **Éxito**, exit 0, 35 s |

Cada carpeta conserva su log completo (`build.log`), el comando, horas de inicio y fin, y el exit code (`build-resultado.txt`).

**Intento 1 (Dockerfile original `app/Dockerfile`, sin cambios).** Hechos observados: las dos imágenes base se
resolvieron y descargaron sin error (el log no muestra si cada capa vino del mirror o de Docker Hub). El build
falla en `RUN mvn -DskipTests package` con exit 1; Maven informa que no pudo transferir
`spring-boot-starter-parent:3.3.4` desde `repo.maven.apache.org` por `PKIX path building failed`.
El Dockerfile original **no construyó en este entorno**.

**Intento 2 (`intento-2-ca-proxy/Dockerfile.ca-proxy`, no el original).** Hechos observados: añade la importación
de `agent-proxy-ca.crt` al `cacerts` del JDK en la etapa de build; keytool imprime "Certificate was added to
keystore"; Maven falla con el mismo error PKIX y exit 1.

**Intento 3 (`intento-3-ca-entorno-completa/Dockerfile.ca-entorno`, no el original; desviación experimental).**
Es idéntico a `app/Dockerfile` salvo un paso en la **etapa de build** que instala las CA de
`/usr/local/share/ca-certificates/*.crt` del host en el sistema y en el `cacerts` del JDK (ver
`diff-vs-app-Dockerfile.txt`). La etapa final (`eclipse-temurin:21-jre` + `app.jar`) no cambia. Los
certificados no se versionan. Este intento **no** es una ejecución exitosa del Dockerfile original.

- Maven: `BUILD SUCCESS`, tests omitidos (`-DskipTests`, como en el Dockerfile original).
- Etiqueta: `patitas-urbanas-api:spike-s10`.
- **ID de imagen** (`docker image inspect -f '{{.Id}}'`, índice OCI con el snapshotter de containerd):
  `sha256:9562b9299e449af34f8d0ab375af4d11fa442202388ac87ededb8a04351e0b16`
- Digest del config de la imagen: `sha256:fd07c70c2c3b21f348ecfb203139929cbbd659e0562d30f4897c148b7dedd4ae`
- Bases resueltas: `maven:3.9.9-eclipse-temurin-21@sha256:3a4ab327…0211e`,
  `eclipse-temurin:21-jre@sha256:cff19e62…a36c5` (digests completos en `build.log`).
- `inspect` e historial completos en `intento-3-ca-entorno-completa/imagen.txt`.

## Parte B: arranque y respuesta del contenedor (verificación separada)

Comandos en `arranque-contenedor/comandos.txt`. Se reprodujo `docker-compose.yml` con `docker run` (mismas
variables y la misma base `postgres:16`), porque `docker compose up` reconstruiría con el `app/Dockerfile` original,
que falla aquí (intento 1). **`docker compose` no se probó.**

- PostgreSQL 16.15 aceptó conexiones (`postgres-version.txt`).
- API iniciada a las 00:11:17Z; log: `Started PatitasUrbanasApplication in 6.418 seconds`, Tomcat en el puerto 3000.
  Primera respuesta HTTP a las 00:11:25Z (`tiempos.txt`). Log completo en `api-container.log`.
- Respuestas observadas (`respuestas-http.txt`):
  - `GET /actuator/health` → 200, `status: UP`, `db: UP (PostgreSQL)`.
  - `GET /api/mascotas/buscar?lat=4.65&lng=-74.05&radio=5` → 200, `{"status":"success", "mensaje":"Endpoint geoespacial activo"}`.
  - `GET /api/mascotas` → 404; `GET /api/adopciones` → 405 con cabecera `Allow: POST`.
  - Sin parámetros, o con `radioKm` en vez de `radio`, `/buscar` → 400.
  - Nota sobre el código: `MascotaController.buscarMascotas` devuelve una cadena fija (comentario "Simulación de
    carga de respuesta"), así que el 200 de `/buscar` muestra que la ruta responde, no que haga una búsqueda real.
- Al detener: `docker stop` de la API terminó con exit code 137; la BD se había detenido 10 s antes
  (`estado-al-detener.txt`). **La causa no se investigó.**

## Interpretaciones (inferidas, no demostradas por este registro)

- El error PKIX es compatible con que el JDK de la imagen `maven` no confíe en la CA con la que el proxy de
  salida del entorno re-firma el TLS. Que el intento 3 construyera tras añadir esas CA es consistente con ello,
  pero el registro no demuestra que el código, el `pom.xml` y el Dockerfile original sean correctos en otro entorno.
- El fallo del intento 2 podría deberse a que keytool importa solo el primer certificado de un archivo con varios
  (`agent-proxy-ca.crt` contiene dos) o a que los contenedores salen por otras CA del entorno. No se aisló.
- El 404 de `GET /api/mascotas` es compatible con que no exista un handler GET en esa ruta; no se verificó otra causa.

## Pendiente o no verificado

- Build con el `app/Dockerfile` original sin modificar en un entorno sin intercepción TLS (por ejemplo, CI o una máquina local).
- `docker compose up` completo.
- Endpoints de escritura (POST) y pruebas automatizadas (`-DskipTests`).
- Windows/WSL2: nada de esto se ejecutó allí.
