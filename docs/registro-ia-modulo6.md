# Registro crítico de IA — Módulo 6 (semanas 11–14)

**Herramienta:** Claude Code (Anthropic). La IA redactó los borradores de A2–A6, diseñó y ejecutó la inyección de fallos de la Semana 12 y verificó cada referencia contra el repositorio. Una propuesta no forma parte del dossier hasta que el equipo decide.

| # | Propuesta de la IA | Dónde | Decisión del equipo | Razón |
|---|---|---|---|---|
| M6-1 | Preregistrar y ejecutar una inyección de fallos (BD caída y recuperada) para tener filas **observadas** en la matriz | `experimentos/12-inyeccion-fallos-s12/` | Aceptado (2026-10-24) | Convierte filas hipotéticas en observadas con un experimento preregistrado (PR #76 antes de ejecutar) |
| M6-2 | Matriz de fallos con 13 filas sobre componentes existentes; excluir los componentes que no existen en el código | `docs/resiliencia/matriz-fallos.md` | Aceptado (2026-10-24) | Cada fila tiene componente del C4, estímulo, consecuencia y referencia; los componentes inexistentes no se modelan |
| M6-3 | Tácticas propuestas R-07 (tiempos de espera explícitos), R-08 (medir Hikari), R-09 (log SQL a INFO), R-10 (reinicio automático), R-11 (`ddl-auto` fuera de desarrollo), R-12 (construir la imagen sin proxy TLS) | `docs/resiliencia/matriz-resiliencia.md` | Aceptado como plan (2026-10-24): se implementan en este orden R-10, R-09, R-08, R-11 y R-12; R-07 se aplaza hasta probar F-10 con carga. Ninguna cuenta como probada hasta que se implemente y se pruebe | Prioriza las de menor costo y mayor impacto (F-12, F-11); R-07 necesita un valor que solo se puede elegir con la prueba de F-10 |
| M6-4 | Alternativas D1–D3, supuestos S1–S5 y estimaciones de esfuerzo (15–25 h para D2, 80–120 h para D3) | `docs/distribucion/comparacion-distribucion.md` | Aceptado (2026-10-24): alternativas, supuestos y horas validadas como estimación | Las horas siguen siendo una estimación, no una medición; se corrigen si cambia el alcance |
| M6-5 | ADR-04: mantener D1 durante 6 meses; D2 aplazada y D3 descartada | `adr/adr-04-distribucion.md` | Aceptado por el equipo (2026-10-24); pendiente del veredicto del mini-comité | Coincide con la evidencia de S11, S12 y del experimento 13 |
| M6-6 | FF-01 sobre ADR-02 con las reglas R1–R3, ejecutada en CI con prueba negativa | `docs/fitness/ff-01-fronteras-modulares.md`, `tools/fitness/`, `.github/workflows/fitness-functions.yml` | Aceptado (2026-10-24): R3 se mantiene como regla de ADR-01 | Impide volver a la organización por capas técnicas que el spike 1 eliminó |

## Rechazado por la propia IA al redactar (para que conste)

- Poner precios en COP sin cotización: se dejaron como pendientes en A4.
- Marcar como probadas las tácticas R-04 y R-05 sin reservas: quedaron como **parciales**.
- Rellenar el veredicto del mini-comité del ADR-04 antes de celebrarlo.
- Una fitness function de rendimiento (k6 a 200 usuarios) en CI: los ejecutores compartidos de GitHub no dan condiciones de medición estables. Queda fuera de FF-01.

Revisado por: Charry Ríos Daniel Estiven y Kevin Steven Torres Caro · Fecha: 2026-10-24
