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

**Nota de auditoría:** este escenario está diseñado en la arquitectura del sistema, pero en el repositorio actual no existe dependencia de Spring Security en el [app/pom.xml](../app/pom.xml) ni código de autenticación implementado todavía. Por tanto, no hay evidencia real de medición de acceso ni de validación JWT; esta sección representa la estructura de diseño prevista y no un resultado verificado en ejecución.

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

## Escenarios Propuestos — Pendientes de Implementación

### QA-02 — Mantenibilidad e Integridad de Datos [Estado: propuesto, no medido]

- **Descripción:** Verificación de integridad transaccional en el flujo de adopción, garantizando que una operación con fallo simulado no deje registros huérfanos ni estados inconsistentes.
- **Evidencia pendiente:** Prueba de rollback de base de datos para confirmar que la transacción completa queda revertida y no persisten `SolicitudAdopcion` ni `EtapaAdopcion` cuando se lanza la excepción simulada.

### QA-03 — Revisión de Calidad de Código y Cobertura de Pruebas [Estado: propuesto, no medido]

- **Descripción:** Evaluación de mantenibilidad del backend, cobertura de pruebas unitarias/integración y claridad del diseño de servicios, controladores y repositorios.
- **Evidencia pendiente:** Medición de cobertura y revisión de complejidad del código para validar que la solución cumple estándares de mantenibilidad.

### BIZ-01 — Concurrencia y Consistencia del Flujo de Adopción [Estado: propuesto, no medido]

- **Descripción:** Ejecución simultánea de peticiones POST para la creación de solicitudes de adopción bajo carga concurrente, evaluando consistencia del negocio y ausencia de errores derivados de condiciones de carrera o deadlocks.
- **Evidencia pendiente:** Carga concurrente con k6 y análisis de errores HTTP, timeouts y percentil p95 para confirmar que el flujo de negocio no degrada ni queda incoherente.
