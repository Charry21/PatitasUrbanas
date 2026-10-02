# Resultado del Spike — Semana 10

## Fronteras modulares (ADR-01 / ADR-02 / ADR-03)

Especificación committeada antes de ejecutar: [04-spike-especificacion-s9.md](./04-spike-especificacion-s9.md).
Auditoría del trabajo delegado (EDAV 2): [05-auditoria-ia-s9.md](./05-auditoria-ia-s9.md).
Evidencia original (salidas sin editar): [`experimentos/spike-s10/`](./spike-s10/).

---

## 1. Hipótesis y criterios (copiados sin cambios de la especificación)

**Hipótesis:** si se aplica la reorganización de ADR-01, la estructura de paquetes pasará a reflejar las fronteras de módulo —Y4 sube de su línea base a **100%** y Y5 baja de su línea base a **0**— **sin coste funcional**: Y1 = 100% de los tests que pasaban antes siguen pasando; Y2 = 0 violaciones; Y3 = 0 diferencias.

**Confirmación:** se cumplen las cinco condiciones (Y4 = 100% después y menor en la línea base; Y5 = 0 después y ≥ 1 en la línea base; Y1 = 100%; Y2 = 0; Y3 = 0).

**Refutación:** basta con que falle cualquiera de las cinco métricas.

---

## 2. Ejecución

| Paso | Rama / commit | Fecha (UTC) |
|---|---|---|
| Commit base | `887ccf1` | 2026-10-02 03:48 |
| Rama de ejecución creada desde la base | `spike/fronteras-modulares-s10` | 2026-10-02 |
| Scripts de medición + línea base Y1–Y5 | `af02cce` | 2026-10-02 17:05 |
| Control del medidor Y2 (rama descartable, no se integra) | `spike/control-y2-descartable` → `4883f9c` | 2026-10-02 |
| Reorganización (único cambio de código) + evidencia del control | `1e522df` | 2026-10-02 |
| Mediciones después + comparación Y3 | `d97cbf3` | 2026-10-02 |

**Cambio realizado** ([`spike-s10/alcance-diff.txt`](./spike-s10/alcance-diff.txt)):

| Clase | Antes | Después |
|---|---|---|
| `AdopcionController` | `api.controller` | `api.adopciones` |
| `AdopcionService` | `api.service` | `api.adopciones` |
| `SolicitudAdopcionRepository` | `api.repository` | `api.adopciones` |
| `EtapaAdopcionRepository` | `api.repository` | `api.adopciones` |
| `SolicitudAdopcion` | `api.model` | `api.adopciones.model` |
| `EtapaAdopcion` | `api.model` | `api.adopciones.model` |
| `MascotaController` | `api.controller` | `api.mascotas` |

- 8 archivos, 15 inserciones y 18 eliminaciones; **todas** las líneas cambiadas son declaraciones `package` o `import` (verificado con `git diff -U0`).
- El test `AdopcionControllerRollbackIntegrationTest` solo cambia sus imports.
- Sin cambios en `pom.xml`, `application.properties`, `application-test.properties`, `docker-compose.yml` ni `Dockerfile`.
- `shared/`, `config/` y `veterinarias/` no se crean: ninguna clase existente pertenece a ellos según el mapeo y Git no versiona carpetas vacías.

**Comandos y repeticiones:**

| Métrica | Comando | Repeticiones (antes / después) |
|---|---|---|
| Y1 | `docker compose down -v && docker compose up -d postgres_db`; luego `mvn -B clean test` desde `app/` | 3 / 3 |
| Y2, Y4, Y5 | `python3 experimentos/spike-s10/revisar_modulos.py app` | 1 / 1 (+1 en la rama de control) |
| Y3 | `experimentos/spike-s10/medir_y3.sh <salida>` (BD limpia, `mvn spring-boot:run`, S1–S3 ×3, `jq -S 'del(.idSolicitud)'`) | 3 por solicitud / 3 por solicitud |

**Entorno** ([`spike-s10/entorno.txt`](./spike-s10/entorno.txt)): Ubuntu 24.04 (contenedor Linux), Docker 29.6.2, Docker Compose v5.3.1, OpenJDK 21.0.11, Maven 3.9.11, PostgreSQL 16.15 (imagen `postgres:16`). Idéntico antes y después.

---

## 3. Validación de los instrumentos

| Instrumento | Control | Resultado | ¿Válido? |
|---|---|---|---|
| Medidor Y2 | Import prohibido inyectado en `MascotaController` (`→ SolicitudAdopcionRepository`) en la rama descartable | Y2 = 1, violación identificada como "repositorio interno de otro módulo" ([`control-y2/`](./spike-s10/control-y2/)) | Sí |
| Medidor Y4/Y5 | La salida del script lista las 7 clases con paquete y módulo; se contrasta con `find app/src/main/java -name '*.java'` | Las 7 clases del mapeo + `PatitasUrbanasApplication` (fuera del mapeo) aparecen en ambos listados, antes y después | Sí |
| Y3 | Las 3 repeticiones de cada solicitud deben coincidir entre sí | 9/9 coinciden antes y 9/9 después | Sí |
| Y1 | Un test cuenta como "pasaba antes" solo si pasa en 3/3 corridas | Ambos tests pasan 3/3; no hay tests inestables | Sí |

---

## 4. Resultados

| Métrica | Línea base (`887ccf1`) | Después (`1e522df`) | Umbral predefinido | ¿Cumple? |
|---|---|---|---|---|
| Y1 — tests que pasaban antes y siguen pasando | 2/2 en 3/3 corridas (`PatitasUrbanasApplicationTests`, `AdopcionControllerRollbackIntegrationTest`) | 2/2 en 3/3 corridas | 100% | ✅ 100% |
| Y2 — imports prohibidos (ADR-02) | 0 | 0 | 0 | ✅ |
| Y3 — solicitudes con diferencias (S1–S3) | S1 y S2: `201` `{estado, etapaInicial}` + `idSolicitud` numérico; S3: `200` `{status, mensaje}` | Idéntico en las 9 respuestas | 0 | ✅ 0 |
| Y4 — clases en su módulo objetivo | 0/7 (0%) | 7/7 (100%) | 100% después y menor en la base | ✅ |
| Y5 — paquetes que mezclan dominios | 1 (`api.controller`: adopciones + mascotas) | 0 | 0 después y ≥ 1 en la base | ✅ |

Salidas: [`spike-s10/antes/`](./spike-s10/antes/), [`spike-s10/despues/`](./spike-s10/despues/), [`spike-s10/y3-comparacion.txt`](./spike-s10/y3-comparacion.txt).

---

## 5. Desviaciones respecto al protocolo

| # | Desviación | Efecto sobre el resultado |
|---|---|---|
| D1 | El entorno fue un contenedor Linux (Ubuntu 24.04), no Windows con Docker Desktop (WSL2) como describe la documentación. | Ninguno sobre la comparación: antes y después usan el mismo entorno. No verifica el comportamiento en Windows. |
| D2 | Los tests se ejecutaron con Maven 3.9.11 local; no se ejecutó `docker run maven:3.9.9-eclipse-temurin-21 mvn -v` ni la construcción de la imagen de `app/Dockerfile`. | Ninguno sobre Y1–Y5 (misma herramienta antes y después). La construcción de la imagen Docker de la API queda sin verificar. |
| D3 | `medir_y3.sh` hace una solicitud `GET /api/mascotas/buscar?lat=0&lng=0&radio=1` para detectar que la aplicación arrancó, antes de S1–S3. | Ninguno: el endpoint es simulado y no escribe datos; no se cuenta en Y3. |
| D4 | El número de imports evaluados por Y2 baja de 8 a 5 porque las clases que pasan a compartir paquete ya no necesitan `import`. | El script solo analiza imports; las referencias dentro del mismo paquete no se cuentan. Todas están dentro de `adopciones/`, así que no pueden ser violaciones entre módulos. |

Ninguna desviación afecta a los criterios de confirmación o refutación.

---

## 6. Aspectos no verificados

- Ejecución en Windows/WSL2 y construcción de la imagen Docker de la API (`docker compose up api_app`).
- Respuesta de `POST /api/adopciones/test-fallo` fuera del test de rollback (no forma parte de S1–S3).
- Entradas no válidas o casos límite de los endpoints: Y3 cubre solo S1–S3.
- Cumplimiento futuro de las fronteras: se mantienen por convención (ADR-02); el spike mide una única reorganización.
- Reglas de ADR-02 sobre `mascotas` → `adopciones`: con el código actual no hay ningún import posible en esa dirección, así que la regla solo se ejercitó en el control.

---

## 7. Veredicto

**Hipótesis soportada por los resultados**, en las condiciones registradas.

Las cinco condiciones de confirmación de la especificación se cumplen: Y4 pasa de 0% a 100%, Y5 pasa de 1 a 0, y la reorganización no tuvo coste funcional observable (Y1 = 100%, Y2 = 0, Y3 = 0). Los cuatro instrumentos se validaron antes de usarse. Las desviaciones D1–D4 no afectan a la comparación porque las condiciones fueron idénticas antes y después.

**Alcance del veredicto:** confirma que la reorganización de ADR-01 materializa las fronteras de módulo en la estructura de paquetes sin romper los tests ni los contratos HTTP medidos. No demuestra equivalencia universal, no mide mantenibilidad a largo plazo y no evalúa la Decisión 3 de ADR-03 (comunicación entre módulos), que no se puede medir con el código actual.

Este veredicto está sujeto a la auditoría humana registrada en [05-auditoria-ia-s9.md](./05-auditoria-ia-s9.md).
