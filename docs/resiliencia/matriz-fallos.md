# Matriz de fallos — Módulo 6 (A2)

Construida a partir de:
- el C4 (`dossier/06-c4-contenedores.md`, `dossier/07-c4-componentes.md` y su tabla de trazado al código);
- el contrato de integración (`docs/integracion/contrato-api.yaml`);
- los resultados experimentales de A1 (`experimentos/10-crecimiento-s11/`) y de la inyección de fallos de la Semana 12 (`experimentos/12-inyeccion-fallos-s12/`).

**Estado de cada fila:**
- **Observado:** el fallo se provocó o se registró, y hay una evidencia que se puede repetir.
- **Hipotético:** el fallo es plausible por el diseño o por la configuración, pero no se ha provocado.
- **Observado / consecuencia hipotética:** el estímulo o la condición se registraron, pero la consecuencia para el usuario no se probó.

Una fila hipotética **no** es un fallo demostrado.

---

## 1. Componentes considerados (solo los que existen en el código)

| Componente C4 | Trazado al código | Fuente |
|---|---|---|
| Contenedor API Backend | `app/` (Spring Boot 3.3.4, Java 21), `app/Dockerfile` | `dossier/06` |
| Contenedor PostgreSQL | `docker-compose.yml` → `postgres:16` | `dossier/06` |
| Controlador de Adopciones | `api/adopciones/AdopcionController` | `dossier/07` |
| Servicio de Adopciones (TRX-02) | `api/adopciones/AdopcionService` (`@Transactional`) | `dossier/07` |
| Repositorios | `SolicitudAdopcionRepository`, `EtapaAdopcionRepository` | `dossier/07` |
| Controlador Geoespacial (simulado) | `api/mascotas/MascotaController` | `dossier/07` |
| Pool de conexiones (Hikari) y health check (Actuator) | Dependencias de Spring Boot en `app/pom.xml`; sin configuración propia en `application.properties` | `app/pom.xml` |

**Excluidos por no existir en el código:** Servicio de Mapas, Notificaciones, Identidad y Atención veterinaria (`docs/dominio/`). Sus fallos no se modelan hasta que exista el componente.

---

## 2. Matriz

| Id | Componente | Estímulo | Consecuencia observable | Estado | Referencia verificable |
|---|---|---|---|---|---|
| F-01 | Contenedor PostgreSQL → Servicio de Adopciones | La BD deja de estar disponible con la API en marcha | `POST /api/adopciones` responde **500**: el primero en ~0.01–0.04 s y los siguientes en **30 s** cada uno. No quedan filas a medias | **Observado** | `experimentos/12-inyeccion-fallos-s12/RESULTADOS.md` §2–§3 (HF1a, HF3); `resultados/ciclo-{1,2,3}.txt` |
| F-02 | Contenedor PostgreSQL → Pool Hikari | La BD vuelve a estar disponible | Sin reiniciar la API, el primer POST responde **201** en < 0.06 s | **Observado** | Ídem, HF2 |
| F-03 | Health check (Actuator) | BD caída y consulta a `/actuator/health` | Responde **503 DOWN**, pero cada respuesta tarda **~30 s** | **Observado** | Ídem, HF1c; `resultados/log-api-extracto.txt` |
| F-04 | Servicio de Adopciones (TRX-02) | Excepción entre el insert de la solicitud y el de la etapa | **500** y rollback completo: 0 filas nuevas | **Observado** | `AdopcionControllerRollbackIntegrationTest` (pasa en `experimentos/spike-s10/seguimiento-s1-2026-10-24/`); `POST /api/adopciones/test-fallo` → 500 en `experimentos/spike-s10/contrato/verificacion-endpoints.txt` |
| F-05 | Servicio de Adopciones + PostgreSQL | 200 usuarios concurrentes escribiendo (operación B) | La cola de latencia crece: p99 de 64.71 ms (50 usuarios) a 209.25 ms (200 usuarios); 0 % de fallos. Causa no aislada | **Observado** | `experimentos/10-crecimiento-s11/RESULTADOS.md` §2 y §4 (hecho 3). El experimento 13 descarta como causa las filas acumuladas, hasta ~88 000 (`experimentos/13-semilla-memoria-s12/RESULTADOS.md` §5) |
| F-06 | Controlador Geoespacial | Parámetro faltante o no numérico en `/api/mascotas/buscar` | **400** con el error por defecto de Spring | **Observado** | `experimentos/spike-s10/contrato/verificacion-endpoints.txt` |
| F-07 | Controlador Geoespacial | Consumidor que exige `Content-Type: application/json` | La respuesta se envía como `text/plain` (observado); que un consumidor estricto falle **no se probó** | **Observado / consecuencia hipotética** | Ídem; `docs/integracion/contrato-api.yaml` |
| F-08 | Contenedor API (`app/Dockerfile`) | Construir la imagen en un entorno con intercepción TLS | `mvn package` falla con `PKIX path building failed`; la imagen no se construye | **Observado** (en el entorno de laboratorio) | `experimentos/09-cierre-spike-s10.md` §3.4 |
| F-09 | Pool Hikari (10 conexiones por defecto) | Más escrituras concurrentes que conexiones, sin caída de la BD | Peticiones esperando conexión hasta 30 s y luego 500 | **Hipotético** | Inferencia de `10-crecimiento-s11/RESULTADOS.md` §4; no se midió la espera de Hikari |
| F-10 | Contenedor API (hilos de Tomcat) | BD caída **bajo carga concurrente** | Cada escritura ocupa un hilo hasta 30 s (F-01); con suficientes peticiones se agotarían los 200 hilos y también fallaría `/buscar` | **Hipotético** | Inferencia de `12-inyeccion-fallos-s12/RESULTADOS.md` §4; solo se probó con peticiones de una en una |
| F-11 | Contenedor API (log) | Carga sostenida con el log SQL en DEBUG | En S11 el log SQL en DEBUG generó unos 176 MB durante el experimento (observado). Que se llene el disco **no se probó** | **Observado / consecuencia hipotética** | `10-crecimiento-s11/RESULTADOS.md` §4 (inferencias) |
| F-12 | Contenedor API (proceso) | El proceso de la API se detiene | Indisponibilidad total: hay una sola instancia y ningún reinicio automático configurado en `docker-compose.yml` | **Hipotético** | `docker-compose.yml` (sin `restart:`); no se provocó |
| F-13 | Contenedor PostgreSQL (datos) | Reinicio de la API con `ddl-auto=create-drop` | Se borran y recrean las tablas: se pierden todos los datos | **Observado** (comportamiento de la configuración) | `app/src/main/resources/application.properties`; `10-crecimiento-s11/RESULTADOS.md` §1 ("las tablas empiezan vacías tras cada reinicio (`create-drop`)") |

---

## 3. Inconsistencias y preguntas de verificación

| # | Observación | Pregunta para el equipo |
|---|---|---|
| I-1 | F-05: la latencia creció a la vez que las filas acumuladas (0 → 79 810), así que los dos efectos estaban confundidos | **Resuelta el 2026-10-24** con el experimento 13 (preregistrado, PR #79): con 79 810 filas iniciales el p95 no aumenta (−13,1 %). Las filas acumuladas no explican F-05 |
| I-2 | F-03 y F-01 dependen del mismo `connectionTimeout` (30 s por defecto), que nadie eligió | ¿El equipo acepta 30 s como tiempo máximo de fallo, o lo fija explícitamente? |
| I-3 | F-13: `create-drop` es una configuración de desarrollo | ¿Es aceptable en el entorno donde se va a desplegar? |
| I-4 | F-12 y F-10 son hipotéticos y son los de mayor impacto | ¿Cuál se prueba primero, y con qué carga? |
| I-5 | F-08 solo se observó detrás de un proxy TLS | ¿Construye el `Dockerfile` original en el computador del equipo? (P1 de `09-cierre-spike-s10.md`) |

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 12 · Módulo 6 · Arquitectura de Software*
