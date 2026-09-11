# C4 Nivel 2: Diagrama de Contenedores

**Audiencia:** Arquitectos de software y desarrolladores.
**Propósito:** Desglosar el sistema en sus unidades de despliegue físico, evidenciando las decisiones tecnológicas reales y flujos internos.

```mermaid
C4Container
  title Diagrama de Contenedores - Patitas Urbanas

  Person(ciudadano, "Ciudadano / Adoptante", "Usuario final de la plataforma.")
  Person(admin, "Administrador de Refugio", "Gestor de datos de adopción.")
  System_Ext(mapas, "Servicio de Mapas", "Servicio externo de geolocalización.")

  System_Boundary(patitas_boundary, "Sistema Patitas Urbanas") {
    Container(web, "Front-end Web", "Next.js (SSR)", "Aplicación web optimizada para renderizado del servidor.")
    Container(movil, "Front-end Móvil", "Kotlin, Jetpack Compose", "Aplicación nativa móvil.")
    Container(api, "API Backend", "Java 21, Spring Boot 3.3.4", "Expone endpoints RESTful de negocio (ej. adopciones).")
    ContainerDb(db, "Base de Datos Transaccional", "PostgreSQL, PostGIS", "Persistencia operada vía Spring Data JPA.")
    ContainerDb(cache, "Almacenamiento No Estructurado", "MongoDB / Firestore", "Almacenamiento rápido para foros.")
  }

  Rel_D(ciudadano, web, "Navega y consulta", "HTTPS")
  Rel_D(ciudadano, movil, "Navega y reporta", "HTTPS")
  Rel_D(admin, web, "Administra catálogo", "HTTPS")
  Rel_D(web, api, "Consume servicios", "JSON/HTTPS")
  Rel_D(movil, api, "Consume servicios", "JSON/HTTPS")
  Rel_D(api, db, "Lee y escribe datos", "JDBC/ORM")
  Rel_D(api, cache, "Lee y escribe hilos", "Controlador NoSQL")
  Rel_R(api, mapas, "Consulta coordenadas", "REST/SDK")
```
