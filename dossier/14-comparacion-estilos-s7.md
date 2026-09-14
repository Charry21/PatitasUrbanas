# 14 — Comparación de Estilos Arquitectónicos · Semana 7
## Patitas Urbanas · Módulo 4

---

## 1. Propósito de este documento

Comparar al menos tres estilos arquitectónicos plausibles para el
sistema actual de Patitas Urbanas, evaluando cada uno contra los
drivers y restricciones reales del proyecto. Este documento es insumo
directo para el borrador de decisión (`16-borrador-decision-estilo-s7.md`)
y para los ADR formales.

---

## 2. Contexto de la comparación

El sistema actual es un monolito en capas desplegado como contenedor
único (Spring Boot 3.3.4 + PostgreSQL 16 + Docker Compose), con un
equipo de 2 personas y plazo universitario fijo. La tensión
arquitectónica identificada en `13-analisis-causa-s7.md` no es de
rendimiento sino de **mantenibilidad y acoplamiento**: el paquete único
`com.patitasurbanas.api` no tiene fronteras de módulo explícitas, lo
que dificulta crecer sin introducir dependencias no controladas.

No existe evidencia de un cuello de botella de rendimiento confirmado.
La decisión de estilo responde a la pregunta de mantenibilidad, no a
una optimización de rendimiento.

---

## 3. Drivers arquitectónicos relevantes

| ID | Driver | Tipo | Prioridad |
|---|---|---|---|
| DA-01 | Mantenibilidad: cambiar un módulo sin romper otros | Atributo de calidad | Alta |
| DA-02 | Testeabilidad: probar lógica de negocio sin levantar Spring | Atributo de calidad | Alta |
| DA-03 | Costo operativo proporcional al equipo de 2 personas | Restricción | Alta |
| DA-04 | Extensibilidad: agregar módulos sin reescribir lo existente | Atributo de calidad | Media |
| DA-05 | Trazabilidad: cada cambio auditable en Git | Restricción del curso | Alta |

---

## 4. Restricciones activas

- Stack comprometido: Java 21 + Spring Boot + PostgreSQL 16.
- Infraestructura: Docker Compose local, sin Kubernetes ni orquestador.
- Equipo: 2 personas, sin DevOps dedicado.
- Plazo: entrega universitaria con fecha fija.
- Tiempo de aprendizaje disponible: máximo 1 semana para cualquier
  tecnología o patrón nuevo.
- No se puede reescribir el sistema completo: los módulos de adopciones
  y mascotas ya tienen código verificado y en producción local.

---

## 5. Criterios de comparación

Los siguientes criterios se aplican igual a todas las alternativas:

1. **Organización de módulos:** cómo se agrupan las responsabilidades.
2. **Dependencias:** qué puede depender de qué y cómo se controla.
3. **Acoplamiento:** qué tan fácil es que un cambio en un lugar rompa
   otro.
4. **Cohesión:** qué tan relacionadas están las piezas dentro de cada
   unidad.
5. **Facilidad de cambio:** costo de modificar o extender el sistema.
6. **Complejidad operativa:** qué requiere desplegar y mantener.
7. **Costo de implementación:** esfuerzo para llegar al estado objetivo
   desde el código actual.
8. **Riesgos:** qué puede salir mal y con qué probabilidad.
9. **Reversibilidad:** qué tan difícil es deshacer la decisión.
10. **Compatibilidad con restricciones:** si la alternativa respeta las
    restricciones activas.

---

## 6. Alternativas comparadas

### Alternativa A — Arquitectura en capas (status quo)

Mantener la estructura actual: un único paquete plano
`com.patitasurbanas.api` con controladores, servicios y repositorios
de todos los dominios mezclados sin fronteras explícitas.

| Criterio | Evaluación para este sistema |
|---|---|
| Organización de módulos | Un único paquete. No hay separación visible entre adopciones, mascotas, veterinarias o cualquier otro dominio. |
| Dependencias | No controladas: cualquier clase puede importar cualquier otra. El compilador no impone restricciones entre dominios. |
| Acoplamiento | Alto entre dominios. Un cambio en `SolicitudAdopcion` puede requerir revisar código de mascotas o veterinarias sin señal estructural que lo indique. |
| Cohesión | Baja por dominio: las clases de un mismo contexto están mezcladas con las de otros. |
| Facilidad de cambio | Decrece a medida que el sistema crece. Sin fronteras, cada cambio requiere leer el sistema completo para estimar el impacto. |
| Complejidad operativa | Mínima: un proceso, un contenedor, Docker Compose sin cambios. |
| Costo de implementación | Cero: es el estado actual. No requiere ningún esfuerzo de reorganización. |
| Riesgos | El sistema evoluciona hacia un "big ball of mud" sin disciplina de equipo sostenida. El riesgo aumenta con cada módulo nuevo que se agregue. |
| Reversibilidad | Total: no hay nada que revertir. |
| Compatibilidad con restricciones | Compatible con todas las restricciones activas. No resuelve DA-01, DA-02 ni DA-04. |

**Evidencia del problema en el sistema actual:**
`app/src/main/java/com/patitasurbanas/api/` contiene controladores,
servicios, repositorios y modelos de todos los dominios en un mismo
nivel de paquete, sin subcarpetas por dominio.

---

### Alternativa B — Monolito modular

Reorganizar el monolito en módulos de negocio con fronteras explícitas
dentro del mismo proceso desplegable. Cada módulo tiene su propio
paquete raíz, sus interfaces públicas declaradas y sus dependencias
internas protegidas. La infraestructura no cambia.

| Criterio | Evaluación para este sistema |
|---|---|
| Organización de módulos | Un paquete por dominio: `adopciones/`, `mascotas/`, `veterinarias/`, `shared/`, `config/`. Las fronteras son visibles en la estructura de directorios. |
| Dependencias | Controladas por convención: un módulo solo accede a otro a través de sus interfaces públicas (servicios). Los repositorios y modelos internos no se exponen. Reforzable con ArchUnit si se decide. |
| Acoplamiento | Bajo entre módulos. Los detalles internos quedan encapsulados dentro del paquete de cada dominio. |
| Cohesión | Alta por módulo: todo lo relacionado con adopciones vive en `adopciones/`. |
| Facilidad de cambio | Alta: cambiar la lógica de adopciones no requiere tocar mascotas ni veterinarias si las fronteras se respetan. |
| Complejidad operativa | Igual que el status quo: un proceso, un contenedor, Docker Compose sin cambios. |
| Costo de implementación | Bajo: es una reorganización de paquetes y clases Java. No requiere nueva infraestructura ni nuevas dependencias. El módulo de adopciones ya está naturalmente cohesionado (PR #22, PR #41). |
| Riesgos | Bajo. El riesgo principal es que las fronteras se rompan por convención sin refuerzo estructural. Mitigable con revisión de PR. |
| Reversibilidad | Alta: si no funciona, revertir implica mover archivos de vuelta. No hay infraestructura nueva que deshacer. |
| Compatibilidad con restricciones | Totalmente compatible. Resuelve DA-01, DA-02 (parcialmente) y DA-04 sin violar DA-03 ni el plazo. |

**Evidencia que favorece esta alternativa:**
Los PRs #22 y #41 operan exclusivamente sobre clases del dominio de
adopciones (`AdopcionController`, `AdopcionService`,
`SolicitudAdopcionRepository`, `EtapaAdopcionRepository`), lo que
confirma que el dominio ya está naturalmente separado en la práctica.
La reorganización formaliza lo que el código ya sugiere.

---

### Alternativa C — Arquitectura hexagonal (ports & adapters)

Separar el núcleo de dominio de los adaptadores (REST, JPA,
notificaciones). El dominio no depende de Spring ni de PostgreSQL.
Los adaptadores implementan puertos (interfaces) definidos por el
dominio.

| Criterio | Evaluación para este sistema |
|---|---|
| Organización de módulos | Tres capas por dominio: dominio puro, aplicación (casos de uso), infraestructura (adaptadores). Más capas que el monolito modular. |
| Dependencias | El dominio no conoce Spring ni JPA. Los adaptadores dependen del dominio, nunca al revés. La regla de dependencia es estructural y verificable. |
| Acoplamiento | Muy bajo. El dominio es Java puro sin anotaciones de framework. |
| Cohesión | Muy alta dentro del dominio. |
| Facilidad de cambio | Muy alta para el dominio. Alta para los adaptadores. Cambiar de JPA a JDBC, por ejemplo, no afecta el dominio. |
| Complejidad operativa | Igual que A y B: un proceso, un contenedor. |
| Costo de implementación | **Alto.** Requiere definir puertos entrantes y salientes, adaptadores, y reorganizar toda la estructura del proyecto. Las entidades actuales (`SolicitudAdopcion`, `EtapaAdopcion`) tienen anotaciones JPA (`@Entity`, `@Id`) que el dominio puro no debería conocer. Separarlos implica duplicar o reescribir los modelos. |
| Riesgos | Medio-alto. La curva de aprendizaje del patrón y el tiempo de refactorización pueden comprometer la entrega en el plazo disponible. |
| Reversibilidad | Baja: una vez reorganizado en puertos y adaptadores, revertir requiere deshacer una cantidad significativa de trabajo estructural. |
| Compatibilidad con restricciones | Viola DA-03 parcialmente: el costo de implementación es desproporcionado para 2 personas con plazo fijo. Resolvería DA-01 y DA-02 completamente. |

---

### Alternativa D — Microservicios (descartada sin análisis detallado)

| Criterio | Evaluación |
|---|---|
| Complejidad operativa | Requiere orquestación (Kubernetes o equivalente), descubrimiento de servicios y comunicación entre procesos. |
| Costo de implementación | Prohibitivo para el contexto: implica rediseñar el sistema completo, configurar infraestructura distribuida y gestionar consistencia eventual. |
| Compatibilidad con restricciones | Viola directamente DA-03 (equipo de 2, sin DevOps, sin orquestador). |

**Razón de descarte:** constituye sobreingeniería evidente para el
problema identificado. El problema es de mantenibilidad en un monolito
pequeño, no de escala o despliegue independiente de servicios. No se
analiza en detalle porque ningún driver activo lo justifica.

---

## 7. Tabla comparativa consolidada

| Criterio | A: Capas (status quo) | B: Monolito modular | C: Hexagonal |
|---|---|---|---|
| Fronteras de módulo explícitas | ✗ No | ✓ Sí (por paquete) | ✓ Sí (por puerto) |
| Dependencias controladas | ✗ No | ✓ Por convención | ✓ Estructuralmente |
| Acoplamiento entre dominios | Alto | Bajo | Muy bajo |
| Cohesión por dominio | Baja | Alta | Muy alta |
| Facilidad de cambio | Decrece con el tiempo | Alta | Muy alta |
| Complejidad operativa | Mínima | Mínima | Mínima |
| Costo de implementación | Ninguno | Bajo | Alto |
| Riesgo principal | Big ball of mud | Fronteras rotas por convención | Plazo comprometido |
| Reversibilidad | Total | Alta | Baja |
| Resuelve DA-01 (mantenibilidad) | ✗ No | ✓ Sí | ✓ Sí |
| Resuelve DA-02 (testeabilidad) | ✗ No | Parcial | ✓ Sí |
| Respeta DA-03 (costo operativo) | ✓ Sí | ✓ Sí | ✗ Parcialmente |
| Proporcional al equipo (2p) | ✓ Sí | ✓ Sí | ✗ Costosa |

---

## 8. Análisis de trade-offs

### B vs A
La alternativa B entrega mantenibilidad y extensibilidad sin costo
operativo adicional. El único sacrificio frente al status quo es el
esfuerzo de reorganización de paquetes, que es bajo y reversible.
El riesgo de fronteras rotas por convención se mitiga con revisión de
PR, que el equipo ya practica (evidencia: PRs #16, #17, #18, #22,
#26, #27, #41).

### C vs B
La alternativa C entrega independencia tecnológica total que B no
ofrece: el dominio puro no conoce Spring ni JPA. Sin embargo, ese
beneficio adicional tiene un costo de implementación desproporcionado
para el plazo disponible. B entrega aproximadamente el 70 % del
beneficio de C con el 20 % del costo. C es la evolución natural de B
si el sistema crece más allá del alcance universitario.

### D vs todas
Los microservicios no resuelven ningún driver activo y violan la
restricción operativa más crítica. Se descarta sin análisis adicional.

---

## 9. Supuestos pendientes de verificar

| Supuesto | Cómo verificarlo | Urgencia |
|---|---|---|
| La reorganización en módulos no rompe los tests existentes | Ejecutar suite de tests tras reorganización | Alta |
| El módulo de adopciones es el único con código verificado real | Revisar si existen más clases fuera del módulo de adopciones | Alta |
| Las fronteras por convención son suficientes sin ArchUnit | Acordar en mini-comité si se requiere refuerzo estructural | Media |

---

## 10. Referencias

| Artefacto | Ubicación | Relevancia |
|---|---|---|
| Análisis de causa S7 | `dossier/13-analisis-causa-s7.md` | Identifica la tensión estructural que motiva la comparación |
| C4 Nivel 2 (as-is) | `dossier/06-c4-contenedores.md` | Confirma monolito como único contenedor real |
| C4 Nivel 3 (as-is) | `dossier/07-c4-componentes.md` | Confirma componentes de adopciones con JPA |
| PR #22 | GitHub | Coherencia natural del módulo de adopciones |
| PR #41 | GitHub | Instrumentación exclusiva sobre adopciones |

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Fecha: 2026-09-13*
*Semana 7 · Módulo 4 · Arquitectura de Software*
