# Especificación del Spike — Semana 9

## 1. ADR y decisión que se pone a prueba

**ADR:** [ADR-01 — Adopción de Monolito Modular como Estilo Arquitectónico](../adr/adr-01-decision-estilo.md).

**Decisión:** probar ADR-01 (monolito modular con fronteras por paquete) y las reglas de dependencia de ADR-02.

**ADR del módulo que referencia este spike:** [ADR-03 — Límites de Módulo, API Pública y Comunicación entre Módulos](../adr/adr-03-limites-y-comunicacion-modulos.md) (Propuesta). El spike evalúa sus Decisiones 1 (límites de módulo) y 2 (API pública sin cambios); la tabla de correspondencia entre decisiones y métricas está en ese ADR. El resultado y el veredicto se enlazarán desde ADR-03 en Semana 10.

La especificación se limita a probar la reorganización estructural prevista por ADR-01. Las reglas de dependencia se describen en [ADR-02](../adr/adr-02-modularidad.md), en estado Ajustada tras el mini-comité de Semana 8; esta especificación no cambia el estado ni el veredicto de ningún ADR.

## 2. Hipótesis numérica y falsable

**Decisión a probar:** ADR-01 (monolito modular con fronteras por paquete) y las reglas de dependencia de ADR-02.

**Modificación X:** mover las clases existentes a paquetes por dominio dentro de `com.patitasurbanas.api`: `adopciones/`, `mascotas/`, `shared/` y `config/`. `veterinarias/` queda declarada pero sin clases porque no existe código de ese dominio y Git no versiona carpetas vacías. No cambiar lógica, endpoints, `pom.xml` ni `application.properties`.

**Métricas Y (medidas antes y después):**

- **Y1 — Tests existentes que pasan:** suite completa, incluido `AdopcionControllerRollbackIntegrationTest`.
- **Y2 — Imports prohibidos:** número de imports que incumplen las reglas prohibidas de [ADR-02](../adr/adr-02-modularidad.md), contado con un script de revisión de imports guardado en `experimentos/` (no en `app/`). En el estado previo, donde las clases no están separadas en paquetes por dominio, el script debe clasificar las clases según el mapeo de clases a módulos de `dossier/15-diseno-modular-s7.md`; después debe aplicar la misma clasificación a los paquetes reorganizados.
- **Y3 — Respuestas de endpoints:** diferencia entre el código HTTP y la estructura JSON de `POST /api/adopciones` y `GET /api/mascotas/buscar` antes y después, ignorando `id` y fecha.
- **Y4 — Clases de producción ubicadas en su módulo objetivo:** porcentaje de las 7 clases de producción listadas en la tabla de la sección 7 de `dossier/15-diseno-modular-s7.md` (`AdopcionController`, `AdopcionService`, `SolicitudAdopcionRepository`, `EtapaAdopcionRepository`, `SolicitudAdopcion`, `EtapaAdopcion`, `MascotaController`) cuyo paquete está dentro del módulo objetivo indicado en esa tabla (`...api.adopciones` o `...api.mascotas`, incluidos subpaquetes como `adopciones.model`). Se cuenta con el mismo script de `experimentos/` que Y2. No cuentan `PatitasUrbanasApplication` (paquete raíz `com.patitasurbanas`) ni las clases de test.
- **Y5 — Paquetes que mezclan dominios:** número de paquetes bajo `com.patitasurbanas.api` que contienen clases de producción de más de un dominio según el mismo mapeo. Se cuenta con el mismo script.

**Naturaleza de las métricas.** Y1, Y2 y Y3 son métricas de **no regresión**: comprueban que la reorganización no rompe tests, no introduce dependencias prohibidas y no altera el comportamiento observable. Una revisión preliminar de imports hecha al preparar esta especificación sugiere que la línea base de Y2 ya es 0, porque hoy no existen clases de mascotas que puedan ser importadas por adopciones ni a la inversa; el valor oficial de la línea base lo fija el script en Semana 10. Por eso Y2 por sí sola no demuestra mejora y se usa como guarda. Y4 e Y5 son las métricas de **mejora**: miden directamente lo que ADR-01 promete (fronteras de módulo visibles en la estructura de paquetes). En el estado base las clases están organizadas por capa técnica (`controller/`, `service/`, `repository/`, `model/`), por lo que se espera Y4 = 0% y Y5 ≥ 1 (`controller/` contiene `AdopcionController` y `MascotaController`); los valores oficiales de línea base los registra el script antes de reorganizar.

**Umbral Z e hipótesis falsable:** si se aplica la reorganización de ADR-01, la estructura de paquetes pasará a reflejar las fronteras de módulo —Y4 sube de su línea base a **100%** (7/7 clases en su módulo) y Y5 baja de su línea base a **0** paquetes mezclados— **sin coste funcional**: Y1 = 100% de los tests que pasaban antes siguen pasando; Y2 = 0 violaciones; Y3 = 0 diferencias.

Si el script registra en la línea base Y4 = 100% o Y5 = 0, la mejora no es observable con estas métricas: se registra como desviación y la hipótesis de mejora no podrá darse por soportada (solo la de no regresión).

## 3. Criterios predefinidos

**Criterio de confirmación:** la hipótesis se considera soportada únicamente si se cumplen las cinco condiciones: Y4 = 100% después (y menor en la línea base), Y5 = 0 después (y ≥ 1 en la línea base), el 100% de los tests que pasaban antes siguen pasando, el script detecta cero imports prohibidos después y los códigos HTTP y estructuras JSON comparados para ambos endpoints no presentan diferencias al ignorar `id` y fecha. El resultado solo aplicaría a este cambio y a las condiciones registradas.

**Criterio de refutación:** la hipótesis se considera refutada si Y4 < 100% después, Y5 ≥ 1 después, algún test que pasaba antes deja de pasar, el script detecta una o más violaciones, o existe una o más diferencias en las respuestas comparadas. Basta con que falle cualquiera de las cinco métricas. Si Y4/Y5 cumplen pero falla Y1, Y2 o Y3, la conclusión es que la reorganización tal como se especificó no es estructural pura y ADR-01 debe revisarse; si Y1–Y3 cumplen pero Y4/Y5 no, el cambio no materializó las fronteras prometidas.

**Control del medidor Y2:** en una rama descartable (`spike/control-y2-descartable`) se inyectará un import prohibido de prueba. El script debe contar una o más violaciones. Si no lo detecta, Y2 no es válido y no se podrá usar para evaluar la hipótesis.

**Control del medidor Y4/Y5:** el script se ejecuta sobre el estado base y su salida debe listar cada una de las 7 clases con su paquete actual y su módulo objetivo; la lista se contrasta manualmente con `find app/src/main/java -name '*.java'`. Si alguna clase falta o está mal clasificada, Y4/Y5 no son válidas. La rama y el import de prueba no forman parte de la reorganización integrada.

## 4. Alcance

**Dentro del cambio especificado:**

- Mover las clases Java existentes a los paquetes de dominio previstos en ADR-01 y `dossier/15-diseno-modular-s7.md`.
- Mantener `veterinarias/` como módulo declarado sin clases; no se crean clases para ese dominio ni se fuerza al repositorio a versionar una carpeta vacía.
- Actualizar declaraciones de paquete e imports que sean necesarios por esos movimientos.
- Crear en `experimentos/` el script de revisión de imports de Y2, fuera de `app/`, y validar su capacidad de detección con el control en rama descartable.
- Medir antes y después Y1–Y5 con el mismo criterio, registrando evidencias comparables.

**Fuera del alcance / no tocar:**

- No cambiar lógica de negocio, modelos, persistencia, transacciones, validaciones, endpoints ni respuestas HTTP.
- No añadir ArchUnit, Spring Security, bibliotecas, módulos JPMS, microservicios, infraestructura o servicios externos.
- No modificar `pom.xml` ni `application.properties`.
- No mover ni alterar las clases fuera de los paquetes objetivo para ampliar el alcance.
- No modificar esquemas o datos de PostgreSQL, Docker Compose ni la configuración de despliegue.
- No hacer optimizaciones de rendimiento ni usar p95, throughput o tiempos de respuesta como resultado de este spike.
- No resolver ni editar ADRs, documentos de semanas anteriores, resultados de mediciones previas o sus veredictos.
- No ejecutar el spike durante la Semana 9 ni registrar resultados o veredictos en esta etapa.

## 5. Condiciones de medición

- **Commit base:** `887ccf1` (rama `main`, merge del PR #45 que integra esta especificación). El último commit que modificó `app/` es `0a243b0` (2026-09-12); el código de `app/` en `887ccf1` es el estado base del spike. La rama de ejecución del spike se crea desde este commit. Si al ejecutar se parte de un commit posterior de `main`, se registra su hash y se demuestra con `git diff --stat 887ccf1 <hash> -- app` (salida vacía) que `app/` no cambió; si cambió, el spike no se ejecuta hasta actualizar esta especificación en un commit propio.
- **Entorno conocido por la documentación:** Windows con Docker Desktop (WSL2); Java 21; Spring Boot 3.3.4; PostgreSQL 16; Docker Compose. Versiones fijadas en el repositorio en el commit base:
  - Java: 21 (`<java.version>21</java.version>` en `app/pom.xml`).
  - Spring Boot: 3.3.4 (`spring-boot-starter-parent` en `app/pom.xml`).
  - Imagen de compilación: `maven:3.9.9-eclipse-temurin-21`; imagen de ejecución: `eclipse-temurin:21-jre` (`app/Dockerfile`).
  - PostgreSQL: imagen `postgres:16` (`docker-compose.yml`), puerto host `5433`.
  - La etiqueta `postgres:16` y la versión de Docker no fijan un parche concreto; por eso, en cada ejecución se registra la salida de `docker version`, `docker compose version`, `docker exec patitas_urbanas_db psql -U admin -d patitas_urbanas -c "SELECT version();"` y `docker run --rm maven:3.9.9-eclipse-temurin-21 mvn -v`. Las mismas versiones deben usarse antes y después; si alguna difiere, se registra como desviación.
- **Comparación:** medir Y1–Y5 tanto antes como después, usando el mismo conjunto de tests, script y procedimiento de solicitud/comparación.
- **Repeticiones y protocolo exacto de medición:** las tres métricas son deterministas (resultado de tests, conteo estático de imports, código HTTP/estructura JSON), así que las repeticiones sirven para descartar resultados inestables, no para promediar:
  1. Antes de cada bloque de medición: `docker compose down -v` y `docker compose up -d postgres_db`, esperando a que el healthcheck reporte `healthy` (base de datos limpia; además `ddl-auto=create-drop` recrea el esquema).
  2. **Y1:** 3 ejecuciones de la suite completa antes y 3 después, con `mvn -B clean test` desde `app/`. Un test cuenta como "pasaba antes" solo si pasa en las 3 ejecuciones previas. Si un test da resultados distintos entre ejecuciones del mismo estado, se registra como inestable y se excluye de Y1 de forma explícita, sin cambiar el criterio.
  3. **Y2, Y4 e Y5:** 1 ejecución del script antes y 1 después (análisis estático determinista), más 1 ejecución en la rama descartable de control de Y2.
  4. **Y3:** con la aplicación levantada (`mvn spring-boot:run` desde `app/`, puerto 3000), cada solicitud se envía 3 veces antes y 3 después. Las 3 respuestas de un mismo estado deben coincidir entre sí; si no coinciden, se registra como desviación. No se medirán tiempos de respuesta ni rendimiento; por tanto, warm-up de carga no es una métrica del spike.
- **Y1:** conservar la salida de la suite completa antes y después e identificar explícitamente qué tests pasaban antes; incluir `AdopcionControllerRollbackIntegrationTest`.
- **Y2:** el agente debe crear y ejecutar primero el script sobre el estado base, usando el mapeo de clases de `dossier/15-diseno-modular-s7.md` para asignar módulos antes de la reorganización; después debe aplicar el mismo criterio a los paquetes reorganizados. Conservar el script, las salidas antes/después, la lista de imports contabilizados y la evidencia del control en rama descartable. Si el control falla, declarar inválida Y2.
- **Y3:** comparar código HTTP y estructura JSON de `POST /api/adopciones` y `GET /api/mascotas/buscar` antes y después, ignorando únicamente `id` y fecha. Solicitudes fijadas (las mismas antes y después):
  - **S1:** `curl -s -i -X POST "http://localhost:3000/api/adopciones"` (sin parámetros; usa los valores por defecto `estado=PENDIENTE`, `nombreEtapa=SOLICITUD_RECIBIDA`). Respuesta esperada en el estado base: `201 Created` con las claves `idSolicitud`, `estado`, `etapaInicial`.
  - **S2:** `curl -s -i -X POST "http://localhost:3000/api/adopciones?estado=PENDIENTE&nombreEtapa=SOLICITUD_RECIBIDA"` (parámetros explícitos).
  - **S3:** `curl -s -i "http://localhost:3000/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5"` (mismos parámetros que `experimentos/escenario-rendimiento.js`).

  Procedimiento de comparación: guardar cada respuesta (código HTTP y cuerpo) en `experimentos/spike-s10/y3-antes/` y `experimentos/spike-s10/y3-despues/`; normalizar el cuerpo eliminando únicamente el campo de identificador (`idSolicitud`) y cualquier campo de fecha, si existiera; ordenar claves (por ejemplo, `jq -S 'del(.idSolicitud)'`) y comparar con `diff`. Se compara: código HTTP, conjunto de claves, tipo de cada valor y valores no excluidos. Y3 = número de solicitudes (S1–S3) con al menos una diferencia; resultado esperado: 0.
- **Limitaciones reconocidas de antemano:** existen solo dos clases de prueba, por lo que la cobertura de verificación es baja; el endpoint de mascotas es simulado; las reglas aplicables a mascotas son hoy casi vacías porque no existe entidad `Mascota`; las fronteras de ADR-02 se revisan por convención, no por un mecanismo automático en el build. La comparación de respuestas y las pruebas cubren solo los casos ejecutados, no demuestran equivalencia universal.

La metodología histórica se consulta en [experimentos/01-metodologia-medicion.md](./01-metodologia-medicion.md) y la línea base histórica en [experimentos/03-linea-base-semana6.md](./03-linea-base-semana6.md). Ninguna medición de esos documentos constituye el resultado de este spike.

## 6. Tarea delegada al agente

**Momento de ejecución:** Semana 10. El commit base, las versiones, el protocolo de repetición, las solicitudes equivalentes y el procedimiento de comparación quedaron fijados en §5 durante Semana 9. No ejecutar ni modificar código de `app/` como parte de la preparación de Semana 9.

**Herramienta/agente delegado:** Claude Code (Anthropic). El modelo y la versión exactos se registran en los metadatos de la EDAV 2 ([05-auditoria-ia-s9.md](./05-auditoria-ia-s9.md)) al iniciar la delegación.

**Ramas:**

- Rama de ejecución del spike: `spike/fronteras-modulares-s10`, creada desde `887ccf1`. Se integra a `main` solo mediante PR, después de la auditoría humana.
- Rama de control del medidor Y2: `spike/control-y2-descartable`, creada desde `887ccf1`. No se integra; se conserva solo como evidencia del control.

**Prompt exacto para el agente:**

> En la rama `spike/fronteras-modulares-s10`, creada desde el commit `887ccf1`, implementa exclusivamente la reorganización estructural de las clases existentes bajo `com.patitasurbanas.api` en `adopciones/`, `mascotas/`, `shared/` y `config/`. Deja veterinarias declarada sin clases: no inventes clases ni fuerces a Git a versionar una carpeta vacía. Usa las reglas prohibidas de `adr/adr-02-modularidad.md`. No cambies lógica, endpoints, `pom.xml`, `application.properties`, persistencia, configuración, Docker Compose ni infraestructura. No agregues ArchUnit, Spring Security, JPMS, bibliotecas o microservicios. Crea el script de revisión de imports (Y2) y de ubicación de clases (Y4, Y5) en `experimentos/`, no en `app/`; para el estado previo, clasifica clases según el mapeo a módulos de `dossier/15-diseno-modular-s7.md`; usa el mismo criterio después del movimiento. Ejecuta el script en el estado base antes de reorganizar. Valida el medidor Y2 en la rama descartable `spike/control-y2-descartable` inyectando un import prohibido de prueba; debe detectar al menos una violación. La rama y el import de control no se integran. Mide antes y después Y1 (suite completa, incluido `AdopcionControllerRollbackIntegrationTest`, con identificación de los tests que pasaban antes), Y2 (conteo con el script validado) y Y3 (código HTTP y estructura JSON de `POST /api/adopciones` y `GET /api/mascotas/buscar`, ignorando `id` y fecha, mediante las solicitudes S1–S3 y el procedimiento de §5), Y4 (porcentaje de las 7 clases de producción del mapeo en su módulo objetivo) e Y5 (paquetes que mezclan clases de más de un dominio). Conserva comandos, salidas y evidencias. Reporta diferencias, desviaciones y aspectos no verificados. No ejecutes este trabajo durante Semana 9 ni redactes resultado o veredicto en los documentos de Semana 9.

**Entradas al agente:**

- Este documento y el hash base `887ccf1` (§5).
- [ADR-01](../adr/adr-01-decision-estilo.md), [ADR-02](../adr/adr-02-modularidad.md) y [dossier/15](../dossier/15-diseno-modular-s7.md).
- Árbol de clases Java existente bajo `app/src/main/java/com/patitasurbanas/api/`.
- Suite completa, incluido `AdopcionControllerRollbackIntegrationTest`.
- Reglas prohibidas de [ADR-02](../adr/adr-02-modularidad.md).
- Solicitudes equivalentes S1–S3 y procedimiento de comparación de respuestas definidos en §5 (Y3).

**Salida esperada:** diff acotado a la reorganización y declaraciones/imports necesarios; script de imports guardado en `experimentos/`; evidencia del control del medidor; resultados antes/después de Y1–Y5; lista de desviaciones y aspectos no verificados. La salida del agente no constituye aceptación automática: se someterá a la auditoría humana de la plantilla [05-auditoria-ia-s9.md](./05-auditoria-ia-s9.md).

**Restricciones:** no inventar código, mediciones, conteos, hashes ni evidencia; no ampliar el alcance; no cambiar criterios después de ver resultados; no ejecutar durante Semana 9; no escribir resultado o veredicto en esta especificación.

## 7. Plan de auditoría (plantilla previa)

Completar durante la auditoría humana en Semana 10. No hay hallazgos registrados en Semana 9. La auditoría de Semana 10 se registra en [05-auditoria-ia-s9.md §4–§8](./05-auditoria-ia-s9.md).

### Hallazgos sustantivos

| # | Hallazgo | Evidencia | Decisión (aceptado / rechazado / corregido) | Seguimiento |
|---|---|---|---|---|
| | | | | |

### Hallazgos cosméticos

| # | Hallazgo | Evidencia | Decisión (aceptado / rechazado / corregido) | Seguimiento |
|---|---|---|---|---|
| | | | | |

### No verificado

- Se completa durante la auditoría humana de Semana 10, tras recibir el resultado del agente. No se registran elementos en Semana 9 para no anticipar el resultado.

## Resultado

Registrado en Semana 10 en [06-spike-resultado-s10.md](./06-spike-resultado-s10.md) (ejecución, evidencia, desviaciones y aspectos no verificados). Las secciones anteriores de esta especificación no se modificaron después de conocer el resultado.

## Veredicto

Ver [06-spike-resultado-s10.md §7](./06-spike-resultado-s10.md). La auditoría humana se registra en [05-auditoria-ia-s9.md](./05-auditoria-ia-s9.md).
