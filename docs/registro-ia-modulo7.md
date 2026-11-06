# Registro crítico de IA — Módulo 7 (semanas 13 y 14)

**Herramienta:** Claude (Anthropic). La IA redactó los borradores, diseñó y ejecutó los experimentos 14, 15 y 16, construyó la capa de seguridad candidata y abrió los pull requests con la cuenta de Kevin Steven Torres Caro, a pedido suyo. Una propuesta no forma parte del dossier hasta que el equipo decide.

**La columna "Decisión del equipo" está vacía a propósito:** a 2026-11-05, nadie del equipo ha revisado este trabajo.

| # | Propuesta de la IA | Dónde | Decisión del equipo | Razón para decidir con cuidado |
|---|---|---|---|---|
| M7-1 | Modelado STRIDE con 18 amenazas y matriz de 17 riesgos, con probabilidad e impacto | `docs/10-seguridad.md` | | Probabilidad e impacto son juicio, no medición |
| M7-2 | Aceptar RS-08, RS-09, RS-12, RS-13, RS-15 y RS-17 | `docs/10-seguridad.md` §4 | | Aceptar un riesgo es responsabilidad del equipo, no de la IA |
| M7-3 | Prueba de fuga con 13 sondas y clasificación automática | `experimentos/14-fuga-datos-s13/` | | `SIN_FUGA` solo significa que esa sonda no obtuvo nada |
| M7-4 | Capa JWT RS256 en la API con denegación por defecto | `feat/s13-capa-seguridad`, ADR-05 decisión A | | Cambia el contrato de la API y no hay emisor de tokens |
| M7-5 | Proxy Caddy y `docker-compose.produccion.yml` | ADR-05 decisión B | | Añade un contenedor a D1: ajusta ADR-04 |
| M7-6 | `.env`, sin root, `health` sin detalles, largo máximo de 255 | ADR-05 decisión C | | Cambia cómo se levanta el proyecto en cada computador |
| M7-7 | R-10 junto con R-11, con `update` | ADR-05 decisión D | | Cambia el orden que el equipo aceptó en M6-3 |
| M7-8 | Alternativas V0, V1 y V2 con costo relativo, y proponer V1 | `docs/12-despliegue-observabilidad.md` §2 | | El proveedor no está elegido y el precio de V1 sigue siendo de fuente secundaria |
| M7-9 | Observabilidad por niveles N1–N3, alertas AL-1 a AL-7 | `docs/12-despliegue-observabilidad.md` §3 | | Los umbrales son propuestos y nada está implementado |
| M7-10 | RPO de 24 h y planes P-1 a P-9 | `docs/12-despliegue-observabilidad.md` §4 | | Nadie ha definido ese objetivo. La mayoría de los planes no se ha probado |
| M7-11 | 14 riesgos operativos y 10 compromisos | `docs/13-riesgos-tradeoffs.md` | | Mismo criterio que M7-1 |
| M7-12 | ADR-05 | `adr/adr-05-seguridad-y-operacion.md` | | Tiene que quedar con decisiones reales del equipo |
| M7-13 | FF-02 en CI | `docs/fitness/ff-02-configuracion-segura.md` | | Si se rechaza una decisión de ADR-05, hay que ajustar sus reglas |
| M7-14 | Reclasificar R-06 de **Probada** a **Parcial**, y añadir F-14 | `docs/resiliencia/` | | Corrige un documento que el equipo ya había revisado |
| M7-15 | Pasar F-12 a **Observado**, R-10 y R-11 a **Probada** | `docs/resiliencia/` | | Probadas, pero no fusionadas en `main` |
| M7-16 | Verificar el arranque con `app/Dockerfile` en GitHub Actions, y marcar R-12 como **Probada en CI** | `docs/verificacion/arranque-limpio-2026-11-06/` | | El equipo delegó esta prueba: nadie la ha repetido en un computador del equipo |

## Rechazado por la propia IA al redactar (para que conste)

- Firmar ADR-05, EDAV 3, este registro o la autoauditoría en nombre del equipo.
- Marcar ADR-05 como aceptada: queda en **Propuesta**.
- Inventar un veredicto de comité para ADR-05, o una sesión EDAV 3 que no ocurrió.
- Fusionar los pull requests: la guía del tutor pide revisión del equipo.
- Presentar el p95 como una predicción de producción.
- Poner precios en COP sin un proveedor elegido.
- Reescribir el historial de Git para quitar la contraseña: invalidaría hashes que cita el dossier.
- Elegir un emisor de tokens: es una decisión del equipo (RS-14).

Revisado por: *pendiente* · Fecha: *pendiente*
