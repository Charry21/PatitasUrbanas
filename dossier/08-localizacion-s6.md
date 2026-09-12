# Localización C4 - Semana 6

Este documento parte de la operación ya medida en dossier/evidencia-consultas.md y la relaciona explícitamente con los elementos del C4 validado en Semana 5, como punto de partida para la localización del fenómeno arquitectónico (no como diagnóstico de causa).

## A. Escenario medible

| Campo | Valor |
|---|---|
| Operación | Crear solicitud de adopción con etapa inicial |
| Método HTTP | POST |
| Ruta | /api/adopciones |
| Parámetros | estado (query param, opcional, default "PENDIENTE"), nombreEtapa (query param, opcional, default "SOLICITUD_RECIBIDA") |
| Tipo de ejecución | Petición única y controlada (no carga concurrente) |
| Datos de entrada | Sin datos previos requeridos; no hay semilla (ver experimentos/03-linea-base-semana6.md) |
| Condiciones del entorno | Ver experimentos/03-linea-base-semana6.md (commit fde35cfee5522303746db8a1f57e7df20ee00d45) |
| Métrica observada | Número y tipo de sentencias SQL ejecutadas por petición (pg_stat_statements) |
| Criterio de reproducibilidad | 3 corridas válidas mostraron el mismo conjunto de operaciones de negocio (ver dossier/evidencia-consultas.md) |

## B. Evidencia de localización

| Elemento a rastrear | Evidencia |
|---|---|
| Petición | POST /api/adopciones?estado=PENDIENTE&nombreEtapa=SOLICITUD_RECIBIDA |
| Controlador | `AdopcionController.crearSolicitud` (app/src/main/java/com/patitasurbanas/api/controller/AdopcionController.java) |
| Servicio | `AdopcionService.crearSolicitudConEtapaInicial`, anotado `@Transactional` (app/src/main/java/com/patitasurbanas/api/service/AdopcionService.java) |
| Repositorio | `SolicitudAdopcionRepository.save()` y `EtapaAdopcionRepository.save()` (interfaces JpaRepository) |
| Entidad | `SolicitudAdopcion` (tabla solicitud_adopcion) y `EtapaAdopcion` (tabla etapa_adopcion, con `@ManyToOne` hacia SolicitudAdopcion vía `@JoinColumn(name = "solicitud_adopcion_id")`) |
| Base de datos | Secuencia observada: BEGIN, INSERT solicitud_adopcion, SELECT ... FOR KEY SHARE (verificación de la llave foránea antes del insert de etapa_adopcion), INSERT etapa_adopcion, COMMIT (ver dossier/evidencia-consultas.md) |
| Elemento C4 | Contenedor "API Backend" (componentes: Controlador de Adopciones, Servicio de Adopciones, Repositorio Solicitudes, Repositorio Etapas, Entidades de Dominio, según dossier/07-c4-componentes.md) → relación JDBC/JPA → Contenedor "Base de Datos" (PostgreSQL 16, según dossier/06-c4-contenedores.md) |

## C. Observación (no diagnóstico)

Se observó que una petición a POST /api/adopciones genera una secuencia de 5 operaciones SQL dentro de una única transacción, incluyendo una verificación de llave foránea no escrita explícitamente en el código de la aplicación, sino generada automáticamente por PostgreSQL debido a la relación `@ManyToOne` entre las entidades.

Esto es una observación de lo que ocurre, no una afirmación de causa ni un diagnóstico de rendimiento. No se concluye que esta secuencia sea un cuello de botella, ni que el repositorio, la base de datos o JPA sean responsables de ningún problema. Esa evaluación corresponde a fases posteriores del curso.
