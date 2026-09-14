# 16 — Borrador de Decisión de Estilo Arquitectónico · Semana 7
## Patitas Urbanas · Módulo 4

---

## 1. Propósito de este documento

Integrar el análisis técnico, la comparación de estilos y el diseño
modular en una decisión provisional de estilo arquitectónico. Este
documento es un borrador: la decisión no está confirmada hasta que el
mini-comité de Semana 8 emita su veredicto. Las incertidumbres están
declaradas explícitamente.

---

## 2. Decisión que se está considerando

> Reorganizar el monolito actual de Patitas Urbanas adoptando una
> estructura de **monolito modular**, con fronteras de paquete
> explícitas por dominio de negocio, manteniendo la infraestructura
> actual sin cambios.

---

## 3. Contexto

El sistema actual es un monolito en capas con un único paquete
`com.patitasurbanas.api` que contiene clases de todos los dominios
sin fronteras explícitas. No existe evidencia de un cuello de botella
de rendimiento confirmado. La tensión identificada es de
**mantenibilidad y acoplamiento**, no de rendimiento.

El análisis de causa (`dossier/13-analisis-causa-s7.md`) concluye que
las hipótesis H1 y H2 de Semana 6 fueron refutadas y que no hay
diagnóstico causal suficiente para justificar una decisión de
rendimiento. La decisión de estilo responde a DA-01 (mantenibilidad)
y DA-04 (extensibilidad).

---

## 4. Drivers y restricciones que motivan esta decisión

| ID | Driver / Restricción | Cómo aplica |
|---|---|---|
| DA-01 | Mantenibilidad | El paquete único actual dificulta cambiar un dominio sin afectar otros |
| DA-02 | Testeabilidad | Los módulos con fronteras claras permiten tests más focalizados |
| DA-03 | Costo operativo proporcional al equipo | La reorganización no cambia infraestructura ni agrega herramientas nuevas |
| DA-04 | Extensibilidad | Agregar veterinarias, donaciones o chat sigue el mismo patrón modular |
| DA-05 | Trazabilidad en Git | Cada módulo nuevo se puede agregar en un PR independiente y auditable |

---

## 5. Alternativas consideradas

Ver análisis completo en `dossier/14-comparacion-estilos-s7.md`.

| Alternativa | Decisión | Razón principal |
|---|---|---|
| A — Capas (status quo) | Descartada | No resuelve el problema de mantenibilidad identificado |
| B — Monolito modular | **Seleccionada provisionalmente** | Resuelve DA-01 y DA-04 con costo proporcional al equipo |
| C — Hexagonal | Descartada por ahora | Costo de implementación desproporcionado para 2 personas con plazo fijo |
| D — Microservicios | Descartada | Sobreingeniería evidente; viola DA-03 |

---

## 6. Evidencia que respalda la decisión

| Evidencia | Qué demuestra |
|---|---|
| PR #22 — adición de JPA | El módulo de adopciones ya opera con cohesión natural |
| PR #41 — instrumentación S6 | La instrumentación afecta exclusivamente clases de adopciones, sin tocar otros dominios |
| `dossier/07-c4-componentes.md` | Los componentes de adopciones están identificados y verificados |
| `dossier/14-comparacion-estilos-s7.md` | La comparación contextualizada favorece el monolito modular |
| `dossier/15-diseno-modular-s7.md` | La reorganización de paquetes está definida con reglas de dependencia claras |
| Issues #19 y #21 | Confirman que no hay evidencia de rendimiento real para justificar una decisión de optimización |

---

## 7. Qué mejora esta decisión

- Las fronteras de módulo quedan visibles en la estructura de paquetes
  y auditables en cualquier PR.
- Un cambio en el módulo de adopciones no puede afectar mascotas ni
  veterinarias sin que el revisor lo detecte en el diff del PR.
- Agregar un módulo nuevo (donaciones, chat, historial médico) sigue
  el mismo patrón sin reescribir lo existente.
- La corrección de terminología del C4 (de "Microservicio" a "Monolito
  modular") queda respaldada por una decisión arquitectónica formal.

---

## 8. Qué sacrifica esta decisión

- El dominio sigue conociendo anotaciones JPA (`@Entity`,
  `@Transactional`). No se logra la independencia tecnológica total
  que ofrecería la arquitectura hexagonal.
- Las fronteras de módulo se mantienen por convención de equipo y
  revisión de PR, no por refuerzo estructural automático. Si el equipo
  no las respeta, el beneficio se pierde.
- No resuelve completamente DA-02: la testeabilidad del dominio sin
  Spring sigue siendo parcial porque las entidades tienen anotaciones
  de framework.

---

## 9. Trade-off declarado

> Se sacrifica la pureza de diseño (independencia de framework) a
> cambio de un costo de implementación proporcional al tamaño del
> equipo y al plazo disponible. Si el sistema evoluciona más allá del
> alcance universitario, la migración a arquitectura hexagonal es el
> paso natural siguiente desde esta base modular.

---

## 10. Costo de implementación estimado

| Tarea | Esfuerzo estimado | Riesgo |
|---|---|---|
| Reorganizar paquete de adopciones en `adopciones/` | Bajo — mover archivos, actualizar imports | Bajo — los tests deben seguir pasando |
| Reorganizar paquete de mascotas en `mascotas/` | Bajo — mover `MascotaController`, actualizar imports | Bajo |
| Crear paquete `shared/` con excepciones base | Bajo — crear carpeta y mover tipos comunes si existen | Bajo |
| Crear paquete `config/` con configuración Spring | Bajo — mover clases de configuración existentes | Bajo |
| Verificar que los tests existentes pasan | Bajo — ejecutar suite tras reorganización | Medio — si hay tests que dependen de la estructura de paquetes actual |
| Documentar las reglas de dependencia en el README del módulo | Bajo | Ninguno |

**Esfuerzo total estimado:** 1 sesión de trabajo para 2 personas.
No requiere nueva infraestructura ni nuevas dependencias en `pom.xml`.

---

## 11. Riesgos de la decisión

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Las fronteras de módulo se rompen por convención sin disciplina | Media | Medio | Revisión de PR con verificación explícita de imports entre módulos |
| Los tests actuales dependen de la estructura de paquetes plana | Baja | Medio | Ejecutar suite completa antes de hacer merge de la reorganización |
| El módulo `shared/` crece sin control y se convierte en un dumping ground | Media | Alto | Definir criterio claro de qué puede entrar en `shared/` y revisarlo en cada PR |

---

## 12. Reversibilidad

La decisión es altamente reversible. Revertir implica mover los
archivos de vuelta al paquete plano original. No hay infraestructura
nueva que deshacer, no hay dependencias nuevas en `pom.xml` y no hay
cambios de comportamiento en tiempo de ejecución: el sistema se
comporta exactamente igual antes y después de la reorganización.

---

## 13. Preguntas abiertas para el mini-comité (Semana 8)

1. ¿Las fronteras de módulo deben reforzarse con ArchUnit o basta con
   la disciplina de revisión de PR para el alcance universitario?

2. ¿El módulo `shared/` debe tener un criterio de admisión explícito
   para evitar que se convierta en un repositorio de clases sin
   cohesión?

3. ¿La corrida 4 de K6 (p95 = 6.50 ms, max = 216.61 ms, 2 dropped
   iterations) representa comportamiento real con JPA activo? Si es
   así, ¿qué experimento de Semana 9 debería verificarlo?

4. ¿La decisión cambia si el sistema debe soportar más de 2
   desarrolladores simultáneos en el futuro?

5. ¿El módulo `veterinarias/` debe crearse vacío ahora para reservar
   la frontera, o esperar hasta que exista código real que mover?

---

## 14. Estado de la decisión

| Campo | Valor |
|---|---|
| Estado | **Borrador — pendiente de revisión en mini-comité** |
| Fecha del borrador | 2026-09-13 |
| Próxima revisión | Semana 8 — mini-comité técnico |
| Veredicto del comité | Pendiente (confirmada / ajustada / reconsiderada) |

---

## 15. Referencias cruzadas

| Documento | Ubicación | Relación |
|---|---|---|
| Análisis de causa | `dossier/13-analisis-causa-s7.md` | Identifica la tensión que motiva esta decisión |
| Comparación de estilos | `dossier/14-comparacion-estilos-s7.md` | Sustenta la selección provisional |
| Diseño modular | `dossier/15-diseno-modular-s7.md` | Define cómo se implementa la decisión |
| ADR formal | `adr/adr-01-decision-estilo.md` | Formalización de esta decisión |
| ADR modularidad | `adr/adr-02-modularidad.md` | Formalización de las reglas de dependencia |
| Decisión consolidada | `docs/08-decision-estilo-arquitectonico.md` | Versión navegable para entrega |

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Fecha: 2026-09-13*
*Semana 7 · Módulo 4 · Arquitectura de Software*
