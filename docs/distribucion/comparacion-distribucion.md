# Comparación de alternativas de distribución y costos — Módulo 6 (A4)

Insumos:
- ADR-01, ADR-02 y ADR-03;
- C4 (`dossier/06`, `dossier/07`);
- matrices de fallos y de resiliencia (`docs/resiliencia/`);
- experimentos S11 (crecimiento) y S12 (inyección de fallos).

**Clase de cada afirmación:**
- **M** = medida: sale de un experimento, que se cita.
- **E** = estimada: sale de un supuesto declarado en §2.
- **D** = documentada: sale de la configuración o del código.
- **P** = pendiente: no hay dato; no se rellena.

**Horizonte:** 6 meses (lo que queda del semestre más la entrega final).

**Unidades:**
- CPU en % de un núcleo, como en S11;
- memoria en GiB;
- componentes y saltos de red en número;
- esfuerzo en horas-persona;
- dinero en COP/mes, solo cuando haya precio cotizado.

---

## 1. Alternativas

| Id | Alternativa | Descripción |
|---|---|---|
| D1 | **Monolito modular, una instancia** (estado actual) | 1 contenedor de la API (todos los módulos) + 1 PostgreSQL (`docker-compose.yml`) |
| D2 | **Monolito modular replicado** | 2 contenedores idénticos de la API detrás de un balanceador + 1 PostgreSQL compartido |
| D3 | **Distribución por contexto** | Adopciones y Mascotas como servicios separados, cada uno con su base de datos; la relación R1 (disponibilidad de la mascota) pasa a ser una llamada HTTP |

## 2. Supuestos declarados

| # | Supuesto | Usado en |
|---|---|---|
| S1 | La carga de referencia es la de S11: 200 usuarios concurrentes, ~194 escrituras/s | Todas las filas de CPU |
| S2 | En D2 la carga se reparte por igual entre las 2 instancias, y cada instancia tiene el mismo consumo base que en D1 | CPU de D2 |
| S3 | En D3 la carga de escritura de S11 la absorbe solo el servicio de Adopciones; Mascotas añade su propio proceso base | CPU de D3 |
| S4 | Esfuerzo de operación de D1 = 0 horas adicionales (línea de comparación). Las cifras de D2 y D3 son **estimaciones iniciales** de tareas listadas en §4, pendientes de validar por el equipo | Esfuerzo |
| S5 | La API no guarda estado de sesión: cada petición es independiente (verificado en el código: no hay sesiones ni cachés locales) | D2 |

## 3. Comparación (mismas dimensiones para las tres)

| Dimensión | Unidad | D1 | D2 | D3 |
|---|---|---|---|---|
| Contenedores a operar | n.º | 2 **(D)** | 4: 2 API + balanceador + BD **(E)** | 4: 2 servicios + 2 BD, más infraestructura de llamadas entre servicios **(E)** |
| CPU de la API a 200 usuarios escribiendo | % de un núcleo | 25,4 **(M, S11)** | ~2 × 12,7 + consumo base de la segunda JVM; el consumo base **(P)** | Adopciones ~25,4 + Mascotas (consumo base **P**) **(E, S3)** |
| CPU de PostgreSQL a 200 usuarios escribiendo | % de un núcleo | 11,9 **(M, S11)** | ~11,9 (misma BD) **(E)** | ~11,9 en la BD de Adopciones + la BD de Mascotas **(P)** |
| Memoria de la API | GiB | **P** (no medida) | **P** | **P** |
| Saltos de red en una escritura (TRX-02) | n.º | 1: API → BD **(D)** | 2: balanceador → API → BD **(D)** | 1 hoy; cuando exista R1: Adopciones → Mascotas (HTTP) → Adopciones → BD = 3 **(D, `docs/integracion/sincrono-vs-asincrono.md`)** |
| Atomicidad de TRX-02 y de la validación R1 | — | Una transacción local **(D, M: S12 HF3)** | Igual que D1 **(D)** | La validación R1 queda fuera de la transacción: requiere compensación o aceptar una copia desactualizada **(D)** |
| Caída de una instancia de la API (F-12) | — | Indisponibilidad total **(D)** | Sigue la otra instancia **(E; no probado)** | Cae solo el contexto afectado **(E; no probado)** |
| Caída de la BD (F-01) | — | Escrituras 500 en ≤ 30 s; `/buscar` sigue **(M, S12)** | Igual que D1 en las 2 instancias **(E)** | Solo falla el contexto cuya BD cae **(E)** |
| Margen frente al escenario 1 (p95 < 800 ms) | ms | p95 de escritura = 51,03 a 200 usuarios **(M, S11)** | **P** (no medido) | **P** (no medido) |
| Esfuerzo de operación adicional (6 meses) | horas-persona | 0 **(E, S4)** | Configurar y probar el balanceador, el health check y el despliegue de 2 réplicas: ~15–25 **(E, S4)** | Separar el código y la BD, el contrato HTTP de R1, el manejo de fallos remotos, el despliegue y el monitoreo de 2 servicios: ~80–120 **(E, S4)** |
| Costo de infraestructura | COP/mes | **P** (precio sin cotizar; proporcional a 2 contenedores) | **P** (proporcional a 4 contenedores) | **P** (proporcional a 4 contenedores) |
| Compatibilidad con DA-03 (equipo de 2, sin DevOps) | — | Sí **(D)** | Parcial: añade un componente nuevo **(E)** | No: duplica la operación y añade fallos remotos **(E)** |
| Reversibilidad | — | — | Alta: volver a 1 réplica **(E)** | Baja: hay que reunir el código y migrar los datos **(E)** |

## 4. Consecuencias por alternativa

- **D1.** Mantiene la atomicidad y el costo mínimo. Su riesgo principal es F-12: un solo proceso sin reinicio automático (la táctica R-10 lo mitiga, pero es una propuesta). Con la carga medida tiene margen: p95 de 51,03 ms frente al umbral de 800 ms.
- **D2.** Ataca F-12 sin tocar el código, porque la API no guarda estado (S5). No ayuda ante F-01: las dos réplicas comparten la BD. No hay medición que muestre que la carga actual la necesite.
- **D3.** Separa los fallos por contexto, pero rompe la transacción local de la que depende la regla R1 y añade saltos de red. Ninguna medición muestra un cuello de botella que justifique el costo, y es la menos reversible.

## 5. Lo que falta para cerrar la comparación

| Pendiente | Por qué importa | Cómo obtenerlo |
|---|---|---|
| Memoria de la API | Dimensiona los contenedores de D2 y D3 | Registrar el RSS de la JVM en una serie como la de S11 |
| Consumo base de una JVM sin carga | CPU de D2 y D3 | Medirlo en reposo |
| p95 de D2 y D3 | Comparar el margen | Solo si el equipo decide ensayarlas |
| Precios unitarios (COP por contenedor/mes) | Convertir las unidades a dinero | Cotizar en el proveedor elegido |
| Validar las horas de S4 | Son estimaciones iniciales | Revisión del equipo |

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 12 · Módulo 6 · Arquitectura de Software*
