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
* **Entorno:** [Condición Hipotética/Futura] Sistema en producción operando con alta disponibilidad. (Nota: El sistema base actual en la Semana 3 consta de un único nodo de despliegue local; este escenario asume la futura implementación de un balanceador de carga y políticas de autorrecuperación).
* **Respuesta:** El orquestador hipotético detecta el fallo del servicio mediante health checks, reinicia el contenedor de manera automática y el balanceador de carga notifica el estado 503 temporal.
* **Medida:** El Tiempo Objetivo de Recuperación (RTO) no debe exceder los 120 segundos para restablecer el servicio a los clientes de Patitas Urbanas.

## 4. Registro de Trazabilidad de IA

Para cumplir con la política de uso de IA, a continuación se detalla el tratamiento de los escenarios propuestos originalmente por el agente evaluador:

* **Propuesta original de la IA:** Riesgo R02 - "El servidor principal puede sufrir una caída debido a un corte de energía, dejando la plataforma inaccesible".
* **Modificación realizada:** Se transformó este riesgo genérico de hardware en el *Escenario Reformulado 2*, enfocándolo en el fallo del contenedor lógico y definiendo un umbral de recuperación (RTO de 120 segundos).
* **Justificación de la modificación:** La sugerencia original carecía de métricas verificables y estructuración arquitectónica (estímulo, respuesta, medida). Se adaptó para que sea auditable mediante pruebas de estrés.
* **Propuestas descartadas:** Se rechazó en su totalidad el riesgo original R03 ("Altos costos de licenciamiento"), ya que la IA generó una alucinación técnica al afirmar que PostgreSQL requería licenciamiento corporativo pago.
