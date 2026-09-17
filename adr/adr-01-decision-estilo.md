# ADR-01 — Adopción de Monolito Modular como Estilo Arquitectónico
## Patitas Urbanas · Módulo 4

---

## Estado

**Propuesta** — pendiente de veredicto del mini-comité (Semana 8).

Veredicto del comité: _pendiente_ (confirmada / ajustada /
reconsiderada)

---

## Contexto

El sistema actual de Patitas Urbanas es un monolito en capas
desplegado como contenedor único (Spring Boot 3.3.4 + PostgreSQL 16).
El paquete `com.patitasurbanas.api` contiene clases de todos los
dominios sin fronteras explícitas. El análisis de Semana 6 refutó
las hipótesis H1 y H2 de rendimiento. No existe evidencia de un
cuello de botella confirmado.

La tensión identificada es de mantenibilidad: sin fronteras de módulo,
cualquier clase puede depender de cualquier otra, y agregar nuevos
dominios incrementa el acoplamiento sin control estructural.

**Restricciones activas:**
- Equipo de 2 personas, sin DevOps dedicado.
- Infraestructura: Docker Compose local, sin orquestador.
- Stack comprometido: Java 21 + Spring Boot + PostgreSQL 16.
- Plazo universitario fijo.

**Evidencia de referencia:**
- `dossier/06-c4-contenedores.md` — confirma monolito como único
  contenedor real.
- `dossier/07-c4-componentes.md` — confirma componentes de adopciones
  con JPA.
- PR #22 y PR #41 — confirman cohesión natural del módulo de
  adopciones.
- `experimentos/resultado-corrida-1.txt` a `resultado-corrida-4.txt`
  — corridas K6 contra endpoint simulado; sin evidencia de problema
  de rendimiento real.

---

## Problema

> ¿Cómo organizar el sistema para que sea mantenible y extensible
> sin introducir complejidad operativa desproporcionada para un equipo
> de 2 personas con plazo fijo?

---

## Alternativas consideradas

| Alternativa | Descripción resumida |
|---|---|
| A — Capas (status quo) | Mantener el paquete plano sin fronteras. No resuelve el problema de mantenibilidad. |
| B — Monolito modular | Reorganizar en paquetes por dominio con fronteras explícitas. Misma infraestructura. |
| C — Hexagonal | Separar dominio de adaptadores. Resuelve más drivers pero costo desproporcionado. |
| D — Microservicios | Requiere orquestación. Viola restricción de costo operativo. Descartada. |

Análisis completo en `dossier/14-comparacion-estilos-s7.md`.

---

## Costo de cada alternativa

| Alternativa | Costo de implementación | Costo operativo | Reversibilidad |
|---|---|---|---|
| A — Capas | Ninguno | Mínimo | Total |
| B — Monolito modular | Bajo — reorganización de paquetes, 1 sesión de trabajo | Mínimo — sin cambios de infraestructura | Alta — mover archivos de vuelta |
| C — Hexagonal | Alto — rediseño de toda la estructura, modelos duplicados | Mínimo | Baja |
| D — Microservicios | Muy alto — nueva infraestructura, orquestación | Alto | Muy baja |

---

## Razones para descartar alternativas

**A — Capas (status quo):** no resuelve DA-01 ni DA-04. El acoplamiento
crecerá sin control a medida que se agreguen módulos nuevos.

**C — Hexagonal:** el beneficio adicional frente al monolito modular
(independencia tecnológica total) no compensa el costo de
implementación en el plazo disponible. Las entidades actuales tienen
anotaciones JPA que el dominio puro no debería conocer; separarlas
implica reescribir los modelos existentes.

**D — Microservicios:** ningún driver activo justifica distribución
de servicios. Viola directamente DA-03 (costo operativo proporcional
al equipo).

---

## Decisión

Se adopta provisionalmente la **Alternativa B — Monolito modular**.

La reorganización consiste en:

1. Crear subcarpetas por dominio dentro de
   `com.patitasurbanas.api/`: `adopciones/`, `mascotas/`,
   `veterinarias/`, `shared/`, `config/`.
2. Mover las clases existentes al módulo correspondiente sin
   cambiar su lógica.
3. Declarar las reglas de dependencia entre módulos (ver
   `adr/adr-02-modularidad.md`).
4. Verificar que los tests existentes pasan tras la reorganización.

El sistema debería comportarse exactamente igual antes y después de la
reorganización en tiempo de ejecución, dado que el cambio es
exclusivamente estructural. Esta es una consecuencia esperada, no un
hecho verificado: la reorganización aún no ha sido implementada y
debe verificarse ejecutando la suite de tests tras mover los archivos.

---

## Consecuencias

### Positivas

- Las fronteras de módulo son visibles en la estructura de paquetes
  y auditables en cada PR.
- Cambiar la lógica de adopciones no requiere tocar mascotas ni
  veterinarias si las reglas de dependencia se respetan.
- Agregar nuevos módulos sigue el mismo patrón sin reescribir
  lo existente.
- La terminología del C4 queda alineada con la decisión:
  el sistema es un monolito modular, no un microservicio.

### Negativas

- El dominio sigue conociendo anotaciones JPA. No se logra
  independencia tecnológica total.
- Las fronteras se mantienen por convención y revisión de PR,
  no por refuerzo estructural automático.
- El módulo `shared/` puede crecer sin control si no se define
  un criterio claro de admisión.

---

## Implicaciones de seguridad

`dossier/03-atributos-calidad.md` clasifica la Seguridad como
atributo de calidad de prioridad **Alta**, dado que el sistema
gestiona datos personales de usuarios y fundaciones bajo el
cumplimiento de la Ley 1581 de 2012 (Colombia).

El monolito modular no cambia el perímetro de seguridad actual:
sigue existiendo un único proceso desplegado, una única base de
datos (PostgreSQL) y un único punto de autenticación. Adoptar
esta alternativa no introduce comunicación entre procesos ni
nuevos canales de red que deban asegurarse, a diferencia de la
Alternativa D (microservicios), que sí habría exigido definir
autenticación y cifrado entre servicios.

Sin embargo, las fronteras de módulo declaradas aquí sí tienen un
efecto positivo indirecto en seguridad: al restringir qué clases
pueden acceder a los repositorios y modelos de cada dominio (ver
`adr/adr-02-modularidad.md`), se reduce la superficie por la que
un error de programación podría exponer datos personales de un
módulo (por ejemplo, `entidades`) a través de la lógica de otro
módulo no relacionado.

**Riesgo residual:** dado que las fronteras se mantienen por
convención y no por refuerzo estructural automático (ADR-02,
Alternativa A), un descuido en la revisión de PR podría permitir
que un módulo acceda directamente a datos personales de otro sin
pasar por su interfaz de servicio. Este riesgo queda documentado
como condición de revisión en ADR-02.

**Condición de revisión:** si en una futura iteración se separan
módulos en servicios independientes, este ADR debe revisarse para
incorporar autenticación entre servicios y cifrado en tránsito,
que hoy no son necesarios por tratarse de un único proceso.

---

## Reversibilidad

Alta. Revertir implica mover los archivos al paquete plano original.
No hay infraestructura nueva que deshacer ni dependencias nuevas en
`pom.xml`. El comportamiento en tiempo de ejecución no cambia.

---

## Supuestos y condición de revisión

| Supuesto | Cómo se verifica |
|---|---|
| La reorganización no rompe los tests existentes | Ejecutar suite completa tras mover los archivos |
| Las fronteras por convención son suficientes para el alcance actual | Confirmar en mini-comité de Semana 8 |
| El módulo de adopciones es suficientemente cohesionado para reorganizarse sin cambios de lógica | Verificado por PR #22 y PR #41 |

**Condición de revisión:** si el mini-comité de Semana 8 determina
que las fronteras por convención son insuficientes, se evaluará
incorporar ArchUnit para refuerzo estructural automático.

---

## Referencias

- `dossier/13-analisis-causa-s7.md`
- `dossier/14-comparacion-estilos-s7.md`
- `dossier/15-diseno-modular-s7.md`
- `dossier/16-borrador-decision-estilo-s7.md`
- `adr/adr-02-modularidad.md`
- `docs/08-decision-estilo-arquitectonico.md`

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Fecha: 2026-09-13*
*Semana 7 · Módulo 4 · Arquitectura de Software*
