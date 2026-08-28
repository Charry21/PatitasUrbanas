# Metodología y Resultados de Línea Base (Semana 4)

## 1. Condiciones del Entorno (Hardware y Software)
* **Sistema Operativo:** Windows
* **Entorno de Ejecución:** Docker Desktop (WSL2)
* **Motor de Base de Datos:** PostgreSQL 16 (Contenedor local)
* **Microservicio:** Java 21 + Spring Boot 3.3.4 (Contenedor local)
* **Herramienta de Inyección de Carga:** k6

## 2. Método de Inyección de Carga
La medición empírica se ejecutó de forma local apuntando al endpoint de estado de salud (`/actuator/health`) de la API. El patrón de carga definió un máximo de 20 Usuarios Virtuales (VUs) distribuidos en tres fases transaccionales:
* **Fase 1 (Rampa de subida):** 0 a 20 VUs durante 10 segundos.
* **Fase 2 (Carga sostenida):** 20 VUs constantes durante 30 segundos.
* **Fase 3 (Rampa de bajada):** 20 a 0 VUs durante 10 segundos.

## 3. Datos Reales Obtenidos
Durante los 50 segundos de la prueba, el orquestador de k6 generó 809 iteraciones completas.

* **Disponibilidad del Servicio:** 100.00% (809 de 809 peticiones respondieron HTTP 200).
* **Tasa de Fallos:** 0.00%
* **Latencia Promedio (avg):** 4.41 ms
* **Latencia Mediana (med):** 2.88 ms
* **Latencia Máxima (max):** 820.28 ms
* **Percentil 90 (p90):** 3.82 ms
* **Percentil 95 (p95):** 4.33 ms
* **Throughput:** 16.17 peticiones por segundo.

## 4. Contraste de Hipótesis Arquitectónica
El escenario de rendimiento estipulado en la fase de diseño (Semana 3) definió como métrica de éxito que la latencia de respuesta en el 95% de las transacciones (p95) fuera estrictamente inferior a 800 milisegundos.

* **Hipótesis (Semana 3):** p95 < 800 ms
* **Dato Experimental (Semana 4):** p95 = 4.33 ms
* **Veredicto:** El sistema base actual aprueba el escenario. La arquitectura resuelve la carga impuesta con una latencia significativamente inferior al umbral límite, validando la eficiencia inicial del contenedor en Spring Boot.

## 5. Variables de Invalidación
Esta medición de línea base perdería rigurosidad técnica si se presenta alguna de las siguientes alteraciones durante la corrida:
* Ejecución de procesos de alto consumo de CPU o E/S de disco en el sistema anfitrión (ej. análisis heurísticos de antivirus).
* Limitaciones dinámicas de hipervisor aplicadas por WSL2 a los recursos de los contenedores Docker.
* Estrangulamiento térmico (thermal throttling) del procesador local por deficiencias de refrigeración.
