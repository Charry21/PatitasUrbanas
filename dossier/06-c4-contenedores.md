# C4 Nivel 2: Diagrama de Contenedores

**Audiencia:** Arquitectos de software y desarrolladores.
**Propósito:** Desglosar el sistema en sus unidades de despliegue físico, evidenciando las decisiones tecnológicas reales y los flujos de comunicación internos.

```mermaid
C4Container
  title Diagrama de Contenedores - Patitas Urbanas

  Person(ciudadano, "Ciudadano / Adoptante", "Usuario final de la plataforma.")
  Person(admin, "Administrador de Refugio", "Gestor de datos de adopción.")
  System_Ext(mapas, "Servicio de Mapas", "Servicio externo de geolocalización.")

  System_Boundary(patitas_boundary, "Sistema Patitas Urbanas") {
    Container(web, "Front-end Web", "Next.js (SSR)", "Aplicación web optimizada para renderizado del lado del servidor.")
    Container(movil, "Front-end Móvil", "Kotlin, Jetpack Compose", "Aplicación nativa para dispositivos móviles.")
    
    Container(api, "API Backend", "Java 21, Spring Boot 3.3.4", "Contenedor central que expone endpoints RESTful y gestiona reglas de negocio.")
    
    ContainerDb(db, "Base de Datos Transaccional", "PostgreSQL, PostGIS", "Persistencia relacional y espacial de usuarios, mascotas e historiales.")
    ContainerDb(cache, "Almacenamiento No Estructurado", "MongoDB / Firestore", "Almacenamiento rápido para foros comunitarios.")
  }

  Rel(ciudadano, web, "Navega y consulta", "HTTPS")
  Rel(ciudadano, movil, "Navega y reporta", "HTTPS")
  Rel(admin, web, "Administra catálogo", "HTTPS")
  
  Rel(web, api, "Consume servicios", "JSON/HTTPS")
  Rel(movil, api, "Consume servicios", "JSON/HTTPS")
  
  Rel(api, db, "Lee y escribe datos relacionales/espaciales", "JDBC/TCP")
  Rel(api, cache, "Lee y escribe hilos de discusión", "Controlador NoSQL")
  Rel(api, mapas, "Consulta coordenadas", "REST/SDK")
```
