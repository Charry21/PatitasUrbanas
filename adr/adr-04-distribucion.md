# ADR-04 — Distribución del despliegue: mantener un único despliegue del monolito modular
## Patitas Urbanas · Módulo 6

---

## Estado

**Propuesta, aceptada por el equipo** (Semana 12, 2026-10-24; M6-5 de `docs/registro-ia-modulo6.md`) — pendiente del veredicto del mini-comité.

Veredicto del mini-comité: _pendiente — se registra en §Veredicto del comité después de celebrarse_ (confirmada / ajustada / reconsiderada).

---

## Contexto

ADR-01 adoptó el monolito modular y el spike 1 lo materializó sin coste funcional (`experimentos/09-cierre-spike-s10.md` §6.2). ADR-03 decidió la comunicación síncrona en proceso entre módulos. Falta decidir **cómo se despliega**: una instancia, varias réplicas o servicios separados por contexto.

**Evidencia disponible:**

| Fuente | Qué aporta |
|---|---|
| S11, crecimiento (`experimentos/10-crecimiento-s11/RESULTADOS.md`) | Hasta 200 usuarios: 0 % de fallos; p95 de escritura 51,03 ms (umbral 800 ms); API al 25,4 % y PostgreSQL al 11,9 % de un núcleo. Primera degradación observable: la cola de latencia de las escrituras (F-05) |
| S12, inyección de fallos (`experimentos/12-inyeccion-fallos-s12/RESULTADOS.md`) | Con la BD caída: escrituras 500 en ≤ 30 s, `/buscar` sigue respondiendo, health 503 tras 30 s; recuperación automática; 0 filas a medias |
| Matriz de fallos (`docs/resiliencia/matriz-fallos.md`) | F-12 (caída del proceso de la API) es el fallo de mayor impacto, y es **hipotético** |
| Matriz de resiliencia (`docs/resiliencia/matriz-resiliencia.md`) | 4 tácticas existentes probadas; R-10 (reinicio automático) propuesta |
| Comparación (`docs/distribucion/comparacion-distribucion.md`) | D1, D2 y D3 en 13 dimensiones, con la clase de cada dato |
| Experimento 13 (`experimentos/13-semilla-memoria-s12/RESULTADOS.md`) | Con 79 810 filas iniciales el p95 no aumenta; la API usa 0,22 GiB en reposo y hasta 0,31 GiB con 200 usuarios |

**Drivers:**
- DA-03: costo operativo proporcional a un equipo de 2 personas;
- QA-02: integridad de TRX-02;
- escenario 1: p95 < 800 ms;
- DA-01: mantenibilidad.

---

## Problema

> ¿Cómo se despliega Patitas Urbanas para cumplir los escenarios de calidad con la carga medida, sin un costo operativo desproporcionado para el equipo?

---

## Alternativas consideradas

| Id | Alternativa |
|---|---|
| D1 | Monolito modular, **una instancia** de la API + PostgreSQL (estado actual) |
| D2 | Monolito modular **replicado**: 2 instancias de la API tras un balanceador + PostgreSQL compartido |
| D3 | **Distribución por contexto**: servicios de Adopciones y de Mascotas, cada uno con su base de datos |

## Costo de cada alternativa

Resumen de `docs/distribucion/comparacion-distribucion.md` §3. La clase de cada dato está en ese documento.

| | D1 | D2 | D3 |
|---|---|---|---|
| Contenedores | 2 | 4 | 4 o más |
| Esfuerzo adicional (6 meses, estimado) | 0 h | ~15–25 h | ~80–120 h |
| Saltos de red en una escritura | 1 | 2 | 3 cuando exista R1 |
| Atomicidad de TRX-02 + R1 | Local | Local | Se pierde para R1 |
| Infraestructura (referencia, USD/mes) | ≈ 12 (fuente secundaria) | ≈ 24 + balanceador | ≈ 24 + 2 BD |

---

## Decisión

Se adopta **D1: un único despliegue del monolito modular** durante el horizonte de 6 meses.

**Razón:**
- Con la carga medida (200 usuarios), D1 cumple el escenario 1 con un margen amplio: p95 de 51,03 ms frente a 800 ms (S11).
- Conserva la atomicidad local de TRX-02 (S12 HF3; QA-02).
- No añade componentes que el equipo tenga que operar (DA-03).
- Ninguna medición muestra un límite de capacidad que D2 o D3 resuelvan.

## Razones para no adoptar las otras alternativas ahora

- **D2:** su beneficio principal es tolerar F-12, que es **hipotético**, y no ayuda ante la caída de la BD (F-01). Se aplaza con una condición de revisión.
- **D3:** rompe la transacción local de la que depende R1, añade saltos de red, es la menos reversible y su costo no se justifica con ninguna medición. Se descarta en este horizonte.

---

## Consecuencias

### Positivas
- Costo operativo mínimo y un solo artefacto que desplegar.
- TRX-02 y la futura validación R1 se mantienen en una sola transacción.
- La evidencia de S11 y S12 sigue siendo válida para lo que se despliega.

### Negativas
- **Punto único de fallo:** si el proceso de la API cae, el sistema queda indisponible (F-12). Mientras R-10 no se adopte, no hay reinicio automático.
- La escala vertical es el único camino de capacidad.
- La caída de la BD afecta a todas las escrituras (F-01, observado).

---

## Implicaciones de seguridad

D1 no abre canales de red nuevos (perímetro de ADR-01). D2 añadiría un balanceador expuesto; D3, llamadas HTTP entre servicios que exigirían autenticación y cifrado (condición del mini-comité de Semana 8).

---

## Reversibilidad

**Alta hacia D2:** la API no guarda estado (supuesto S5 de A4, verificado en el código), así que añadir réplicas no requiere cambiar el código. **Baja hacia D3:** requiere separar el código y migrar los datos.

---

## Supuestos y condición de revisión

| Supuesto | Cómo se verifica | Condición de revisión |
|---|---|---|
| La carga real no supera la probada en S11 (200 usuarios) | Comparar con el uso real cuando haya despliegue | Si la carga esperada supera 200 usuarios, se preregistra una serie con más carga antes de decidir |
| F-12 es tolerable con una sola instancia | Probar F-12 (matar el proceso y medir el tiempo de vuelta) | Si se exige un objetivo de disponibilidad que una instancia no cumple, se ensaya D2 |
| Los 30 s de espera ante la caída de la BD son aceptables | Decisión del equipo sobre R-02 / R-07 | Si no lo son, se adopta R-07 y se repite S12 |
| La escritura no tiene un cuello de botella cercano | Repetir la serie B de S11 aislando el efecto de las filas acumuladas (I-1) | Si p95 o p99 se acercan al umbral, se revisa antes que la distribución |
| El equipo sigue siendo de 2 personas (DA-03) | — | Si el equipo crece, se reevalúa D3 |

---

## Veredicto del comité

_Se completa después del mini-comité. No se rellena antes._

- Fecha:
- Rol(es) del comité:
- Preguntas realizadas y respuestas del equipo:
- Veredicto (confirmada / ajustada / reconsiderada) y condición:

---

## Referencias

- `adr/adr-01-decision-estilo.md`, `adr/adr-02-modularidad.md`, `adr/adr-03-limites-y-comunicacion-modulos.md`
- `dossier/06-c4-contenedores.md`, `dossier/07-c4-componentes.md`
- `experimentos/10-crecimiento-s11/RESULTADOS.md`, `experimentos/12-inyeccion-fallos-s12/RESULTADOS.md`
- `docs/resiliencia/matriz-fallos.md`, `docs/resiliencia/matriz-resiliencia.md`
- `docs/distribucion/comparacion-distribucion.md`
- `experimentos/13-semilla-memoria-s12/RESULTADOS.md`

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 12 · Módulo 6 · Arquitectura de Software*
