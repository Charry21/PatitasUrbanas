# Contrato de fitness function FF-02 — Configuración segura y operable

> **Estado: aceptada por el equipo** el 2026-11-06 (ADR-05, decisión F). La redactó la IA. Corre en CI desde que se fusionó el PR #83 ese mismo día.

| Campo | Contenido |
|---|---|
| **Decisión arquitectónica** | ADR-05 (propuesta): denegar por defecto, no publicar la BD, no versionar secretos, y reinicio automático solo con datos que sobreviven (R-10 + R-11) |
| **Propiedad comprobable** | La configuración que se despliega mantiene esos controles |
| **Alcance** | `application.properties`, `docker-compose.yml`, `docker-compose.produccion.yml`, `app/Dockerfile`, `app/pom.xml` y `SeguridadConfig.java` |
| **Condición de cumplimiento** | 0 violaciones |
| **Condición de fallo** | 1 o más violaciones → código 1. Código 2 si falta un archivo |
| **Mecanismo de ejecución** | `tools/fitness/configuracion_segura.py`, en el job `ff-02-configuracion-segura` de `.github/workflows/fitness-functions.yml`, en cada `push` a `main` y en cada pull request |
| **Prueba negativa** | `tools/fitness/prueba_negativa_ff02.sh` rompe 10 controles en una copia y exige que cada uno haga fallar la comprobación. Se ejecuta en el mismo job |

## Reglas

| Regla | Qué comprueba | Origen |
|---|---|---|
| S1 | Actuator solo expone `health` | P02 del experimento 14 |
| S2 | `health` no muestra detalles | P03 |
| S3 | No hay contraseñas literales en `application.properties` ni en los Compose | P08 |
| S4 | En `docker-compose.yml`, el puerto de la BD solo escucha en `127.0.0.1` | P07 |
| S5 | En producción, la API y la BD no publican puertos | P07, P11 |
| S6 | Producción incluye el proxy TLS | P11 |
| S7 | La etapa final de la imagen no corre como root | P12 |
| S8 | Existe la dependencia de la capa de seguridad | P06, P13 |
| S9 | `SeguridadConfig` deniega toda ruta no declarada | P02 |
| O1 | La API tiene reinicio automático | Condición del ADR-04, experimento 16 |
| O2 | El reinicio automático va con `ddl-auto` `update` o `validate` | HR2 del experimento 16 |

## Limitaciones declaradas

- Revisa archivos, no el sistema en ejecución: la prueba de fuga (experimento 14) sigue siendo la que comprueba el comportamiento.
- Las reglas S4, S8 y S9 buscan texto; un cambio de nombre o de forma las puede engañar.
- No revisa el historial de Git, ni dependencias vulnerables, ni el contenido de `.env`.

---

*Redactada por la IA · aceptada por el equipo (Kevin Torres · Daniel Charry, 2026-11-06) · Semana 14*
