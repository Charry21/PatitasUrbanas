# Registro de cierre — Spike 1 de fronteras modulares (Semana 10)

> Borrador preparado el 2026-10-10 para revisión del equipo. Este registro **no modifica** la hipótesis, los criterios, los resultados ni la auditoría ya registrados. Enlaza la evidencia existente, añade las verificaciones hechas después del 2026-10-02 y deja el veredicto final para el equipo (§6).

## 1. Documentos que se cierran

| Documento | Commit que fija su contenido | Estado verificado el 2026-10-10 |
|---|---|---|
| Especificación: [04-spike-especificacion-s9.md](./04-spike-especificacion-s9.md) | Hipótesis y criterios: `c16cd03` | Desde `c16cd03` solo cambian enlaces (ADR-03, resultado, auditoría) y el estado de ADR-02 (`01f1c7b`, `403d7b5`, `e9bcd93`). Hipótesis y criterios de confirmación y refutación sin cambios. |
| Resultado: [06-spike-resultado-s10.md](./06-spike-resultado-s10.md) | `e9bcd93`, más la fila D5 en `36e2e97` | Coincide con sus salidas originales (§3.2). |
| Auditoría EDAV 2: [05-auditoria-ia-s9.md](./05-auditoria-ia-s9.md) | Último cambio `f0b2b43` | Decisiones S1–S5 y C1–C2 completas; firma de §8 con dos integrantes (§3.3). |
| Evidencia original: [spike-s10/](./spike-s10/) | `af02cce` (antes), `1e522df`/`4883f9c` (control), `d97cbf3` (después) | Sin cambios desde `d97cbf3`. Solo se añadió después `contrato/verificacion-endpoints.txt` (`bc908e2`), que pertenece a otro trabajo. |
| Trazabilidad temporal: [07-trazabilidad-temporal.md](./07-trazabilidad-temporal.md) | — | Sin cambios en este cierre. |

## 2. Resultado registrado (copiado de 06 §4, sin cambios)

| Métrica | Línea base (`887ccf1`) | Después (`1e522df`) | Umbral | ¿Cumple? |
|---|---|---|---|---|
| Y1 | 2/2 tests en 3/3 corridas | 2/2 en 3/3 | 100% | Sí |
| Y2 | 0 | 0 | 0 | Sí |
| Y3 | — | 0 diferencias (9/9) | 0 | Sí |
| Y4 | 0/7 (0%) | 7/7 (100%) | 100% | Sí |
| Y5 | 1 | 0 | 0 | Sí |

## 3. Verificaciones de cierre (2026-10-09 y 2026-10-10)

### 3.1 El código integrado es el código medido

- El árbol de `app/` en `main` (`3e56742`) es `cef1272…`, **el mismo objeto** que el árbol de `app/` en `1e522df`. `git diff 1e522df 3e56742 -- app` está vacío.
- Los únicos commits que tocan `app/` entre ambos son `4883f9c` (import de control), `0206cfd` (merge que lo trae) y `36e2e97` (lo quita). Su efecto neto es nulo.
- La reescritura de autoría de `main` del 2026-10-09 no cambia el contenido: el `main` anterior (`a3e76c0`) y el actual (`3e56742`) tienen el mismo árbol raíz (`fed2b44…`). `1e522df` sigue siendo ancestro de `main`.

### 3.2 El informe 06 coincide con sus salidas originales

| Afirmación de 06 | Salida comprobada | Coincide |
|---|---|---|
| Y1: 2/2 en 3/3 antes y después | `antes/y1-corrida-{1,2,3}.log`, `despues/y1-corrida-{1,2,3}.log`: `Tests run: 2, Failures: 0, Errors: 0`, `BUILD SUCCESS` en las seis | Sí |
| Y2 = 0, Y4 0/7 → 7/7, Y5 1 → 0 | `antes/y2-y4-y5.txt`, `despues/y2-y4-y5.txt` | Sí |
| Y3: 9/9 iguales | `y3-comparacion.txt`; `antes/y3/resumen.txt` y `despues/y3/resumen.txt` idénticos (S1, S2: 201; S3: 200) | Sí |
| 8 archivos, 15 inserciones, 18 eliminaciones | `git diff --shortstat -M 887ccf1 1e522df -- app` y `alcance-diff.txt` | Sí |
| Entorno | `entorno.txt` (Ubuntu 24.04.4, Docker 29.6.2, OpenJDK 21.0.11, Maven 3.9.11, PostgreSQL 16.15) | Sí |

Además, Y1–Y5 se volvieron a medir el 2026-10-09 sobre `887ccf1`, `1e522df` y el control `4883f9c`, en un contenedor Linux con versiones cercanas a las originales, y los resultados coinciden con los registrados; las salidas de `revisar_modulos.py` se regeneran idénticas byte a byte (evidencia en [`spike-s10/reproduccion-2026-10-09/`](./spike-s10/reproduccion-2026-10-09/), integrada con el PR #61).

Observaciones menores, sin efecto sobre los valores: 06 §7 menciona "D1–D4" aunque §5 ya incluye D5 (aclaración N1, §3.5); el log de Y1 "después" muestra el test de rollback aún en el paquete `api.controller` (es el hallazgo S1, ya aceptado).

### 3.3 Auditoría EDAV 2: decisiones y firma

- Todos los hallazgos tienen decisión: S1–S4, C1 y C2 aceptados; S5 corregido en `36e2e97`. §5.2 (rechazados): ninguno.
- §8 está firmada por Charry Ríos Daniel Estiven y Kevin Steven Torres Caro, con fecha 2026-10-02.
- Trazabilidad de la firma: las decisiones de §4–§5 se escribieron en `fe39133` (17:30 UTC, 21 minutos después del resultado) y la revisión del diff en `1a3e1ef`, ambos con la identidad `Charry21`. La incorporación de Kevin Steven Torres Caro como firmante la hizo él desde GitHub (`6a553f2`, `42a8486`). Git registra quién hizo cada commit, no quién tomó cada decisión: la firma es una declaración del equipo que el equipo debe poder sostener.
- La §2.1 de la EDAV omite el cambio de hipótesis de `c16cd03` (aclaración N2, §3.5).

### 3.4 Construcción de la imagen Docker de la API

Verificación hecha el 2026-10-10 en un contenedor Linux con intercepción TLS (evidencia en [`spike-s10/build-imagen-api-2026-10-10/`](./spike-s10/build-imagen-api-2026-10-10/), integrada con el PR #62):

- `app/Dockerfile` original: **falla** en `mvn -DskipTests package` por `PKIX path building failed` al descargar dependencias de Maven Central.
- Variante que solo añade las CA del entorno en la etapa de build: construye (`BUILD SUCCESS`) y el contenedor arranca; `GET /actuator/health` → 200 con BD `UP`, `GET /api/mascotas/buscar` → 200.
- Esto **no** demuestra que el Dockerfile original construya en otro entorno, ni que el fallo se deba al código. Lo más probable, sin demostrar, es que se deba al proxy del entorno.

### 3.5 Aclaraciones sobre documentos ya registrados

Estas aclaraciones se registran aquí para no alterar en silencio documentos ya integrados. `06-spike-resultado-s10.md` y `05-auditoria-ia-s9.md` (firmada el 2026-10-02) quedan tal como están.

| # | Documento y sección | Texto registrado | Aclaración | Efecto sobre el resultado |
|---|---|---|---|---|
| N1 | `06-spike-resultado-s10.md` §7 | "Las desviaciones D1–D4 no afectan a la comparación…" | Debe leerse "D1–D5". D5 (fusión errónea de la rama de control, PR #50) se añadió a §5 en `36e2e97`, después de redactar §7 en `e9bcd93`, y §7 no se actualizó. Según §5, D5 tampoco afecta a las mediciones, que se hicieron antes de la fusión. | Ninguno |
| N2 | `05-auditoria-ia-s9.md` §2.1 | "Hipótesis y criterios no se modificaron después de conocer el resultado" | La frase es correcta respecto al resultado, pero incompleta: no registra que `c16cd03` (2026-10-02 16:10 UTC) cambió la hipótesis de no regresión (Y1–Y3) a una de mejora (Y4/Y5 más Y1–Y3) después de una revisión preliminar de imports del estado base que no quedó registrada (§4.1). El equipo puede añadir un anexo fechado a la EDAV que remita a esta nota, sin reescribir lo firmado. | Afecta a cómo se interpreta la preinscripción, no a los valores medidos |

### 3.6 Estado actual de `main` (2026-10-10)

Verificación hecha sobre `main` = `6465b1a`, cuyo árbol de `app/` es `cef1272…`, el mismo que en `1e522df` (`44ede36`). Evidencia en [`spike-s10/verificacion-main-2026-10-10/`](./spike-s10/verificacion-main-2026-10-10/).

| Métrica | Resultado en `main` | Coincide con 06 §4 (después) |
|---|---|---|
| Y1 | 2 tests, 0 fallos, en 3/3 corridas con BD limpia | Sí |
| Y2 | 0 | Sí |
| Y3 | S1, S2: 201; S3: 200; 3/3 repeticiones coinciden; 0 diferencias frente a `spike-s10/despues/y3` | Sí |
| Y4 | 7/7 (100%) | Sí |
| Y5 | 0 | Sí |

- Hallazgo S1 de la EDAV 2: **sigue abierto**. `AdopcionControllerRollbackIntegrationTest` continúa en el paquete de test `com.patitasurbanas.api.controller`, y ningún commit ha tocado `app/src/test` desde `1e522df`. Ver P5.
- El entorno es el de la reproducción del 2026-10-09 (Ubuntu 24.04.5, OpenJDK 21.0.12.1, Docker 29.8.2, PostgreSQL 16.15), no el de la medición original.

## 4. Limitaciones que el cierre deja explícitas

### 4.1 Preinscripción y diseño de las métricas

- La hipótesis con la que se emite el veredicto es la de `c16cd03` (2026-10-02 16:10 UTC), menos de una hora antes de las mediciones. Ese commit pasó de una hipótesis de no regresión (Y1–Y3) a una de mejora (Y4/Y5 más Y1–Y3) e indica que se apoyó en "una revisión preliminar de imports" del estado base. No hay registro independiente de cuándo se hizo esa revisión.
- Y4 e Y5 miden la ubicación de las clases, que es exactamente lo que cambia X. Si X se aplica según lo especificado, se cumplen casi por construcción. Su capacidad para refutar es baja; la carga de refutación recae en Y1–Y3.

### 4.2 Instrumentos

- El medidor Y2 detecta imports explícitos prohibidos, pero no ve imports comodín, imports estáticos, nombres totalmente calificados ni referencias dentro del mismo paquete. En el código medido se comprobó manualmente que no hay casos de ese tipo.
- Y5 no detecta una clase nueva sin mapear colocada en el módulo equivocado. No afecta al código medido, pero el script no sirve tal cual para código futuro.

### 4.3 Validez externa (pendiente)

- Ejecución en Windows/WSL2: **no verificada**.
- `docker compose up --build` con el `app/Dockerfile` original: **no verificado**. La imagen solo se construyó con una variante (§3.4).
- `POST /api/adopciones/test-fallo` fuera del test de rollback, entradas no válidas y casos límite: **no verificados**.
- El cumplimiento futuro de las fronteras sigue dependiendo de la convención (ADR-02).

### 4.4 Alcance de lo que se evalúa

El spike evalúa la reorganización de paquetes y las fronteras modulares (Decisiones 1 y 2 de ADR-03). No evalúa la comunicación entre módulos (Decisión 3), ni la adecuación de la arquitectura completa, ni la mantenibilidad a largo plazo.

## 5. Pendientes

Los pendientes técnicos siguen abiertos y **no** se presentan como pruebas superadas. Responsable y fecha los asigna el equipo.

| # | Pendiente o supuesto | Tipo | Estado | Condición de revisión | Responsable | Fecha |
|---|---|---|---|---|---|---|
| P1 | Construir la imagen con el `app/Dockerfile` original en un entorno sin intercepción TLS | Verificación técnica | No verificado (§3.4) | Antes de desplegar la API con Docker o de afirmar que el Dockerfile construye | | |
| P2 | Ejecutar `docker compose up --build` completo | Verificación técnica | No verificado | Al resolver P1, o antes de usar Compose como entorno de ejecución de la API | | |
| P3 | Ejecutar en Windows/WSL2 (Y1 y Y3 como mínimo) | Validez externa | No verificado | Antes de afirmar que el resultado vale en el entorno documentado del equipo (Windows con Docker Desktop) | | |
| P4 | Probar `POST /api/adopciones/test-fallo` fuera del test de rollback, entradas no válidas y casos límite | Verificación técnica | No verificado | Cuando se cambie la lógica de adopciones o se amplíe la API | | |
| P5 | Mover el test de rollback a `api.adopciones` (hallazgo S1) | Seguimiento del spike | Abierto: el test sigue en `api.controller` en `main` (`6465b1a`, §3.6) | En el siguiente cambio que toque `app/src/test`, y antes de añadir tests del módulo `adopciones` | | |
| P6 | Añadir a la EDAV 2 un anexo fechado que remita a la aclaración N2 | Trazabilidad | Pendiente de decisión del equipo | Antes de citar la EDAV 2 como prueba de una preinscripción íntegra | | |
| P8 | Ajustar `revisar_modulos.py` (Y2: comodines, nombres calificados; Y5: clases sin mapear) si se reutiliza en otro spike | Instrumento | Limitación conocida (§4.2) | Antes de reutilizar el script en otro spike o sobre código nuevo | | |
| P9 | La evidencia funcional cubre solo los 2 tests existentes y las 3 solicitudes S1–S3 | Supuesto (cobertura) | Aceptado como límite; no demuestra equivalencia universal | Al añadir tests o endpoints, o si se observa una regresión fuera de S1–S3 | | |
| P10 | Las fronteras entre módulos se mantienen solo por convención (ADR-02); no hay comprobación automática en el build | Supuesto (mantenimiento) | Aceptado como límite; el spike midió una sola reorganización | En cada cambio que añada clases o imports entre módulos, o si se decide automatizar la regla (por ejemplo, en CI) | | |

Los límites de cobertura (P9), la imagen Docker (P1, P2), los casos límite (P4) y las fronteras por convención (P10) figuran aquí como pendientes o supuestos, no como garantías demostradas.

## 6. Veredicto del equipo

> El informe 06 propone "hipótesis soportada en las condiciones registradas". El veredicto final lo emite el equipo, comparando los resultados con la línea base y con la hipótesis y los criterios fijados en `c16cd03`, sin modificarlos. Refutar también es un resultado válido.

### 6.1 Pregunta que el veredicto debe responder

**¿Qué parte de la evidencia sostiene el veredicto, teniendo en cuenta que (a) la hipótesis se fijó en `c16cd03` después de una revisión preliminar de la línea base que no quedó registrada, y (b) Y4 e Y5 apenas pueden refutar la mejora, porque miden el mismo movimiento de clases que constituye el cambio?**

Para responderla, el equipo debería indicar:

1. Qué métricas considera evidencia con capacidad real de refutar (por ejemplo, Y1–Y3) y cuáles solo constatan que el cambio se aplicó (Y4/Y5).
2. Si, con esa distinción, el veredicto sobre la hipótesis de `c16cd03` es el mismo que sobre la hipótesis original de no regresión (`99269dd`), o si debe formularse de forma más acotada.
3. Qué pendientes de §5 condicionan el veredicto y cuáles no.
4. Qué decisión arquitectónica se toma a partir de la evidencia (adoptar, refutar o adoptar con condiciones la reorganización de ADR-01) y qué cambia en ADR-01, ADR-02 y ADR-03.

### 6.2 Respuesta del equipo

- Veredicto (se adopta / se refuta / se adopta con condiciones): 
- Respuesta a la pregunta de §6.1: 
- Justificación, con referencia a §2–§4: 
- Limitaciones y pendientes que acompañan al veredicto: 
- Consecuencias para ADR-01, ADR-02 y ADR-03: 

Nombre(s): 

Fecha: 

---

## Anexo A. Equivalencia de hashes tras la reescritura de `main` (2026-10-10)

### A.1 Por qué cambiaron los hashes

El 2026-10-09 y el 2026-10-10, `main` se reescribió con force-push para corregir metadatos de autoría: se cambió el autor de varios commits y se eliminaron los trailers de coautoría. Un hash de Git depende del autor, del mensaje y de los padres del commit, así que cualquier cambio en uno de ellos cambia el hash de ese commit y el de todos sus descendientes. Por eso los últimos 64 commits de `main` tienen hashes nuevos.

**El contenido no cambió.** En los 38 commits de la tabla, el árbol (el contenido completo del repositorio en ese commit) es idéntico en el hash antiguo y en el nuevo. Se conservan también la fecha de autor y el asunto. En particular, el árbol de `app/` sigue siendo `cef1272…` y `1e522df` equivale a `44ede36`.

Los documentos anteriores (`04` a `08`, la EDAV 2 y los ADR) **no se reescriben**: siguen citando los hashes originales con los que se firmaron y verificaron. Esta tabla permite traducirlos.

### A.2 Dónde siguen los commits originales

Los hashes antiguos no están en `main`, pero siguen existiendo en GitHub:

- En las ramas antiguas; por ejemplo, `spike/fronteras-modulares-s10` contiene `af02cce`, `1e522df`, `d97cbf3` y `e9bcd93`.
- En las referencias de los PR, que GitHub no borra: `refs/pull/45/head` a `refs/pull/49/head` contienen `8a2a001`, `99269dd` y `c16cd03`.

Para comprobar cualquier fila:

```
git fetch origin '+refs/pull/*/head:refs/remotes/pr/*'
git log -1 --format='%T %at %s' <hash antiguo>
git log -1 --format='%T %at %s' <hash nuevo>
```

Ambas salidas deben coincidir.

### A.3 Tabla de equivalencias

Método: para cada hash citado en `experimentos/*.md`, en `adr/` y en este registro, se buscó en `main` (`aed92f6`) el commit con la misma fecha de autor (en segundos) y el mismo asunto. Después se comparó el árbol. Todas las coincidencias fueron únicas. La fecha se muestra en la zona horaria del autor.

| Hash citado (original) | Hash en `main` (`aed92f6`) | Fecha de autor | Asunto | Árbol |
|---|---|---|---|---|
| `8a2a001` | `e2318e1` | 2026-10-01 22:47 | docs(s9): especificación del spike (hipótesis, criterios y alcance) antes de ejecutar | igual |
| `887ccf1` | `6ad651d` | 2026-10-01 22:48 | Merge pull request #45 from Charry21/feat/spike-especificacion-s9 | igual |
| `99269dd` | `305d62e` | 2026-10-02 16:07 | docs(s9): completar condiciones de medición del spike antes de ejecutar | igual |
| `c16cd03` | `77007ce` | 2026-10-02 16:10 | docs(s9): añadir métricas de mejora Y4/Y5, agente y ramas del spike; referenciar spike desde ADRs | igual |
| `01f1c7b` | `5977204` | 2026-10-02 16:22 | docs(s9): registrar en ADR-01 y ADR-02 el veredicto Ajustada del mini-comité de Semana 8 | igual |
| `403d7b5` | `c1c52da` | 2026-10-02 16:32 | docs(s9): ADR-03 de límites de módulo, API pública y comunicación síncrona/asíncrona (propuesta) | igual |
| `3d458a2` | `dd451cf` | 2026-10-02 11:38 | Merge pull request #48 from Charry21/claude/determined-albattani-d1aliu | igual |
| `af02cce` | `b52207e` | 2026-10-02 17:05 | exp(s10): scripts de medición y línea base Y1-Y5 en el commit base 887ccf1 | igual |
| `4883f9c` | `6508379` | 2026-10-02 17:05 | control(y2): inyectar import prohibido para validar el medidor (rama descartable, no se integra) | igual |
| `1e522df` | `44ede36` | 2026-10-02 17:05 | spike(s10): reorganizar clases en paquetes por dominio (adopciones/, mascotas/) | igual |
| `d97cbf3` | `ac85955` | 2026-10-02 17:07 | exp(s10): mediciones después de la reorganización Y1-Y5 y comparación Y3 | igual |
| `e9bcd93` | `7488569` | 2026-10-02 17:08 | exp(s10): registro de ejecución, desviaciones y veredicto del spike 1 | igual |
| `66a38ef` | `bbfae67` | 2026-10-02 17:10 | docs(s10): ADR-03 actualizado con el resultado del spike (Aceptada) | igual |
| `af92e3f` | `545395a` | 2026-10-02 12:11 | Merge pull request #50 from Charry21/spike/control-y2-descartable | igual |
| `0206cfd` | `588fa8a` | 2026-10-02 17:12 | Merge main (incluye PR #50 fusionado por error) en la rama del spike | igual |
| `36e2e97` | `5f78881` | 2026-10-02 17:13 | fix(s10): quitar el import de control de Y2 fusionado en main por error (PR #50) | igual |
| `fe39133` | `6414186` | 2026-10-02 17:30 | docs(s10): auditoría EDAV 2 con las decisiones del equipo sobre S1-S5 y C1-C2 | igual |
| `1a3e1ef` | `e5be2f0` | 2026-10-02 23:33 | docs(s10): cerrar campos pendientes de la EDAV 2 (agente y revisión del diff) | igual |
| `7b1f022` | `4b6a0aa` | 2026-10-02 18:34 | Merge pull request #49 from Charry21/spike/fronteras-modulares-s10 | igual |
| `6a553f2` | `d198723` | 2026-10-02 18:44 | Add Kevin Steven Torres Caro as author in EDAV | igual |
| `42a8486` | `136c32c` | 2026-10-02 18:45 | Revise authorship details in EDAV document | igual |
| `f0b2b43` | `0d5cf62` | 2026-10-02 23:50 | docs(s10): corregir formato de la fila de firmantes en la EDAV 2 | igual |
| `7b8f408` | `8c0369f` | 2026-10-03 00:54 | docs(domain): modelar subdominios, bounded contexts y context map | igual |
| `bc908e2` | `2837fd2` | 2026-10-03 00:55 | docs(integracion): contrato API verificado y decisión síncrono/asíncrono por relación | igual |
| `ed5aba1` | `c811ca4` | 2026-10-02 19:58 | Merge pull request #52 from Charry21/docs/modulo5-dominio-integracion | igual |
| `e4e0ece` | `85569b7` | 2026-10-02 20:36 | Merge pull request #53 from Charry21/docs/modelo-dominio | igual |
| `91afab8` | `dd99d51` | 2026-10-09 09:48 | Unificar el modelo del dominio en docs/dominio con 4 contextos basados en evidencia | igual |
| `8f80b21` | `f4be49c` | 2026-10-09 10:15 | Merge pull request #54 from Charry21/docs/unificar-modelo-dominio | igual |
| `42c7c9c` | `3bf27cd` | 2026-10-09 11:23 | Registrar respuestas P1-P4 como decisiones D6-D9 del modelo del dominio | igual |
| `9c84f21` | `561e106` | 2026-10-09 11:26 | Merge pull request #56 from Charry21/docs/respuestas-p1-p4 | igual |
| `3e56742` | `8c2d244` | 2026-10-09 16:26 | Merge pull request #57 from Charry21/docs/entregable2-encuadre-spike | igual |
| `a3e76c0` | `8c2d244` | 2026-10-09 16:26 | Merge pull request #57 from Charry21/docs/entregable2-encuadre-spike | igual |
| `cd2dba1` | `3489d7f` | 2026-10-10 00:48 | docs(s10): registro de cierre del spike 1 (pendiente del veredicto del equipo) | igual |
| `844d4b3` | `5b5700b` | 2026-10-09 19:54 | Merge pull request #61 from Charry21/claude/project-thread-4cy091 | igual |
| `00e3ead` | `d8b88ab` | 2026-10-09 19:55 | Merge pull request #62 from Charry21/claude/project-thread-hlv246 | igual |
| `b51b353` | `b88c50a` | 2026-10-10 00:55 | docs(s10): enlazar en el cierre la evidencia integrada de los PR #61 y #62 | igual |
| `fed73ce` | `baa53c5` | 2026-10-10 00:55 | Merge remote-tracking branch 'origin/main' into claude/project-thread-66yxi6 | igual |
| `16cffbd` | `aed92f6` | 2026-10-09 19:55 | Merge pull request #63 from Charry21/claude/project-thread-66yxi6 | igual |

`3e56742` y `a3e76c0` son dos versiones anteriores del mismo merge del PR #57, ambas reescritas. Las dos corresponden a `8c2d244`.

Quedan fuera de la tabla:

- `0a243b0` (último cambio en `app/` antes del spike), que no cambió y sigue en `main`.
- Los commits que cita `docs/EDAV-01.md` (`18ed28e`, `4d13ad3`, `6bd39c1`, `773d97a`, `e75b94d`), que no estaban en `main` antes de la reescritura y no se vieron afectados.
