# CQRS y Event Sourcing — análisis de aplicabilidad
## Módulo 5 · Entregable 5

Estos patrones no se adoptan por aparecer en el temario. Cada uno se evalúa
con la misma pregunta: **¿qué problema concreto del sistema resolvería y
cuánto costaría?**

---

## 1. CQRS

Análisis completo, contrastado con las operaciones reales del código, en
[`dossier/17-cqrs-consistencia-eventual-s10.md`](../../dossier/17-cqrs-consistencia-eventual-s10.md) (§3).

| | |
|---|---|
| **Problema que resolvería** | Separar modelos de escritura y lectura cuando sus necesidades divergen (vistas agregadas, cargas de lectura muy superiores, contención). |
| **Evidencia actual** | No existe ningún endpoint de lectura sobre datos persistidos (`GET /api/adopciones` → 405, verificado). La única lectura (`/api/mascotas/buscar`) es simulada. En Semana 6 el SQL fue solo el 2–9% del tiempo de `POST /api/adopciones` (`dossier/10`). |
| **Costo que introduciría** | Dos modelos, proyecciones que mantener sincronizadas, más pruebas y consistencia eventual en datos que hoy son inmediatos. |
| **Decisión** | **No se incorpora.** |
| **Se reconsidera si** | Aparece una lectura agregada entre contextos (por ejemplo, un panel de fundaciones con solicitudes por etapa y datos de mascotas) que el modelo de escritura no pueda servir sin romper ADR-02; o una medición muestra que las lecturas degradan TRX-02; o el catálogo de mascotas (QA-03: paginación y clustering) necesita un modelo de lectura propio. |

---

## 2. Event Sourcing

| | |
|---|---|
| **Qué es** | Guardar la secuencia de eventos como fuente de verdad y reconstruir el estado actual reproduciéndolos, en lugar de guardar solo el último estado. |
| **Beneficio potencial en Patitas Urbanas** | Historial completo y auditable de cada solicitud de adopción; auditoría de tratamiento de datos (Ley 1581). |
| **Lo que ya cubre el sistema sin Event Sourcing** | El historial de una solicitud ya existe como tabla: cada `EtapaAdopcion` registra una etapa con su fecha. Es un registro de cambios suficiente para saber por qué etapas pasó una solicitud. |
| **Costo** | Almacén de eventos, versionado del esquema de cada evento, proyecciones para leer el estado, reconstrucción, instantáneas para rendimiento, y depuración más difícil. Para un equipo de 2 personas con plazo fijo (DA-03) es desproporcionado. |
| **Riesgo específico** | Los eventos inmutables con datos personales chocan con el derecho de supresión de la Ley 1581: borrar datos de un usuario exigiría técnicas adicionales (por ejemplo, cifrado por usuario y destrucción de la clave). |
| **Evidencia actual** | Ningún driver ni escenario de calidad pide reconstruir estados pasados más allá del historial de etapas. |
| **Decisión** | **No se incorpora.** |
| **Se reconsidera si** | Se exige auditoría completa e inmutable de cada cambio de estado de una adopción (por ejemplo, por un regulador) que la tabla `etapa_adopcion` no pueda cubrir; o aparecen disputas que requieran reconstruir el estado exacto en una fecha pasada. |

---

## 3. Conclusión

Ninguno de los dos patrones resuelve hoy un problema medido del sistema.
Adoptarlos añadiría costo sin mejorar ningún driver. La decisión
documentada es **no adoptarlos**, con condiciones de revisión explícitas;
esto es coherente con ADR-03 (comunicación síncrona en proceso) y con el
resultado del spike 1.

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 10 · Módulo 5 · Arquitectura de Software*
