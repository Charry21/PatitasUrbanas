# Inyección de fallos: caída y recuperación de PostgreSQL — Semana 12

> **Estado: preregistro.** Este documento fija los fallos, las hipótesis, el procedimiento y los criterios **antes** de ejecutar. Los resultados se registran en `RESULTADOS.md` en un commit posterior. Las secciones 1 a 5 no se modifican después de ver los datos.

- Fecha del preregistro: 2026-10-24
- Código bajo prueba: `app/` de `main` en el momento de ejecutar (se registra el hash). El experimento **no modifica** `app/`.
- Propósito: aportar filas **observadas** (no hipotéticas) a la matriz de fallos (A2) y probar las tácticas de resiliencia que el sistema ya tiene (A3).

## 1. Fallos que se inyectan

| Id | Fallo | Cómo se provoca | Componente C4 afectado |
|---|---|---|---|
| F1 | La base de datos deja de estar disponible con la API en marcha | `docker stop patitas_urbanas_db` | Contenedor PostgreSQL; Repositorios y Servicio de Adopciones (`dossier/07`) |
| F2 | La base de datos vuelve a estar disponible | `docker start patitas_urbanas_db` y esperar `healthy` | Ídem |

## 2. Hipótesis (preregistradas)

Configuración relevante, sin cambios: Hikari con valores por defecto (`connectionTimeout` = 30 s; no hay propiedades `hikari` en `application.properties`); Actuator con `health.show-details=always`.

| Id | Predicción | Se refuta si |
|---|---|---|
| HF1a | Con la BD caída, `POST /api/adopciones` **no** responde 2xx y responde 5xx en ≤ 35 s | Alguna respuesta es 2xx, o alguna tarda > 35 s, o no hay respuesta |
| HF1b | Con la BD caída, `GET /api/mascotas/buscar` sigue respondiendo 200 | Alguna respuesta distinta de 200 |
| HF1c | Con la BD caída, `GET /actuator/health` responde 503 con `status` = `DOWN` | Alguna respuesta distinta de 503/DOWN |
| HF2 | Tras `docker start` y BD `healthy`, **sin reiniciar la API**, `POST /api/adopciones` vuelve a responder 201 en ≤ 60 s | No vuelve a 201 en 60 s |
| HF3 | Después de cada ciclo: filas de `solicitud_adopcion` = filas de `etapa_adopcion` = número acumulado de respuestas 201 recibidas; 0 solicitudes sin etapa | Cualquier diferencia |

## 3. Procedimiento

`ejecutar.sh` hace **3 ciclos** idénticos. En cada ciclo:

1. Línea base: 3 × `POST /api/adopciones`, 3 × `GET /api/mascotas/buscar`, 1 × `GET /actuator/health` (todo debe ser 201/200/200).
2. F1: `docker stop`; luego 3 × POST, 3 × GET buscar y 3 × health, registrando código, tiempo total (`curl -w %{time_total}`) y cuerpo.
3. F2: `docker start`; esperar `healthy`; enviar `POST /api/adopciones` cada 2 s hasta el primer 201 o 60 s, registrando cada intento.
4. HF3: contar filas y solicitudes sin etapa con `psql`.

Toda la salida va a `resultados/` (una bitácora por ciclo). La API se arranca una sola vez antes del ciclo 1 y **no se reinicia** durante el experimento.

## 4. Tratamiento de los datos

- No se descarta ningún ciclo: el experimento verifica comportamiento funcional, no latencias de rendimiento.
- Cada hipótesis se evalúa en los 3 ciclos; basta un ciclo que cumpla el criterio de refutación para refutarla.
- Los tiempos se reportan tal cual (mínimo y máximo por ciclo); no se calcula mediana.

## 5. Condiciones y límites conocidos

- Entorno: contenedor Linux (se registra SO, Java, Maven, Docker y PostgreSQL en `resultados/entorno.txt`). API con `mvn spring-boot:run`, no con la imagen Docker (el `Dockerfile` original no construye en este entorno; ver `09-cierre-spike-s10.md` §3.4).
- Solo se prueba una caída **completa** de la BD. No se prueban BD lenta, red intermitente, agotamiento del pool ni disco lleno: quedan como filas **hipotéticas** de la matriz de fallos.
