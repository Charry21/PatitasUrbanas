# C4 Nivel 2: Diagrama de Contenedores

**Audiencia:** Arquitectos de software y desarrolladores.
**Propósito:** Desglosar el sistema en sus unidades de despliegue físico, evidenciando las decisiones tecnológicas reales y los flujos de comunicación internos.

```mermaid
C4Container
  title Diagrama de Contenedores - Patitas Urbanas
  UpdateLayoutConfig($c4ShapeInRow="2", $c4BoundaryInRow="1")

  Person(ciudadano, "Ciudadano / Adoptante", "Usuario final de la plataforma.")
  Person(admin, "Administrador de Refugio", "Gestor de datos de adopción.")

  System_Boundary(patitas_boundary, "Sistema Patitas Urbanas") {
    Container(web, "Front-end Web", "Next.js (SSR)", "Aplicación web optimizada para renderizado del lado del servidor.")
    Container(movil, "Front-end Móvil", "Kotlin, Jetpack Compose", "Aplicación nativa para dispositivos móviles.")

    Container(api, "API Backend", "Java 21, Spring Boot 3.3.4", "Contenedor central que expone endpoints RESTful de negocio y transacciones.")

    ContainerDb(db, "Base de Datos Transaccional", "PostgreSQL, PostGIS", "Persistencia relacional y espacial operada vía Spring Data JPA.")
    ContainerDb(cache, "Almacenamiento No Estructurado", "MongoDB / Firestore", "Almacenamiento rápido para foros comunitarios.")
  }

  System_Ext(mapas, "Servicio de Mapas", "Servicio externo de geolocalización.")

  Rel_D(ciudadano, web, "Navega y consulta", "HTTPS")
  Rel_D(ciudadano, movil, "Navega y reporta", "HTTPS")
  Rel_D(admin, web, "Administra catálogo", "HTTPS")

  Rel_D(web, api, "Consume servicios", "JSON/HTTPS")
  Rel_D(movil, api, "Consume servicios", "JSON/HTTPS")

  Rel_D(api, db, "Lee y escribe datos relacionales/espaciales", "JDBC/ORM")
  Rel_D(api, cache, "Lee y escribe hilos", "Controlador NoSQL")

  Rel_R(api, mapas, "Consulta coordenadas", "REST/SDK")
```
