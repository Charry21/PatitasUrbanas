# Matriz de resiliencia — Módulo 6 (A3)

Relaciona cada fallo de la [matriz de fallos](./matriz-fallos.md) con una táctica, un objetivo verificable, un criterio de prueba y su estado de validación. Escenarios de calidad: QA-02 (integridad transaccional, `dossier/02-stakeholders-drivers.md`) y escenario 1 (búsqueda, p95 < 800 ms, `dossier/04-escenarios-calidad.md`).

**Estado de validación:**
- **Probada:** hay una prueba o un experimento que la ejercita y cumple el criterio.
- **Parcial:** se probó, pero no cumple todo el objetivo o solo se probó en parte de las condiciones.
- **Propuesta:** no está implementada ni probada. Tiene que decidirla el equipo.

**Origen de la táctica:**
- **Existente:** ya está en el código o en la configuración actual.
- **Propuesta (IA):** la sugirió la IA y está pendiente de decisión (registro en `docs/registro-ia-modulo6.md`).

---

## 1. Matriz

| Id | Fallo | Táctica | Origen | Objetivo verificable | Criterio de prueba | Estado | Costo secundario y su fundamento |
|---|---|---|---|---|---|---|---|
| R-01 | F-04, F-01 | Transacción atómica (`@Transactional` en `AdopcionService`) | Existente | 0 solicitudes sin etapa ante cualquier fallo de la escritura (QA-02) | `AdopcionControllerRollbackIntegrationTest`; HF3 de S12 (12 = 12, 0 sin etapa); hecho 5 de S11 (79 810 = 79 810) | **Probada** | No se identificó ninguno medido |
| R-02 | F-01 | Tiempo máximo de espera de conexión (Hikari `connectionTimeout`, 30 s por defecto) | Existente (por defecto, no elegido) | Una escritura con la BD caída termina con error en ≤ 35 s | HF1a de S12: 9/9 respuestas 500, máximo 30.013 s | **Probada** | Cada escritura fallida ocupa un hilo hasta 30 s. **Tiempo observado** (S12); el efecto sobre los hilos bajo carga es **hipotético** (F-10) |
| R-03 | F-02 | Reconexión automática del pool (validación y recreación de conexiones de Hikari) | Existente | Volver a aceptar escrituras sin reiniciar la API en ≤ 60 s desde que la BD está disponible | HF2 de S12: primer POST con 201 en < 0.06 s, en 3/3 ciclos | **Probada** | No se identificó ninguno medido |
| R-04 | F-01, F-03 | Detección de la caída por health check (Actuator, `db` en el estado) | Existente | `/actuator/health` responde DOWN mientras la BD no está disponible | HF1c de S12: 9/9 respuestas 503 DOWN | **Parcial**: detecta la caída, pero tarda ~30 s en responder (F-03) | Un monitor con un tiempo de espera menor que 30 s no recibiría el 503. Tiempo **observado**; el efecto en un monitor real **no se probó** |
| R-05 | F-01, F-10 | Aislamiento de la operación que no usa la BD | Existente, pero **incidental**: `/buscar` es simulado y no consulta la BD | `/buscar` sigue respondiendo 200 con la BD caída | HF1b de S12: 9/9 respuestas 200 | **Parcial**: probado sin carga concurrente; con carga (F-10) **no se probó** | Ninguno. **No es una táctica diseñada:** dejará de valer cuando `/buscar` consulte la BD |
| R-06 | F-06 | Validación de parámetros de entrada (tipos de `@RequestParam` de Spring) | Existente | Entrada inválida → 400, nunca 500 | `verificacion-endpoints.txt`: faltante y no numérico → 400 | **Probada** | No se identificó ninguno |
| R-07 | F-03, F-10 | Fijar explícitamente `connectionTimeout` y el tiempo del health check a un valor menor que 30 s | Propuesta (IA) | Error y estado DOWN en menos tiempo que el tiempo de espera del monitor | Repetir S12 con el nuevo valor | **Propuesta** | Posibles falsos DOWN o errores en picos de carga. **Hipotético**, sin medir |
| R-08 | F-09, F-05 | Medir la espera de conexión de Hikari bajo carga antes de cambiar el tamaño del pool | Propuesta (IA) | Saber si F-05 se debe al pool | Repetir la serie B de S11 con las métricas de Hikari activadas | **Propuesta** | Ninguno en producción; es una medición |
| R-09 | F-11 | Bajar el log SQL de DEBUG a INFO fuera de los experimentos | Propuesta (IA) | El log no crece con cada petición | Comparar el tamaño del log en una serie como la de S11 | **Propuesta** | Menos detalle para diagnosticar. **Hipotético** |
| R-10 | F-12 | Reinicio automático del contenedor (`restart: unless-stopped` en `docker-compose.yml`) | Propuesta (IA) | La API vuelve sola tras detenerse el proceso | Matar el proceso de la API y medir el tiempo hasta un 200 | **Propuesta** | No evita la indisponibilidad mientras la API arranca (tiempo de arranque **no medido**) |
| R-11 | F-13 | Usar `ddl-auto=validate` o `update` fuera del desarrollo | Propuesta (IA) | Reiniciar la API no borra datos | Reiniciar la API y contar filas | **Propuesta** | Requiere gestionar el esquema (por ejemplo, migraciones). **Hipotético** |
| R-12 | F-08 | Construir la imagen en el computador del equipo o en CI sin proxy TLS | Propuesta (IA) | `docker build` termina sin error con el `Dockerfile` original | P1 de `09-cierre-spike-s10.md` | **Propuesta** | Ninguno identificado |

---

## 1.1 Decisión del equipo sobre las propuestas (2026-10-24)

M6-3 de `docs/registro-ia-modulo6.md`: R-07 a R-12 se aceptan como plan. Se implementan en este orden: R-10, R-09, R-08, R-11 y R-12. **R-07 se aplaza** hasta probar F-10 con carga. Su estado en la tabla sigue siendo **Propuesta** hasta que cada una se implemente y se pruebe.

**Mini-comité del ADR-04 (2026-10-31):** R-10 pasa a ser la condición del veredicto **Ajustada**. Hay que implementarla y probarla antes del cierre de la Semana 13 (`dossier/evidencia-comite-adr04.md`).

## 2. Tácticas presentadas como probadas sin evidencia suficiente

Ninguna fila figura como **Probada** sin una prueba o un experimento enlazado. Dos llevan reservas explícitas:

- **R-04:** el criterio "detecta la caída" se cumple, pero la latencia de 30 s limita su utilidad.
- **R-05:** el aislamiento es una consecuencia de que `/buscar` es simulado, no una decisión de diseño.

## 3. Preguntas para el equipo

1. ¿Qué tácticas propuestas (R-07 a R-12) se adoptan? Las no adoptadas, ¿se rechazan o se aplazan, y con qué condición?
2. ¿Qué tiempo máximo de error aceptan para una escritura con la BD caída (R-02 / R-07)?
3. ¿Se repite S12 con carga concurrente para probar F-10 antes de decidir R-07?

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 12 · Módulo 6 · Arquitectura de Software*
