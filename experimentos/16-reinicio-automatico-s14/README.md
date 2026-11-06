# Reinicio automático de la API (R-10) y conservación de datos (R-11) — Semana 14

> **Estado: preregistro.** Este documento fija las hipótesis, el procedimiento y los criterios **antes** de ejecutar. Los resultados se registran en `RESULTADOS.md` en un commit posterior. Las secciones 1 a 4 no se modifican después de ver los datos.

- Fecha del preregistro: 2026-11-05 (America/Bogota)
- Rama de trabajo: `experimento/s13-s14-seguridad-operacion`
- Lo prepara y lo ejecuta la IA (Claude). El equipo todavía no lo ha revisado.

## 1. Por qué se hace

El veredicto **Ajustada** del ADR-04 (2026-10-31) puso una condición con fecha límite al cierre de la Semana 13: implementar R-10 y probarlo, "detener el proceso de la API y medir el tiempo hasta la primera respuesta 200" (`dossier/evidencia-comite-adr04.md`). `docker-compose.yml` sigue sin `restart:`.

Hay además una interacción que el plan M6-3 no contempla: R-10 va **primero** y R-11 **cuarta**, pero la API usa `ddl-auto=create-drop` (F-13). Si un reinicio borra las tablas, R-10 por sí sola convertiría cada caída en una pérdida total de datos sin que nadie intervenga.

## 2. Hipótesis (preregistradas)

| Id | Configuración | Predicción | Se refuta si |
|---|---|---|---|
| HR1 | `restart: unless-stopped` | Tras matar el proceso con `kill -9` desde el anfitrión, el contenedor vuelve solo y responde el primer 200 en ≤ 120 s en 5 de 5 ciclos. Es el RTO del escenario reformulado 2 de `dossier/04-escenarios-calidad.md` | Algún ciclo tarda más de 120 s o no vuelve |
| HR2 | R-10 con `ddl-auto=create-drop` | Después de cada reinicio automático, las tablas quedan con 0 filas | Alguna fila sobrevive |
| HR3 | R-10 con `ddl-auto=update` (R-11) | Después de cada reinicio automático se conservan todas las filas y el número de respuestas 201 coincide con las filas | Se pierde alguna fila |
| HR4 | `restart: unless-stopped` | Tras `docker stop`, el contenedor **no** vuelve solo durante 30 s (parada deliberada) | El contenedor vuelve |
| HR5 | Sin `restart:` (control, como `main`) | Tras `kill -9`, el contenedor sigue detenido a los 30 s | El contenedor vuelve |

## 3. Procedimiento

`ejecutar.sh` corre tres fases, con la imagen de `main` (`3f4b124`) y variantes de Compose:

1. **Control (HR5):** sin `restart:`. 1 ciclo.
2. **R-10 sola (HR1, HR2, HR4):** `restart: unless-stopped` y `create-drop`. 5 ciclos y luego la prueba de `docker stop`.
3. **R-10 + R-11 (HR1, HR3):** `restart: unless-stopped` y `SPRING_JPA_HIBERNATE_DDL_AUTO=update`. 5 ciclos.

En cada ciclo:

1. Crea 5 solicitudes con `POST /api/adopciones` y cuenta las filas.
2. Obtiene el PID del proceso en el anfitrión y ejecuta `kill -9`. Se usa `kill -9` desde el anfitrión porque Docker trata `docker kill` y `docker stop` como una parada manual, que `unless-stopped` no reinicia.
3. Consulta `GET /api/mascotas/buscar` cada 0,2 s hasta el primer 200, con un límite de 180 s, y registra el tiempo.
4. Vuelve a contar las filas y registra `RestartCount`.

## 4. Tratamiento de los datos

- No se descarta ningún ciclo. Se reportan mínimo, mediana y máximo del tiempo hasta el primer 200.
- El tiempo se mide desde el `kill -9`. La máquina tiene 2 vCPU y 7.8 GiB y no tiene carga durante la prueba: es el tiempo de arranque en reposo, no con tráfico.

## 5. Límites conocidos

- Docker solo reacciona cuando el proceso **termina**. Una API colgada que sigue viva no se reinicia con R-10.
- No se prueba la caída de la máquina ni la del daemon de Docker.
- `update` no es una herramienta de migraciones: no borra columnas ni gestiona cambios incompatibles.
