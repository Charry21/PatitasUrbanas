# C4 Nivel 1: Diagrama de Contexto

**Audiencia:** Patrocinadores, stakeholders de negocio y equipo de desarrollo.
**Propósito:** Visualizar el alcance del sistema Patitas Urbanas, identificando a los usuarios principales y las dependencias con plataformas externas.

```mermaid
C4Context
  title Diagrama de Contexto - Patitas Urbanas

  Person(ciudadano, "Ciudadano / Adoptante", "Busca adopciones, reporta animales perdidos o participa en la comunidad.")
  Person(admin, "Administrador de Refugio", "Encargado de gestionar la publicación de mascotas disponibles.")
  
  System(patitas, "Patitas Urbanas", "Plataforma centralizada para adopción de mascotas, rastreo de animales perdidos e interacción comunitaria.")
  
  System_Ext(mapas, "Servicio de Mapas y Geolocalización", "Proveedor externo que renderiza mapas interactivos y ubica refugios/reportes.")

  Rel(ciudadano, patitas, "Interactúa para buscar, reportar o debatir", "HTTPS")
  Rel(admin, patitas, "Gestiona el catálogo de adopciones", "HTTPS")
  Rel(patitas, mapas, "Solicita ubicaciones y renderizado geográfico", "API Externa")
```
