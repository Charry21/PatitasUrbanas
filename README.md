# PatitasUrbanas

## Levantar la base de datos

El proyecto utiliza PostgreSQL mediante Docker Compose. Para levantar la base de datos después de clonar el repositorio:

1. Instala [Docker Desktop](https://www.docker.com/products/docker-desktop/) y asegúrate de que esté iniciado.
2. Abre una terminal en la carpeta raíz del proyecto.
3. Ejecuta:

```powershell
docker compose up -d
```

Este comando crea el contenedor `patitas_urbanas_db`, inicia PostgreSQL 16 y conserva los datos nuevos en el volumen `pgdata_v16`.

Para comprobar el estado del servicio:

```powershell
docker compose ps
```

Para detener el servicio sin eliminar los datos:

```powershell
docker compose down
```

Datos de conexión local:

- Host: `localhost`
- Puerto: `5433`
- Nota: 5433 al conectarte desde tu máquina; 5432 es el puerto interno usado entre contenedores de Docker.
- Base de datos: `patitas_urbanas`
- Usuario: `admin`
- Contraseña: `adminpassword`

## Evidencia de Ejecución Local (Semana 1)
A continuación, se demuestra la correcta inicialización del contenedor y la conexión exitosa al motor de base de datos PostgreSQL en el entorno de desarrollo local.

![Evidencia de ejecución](ejecucion_local.png)

## Evidencia de Ejecución de la API

![Ejecución de la API](evidencia_ejecucion_api.png)

## Validación de pruebas

Las pruebas de validación confirman de manera consistente que el *healthcheck* de la base de datos se mantiene en estado `healthy` y que el endpoint de la API responde con el código de estado HTTP `200`.

![Evidencia de Pruebas Spring Boot](evidencia_pruebas_java.png)
## Módulo 5 — Dominio, integración y Spike 1 (Semanas 9–10)

| Entregable | Dónde está |
|---|---|
| 1. Modelo del dominio y Context Map | [`docs/dominio/modelo-dominio.md`](docs/dominio/modelo-dominio.md) (evidencia y decisiones), [`docs/dominio/subdominios.md`](docs/dominio/subdominios.md), [`docs/dominio/responsabilidades-contextos.md`](docs/dominio/responsabilidades-contextos.md), [`docs/dominio/context-map.puml`](docs/dominio/context-map.puml) ([PNG](docs/dominio/context-map.png)) |
| 2. Decisión síncrono / asíncrono | [`docs/integracion/sincrono-vs-asincrono.md`](docs/integracion/sincrono-vs-asincrono.md) |
| 3. Contrato API | [`docs/integracion/contrato-api.yaml`](docs/integracion/contrato-api.yaml) (OpenAPI 3.0) |
| 4. Eventos candidatos | [`docs/integracion/eventos-candidatos.md`](docs/integracion/eventos-candidatos.md) |
| 5. CQRS y Event Sourcing | [`docs/integracion/cqrs-event-sourcing.md`](docs/integracion/cqrs-event-sourcing.md), [`dossier/17-cqrs-consistencia-eventual-s10.md`](dossier/17-cqrs-consistencia-eventual-s10.md) |
| 6. Preregistro del Spike 1 | [`experimentos/04-spike-especificacion-s9.md`](experimentos/04-spike-especificacion-s9.md) |
| 6b. Preregistro del Spike 2 (integración Adopciones ↔ Mascotas) | [`experimentos/08-spike-integracion-especificacion.md`](experimentos/08-spike-integracion-especificacion.md) |
| 7. Rama experimental | `spike/fronteras-modulares-s10` (desde `887ccf1`); control descartable `spike/control-y2-descartable` |
| 8. Ejecución, resultados y veredicto | [`experimentos/06-spike-resultado-s10.md`](experimentos/06-spike-resultado-s10.md), evidencia en [`experimentos/spike-s10/`](experimentos/spike-s10/); orden temporal verificado en [`experimentos/07-trazabilidad-temporal.md`](experimentos/07-trazabilidad-temporal.md) |
| 9. ADR 3 | [`adr/adr-03-limites-y-comunicacion-modulos.md`](adr/adr-03-limites-y-comunicacion-modulos.md) |
| 10. Registro crítico de IA | [`experimentos/05-auditoria-ia-s9.md`](experimentos/05-auditoria-ia-s9.md) (spike), [`docs/integracion/registro-ia-modulo5.md`](docs/integracion/registro-ia-modulo5.md) (dominio e integración) |

## Semana 11 — Experimento de crecimiento

| Entregable | Dónde está |
|---|---|
| Preregistro: escenario, vínculo con la línea base, hipótesis H1–H4 y reglas de análisis | [`experimentos/10-crecimiento-s11/README.md`](experimentos/10-crecimiento-s11/README.md) (commit `964dd4a`, [PR #66](https://github.com/Charry21/PatitasUrbanas/pull/66)) |
| Script de carga (50, 100, 150 y 200 usuarios) y orquestador | [`escenario-crecimiento.js`](experimentos/10-crecimiento-s11/escenario-crecimiento.js), [`ejecutar.sh`](experimentos/10-crecimiento-s11/ejecutar.sh) |
| Saturación del generador (CPU por segundo) | [`muestreo_cpu.py`](experimentos/10-crecimiento-s11/muestreo_cpu.py); resultado en H4 |
| Desviaciones registradas antes de medir | [`entorno/desviaciones.md`](experimentos/10-crecimiento-s11/entorno/desviaciones.md) |
| Resultados, conclusiones y límites | [`experimentos/10-crecimiento-s11/RESULTADOS.md`](experimentos/10-crecimiento-s11/RESULTADOS.md) ([PR #67](https://github.com/Charry21/PatitasUrbanas/pull/67)) |
| Datos crudos, bitácoras y análisis | [`resultados/`](experimentos/10-crecimiento-s11/resultados/), [`analizar.py`](experimentos/10-crecimiento-s11/analizar.py) |
| Trazabilidad del análisis y orden temporal | [`trazabilidad-analisis.md`](experimentos/10-crecimiento-s11/trazabilidad-analisis.md) |

## Módulo 6 — Resiliencia, distribución y fitness functions (Semanas 11–14)

| Paso | Entregable | Dónde está |
|---|---|---|
| A1 | Experimento de crecimiento (50–200 usuarios) y semilla de datos y memoria | [`experimentos/10-crecimiento-s11/`](experimentos/10-crecimiento-s11/), [`experimentos/13-semilla-memoria-s12/`](experimentos/13-semilla-memoria-s12/) |
| A2 | Matriz de fallos (observados / hipotéticos) | [`docs/resiliencia/matriz-fallos.md`](docs/resiliencia/matriz-fallos.md), evidencia de [`experimentos/12-inyeccion-fallos-s12/`](experimentos/12-inyeccion-fallos-s12/) |
| A3 | Matriz de resiliencia | [`docs/resiliencia/matriz-resiliencia.md`](docs/resiliencia/matriz-resiliencia.md) |
| A4 | Distribución y costos | [`docs/distribucion/comparacion-distribucion.md`](docs/distribucion/comparacion-distribucion.md) |
| A5 | ADR 4 (veredicto del comité: **Ajustada**, 2026-10-31) | [`adr/adr-04-distribucion.md`](adr/adr-04-distribucion.md) · acta: [`dossier/evidencia-comite-adr04.md`](dossier/evidencia-comite-adr04.md) |
| A6 | Fitness function FF-01 en CI | [`docs/fitness/ff-01-fronteras-modulares.md`](docs/fitness/ff-01-fronteras-modulares.md), [`.github/workflows/fitness-functions.yml`](.github/workflows/fitness-functions.yml) |
| — | Autoauditoría A1–A6 | [`docs/auditoria-modulo6.md`](docs/auditoria-modulo6.md) |
| — | Registro crítico de IA | [`docs/registro-ia-modulo6.md`](docs/registro-ia-modulo6.md) |
