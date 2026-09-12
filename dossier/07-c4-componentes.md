# C4 Nivel 3: Diagrama de Componentes (API Backend)

**Audiencia:** Equipo de desarrollo y arquitectos.
**Propósito:** Desglosar los módulos internos del contenedor API Backend y validar su estado real de implementación frente al código fuente.

**Tabla de Trazado (Auditoría As-Is)**

| Componente C4 | Clase/Módulo Real | Estado | Evidencia en Código |
| :--- | :--- | :--- | :--- |
| Controlador de Adopciones | `AdopcionController` | Implementado | Expone `POST /api/adopciones` y `POST /api/adopciones/test-fallo` |
| Servicio de Adopciones | `AdopcionService` | Implementado | Contiene operación `@Transactional` (`crearSolicitudConEtapaInicial`) |
| Repositorio (Solicitudes) | `SolicitudAdopcionRepository` | Implementado | Importado y utilizado por `AdopcionService` |
| Repositorio (Etapas) | `EtapaAdopcionRepository` | Implementado | Importado y utilizado por `AdopcionService` |
| Entidades de Dominio | `EtapaAdopcion`, `SolicitudAdopcion` | Implementado | Modelos respaldados por JPA |
| Dependencia de Persistencia | `spring-boot-starter-data-jpa` | Implementado | Declarada en `app/pom.xml` |
| Controlador Geoespacial | `MascotaController` | Implementado como endpoint local de simulación (no realiza consulta geoespacial real ni integración con proveedor externo de mapas) | Expone el endpoint medido en Semana 4; el comentario del código indica: "Simulación de carga de respuesta para la medición de la línea base S4" |

**Registro Formal de Correcciones**
* **Qué mostraba inicialmente:** La documentación no reflejaba los servicios, repositorios de negocio ni la persistencia JPA que forman parte del módulo de adopciones.
* **Qué encontró el código:** La auditoría sobre `main` confirmó las clases `AdopcionController`, `AdopcionService`, los repositorios asociados y las entidades respaldadas por JPA.
* **Qué se corrigió:** Se actualizaron los componentes de adopción a estado "Implementado" en la tabla de trazado, referenciando directamente los endpoints, la operación `@Transactional` y la dependencia `spring-boot-starter-data-jpa`.
* **Por qué:** El modelo C4 as-is debe representar fielmente el código actual y sus dependencias de persistencia.
