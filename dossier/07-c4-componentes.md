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
| Controlador Geoespacial | `MascotaController` | Implementado | Expone el endpoint medido en Semana 4 |

**Registro Formal de Correcciones**
* **Qué mostraba inicialmente:** El documento afirmaba que no existían servicios, repositorios de negocio ni persistencia para el módulo de adopciones.
* **Qué encontró el código:** La auditoría sobre `main` desmintió esta carencia. Se localizaron las clases `AdopcionController`, `AdopcionService`, y los repositorios asociados que gestionan las entidades.
* **Qué se corrigió:** Se reclasificaron los componentes de adopción a estado "Implementado" en la tabla de trazado, referenciando directamente los endpoints y operaciones (ej. `@Transactional`) detectados.
* **Por qué:** El modelo C4 as-is no debe presentar como "planificado" o inexistente un módulo que el código demuestra que ya opera con respaldo de sus dependencias.
