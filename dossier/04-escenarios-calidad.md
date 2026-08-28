## Escenarios de Calidad Verificables

### Escenario 1: Rendimiento (Búsqueda de Mascotas)

- **Estímulo:** Ejecución concurrente de múltiples consultas de geolocalización.
- **Ambiente:** Operación normal del sistema bajo una carga máxima de 100 peticiones por segundo.
- **Respuesta:** El sistema procesa los parámetros espaciales y retorna un conjunto de datos paginado.
- **Medida:** La latencia de respuesta en el 95% de las transacciones (p95) debe ser estrictamente inferior a 800 milisegundos.

### Escenario 2: Seguridad (Control de Acceso)

- **Estímulo:** Intento de modificación o extracción de datos del módulo de adopciones sin un token JWT válido.
- **Ambiente:** Plataforma operativa expuesta a la red pública de internet.
- **Respuesta:** La arquitectura intercepta la petición, deniega el acceso y registra el evento en el log de auditoría del servidor.
- **Medida:** El 100% de los intentos de acceso no autorizados son bloqueados retornando un código HTTP 401 en menos de 500 milisegundos.

## Reformulación de Escenarios Propuestos por la IA

### Escenario Reformulado 1: Rendimiento en Consultas Espaciales (Riesgo R01)

* **Estímulo:** Ejecución sostenida de 500 consultas de proximidad geográfica por minuto.
* **Ambiente:** Entorno de producción bajo condiciones de tráfico pico.
* **Respuesta:** El orquestador de base de datos procesa las consultas espaciales sin degradar el rendimiento del resto de la API.
* **Medida:** El 99% de las consultas geográficas deben resolverse en menos de 1.2 segundos, mitigando la latencia identificada.

### Escenario Reformulado 2: Disponibilidad ante Fallos de Infraestructura (Riesgo R02)

* **Estímulo:** Caída inesperada y total del contenedor principal de la base de datos o de la API.
* **Ambiente:** Operación en producción.
* **Respuesta:** El orquestador detecta el fallo del servicio mediante health checks, reinicia el contenedor de manera automática y el balanceador de carga notifica el estado 503 temporal.
* **Medida:** El Tiempo Objetivo de Recuperación (RTO) no debe exceder los 120 segundos para restablecer el servicio a los clientes de Patitas Urbanas.
