# 13 — Análisis de Causa · Semana 7
## Patitas Urbanas · Módulo 4

---

## 1. Propósito de este documento

Registrar el análisis técnico que profundiza las observaciones de 
Semana 6, distinguiendo explícitamente entre lo observado, lo inferido 
y lo que todavía no está demostrado. Este archivo es insumo para la 
comparación de estilos (`14-comparacion-estilos-s7.md`) y no contiene 
decisiones arquitectónicas.

---

## 2. Escenario analizado

**Endpoint bajo análisis:** `POST /api/adopciones`
**Componente:** `AdopcionController → AdopcionService →
SolicitudAdopcionRepository + EtapaAdopcionRepository`
**Stack:** Java 21, Spring Boot 3.3.4, Spring Data JPA, PostgreSQL 16,
Docker Compose
**Versión del código:** commit `37a45d8` (PR #41, mergeado 2026-09-13)

---

## 3. Referencia a hipótesis de Semana 6

| Hipótesis | Enunciado | Resultado |
|---|---|---|
| H1 | El tiempo de ejecución SQL supera el 60 % del tiempo total de respuesta bajo 100 req/s | **Refutada** — el umbral no se alcanzó bajo las condiciones medidas |
| H2 | El tiempo externo al método del controlador supera el 40 % del tiempo total | **Refutada** — el criterio predefinido no se cumplió, aunque el resultado estuvo cercano al umbral con limitaciones declaradas |

Ninguna hipótesis de S6 identificó una causa definitiva. La 
instrumentación de H2 (PR #41) midió el tiempo interno del controlador 
usando `System.nanoTime()`, emitiendo `MEDICION_S6_CONTROLADOR_MS` por 
log.

---

## 4. Instrumentos utilizados

### 4.1 K6 — medición externa (carga HTTP)

**Herramienta:** Grafana K6
**Script:** `experimentos/escenario-rendimiento.js`
**Propósito:** medir latencia HTTP end-to-end desde el cliente

**Resultados consolidados de las corridas disponibles:**

| Corrida | Escenario | Iteraciones | p(95) ms | p(90) ms | avg ms | max ms | Dropped |
|---|---|---|---|---|---|---|---|
| línea-base | Ramp-up/down, 20 VUs, 50 s | 809 | 4.33 | 3.82 | 4.41 | 820.28 | 0 |
| corrida-1 | Constante 100 iter/s, 40 s | 4.000 | 2.85 | 2.47 | 1.79 | 12.23 | 0 |
| corrida-2 | Constante 100 iter/s, 40 s | 4.000 | 1.82 | 1.72 | 1.39 | 12.15 | 0 |
| corrida-3 | Constante 100 iter/s, 40 s | 4.001 | 1.80 | 1.71 | 1.35 | 11.23 | 0 |
| corrida-4 | Constante 100 iter/s, 40 s | 3.999 | 6.50 | 3.62 | 3.46 | 216.61 | 2 |

**Tasa de error en todas las corridas:** 0.00 %

### 4.2 Instrumentación interna — `System.nanoTime()`

**Herramienta:** logging con SLF4J en `AdopcionController`
**PR:** #41 — mergeado 2026-09-13
**Propósito:** medir el tiempo consumido dentro del controlador,
excluyendo red y serialización HTTP

```java
long inicioNs = System.nanoTime();
SolicitudAdopcion solicitud =
    adopcionService.crearSolicitudConEtapaInicial(
        estado, nombreEtapa, false);
// ... construcción de respuesta ...
long finNs = System.nanoTime();
double tiempoControladorMs = (finNs - inicioNs) / 1_000_000.0;
log.info("MEDICION_S6_CONTROLADOR_MS={}", tiempoControladorMs);
```

**Estado:** la instrumentación está mergeada en `main` pero los valores
de ejecución aún no están registrados en el repositorio como evidencia
versionada. Pendiente de ejecución y registro antes del cierre de
Semana 7.

---

## 5. Limitación metodológica crítica

Las corridas 1 a 3 y la línea base se ejecutaron contra
`MascotaController`, que devuelve una respuesta JSON estática sin
ejecutar ninguna consulta a la base de datos. Esto está documentado en
el propio código:

> *"Simulación de carga de respuesta para la medición de la línea base
> S4"*

Esta limitación fue identificada y registrada en los Issues #19 y #21
del repositorio.

**Consecuencia directa:** los valores p(95) de 1.80–2.85 ms de las
corridas 1–3 no representan el comportamiento del sistema con
transacciones JPA reales. No pueden usarse para afirmar que el sistema
tiene buen rendimiento bajo carga real, ni para afirmar que tiene
un problema de rendimiento. Son evidencia del comportamiento del
endpoint simulado únicamente.

---

## 6. Observaciones verificables

Las siguientes afirmaciones están respaldadas directamente por
artefactos del repositorio:

**OBS-01:** La corrida 4 muestra un p(95) de 6.50 ms, un max de
216.61 ms y 2 `dropped_iterations`, a diferencia de las corridas 1–3.
Esto sugiere que en esa ejecución ocurrió algo distinto: posiblemente
el endpoint real con JPA estuvo activo, o hubo presión de GC de la JVM
en el período de warm-up. No se puede determinar la causa sin evidencia
adicional.
*Fuente: `experimentos/resultado-corrida-4.txt`*

**OBS-02:** La línea base registra un max de 820.28 ms con ramp-up de
VUs concurrentes. Este pico aislado es consistente con el cold start de
Spring Boot y la inicialización del pool HikariCP. El p(95) de 4.33 ms
no refleja ese pico en el percentil estadístico.
*Fuente: `experimentos/resultado-linea-base.txt`*

**OBS-03:** El módulo de adopciones (`AdopcionController`,
`AdopcionService`, `SolicitudAdopcionRepository`,
`EtapaAdopcionRepository`) está implementado con JPA y operaciones
`@Transactional`. Cada solicitud de adopción implica al menos dos
escrituras en la base de datos (una en `solicitud_adopcion` y una en
`etapa_adopcion`).
*Fuente: `dossier/07-c4-componentes.md`, PR #22*

**OBS-04:** El tiempo interno del controlador (`MEDICION_S6_CONTROLADOR_MS`)
no tiene valores registrados como evidencia en el repositorio. La
instrumentación existe en el código pero no hay resultados versionados.
*Fuente: PR #41*

---

## 7. Inferencias (no verificadas)

Las siguientes afirmaciones son plausibles dado lo observado, pero no
están demostradas con evidencia suficiente:

**INF-01:** El max de 216.61 ms en la corrida 4 podría corresponder al
costo de la primera transacción JPA real, que incluye inicialización del
pool de conexiones y compilación de queries por Hibernate.
*Estado: supuesto — requiere ejecución con endpoint real para confirmar.*

**INF-02:** Bajo carga sostenida de 100 req/s con el endpoint real de
adopciones, el p(95) podría ser significativamente mayor que los 2–3 ms
observados con el endpoint simulado, debido al costo de las dos
escrituras `@Transactional`.
*Estado: hipótesis — requiere corrida K6 contra `POST /api/adopciones`
con JPA activo.*

---

## 8. Lo que no está demostrado

- No se puede afirmar que JPA sea el cuello de botella del sistema.
- No se puede afirmar que el sistema cumple el umbral de rendimiento
  (p95 < 800 ms) bajo carga real con transacciones a la base de datos.
- No se puede afirmar que la arquitectura en capas sea la causa de
  ningún problema de rendimiento observado.
- No existe un plan `EXPLAIN` ejecutado y registrado para ninguna
  consulta del sistema.

---

## 9. Qué falta para completar el análisis de causa

| Pendiente | Instrumento | Responsable | Estado |
|---|---|---|---|
| Ejecutar K6 contra `POST /api/adopciones` real con JPA activo | K6 | Equipo | Pendiente |
| Registrar valores de `MEDICION_S6_CONTROLADOR_MS` en evidencia versionada | Log + archivo en `experimentos/` | Equipo | Pendiente |
| Obtener plan `EXPLAIN` de las queries de adopción | `EXPLAIN ANALYZE` en PostgreSQL 16 | Equipo | Pendiente |

---

## 10. Relación con la decisión arquitectónica

Este análisis no identifica una causa de rendimiento confirmada.
Lo que sí identifica es una tensión estructural: el sistema tiene un
único paquete `com.patitasurbanas.api` sin fronteras de módulo
explícitas. Esa tensión no es de rendimiento sino de
**mantenibilidad y acoplamiento**, y es la que motiva la comparación
de estilos en `14-comparacion-estilos-s7.md`.

---

## 11. Trazabilidad de este documento

| Artefacto | Ubicación |
|---|---|
| Corridas K6 | `experimentos/resultado-corrida-1.txt` a `resultado-corrida-4.txt` |
| Línea base K6 | `experimentos/resultado-linea-base.txt` |
| Instrumentación interna | PR #41, `AdopcionController.java` |
| Limitación endpoint simulado | Issues #19 y #21 |
| Componentes JPA verificados | `dossier/07-c4-componentes.md`, PR #22 |

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Fecha: 2026-09-13*
*Semana 7 · Módulo 4 · Arquitectura de Software*
