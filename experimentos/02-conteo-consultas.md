# Conteo de Consultas SQL por Petición (Semana 5)

## Objetivo

Documentar el número de sentencias SQL generadas por una petición al endpoint existente de `MascotaController`, usando las estadísticas de Hibernate como instrumentación y preservando el estado as-is del sistema.

## Instrumentación aplicada

En `app/src/main/resources/application.properties` se habilitaron las estadísticas de Hibernate y el logging asociado:

```properties
spring.jpa.properties.hibernate.generate_statistics=true
logging.level.org.hibernate.stat=DEBUG
logging.level.org.hibernate.SQL=DEBUG
```

Esta configuración permite observar estadísticas y SQL emitido cuando una operación usa Hibernate/JPA. No agrega consultas ni modifica el comportamiento funcional del controlador.

## Petición evaluada

```http
GET /api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5
```

Implementación evaluada:

`app/src/main/java/com/patitasurbanas/api/controller/MascotaController.java`

El método `buscarMascotas` recibe `lat`, `lng` y `radio`, pero devuelve directamente una respuesta JSON estática. No invoca `AdopcionService`, un repositorio, `EntityManager` ni una consulta geoespacial sobre PostgreSQL/PostGIS.

## Resultado as-is

| Métrica | Resultado | Evidencia |
|---|---:|---|
| Petición HTTP evaluada | 1 | `GET /api/mascotas/buscar` |
| Consultas SQL generadas por el endpoint | **0** | El método devuelve JSON estático y no accede a persistencia |
| Consultas Hibernate observables para esa operación | **0** | No se inicia una operación JPA desde `MascotaController` |
| Consulta espacial PostgreSQL/PostGIS | No aplica | La búsqueda geoespacial aún no está implementada en este endpoint |

El valor **0** es el resultado real del flujo implementado, no una estimación de rendimiento. Las estadísticas de Hibernate sirven como comprobación adicional: para esta petición no debe aparecer una sentencia SQL originada por el controlador.

## Procedimiento reproducible

1. Levantar la aplicación con el perfil y la base de datos configurados en el repositorio.
2. Observar la salida de aplicación con los loggers `org.hibernate.stat` y `org.hibernate.SQL` habilitados.
3. Ejecutar la petición:

   ```powershell
   Invoke-WebRequest "http://localhost:3000/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5"
   ```

4. Corroborar que la respuesta HTTP sea `200` y que no aparezca una sentencia SQL causada por `MascotaController`.
5. Registrar cualquier sentencia SQL de inicialización o de otras operaciones por separado; no atribuirla a esta petición si no existe una llamada JPA desde el endpoint.

Como alternativa de verificación a nivel PostgreSQL, `pg_stat_statements` requeriría habilitar la extensión en el servidor y consultar sus contadores antes y después de la petición. Esa extensión no se declara ni se configura en el repositorio actual, por lo que no se presenta como evidencia ejecutada en este resultado.

## Vinculación con C4

La medición corresponde al componente **Controlador Geoespacial — `MascotaController`**, clasificado como `Implementado` en `dossier/07-c4-componentes.md`. La evidencia confirma que el componente expone el endpoint medido, pero todavía no representa una consulta geoespacial persistente.

La persistencia JPA y los componentes de adopción (`AdopcionController`, `AdopcionService`, `SolicitudAdopcionRepository` y `EtapaAdopcionRepository`) son componentes implementados y trazados por separado en el mismo documento C4. Su existencia no implica que sean invocados por `MascotaController` en la petición evaluada.

## Prueba de trazabilidad en 30 segundos

Cada elemento verificado de la tabla C4 puede abrirse directamente desde estas rutas existentes:

| Elemento verificado | Ruta de evidencia |
|---|---|
| `AdopcionController` | `app/src/main/java/com/patitasurbanas/api/controller/AdopcionController.java` |
| `AdopcionService` | `app/src/main/java/com/patitasurbanas/api/service/AdopcionService.java` |
| `SolicitudAdopcionRepository` | `app/src/main/java/com/patitasurbanas/api/repository/SolicitudAdopcionRepository.java` |
| `EtapaAdopcionRepository` | `app/src/main/java/com/patitasurbanas/api/repository/EtapaAdopcionRepository.java` |
| `EtapaAdopcion` y `SolicitudAdopcion` | `app/src/main/java/com/patitasurbanas/api/model/` |
| `spring-boot-starter-data-jpa` | `app/pom.xml` |
| `MascotaController` | `app/src/main/java/com/patitasurbanas/api/controller/MascotaController.java` |

## Conclusión

Para el endpoint actual de mascotas, el conteo as-is es **0 consultas SQL por petición**. La instrumentación queda preparada para detectar consultas cuando el controlador sea conectado a una capa de servicio y persistencia real, sin afirmar anticipadamente que esa funcionalidad ya existe.
