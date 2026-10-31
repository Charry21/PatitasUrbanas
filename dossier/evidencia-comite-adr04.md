# Evidencia — Mini-comité del ADR-04 (distribución del despliegue)
## Patitas Urbanas · Módulo 6

---

## Datos de la sesión

| Campo | Valor |
|---|---|
| Fecha | 2026-10-31 (Semana 13) |
| Formato | Comité interno del equipo, con roles separados. Según la indicación del profesor del curso, el equipo puede evaluar su propio comité |
| Decisión evaluada | `adr/adr-04-distribucion.md`: mantener D1 (una instancia del monolito modular + PostgreSQL) durante 6 meses; D2 aplazada y D3 descartada en ese horizonte |
| Defensor de la decisión | Charry Ríos Daniel Estiven |
| Comité (arquitecto revisor) | Kevin Steven Torres Caro |
| Preparación | Las preguntas y las respuestas parten de un borrador de la IA, construido con el ADR-04 y las decisiones M6-3 y M6-5. El equipo lo revisó en la sesión y lo aceptó sin cambios (M6-7 de `docs/registro-ia-modulo6.md`) |

---

## Preguntas realizadas

1. D1 tiene un punto único de fallo (F-12) y no hay reinicio automático. ¿Es aceptable?
   - **Respuesta del equipo:** Sí, en este horizonte, porque no hay despliegue real ni un objetivo de disponibilidad definido. Se mitiga con R-10 (`restart: unless-stopped`), la primera táctica del plan aceptado en M6-3.

2. La carga solo se probó hasta 200 usuarios (S11). ¿Qué pasa si la carga real es mayor?
   - **Respuesta del equipo:** Todavía no hay una carga real medida. Si la carga esperada supera 200 usuarios, se preregistra una serie con más carga antes de cambiar la distribución. Es la condición de revisión que ya tiene el ADR.

3. Con la BD caída, cada escritura tarda 30 s en fallar (F-01, F-03). ¿Lo aceptan?
   - **Respuesta del equipo:** Sí, de forma provisional. R-07 se aplaza hasta probar F-10 con carga (M6-3). Si esa prueba muestra que se agotan los hilos, se adopta R-07.

4. ¿Por qué no D2, si es reversible?
   - **Respuesta del equipo:** Su beneficio principal es tolerar F-12, que es hipotético, y no ayuda ante la caída de la BD (F-01). R-10 cubre buena parte de F-12 con una línea de configuración, frente a las ~15–25 h que costaría D2.

5. El precio de referencia (12 USD/mes) sale de fuentes secundarias y no hay precio en COP. ¿Cambia la decisión?
   - **Respuesta del equipo:** No. D1 es la opción más barata con cualquier precio, porque D2 y D3 necesitan al menos el doble de servidores. El precio oficial se confirma cuando se elija el proveedor.

---

## Veredicto emitido

☐ **Confirmada** — la decisión está bien sustentada, sin condiciones.
☒ **Ajustada** — válida, pero con la siguiente condición:
   Implementar R-10 (reinicio automático del contenedor de la API) y probarlo: detener el proceso de la API y medir el tiempo hasta la primera respuesta 200.
☐ **Reconsiderada** — falta evidencia o el costo no se justifica porque:
   _(no aplica)_

| Condición | Responsables | Fecha límite |
|---|---|---|
| Implementar y probar R-10 | Charry Ríos Daniel Estiven y Kevin Steven Torres Caro | Cierre de la Semana 13 |

**Justificación breve del veredicto:**
La evidencia de S11, S12 y del experimento 13 sostiene D1 con la carga probada. El riesgo que queda abierto es F-12: con una sola instancia, la caída del proceso deja el sistema sin servicio, y hoy nada lo reinicia. Por eso el veredicto es "Ajustada" y no "Confirmada": D1 se mantiene, pero con la condición de cubrir F-12 con R-10 y medirlo.

---

Firmado: Charry Ríos Daniel Estiven · Kevin Steven Torres Caro · 2026-10-31

*Semana 13 · Módulo 6 · Arquitectura de Software*
