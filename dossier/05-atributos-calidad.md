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

## 3. Reformulación de Escenarios Propuetos por la IA

**Escenario Reformulado 1: Rendimiento en Consultas Espaciales (Riesgo R01)**

* **Fuente del Estímulo:** Sistema de monitoreo y pruebas de carga.
* **Estímulo:** Ejecución sostenida de 500 consultas de proximidad geográfica por minuto.
* **Artefacto:** Motor de base de datos PostgreSQL (con o sin PostGIS).
* **Entorno:** Entorno de producción bajo condiciones de tráfico pico.
* **Respuesta:** El orquestador de base de datos procesa las consultas espaciales sin degradar el rendimiento del resto de la API.
* **Medida de Respuesta:** El 99% de las consultas geográficas deben resolverse en menos de 1.2 segundos, mitigando la latencia identificada.

**Escenario Reformulado 2: Disponibilidad ante Fallos de Infraestructura (Riesgo R02)**

* **Fuente del Estímulo:** Interrupción en la capa de hardware o red.
* **Estímulo:** Caída inesperada y total del contenedor principal de la base de datos o de la API.
* **Artefacto:** Orquestador de contenedores (Docker Compose).
* **Entorno:** Operación en producción.
* **Respuesta:** El orquestador detecta el fallo del servicio mediante health checks, reinicia el contenedor de manera automática y el balanceador de carga notifica el estado 503 temporal.
* **Medida de Respuesta:** El Tiempo Objetivo de Recuperación (RTO) no debe exceder los 120 segundos para restablecer el servicio a los clientes de Patitas Urbanas.
