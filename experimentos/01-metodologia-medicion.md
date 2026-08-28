# Metodología y Resultados de Línea Base (Semana 4)

## 1. Trazabilidad de la Medición
* **Fecha de Ejecución:** 28 de agosto de 2026
* **Versión del Código (Commit Hash):** 4d13ad35b2b0eaa8a2938d05b28857d8c75ff697

## 2. Condiciones del Entorno (Hardware y Software)
* **Sistema Operativo:** Windows
* **Entorno de Ejecución:** Docker Desktop (WSL2)
* **Motor de Base de Datos:** PostgreSQL 16 (Contenedor local)
* **Microservicio:** Java 21 + Spring Boot 3.3.4 (Contenedor local)
* **Herramienta de Inyección de Carga:** k6

## 3. Método de Inyección de Carga
Se ajustó el modelo de inyección para garantizar la correspondencia con la hipótesis de la Semana 3. Se utilizó el ejecutor `constant-arrival-rate` de k6 para forzar una carga constante de exactamente 100 peticiones por segundo durante 40 segundos, permitiendo la asignación dinámica de VUs.

## 4. Datos Reales Obtenidos (Protocolo de 3 Corridas)
Se ejecutaron tres mediciones consecutivas bajo condiciones idénticas de entorno. En estricto cumplimiento del rigor estadístico, la primera corrida se descarta por ser un periodo de calentamiento de la Máquina Virtual de Java.

* **Corrida 1 (Descartada):** 4000 peticiones a 99.99 req/s. p95 = 3.82 ms.
* **Corrida 2 (Válida):** 4000 peticiones a 99.99 req/s. p95 = 2.78 ms.
* **Corrida 3 (Válida):** 4001 peticiones a 100.01 req/s. p95 = 2.73 ms.

**Cálculo de la Mediana Representativa:**
* **Mediana del p95 (Corridas 2 y 3):** 2.755 ms.
* **Disponibilidad y Códigos HTTP:** 100% de las peticiones respondieron HTTP 200 en las corridas válidas (0 fallos).

## 5. Contraste de Hipótesis Arquitectónica
* **Hipótesis (Semana 3):** p95 < 800 ms (bajo una carga de 100 peticiones/s).
* **Dato Experimental (Semana 4):** Mediana p95 = 2.755 ms.
* **Veredicto:** El sistema base aprueba el escenario. La latencia representativa se mantiene drásticamente por debajo del umbral crítico exigido bajo el estrés arquitectónico definido.

## 6. Variables de Invalidación
Esta medición de línea base perdería rigurosidad técnica si se presenta alguna de las siguientes alteraciones durante la corrida:
* Ejecución de procesos de alto consumo de CPU o E/S de disco en el sistema anfitrión.
* Limitaciones dinámicas de hipervisor aplicadas por WSL2 a los recursos de los contenedores Docker.
* Estrangulamiento térmico (thermal throttling) del procesador local por deficiencias de refrigeración.
