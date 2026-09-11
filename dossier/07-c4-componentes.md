# C4 Nivel 3: Diagrama de Componentes (API Backend)

**Audiencia:** Equipo de desarrollo y arquitectos.
**Propósito:** Desglosar los módulos internos del contenedor API Backend y validar su estado real de implementación frente al código fuente.

## Tabla de Trazado (Auditoría As-Is)

| Componente C4 | Clase/Módulo Real | Estado | Evidencia en Código |
| :--- | :--- | :--- | :--- |
| Controlador de Adopciones | `AdopcionController` | Implementado | `app/src/main/java/.../controller/AdopcionController.java` |
| Servicio de Negocio | `AdopcionService` | Implementado | `app/src/main/java/.../service/AdopcionService.java` |
| Persistencia (Solicitudes) | `SolicitudAdopcionRepository` | Implementado | `app/src/main/java/.../repository/SolicitudAdopcionRepository.java` |
| Persistencia (Etapas) | `EtapaAdopcionRepository` | Implementado | `app/src/main/java/.../repository/EtapaAdopcionRepository.java` |
| Controlador Geoespacial | `MascotaController` | Implementado (Base) | `app/src/main/java/.../controller/MascotaController.java` |
| Gestión de Foros | N/A | Planificado | Inexistente en la base de código actual |

## Registro Formal de Correcciones
* **Qué mostraba inicialmente:** La documentación afirmaba que el módulo de Gestión de Adopciones carecía de servicios y repositorios de negocio.
* **Qué encontró el código:** La revisión de la rama `main` evidenció la existencia de `AdopcionController` y `AdopcionService` con anotaciones transaccionales, además de los repositorios asociados. Asimismo, se detectó la ausencia de la dependencia JPA en el motor de construcción.
* **Qué se corrigió:** Se modificó la Tabla de Trazado para reclasificar los componentes de adopción de "Planificados" a "Implementados". Se insertó la dependencia `spring-boot-starter-data-jpa` en `pom.xml` para respaldar la ejecución real del código detectado.
* **Por qué:** La trazabilidad exige que las afirmaciones arquitectónicas coincidan con la topología real del repositorio. Esta corrección sincroniza la evidencia documental con el estado as-is del sistema.
