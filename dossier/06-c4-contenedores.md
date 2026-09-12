# C4 Nivel 2: Diagrama de Contenedores

**Audiencia:** Arquitectos de software y desarrolladores.
**Propósito:** Desglosar el sistema en sus unidades de despliegue físico, evidenciando las decisiones tecnológicas reales y los flujos de comunicación internos.

## Diagrama de contenedores (as-is verificado)

```mermaid
C4Container
  title Diagrama de Contenedores - Patitas Urbanas (as-is verificado)

  Person(ciudadano, "Ciudadano / Adoptante", "Usuario final de la plataforma.")
  Person(admin, "Administrador de Refugio", "Gestor de datos de adopción.")

  System_Boundary(patitas_boundary, "Sistema Patitas Urbanas") {
    Container(api, "API Backend", "Java 21, Spring Boot 3.3.4", "Microservicio que expone endpoints REST para negocio y transacciones.")
    ContainerDb(db, "Base de Datos", "PostgreSQL 16", "Persistencia relacional operada mediante Spring Data JPA y el driver PostgreSQL.")
  }

  Rel_D(ciudadano, api, "Consulta y registra solicitudes", "JSON/HTTPS")
  Rel_D(admin, api, "Administra catálogo y adopciones", "JSON/HTTPS")
  Rel_D(api, db, "Lee y escribe datos relacionales", "JDBC/JPA")
```

## Elementos planificados (fuera del as-is)

Los siguientes elementos no tienen evidencia real de implementación en el repositorio y se mantienen solo como contexto de negocio, con estilo punteado para distinguirlos del estado actual.

```mermaid
flowchart LR
    subgraph FUT["Planificado / no implementado"]
        WEB["Front-end Web<br/>Next.js (SSR)"]
        MOVIL["Front-end Móvil<br/>Kotlin / Jetpack Compose"]
        CACHE["Almacenamiento No Estructurado<br/>MongoDB / Firestore"]
        MAPS["Servicio de Mapas y Geolocalización<br/>(sistema externo)"]
    end

    style WEB fill:#f5f5f0,stroke:#999999,color:#666666,stroke-dasharray: 4 3
    style MOVIL fill:#f5f5f0,stroke:#999999,color:#666666,stroke-dasharray: 4 3
    style CACHE fill:#f5f5f0,stroke:#999999,color:#666666,stroke-dasharray: 4 3
    style MAPS fill:#f5f5f0,stroke:#999999,color:#666666,stroke-dasharray: 4 3
```

## Trazabilidad de contenedores

| Contenedor del C4 | Evidencia real (archivo/ruta) | Estado |
|---|---|---|
| API Backend | `docker-compose.yml`, `app/pom.xml`, `app/src/main/java/com/patitasurbanas/` | Verificado |
| Base de Datos | `docker-compose.yml`, `app/src/main/resources/application.properties`, `app/src/test/resources/application-test.properties` | Verificado |

## Registro de correcciones

Antes el diagrama mostraba un contenedor web, móvil, caché NoSQL y un servicio de mapas como parte del sistema actual. Se corrigió a la realidad del repositorio: el backend es Spring Boot y la base de datos es PostgreSQL 16 sin PostGIS, evidenciado por `docker-compose.yml` y los artefactos de la app. Los elementos no implementados se mantienen como futuros con estilo punteado, sin mezclarlos con el as-is. Esta corrección evita presentar requisitos planeados como si ya estuvieran desplegados.

**Evidencia utilizada:** `docker-compose.yml`, `app/pom.xml`, `app/src/main/resources/application.properties`.
