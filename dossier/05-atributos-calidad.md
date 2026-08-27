## Matriz de Atributos de Calidad Priorizada

| Prioridad | Atributo de Calidad | Justificación Arquitectónica |
|---|---|---|
| Alta | Rendimiento | La búsqueda espacial de mascotas perdidas exige respuestas inmediatas para la coordinación de rescates en tiempo real. |
| Alta | Seguridad | La gestión de datos personales de usuarios y fundaciones requiere el cumplimiento estricto de la Ley 1581 de 2012 de Colombia. |
| Media | Disponibilidad | La plataforma debe mantener operaciones continuas, aunque las interrupciones en ventanas de mantenimiento nocturno no representan un riesgo de pérdida de vida. |

## Escenario 1: Rendimiento (Búsqueda de Mascotas)

- **Fuente:** Usuario final interactuando mediante la aplicación cliente.
- **Estímulo:** Ejecución concurrente de múltiples consultas de geolocalización.
- **Artefacto:** API REST en Spring Boot y motor relacional PostgreSQL.
- **Entorno:** Operación normal del sistema bajo una carga máxima de 100 peticiones por segundo.
- **Respuesta:** El sistema procesa los parámetros espaciales y retorna un conjunto de datos paginado.
- **Medida:** La latencia de respuesta en el 95% de las transacciones (p95) debe ser estrictamente inferior a 800 milisegundos.

## Escenario 2: Seguridad (Control de Acceso)

- **Fuente:** Agente externo no autenticado.
- **Estímulo:** Intento de modificación o extracción de datos del módulo de adopciones sin un token JWT válido.
- **Artefacto:** Capa de seguridad y filtrado de la API.
- **Entorno:** Plataforma operativa expuesta a la red pública de internet.
- **Respuesta:** La arquitectura intercepta la petición, deniega el acceso y registra el evento en el log de auditoría del servidor.
- **Medida:** El 100% de los intentos de acceso no autorizados son bloqueados retornando un código HTTP 401 en menos de 500 milisegundos.
