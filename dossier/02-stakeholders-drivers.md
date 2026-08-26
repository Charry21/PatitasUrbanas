# Drivers Arquitectónicos y Análisis de Riesgos

## 1. Relación de Stakeholders y Preocupaciones Arquitectónicas

Las decisiones de diseño del sistema Patitas Urbanas se fundamentan en satisfacer las necesidades críticas de los siguientes actores:

- **Usuarios Finales (Adoptantes):** Su principal preocupación es la fluidez de la interfaz móvil (desarrollada en Kotlin/Jetpack Compose) y la garantía de privacidad sobre sus datos personales y de ubicación, conforme a la legislación colombiana.
- **Fundaciones y Veterinarias:** Requieren alta consistencia en los datos. Su operatividad depende de que las transacciones de adopción (TRX-02) no presenten estados huérfanos o inconsistentes.
- **Equipo de Ingeniería:** Prioriza la mantenibilidad del código, la integridad referencial en la base de datos PostgreSQL y la capacidad de ejecutar pruebas locales de forma reproducible.

## 2. Drivers Arquitectónicos Preliminares (Priorizados)

Estos drivers guiarán las decisiones estructurales del sistema base, priorizando la seguridad y la integridad transaccional.

### 2.1 Drivers de Calidad

- **QA-01 Seguridad y Cumplimiento Normativo (Prioridad Alta):** El sistema debe garantizar el cumplimiento de la Ley 1581 de 2012.

	**Escenario:** Cuando un usuario se registra, el sistema de autenticación debe requerir y almacenar de forma inmutable un Opt-In explícito. Los controladores del backend deben denegar cualquier escritura en PostgreSQL si el token del usuario no posee los permisos requeridos.

- **QA-02 Mantenibilidad e Integridad de Datos (Prioridad Alta):** Garantizar la trazabilidad y consistencia del modelo relacional.

	**Escenario:** Durante el procesamiento del módulo TRX-02 (Adopción), las inserciones en las tablas `solicitud_adopcion` y `etapas_adopcion` deben ejecutarse dentro de un bloque transaccional atómico. Si ocurre un fallo en el servidor, la transacción debe aplicar un *rollback* automático para evitar registros huérfanos.

- **QA-03 Rendimiento (Prioridad Media):** Optimización del consumo de recursos en el cliente móvil.

	**Escenario:** Al consultar el catálogo de mascotas disponibles o veterinarias cercanas, el cliente Android no debe sufrir desbordamientos de memoria (OOM). Se requiere implementar paginación en las consultas SQL y agrupamiento espacial (clustering) en la vista del mapa.

### 2.2 Drivers de Negocio

- **BIZ-01 Viabilidad Operativa:** El sistema debe operar de manera eficiente dentro de los recursos de infraestructura asignados, optimizando las consultas a la base de datos relacional para soportar concurrencia (ej. 500 solicitudes simultáneas en pruebas de estrés) sin incurrir en bloqueos de tablas (*table locks*) prolongados.

## 3. Inventario Inicial de Riesgos y Evaluación Crítica (Uso de IA)

En cumplimiento con el protocolo de adopción del sistema base, se presenta el análisis y la clasificación de los riesgos iniciales propuestos para la arquitectura, depurando aquellos correspondientes a modelos tecnológicos descartados.

### 3.1 Tabla de Riesgos

| ID | Riesgo Propuesto | Clasificación | Justificación y Veredicto Técnico |
|---|---|---|---|
| R-01 | Vulneración de datos sensibles mediante Inyección SQL en los formularios de adopción. | **Válido** | Al migrar de un modelo NoSQL a un esquema relacional (PostgreSQL), la inyección SQL se convierte en un vector de ataque directo. Es imperativo el uso de consultas parametrizadas o un ORM robusto en el backend. |
| R-02 | Inconsistencia de datos por caída de red durante el cambio de estado de una mascota. | **Válido** | Los clientes móviles operan en redes inestables. Si la petición se interrumpe, la base de datos relacional debe manejar la concurrencia y el *rollback* para mantener las propiedades ACID. |
| R-03 | Sobrecostos exponenciales y bloqueos por límite de escritura de 1 documento por segundo. | **Irrelevante / Falso** | Riesgo heredado del análisis de la arquitectura anterior basada en Firestore. Al utilizar PostgreSQL, esta limitación técnica específica desaparece, dependiendo ahora de la capacidad de procesamiento del servidor relacional. |
| R-04 | Desbordamiento de memoria (OOM) en la aplicación Android al renderizar el mapa de emergencias. | **Válido** | Jetpack Compose requiere una gestión de estado cuidadosa. Cargar miles de GeoPoints simultáneamente en la interfaz gráfica saturará la memoria del dispositivo cliente. Requiere mitigación arquitectónica en la capa de presentación. |
| R-05 | El sistema es susceptible a ataques DDoS que saturen los puertos de la base de datos. | **Genérico** | Es un riesgo aplicable a cualquier sistema expuesto a internet. Para mitigarlo, la base de datos PostgreSQL debe operar en una red privada (VPC), accesible únicamente por las instancias del backend, nunca expuesta directamente a la red pública. |
