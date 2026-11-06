# Riesgos y compromisos — Semanas 13 y 14

> **Estado: revisado por el equipo el 2026-11-06.** Los tratamientos son decisiones del equipo (ADR-05). Probabilidad e impacto los calificó el equipo (revisión manual S6, `docs/verificacion/revision-manual-s6-2026-11-06/`). El equipo registra las aceptaciones como **deuda técnica** que se revisa antes de desplegar.

Este documento reúne los riesgos que siguen abiertos. Los riesgos de seguridad están en [`10-seguridad.md`](./10-seguridad.md) §4; aquí solo se resumen los que condicionan una decisión.

**Identificadores:** `RS` riesgo de seguridad, `RO` riesgo operativo, `TO` compromiso. Se usan prefijos propios porque `R-01`… ya significa dos cosas en el repositorio (ver [`auditoria-modulo7.md`](./auditoria-modulo7.md), I-07).

**Escala:** la misma de `docs/10-seguridad.md` §4, acordada en la revisión manual S6 (2026-11-06). Se califica el riesgo sin su control y suponiendo un despliegue público.

---

## 1. Matriz de riesgos operativos

| Id | Riesgo | Fallo | Prob. | Impacto | Evidencia | Tratamiento propuesto | Señal | Riesgo residual |
|---|---|---|---|---|---|---|---|---|
| RO-01 | Pérdida total de datos al reiniciar la API | F-13 | Alta | Alto | **Observado:** 5/5 ciclos, de 5 filas a 0 (exp. 16, HR2) | **Mitigar:** R-10 y R-11 juntas. `update` en Compose | Conteo de filas | `update` no gestiona cambios incompatibles (RO-08) |
| RO-02 | Sin copias de la BD: un error o la pérdida del servidor es irrecuperable | Nuevo | Alta | Alto | **Documentado:** no hay ningún mecanismo | **Mitigar:** `pg_dump` diario y simulacro. **No implementado** | AL-7 | RPO de 24 h, sin probar |
| RO-03 | Una caída de la API no la ve nadie: R-10 la oculta | F-12 | Alta | Medio | **Observado:** vuelve en < 10 s sin aviso (exp. 16) | **Mitigar:** AL-2 sobre `RestartCount`. **No implementado** | AL-2 | — |
| RO-04 | Punto único de fallo: servidor, Docker o BD | F-01, F-12 | Media | Alto | **Decidido:** ADR-04 | **Aceptar** en el horizonte de 6 meses | AL-1 | Indisponibilidad hasta intervenir |
| RO-05 | API viva pero colgada: Docker no la reinicia | Nuevo | Media | Alto | **Hipotético** | **Aceptar** por ahora. Revisar si se añade un `healthcheck` al contenedor | AL-1 | Requiere reinicio manual |
| RO-06 | Disco lleno por logs: no hay rotación y SQL está en DEBUG | F-11 | Alta | Alto | **Observado:** 176 MB en S11. Disco lleno, **hipotético** | **Mitigar:** R-09 y rotación. **No implementado** | AL-5 | — |
| RO-07 | Con la BD caída y carga, se agotan los hilos y también cae `/buscar` | F-10 | Media | Medio | **Hipotético:** S12 fue de una en una | **Aceptar** hasta probarlo con carga. Decisión de M6-3 y del comité del ADR-04 | Hilos ocupados | — |
| RO-08 | Cambio de esquema incompatible con `ddl-auto=update` | Nuevo | Media | Alto | **Documentado:** `update` no elimina ni transforma | **Aceptar** ahora que hay 2 tablas. Migraciones con Flyway cuando exista el contexto de Identidad | Error al arrancar | Rollback de esquema manual |
| RO-09 | Causa de F-05 sin aislar: la cola de latencia crece a 200 usuarios | F-05 | Media | Medio | **Observado:** p99 de 64,71 a 209,25 ms (S11). No son las filas (exp. 13) | **Mitigar:** R-08. **No implementado** | AL-4 | — |
| RO-10 | La imagen original no construye detrás de un proxy TLS | F-08 | Baja | Bajo | **Observado** detrás de proxy TLS. **Construye en una máquina limpia y en Windows** (`docs/verificacion/arranque-limpio-2026-11-06/` y `docs/verificacion/windows-2026-11-06/`) | **Mitigado:** construye en Linux limpio y en Windows | Build fallido | Las mediciones usan `Dockerfile.runtime` |
| RO-11 | Las pruebas de la API no corren en CI: el test de rollback (QA-02) y los de seguridad dependen de ejecutarlos a mano | Nuevo | Alta | Medio | **Documentado:** `.github/workflows` solo ejecuta fitness functions | **Mitigar:** job con PostgreSQL de servicio. **No implementado** | CI | — |
| RO-12 | La evidencia de rendimiento no incluye una búsqueda real: `/buscar` es simulado | Escenario 1 | Alta | Medio | **Documentado:** `MascotaController` devuelve texto fijo | **Aceptar** hasta implementar Mascotas. Repetir S11 entonces | — | El margen de ADR-04 no vale para la búsqueda real |
| RO-13 | Conocimiento en 2 personas, sin guardia | Nuevo | Media | Alto | **Documentado:** DA-03 | **Aceptar** | — | Una alerta nocturna puede no atenderse |
| RO-14 | Sin emisor de tokens no se puede operar con clientes reales | RS-14 | Alta | Alto | **Documentado:** Identidad no existe | **Aplazado** en ADR-05: solución de identidad de terceros | — | La capa solo funciona con tokens de prueba |
| RO-15 | El margen de rendimiento solo está medido en el entorno de S11; en el computador del equipo, la API no sostuvo 100 req/s en S8 | Escenario 1 | Alta | Medio | **Registro histórico, sin condiciones:** corrida 1 bloqueada a los 4 s (20,92 % de fallos) y corrida 2 con un p95 de 2,98 s (`experimentos/defensa-s8-historico/`) | **Mitigar:** repetir `escenario-defensa.js` con token y con el código actual, en el computador del equipo | AL-4 | Mientras no se repita, el margen de ADR-04 vale solo para el entorno de S11 |

---

## 2. Riesgos de seguridad que condicionan una decisión

| Id | Riesgo | Por qué se trae aquí |
|---|---|---|
| RS-01 | Cualquiera puede crear solicitudes | Sin la capa, el escenario 2 no se cumple |
| RS-05 | La BD es accesible desde otra red con la contraseña del repositorio | Fue el hallazgo más grave. Mitigado en `main` con el PR #83 (2026-11-06); en producción la BD no publica puertos |
| RS-14 | No hay emisor de tokens | Bloquea el uso real de la capa |
| RS-15 | Datos personales futuros bajo la Ley 1581 | Hoy no se guardan; cuando existan, varias aceptaciones de este documento se revisan |

---

## 3. Compromisos (*trade-offs*)

| Id | Decisión propuesta | Qué se gana | Qué se paga | Evidencia del costo | Condición de revisión |
|---|---|---|---|---|---|
| TO-01 | Validar JWT en la API | Sin estado: mantiene S5 y deja abierta D2. Cumple el escenario 2 | Más dependencias, y claves que gestionar | +5,23 ms en `buscar` y +9,72 ms en `adopcion`; CPU máx. de 19,9 % a 33,9 % (exp. 15) | Si el p95 con datos reales se acerca a 800 ms |
| TO-02 | TLS con un proxy | Tráfico cifrado sin tocar la API; certificados automáticos | +1 contenedor frente a los 2 de ADR-04, y otro punto de fallo | Δ del p95 no concluyente; el p99 de escritura sube de 134 a 227 ms, sin confirmar (exp. 15) | Si se elige V2, el proveedor pone el TLS y este contenedor sobra |
| TO-03 | D1 en un solo servidor | Costo relativo mínimo y evidencia válida | Punto único de fallo (RO-04) | ADR-04 | Objetivo de disponibilidad que una instancia no cumpla |
| TO-04 | V1 frente a V2 | Conserva las mediciones y es portable | El equipo responde por el sistema operativo y las copias | §2 de `12-despliegue-observabilidad.md`: costo relativo 1,0 frente a ≈ 1,1 | Si el mantenimiento supera lo que el equipo puede atender |
| TO-05 | `update` en lugar de migraciones | Una línea de configuración; R-10 deja de borrar datos | Sin historial del esquema ni rollback (RO-08) | HR3, exp. 16 | Al crear el contexto de Identidad o la tercera tabla |
| TO-06 | R-10 antes que D2 | ~1 línea frente a ~15–25 h | Se pierden las peticiones en curso durante unos 8 s | < 10 s, exp. 16 | Si no se acepta ese corte |
| TO-07 | Observabilidad N1 | Sin contenedores nuevos | No hay métricas por operación: F-05 y F-09 no se ven sin k6 | §3.2 de `12-despliegue-observabilidad.md` | Al tener usuarios reales |
| TO-08 | Registrar el origen en el log de auditoría | Permite actuar ante abusos (escenario 2) | Una dirección IP puede ser dato personal: hay que definir retención | Riesgo RS-16 | Antes del primer despliegue público |
| TO-09 | Secretos en `.env` | Sin herramientas nuevas | Quedan en texto en el servidor y en las variables del contenedor (P08) | P08, exp. 14 | Si hay más de un servidor o más personas con acceso |
| TO-10 | Búsqueda pública, sin token | Sin fricción para el ciudadano; menos costo por petición | Cualquiera puede consumirla sin límite (RS-08) | Decisión de producto, por confirmar | Cuando devuelva datos reales de ubicación |

---

## 4. Supuestos abiertos

| Supuesto | Cómo se verifica | Si no se cumple |
|---|---|---|
| El sistema aún no guarda datos personales | `app/src/main` no tiene entidades con esos datos (revisado el 2026-11-05) | Se revisa todo lo aceptado en `10-seguridad.md` |
| La carga real no supera los 200 usuarios | Comparar al desplegar | Serie nueva antes de decidir (ADR-04) |
| El equipo puede atender una alerta en horas, no en minutos | Decisión del equipo | Revisar el RTO |
| RPO de 24 h aceptable | Decisión del equipo | Copias más frecuentes |

---

## 5. Prioridades del equipo antes de desplegar

Fuente: conclusión del equipo en la EDAV 3, §8 (2026-11-06).

| Prioridad | Qué | Riesgos que cierra |
|---|---|---|
| 1 | ~~Revisar a mano probabilidades, impactos y umbrales~~ Hecho el 2026-11-06 | S6 de la EDAV 3 |
| 2 | Integrar un emisor de tokens de terceros | RS-14, RO-14 |
| 3 | Reforzar las pruebas de integración: servidor real y job de CI con PostgreSQL | RO-11 y el punto ciego de MockMvc (S8) |
| 4 | Control de acceso en la búsqueda antes de usar datos reales | TO-10 |
| 5 | Revisar los riesgos aceptados y definir la retención de IP | RS-08, RS-09, RS-12, RS-13, RS-15, RS-16, RS-17 |
| 6 | Copias, alertas, R-09 y R-08 | RO-02, RO-03, RO-06, RO-09 |

---

*Borrador de la IA, revisado por el equipo (Kevin Torres · Daniel Charry, 2026-11-06) · Semana 14 · Módulo 7 · Arquitectura de Software*
