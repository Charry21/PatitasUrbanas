# ADR-05 — Seguridad y operación del despliegue único
## Patitas Urbanas · Módulo 7

---

## Estado

**Propuesta** — borrador de la IA, sin decisión del equipo ni veredicto de comité.

Las decisiones de este documento **no son del equipo todavía**. Cada una se puede aceptar, ajustar o rechazar en la sección "Decisión del equipo". El código que las implementa está en la rama `feat/s13-capa-seguridad` y no está en `main`.

Historial: Propuesta por la IA (Semana 14, 2026-11-05).

---

## Contexto

ADR-04 mantiene una sola instancia (D1). Su veredicto **Ajustada** exige implementar y probar R-10. El dossier declara la seguridad como atributo de prioridad alta (QA-01, Ley 1581 de 2012) y define el escenario 2: el 100 % de los accesos sin token válido se bloquea con 401 en menos de 500 ms y queda registrado.

**Evidencia disponible:**

| Fuente | Qué aporta |
|---|---|
| Modelado de amenazas ([`docs/10-seguridad.md`](../docs/10-seguridad.md)) | 18 amenazas STRIDE sobre lo que existe en el código |
| Experimento 14, fuga de datos, `main` | 8 sondas con fuga o hallazgo. Cualquiera crea solicitudes (P06, P13), y desde otra red se lee PostgreSQL con la contraseña del repositorio (P07) |
| Experimento 15, costo sobre el p95 | ⟦EVID15⟧ |
| Experimento 16, reinicio | R-10 recupera la API en < 10 s (10/10 ciclos). Con `create-drop`, cada reinicio borra los datos (5/5). Con `update`, se conservan (5/5) |
| ADR-04 y A4 | D1 durante 6 meses; la API no guarda estado (S5) |
| Matriz de fallos | F-12 y F-13 |

**Drivers:**
- QA-01: seguridad y Ley 1581;
- escenario 2: control de acceso;
- escenario 1: p95 < 800 ms;
- DA-03: costo operativo para un equipo de 2 personas;
- QA-02: integridad de TRX-02;
- escenario reformulado 2: RTO de 120 s.

---

## Problema

> ¿Cómo se protege, se expone y se recupera Patitas Urbanas con una sola instancia, sin un costo operativo desproporcionado para el equipo?

---

## Decisión A — Autenticación y autorización

| Id | Alternativa | A favor | En contra |
|---|---|---|---|
| A1 | **JWT validado en la API** (Spring Security, servidor de recursos, RS256) | Sin estado: mantiene S5. Sirve para cualquier emisor. Cumple el escenario 2 | Depende de un emisor que no existe. Revocar un token antes de su caducidad no es inmediato |
| A2 | Clave de API compartida | Muy simple | No identifica personas ni permisos; incumple QA-01 |
| A3 | Autenticación en el proxy | Protege todo desde fuera | La API confía en cualquiera que llegue a su puerto; ata el control a un componente |
| A4 | Sesiones en servidor | Revocación inmediata | Añade estado: rompe S5 y encarece D2 |

**Propuesta: A1**, denegando por defecto toda ruta no declarada. `POST /api/adopciones` exige `adopciones:escribir`, `/api/adopciones/test-fallo` exige `adopciones:pruebas`, y `GET /api/mascotas/buscar` y `GET /actuator/health` son públicas. Cada 401 y 403 deja una línea `AUDITORIA_ACCESO_DENEGADO`.

**Sin resolver:** quién emite los tokens (RS-14). Identidad es un subdominio genérico (`docs/dominio/subdominios.md`), así que puede cubrirse con una solución existente. El equipo debe elegirla.

## Decisión B — Exposición y cifrado en tránsito

| Id | Alternativa | A favor | En contra |
|---|---|---|---|
| B1 | **Proxy Caddy que termina TLS** | Certificados automáticos; la API y la BD no publican puertos | +1 contenedor frente a los 2 de ADR-04 |
| B2 | TLS en Tomcat | Sin contenedores nuevos | Gestión manual de certificados dentro de la imagen |
| B3 | TLS del proveedor (V2) | Sin operación | Exige cambiar de alternativa de despliegue y repetir mediciones |

**Propuesta: B1**, con `docker-compose.produccion.yml`. Esto **ajusta ADR-04**: D1 sigue siendo una instancia de la API, pero pasa de 2 a 3 contenedores.

## Decisión C — Secretos y endurecimiento

**Propuesta:**
- contraseñas y claves en un `.env` sin versionar, con `.env.example` como plantilla;
- la API no arranca sin la clave pública: falla cerrada;
- `health` sin detalles;
- imagen sin root;
- entrada de más de 255 caracteres → 400.

Alternativas descartadas por ahora: Docker Secrets y un gestor de secretos, porque no se justifican con un servidor y 2 personas (TO-09).

## Decisión D — Recuperación

| Id | Alternativa | A favor | En contra |
|---|---|---|---|
| R1 | R-10 sola | Una línea; respeta el orden de M6-3 | **Cada caída borra los datos** (HR2) |
| R2 | **R-10 + R-11 (`update`)** | Recuperación en < 10 s conservando datos (HR1, HR3) | Sin migraciones (RO-08) |
| R3 | R-10 + migraciones con Flyway | Esquema versionado | Más trabajo con solo 2 tablas |
| R4 | D2 | Sin corte ante F-12 | ~15–25 h; ADR-04 la aplazó |

**Propuesta: R2.** Esto **cambia el orden aceptado en M6-3:** R-11 pasa del cuarto lugar al mismo cambio que R-10. Plan de operación y copias: [`docs/12-despliegue-observabilidad.md`](../docs/12-despliegue-observabilidad.md) §4.

## Decisión E — Observabilidad

**Propuesta:** nivel N1 antes del primer despliegue público; N2 cuando haya usuarios reales; N3 solo si aparece un segundo proceso. Se rechaza un stack completo ahora porque añadiría más componentes que el sistema que vigila (DA-03).

## Decisión F — Restricción ejecutable

**Propuesta:** FF-02 en CI ([contrato](../docs/fitness/ff-02-configuracion-segura.md)). Falla si reaparece una contraseña literal, si la BD se publica, si Actuator expone más que `health`, si la imagen corre como root o si R-10 aparece sin R-11. La prueba negativa rompe 10 controles y exige que los 10 fallen.

---

## Costo

| | Sin capa (S) | Capa JWT (C) | Capa + TLS (T) |
|---|---:|---:|---:|
⟦TABLA15⟧

Condiciones: 200 usuarios, 2 vCPU compartidas por todo, 6 corridas válidas por celda. Los números **solo comparan condiciones** y no predicen producción. Resultado completo: [`experimentos/15-costo-seguridad-s13/RESULTADOS.md`](../experimentos/15-costo-seguridad-s13/RESULTADOS.md).

| Costo operativo | Valor | Clase |
|---|---|---|
| Contenedores | 3 frente a 2 | Documentado |
| Infraestructura | Sin cambio: mismo servidor | Estimado |
| Interrupción por una caída del proceso | ≈ 8 s en reposo | Medido |

---

## Consecuencias

### Positivas
- El escenario 2 pasa de "no implementado" a verificado: ⟦POS2⟧.
- Se cierra la lectura directa de la BD desde otra red (P07) y el HTTP en claro hacia fuera (P11).
- R-10 deja de ser peligrosa y se cumple la condición de ADR-04, si el equipo fusiona el cambio.
- Se conserva S5: D2 sigue disponible.
- FF-02 impide que estos controles se pierdan sin que CI lo note.

### Negativas
- Sin emisor de tokens, la capa solo funciona con tokens de prueba (RS-14, RO-14).
- `docker compose up` deja de funcionar sin `.env` y sin clave: más pasos para empezar.
- Un contenedor más que operar y un punto más de fallo.
- `update` no sustituye a las migraciones (RO-08).
- Revocar un token exige esperar a su caducidad.
- El log de auditoría guarda direcciones IP, que pueden ser dato personal (RS-16).

### Riesgos que siguen abiertos
RS-08 (sin límite de peticiones), RS-13 (tráfico interno sin cifrar), RS-15 (datos personales futuros), RS-17 (contraseña en el historial de Git), RO-02 (sin copias) y RO-03 (nadie ve las caídas hasta tener alertas).

---

## Implicaciones de seguridad

Este ADR es la decisión de seguridad del sistema. Cumple la condición que dejó ADR-01: una sola superficie autenticada. No cubre el cifrado en reposo ni el consentimiento de la Ley 1581, porque hoy no hay datos personales. Eso se revisa con el contexto de Identidad.

---

## Reversibilidad

- **Alta:** R-10, R-11 y el proxy son configuración.
- **Media:** la capa JWT cambia el contrato de la API. Retirarla reabre el escenario 2.

---

## Supuestos y condición de revisión

| Supuesto | Cómo se verifica | Condición de revisión |
|---|---|---|
| No se guardan datos personales | Revisar las entidades en cada cambio del dominio | Al crear Identidad se revisan el cifrado en reposo, el consentimiento, la retención de logs y RS-15 |
| Habrá un emisor compatible con JWT RS256 | Elegirlo y probarlo con las sondas P13 | Si no emite RS256, se cambia el decodificador |
| El costo de la capa no compromete el escenario 1 | Repetir el experimento 15 cuando `/buscar` consulte la BD | Si Δ deja de ser despreciable frente a 800 ms |
| Una sola máquina (proxy, API y BD) | ADR-04 | Si se separan, RS-13 deja de ser aceptable |
| Corte de ≈ 8 s aceptable | Objetivo de disponibilidad del equipo | Si no se acepta, ensayar D2 |

---

## Decisión del equipo

| Decisión | Propuesta | Decisión del equipo | Fecha |
|---|---|---|---|
| A. Autenticación | A1, JWT en la API | ☐ Aceptada ☐ Ajustada ☐ Rechazada | |
| A. Emisor de tokens | Sin propuesta | | |
| B. Exposición | B1, proxy Caddy | ☐ Aceptada ☐ Ajustada ☐ Rechazada | |
| C. Secretos y endurecimiento | `.env` y controles | ☐ Aceptada ☐ Ajustada ☐ Rechazada | |
| D. Recuperación | R-10 + R-11 | ☐ Aceptada ☐ Ajustada ☐ Rechazada | |
| E. Observabilidad | N1 | ☐ Aceptada ☐ Ajustada ☐ Rechazada | |
| F. FF-02 | En CI | ☐ Aceptada ☐ Ajustada ☐ Rechazada | |

## Veredicto del comité

Pendiente. El sílabo y la rúbrica no están en el repositorio: el equipo debe confirmar si ADR-05 necesita mini-comité, como ADR-04.

---

## Referencias

- `adr/adr-01-decision-estilo.md`, `adr/adr-04-distribucion.md`
- `dossier/04-escenarios-calidad.md`, `dossier/02-stakeholders-drivers.md`
- `docs/10-seguridad.md`, `docs/12-despliegue-observabilidad.md`, `docs/13-riesgos-tradeoffs.md`
- `experimentos/14-fuga-datos-s13/`, `experimentos/15-costo-seguridad-s13/`, `experimentos/16-reinicio-automatico-s14/`
- `docs/resiliencia/matriz-fallos.md`, `docs/resiliencia/matriz-resiliencia.md`

---

*Borrador de la IA · Semana 14 · Módulo 7 · Arquitectura de Software · Pendiente de revisión y firma del equipo*
