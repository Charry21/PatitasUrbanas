# Registro histórico: pruebas de carga de la defensa de la Semana 8

> **No es una medición formal.** Estos archivos estaban solo en el computador de Kevin Torres y se suben el 2026-11-06 para no perderlos. No tienen preregistro, ni entorno registrado, ni repeticiones. Se conservan como antecedente; ninguna decisión del dossier se apoya en ellos.

## Qué hay aquí

| Archivo | Qué es | Origen |
|---|---|---|
| [`resultado-defensa-s8.txt`](./resultado-defensa-s8.txt) | Salida de k6 de la **corrida 1** | Archivo local, sin cambios. Los caracteres raros del logo vienen de la codificación con que PowerShell guardó la salida |
| [`capturas-corrida-2/`](./capturas-corrida-2/) | Capturas de la **corrida 2** | Historial de la terminal de VS Code, recuperado el 2026-11-06. No se guardó en archivo |
| [`escenario-1000rps.js`](./escenario-1000rps.js) | Script de 1000 peticiones/s | Archivo local, sin cambios. **No hay resultado guardado**: no consta que se haya ejecutado |

Las corridas 1 y 2 usaron [`../escenario-defensa.js`](../escenario-defensa.js), que se versionó el 2026-09-17 (`cfd2e65`).

## Corridas con `escenario-defensa.js`

Modelo abierto (`constant-arrival-rate`): 100 peticiones/s durante 40 s, con un máximo de 100 VUs, contra `POST /api/adopciones`. El script envía `estado` y `nombreEtapa` en un cuerpo JSON, pero la API los lee como parámetros de la URL, así que usó los valores por defecto. La carga es la misma; el contenido enviado no es el que la API leyó.

| | Corrida 1 | Corrida 2 |
|---|---|---|
| Fecha | 2026-09-17, 21:55–21:56 (Bogotá), según las marcas de k6 | **Desconocida.** Estaba en el historial de la terminal; anterior al 2026-11-06 |
| Máquina | Windows (rutas con `\`); por el contexto, el computador de Kevin Torres | La misma carpeta, `C:\Users\USUARIO\PatitasUrbanas` |
| Código de la API | Desconocido; el script se versionó ese mismo día | Desconocido |
| Peticiones completadas | 478 | 2722 |
| Tasa lograda | 7,29 req/s (se pidieron 100) | 67,57 req/s (se pidieron 100) |
| Iteraciones descartadas | 3523 | 1279 |
| Fallos | **20,92 %**: 100 peticiones agotaron el tiempo de 60 s | 0 % |
| p50 / p95 / máx. | 40,48 ms / **60 s** / 60 s | 775,12 ms / **2,98 s** / 13,86 s |
| p95 de las respuestas correctas | 87,74 ms | 2,98 s |
| Umbral p95 < 800 ms | No se cumple | No se cumple |

**Qué se observa en la corrida 1:** las 378 respuestas correctas llegaron en los primeros 4 s. Después la API dejó de completar peticiones: k6 llegó al máximo de 100 VUs y todas esperaron hasta agotar el tiempo a los 60 s. La causa **no se registró**.

**Qué se observa en la corrida 2:** la API no se cayó, pero tampoco sostuvo 100 req/s, y la latencia quedó en segundos.

## Por qué importa: contraste con S11

En S11 (`experimentos/10-crecimiento-s11/`), con 200 usuarios y 1 s de espera, la API sostuvo unas 196 req/s con un p95 de escritura de unos 51 ms. ADR-04 usa ese dato para decir que D1 cumple el escenario 1 con margen amplio.

Estas dos corridas, en el computador del equipo, **no alcanzaron 100 req/s**. No son comparables de forma directa:

- **Máquina:** S11 corrió en un contenedor Linux en la nube; estas, en Windows con Docker Desktop.
- **Código:** S11 usó el código de octubre; el de estas corridas es desconocido.
- **Modelo de carga:** S11 usa un modelo cerrado, que baja el ritmo si el servidor se frena; estas usan un modelo abierto, que no lo baja.

Aun así, la diferencia es demasiado grande para ignorarla. **La conclusión de ADR-04 sobre el margen solo está respaldada en el entorno de S11.**

## Cómo repetirlo hoy

Los dos scripts envían peticiones sin token. Con la capa de seguridad de `main` (PR #83), todas responderían 401. Para repetir la prueba hay que añadir la cabecera `Authorization: Bearer <token>` con un token de `secretos/valido.jwt`.

---

*Registrado el 2026-11-06 a partir de los archivos y capturas de Kevin Torres. Redacción de la IA.*
