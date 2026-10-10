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

Además, Y1–Y5 se volvieron a medir el 2026-10-09 sobre `887ccf1`, `1e522df` y el control `4883f9c`, en un contenedor Linux con versiones cercanas a las originales, y los resultados coinciden con los registrados; las salidas de `revisar_modulos.py` se regeneran idénticas byte a byte (evidencia en el PR #61, pendiente de integrar).

Observaciones menores, sin efecto sobre los valores: 06 §7 menciona "D1–D4" aunque §5 ya incluye D5 (aclaración N1, §3.5); el log de Y1 "después" muestra el test de rollback aún en el paquete `api.controller` (es el hallazgo S1, ya aceptado).

### 3.3 Auditoría EDAV 2: decisiones y firma

- Todos los hallazgos tienen decisión: S1–S4, C1 y C2 aceptados; S5 corregido en `36e2e97`. §5.2 (rechazados): ninguno.
- §8 está firmada por Charry Ríos Daniel Estiven y Kevin Steven Torres Caro, con fecha 2026-10-02.
- Trazabilidad de la firma: las decisiones de §4–§5 se escribieron en `fe39133` (17:30 UTC, 21 minutos después del resultado) y la revisión del diff en `1a3e1ef`, ambos con la identidad `Charry21`. La incorporación de Kevin Steven Torres Caro como firmante la hizo él desde GitHub (`6a553f2`, `42a8486`). Git registra quién hizo cada commit, no quién tomó cada decisión: la firma es una declaración del equipo que el equipo debe poder sostener.
- La §2.1 de la EDAV omite el cambio de hipótesis de `c16cd03` (aclaración N2, §3.5).

### 3.4 Construcción de la imagen Docker de la API

Verificación hecha el 2026-10-10 en un contenedor Linux con intercepción TLS (evidencia en el PR #62, pendiente de integrar):

- `app/Dockerfile` original: **falla** en `mvn -DskipTests package` por `PKIX path building failed` al descargar dependencias de Maven Central.
- Variante que solo añade las CA del entorno en la etapa de build: construye (`BUILD SUCCESS`) y el contenedor arranca; `GET /actuator/health` → 200 con BD `UP`, `GET /api/mascotas/buscar` → 200.
- Esto **no** demuestra que el Dockerfile original construya en otro entorno, ni que el fallo se deba al código. Lo más probable, sin demostrar, es que se deba al proxy del entorno.

### 3.5 Aclaraciones sobre documentos ya registrados

Estas aclaraciones se registran aquí para no alterar en silencio documentos ya integrados. `06-spike-resultado-s10.md` y `05-auditoria-ia-s9.md` (firmada el 2026-10-02) quedan tal como están.

| # | Documento y sección | Texto registrado | Aclaración | Efecto sobre el resultado |
|---|---|---|---|---|
| N1 | `06-spike-resultado-s10.md` §7 | "Las desviaciones D1–D4 no afectan a la comparación…" | Debe leerse "D1–D5". D5 (fusión errónea de la rama de control, PR #50) se añadió a §5 en `36e2e97`, después de redactar §7 en `e9bcd93`, y §7 no se actualizó. Según §5, D5 tampoco afecta a las mediciones, que se hicieron antes de la fusión. | Ninguno |
| N2 | `05-auditoria-ia-s9.md` §2.1 | "Hipótesis y criterios no se modificaron después de conocer el resultado" | La frase es correcta respecto al resultado, pero incompleta: no registra que `c16cd03` (2026-10-02 16:10 UTC) cambió la hipótesis de no regresión (Y1–Y3) a una de mejora (Y4/Y5 más Y1–Y3) después de una revisión preliminar de imports del estado base que no quedó registrada (§4.1). El equipo puede añadir un anexo fechado a la EDAV que remita a esta nota, sin reescribir lo firmado. | Afecta a cómo se interpreta la preinscripción, no a los valores medidos |

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

| # | Pendiente | Tipo | Estado | Responsable | Fecha |
|---|---|---|---|---|---|
| P1 | Construir la imagen con el `app/Dockerfile` original en un entorno sin intercepción TLS | Verificación técnica | No verificado (§3.4) | | |
| P2 | Ejecutar `docker compose up --build` completo | Verificación técnica | No verificado | | |
| P3 | Ejecutar en Windows/WSL2 (Y1 y Y3 como mínimo) | Validez externa | No verificado | | |
| P4 | Probar `POST /api/adopciones/test-fallo` fuera del test de rollback, entradas no válidas y casos límite | Verificación técnica | No verificado | | |
| P5 | Mover el test de rollback a `api.adopciones` (hallazgo S1) | Seguimiento del spike | Aceptado, sin hacer | | |
| P6 | Añadir a la EDAV 2 un anexo fechado que remita a la aclaración N2 | Trazabilidad | Pendiente de decisión del equipo | | |
| P7 | Decidir si se integran los PR #61 (reproducción Y1–Y5) y #62 (build de la imagen) | Evidencia | PR abiertos | | |
| P8 | Ajustar `revisar_modulos.py` (Y2: comodines, nombres calificados; Y5: clases sin mapear) si se reutiliza en otro spike | Instrumento | Limitación conocida (§4.2) | | |

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
