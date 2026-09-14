# 08 — Decisión de Estilo Arquitectónico
## Patitas Urbanas · Módulo 4

---

## Estado

**Borrador** — pendiente de veredicto del mini-comité (Semana 8).

| Campo | Valor |
|---|---|
| Fecha del borrador | 2026-09-13 |
| Próxima revisión | Semana 8 — mini-comité técnico |
| Veredicto del comité | _pendiente_ (confirmada / ajustada / reconsiderada) |
| ADR de referencia | `adr/adr-01-decision-estilo.md` · `adr/adr-02-modularidad.md` |

---

## 1. Contexto del sistema

El sistema actual es un monolito en capas desplegado como contenedor
único: Spring Boot 3.3.4 + PostgreSQL 16 + Docker Compose. El equipo
es de 2 personas con plazo universitario fijo.

**Corrección de terminología:** el C4 Nivel 2 etiquetaba el backend
como "Microservicio". El sistema es un **monolito en capas** con un
único contenedor desplegable. Esta decisión corrige esa inconsistencia.

Evidencia verificada: `dossier/06-c4-contenedores.md`,
`dossier/07-c4-componentes.md`.

---

## 2. Problema arquitectónico

El análisis técnico de Semana 6 refutó las hipótesis H1 y H2 de
rendimiento. No existe evidencia de un cuello de botella confirmado.

La tensión identificada es de **mantenibilidad**: el paquete único
`com.patitasurbanas.api` no tiene fronteras de módulo explícitas.
Cualquier clase puede depender de cualquier otra sin señal estructural.

Análisis completo: `dossier/13-analisis-causa-s7.md`.

---

## 3. Drivers y restricciones

| ID | Driver | Prioridad |
|---|---|---|
| DA-01 | Mantenibilidad: cambiar un módulo sin romper otros | Alta |
| DA-02 | Testeabilidad: probar lógica sin levantar Spring | Alta |
| DA-03 | Costo operativo proporcional al equipo de 2 personas | Alta |
| DA-04 | Extensibilidad: agregar módulos sin reescribir | Media |
| DA-05 | Trazabilidad: cada cambio auditable en Git | Alta |

**Restricciones activas:** stack comprometido (Java 21 + Spring Boot
+ PostgreSQL 16), Docker Compose sin orquestador, plazo fijo,
máximo 1 semana de aprendizaje para cualquier tecnología nueva.

---

## 4. Alternativas consideradas

Análisis completo con criterios, costos y trade-offs:
`dossier/14-comparacion-estilos-s7.md`.

| Alternativa | Decisión | Razón |
|---|---|---|
| A — Capas (status quo) | Descartada | No resuelve DA-01 ni DA-04 |
| B — Monolito modular | **Seleccionada provisionalmente** | Proporcional al equipo y al plazo; resuelve DA-01 y DA-04 |
| C — Hexagonal | Descartada por ahora | Costo desproporcionado para 2 personas con plazo fijo |
| D — Microservicios | Descartada | Sobreingeniería; viola DA-03 |

---

## 5. Decisión provisional

Se adopta el **monolito modular**: reorganizar el paquete
`com.patitasurbanas.api` en módulos por dominio con fronteras
explícitas, manteniendo la infraestructura sin cambios.

### Estructura objetivo

com.patitasurbanas.api
├── adopciones/ ← AdopcionController, AdopcionService, repos, models
├── mascotas/ ← MascotaController, MascotaService, repos, models
├── veterinarias/ ← por definir cuando exista código real
├── shared/ ← excepciones base, DTOs comunes
└── config/ ← beans de infraestructura Spring


Diseño completo: `dossier/15-diseno-modular-s7.md`.

### Reglas de dependencia

Ningún módulo puede importar repositorios ni modelos internos de
otro módulo. La comunicación entre módulos es exclusivamente a través
de interfaces de servicio públicas.

Reglas formales: `adr/adr-02-modularidad.md`.

---

## 6. Qué mejora y qué sacrifica

**Mejora:**
- Fronteras de módulo visibles y auditables en cada PR.
- Cambiar adopciones no afecta mascotas ni veterinarias.
- Agregar nuevos módulos sigue el mismo patrón.
- Terminología del C4 alineada con la realidad del sistema.

**Sacrifica:**
- El dominio sigue conociendo anotaciones JPA. No hay independencia
  tecnológica total.
- Las fronteras se mantienen por convención y revisión de PR,
  no por refuerzo automático.

**Trade-off declarado:** se sacrifica pureza de diseño a cambio de
costo de implementación proporcional al equipo y al plazo. La
arquitectura hexagonal es la evolución natural si el sistema crece
más allá del alcance universitario.

---

## 7. Costo y reversibilidad

**Costo:** bajo — reorganización de paquetes en 1 sesión de trabajo,
sin nueva infraestructura ni dependencias en `pom.xml`. El sistema
se comporta exactamente igual en tiempo de ejecución.

**Reversibilidad:** alta — revertir implica mover los archivos al
paquete plano original. No hay infraestructura que deshacer.

---

## 8. Crítica a la propuesta previa de la IA

El agente propuso inicialmente una arquitectura de 39 componentes
(6 librerías + 12 DAOs + 10 servicios TRX + librerías adicionales)
diseñada para Firestore/NoSQL. Esa propuesta tenía tres supuestos
falsos para este sistema:

- **Stack incorrecto:** el sistema usa Spring Boot + PostgreSQL,
  no Firestore.
- **Escala incorrecta:** 39 componentes es sobreingeniería para
  2 personas con plazo fijo.
- **Sin evidencia:** no estaba sustentada en mediciones del sistema
  real sino en el PDF de diseño inicial.

La decisión adoptada se basa en el código verificado del repositorio,
no en el diseño propuesto por la IA.

Registro completo de la crítica: `dossier/evidencia-ia-s7.md`.

---

## 9. Preguntas abiertas para el mini-comité (Semana 8)

1. ¿Las fronteras por convención son suficientes o se requiere
   ArchUnit para refuerzo automático?
2. ¿El módulo `shared/` necesita un criterio de admisión más estricto?
3. ¿La corrida 4 de K6 (p95 = 6.50 ms, max = 216.61 ms) representa
   comportamiento real con JPA activo? ¿Qué experimento de Semana 9
   lo verifica?
4. ¿El módulo `veterinarias/` se crea vacío ahora o se espera código
   real?

---

## 10. Mapa de documentos de Semana 7

| Documento | Ubicación | Contenido |
|---|---|---|
| Análisis de causa | `dossier/13-analisis-causa-s7.md` | Evidencia técnica, limitaciones, observaciones vs inferencias |
| Comparación de estilos | `dossier/14-comparacion-estilos-s7.md` | Análisis detallado de 4 alternativas con criterios y trade-offs |
| Diseño modular | `dossier/15-diseno-modular-s7.md` | Estructura de paquetes, reglas, acoplamiento y cohesión |
| Borrador de decisión | `dossier/16-borrador-decision-estilo-s7.md` | Integración de análisis en decisión provisional con riesgos |
| Evidencia de IA | `dossier/evidencia-ia-s7.md` | Uso, crítica y auditoría de la propuesta del agente |
| ADR-01 | `adr/adr-01-decision-estilo.md` | Decisión formal de estilo arquitectónico |
| ADR-02 | `adr/adr-02-modularidad.md` | Decisión formal de reglas de dependencia |

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Fecha: 2026-09-13*
*Semana 7 · Módulo 4 · Arquitectura de Software*
