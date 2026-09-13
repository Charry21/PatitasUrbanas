# Resultado de la Hipótesis 2 de Localización - Semana 6

Contrasta la hipótesis registrada en dossier/11-hipotesis2-localizacion-s6.md, instrumentada mediante el log agregado en app/src/main/java/com/patitasurbanas/api/controller/AdopcionController.java (MEDICION_S6_CONTROLADOR_MS).

## Procedimiento ejecutado

Se reconstruyó el contenedor de la API con la instrumentación de timing. Se ejecutaron 4 peticiones POST /api/adopciones?estado=PENDIENTE&nombreEtapa=SOLICITUD_RECIBIDA, cronometrando el tiempo total con Measure-Command en PowerShell y extrayendo el tiempo interno del controlador del log MEDICION_S6_CONTROLADOR_MS. La corrida 1 se descartó por warm-up tras el rebuild (patrón ya documentado en experimentos/01-metodologia-medicion.md). Las corridas 2, 3 y 4 se consideran válidas.

## Datos observados

| Corrida | Tiempo total cliente (ms) | Tiempo controlador (ms) | Proporción externa |
|---|---:|---:|---:|
| 1 (descartada) | 387.94 | 117.29 | 69.77% |
| 2 (válida) | 20.81 | 10.85 | 47.87% |
| 3 (válida) | 18.53 | 9.59 | 48.28% |
| 4 (válida) | 27.77 | 15.97 | 42.49% |

Mediana de la proporción externa (corridas válidas 2, 3, 4): 47.87%

## Contraste contra el criterio de refutación

El criterio pre-registrado establecía: si `proporcion_externa` ≤ 50%, la hipótesis se considera refutada.

La mediana observada (47.87%) es menor a 50%, por lo que, según el criterio pre-registrado, **la hipótesis se considera REFUTADA**.

## Veredicto con matiz honesto

A diferencia del resultado de dossier/10-resultado-hipotesis-s6.md (donde la proporción de base de datos fue de solo 2-9%, un no rotundo), este resultado es un caso límite: la proporción externa (42-48%) está muy cerca del umbral de 50%, no lejos de él. La interpretación más honesta no es "la mayoría del tiempo está claramente dentro de la aplicación", sino que **el tiempo se reparte de forma aproximadamente equilibrada entre el procesamiento interno del controlador/servicio y factores externos (red, cliente, reenvío de puertos de Docker)**, con una leve inclinación hacia el lado interno.

## Observación adicional (no diagnóstico)

Esta medición no descompone qué parte específica del tiempo interno del controlador corresponde a la llamada al servicio (que ya se sabe que en su mayoría no es tiempo de SQL, según dossier/10-resultado-hipotesis-s6.md) frente a otros factores dentro de la JVM (serialización del objeto Map de respuesta, overhead de Spring). Tampoco descompone el lado externo entre red real y overhead del proceso cliente de PowerShell. Profundizar en esa descomposición corresponde a un análisis posterior.

## Limitación reconocida

Como se anticipó en la especificación, el tiempo del controlador no incluye la serialización de salida ni el tiempo previo de Tomcat, por lo que el tiempo interno real de la aplicación podría ser ligeramente mayor al reportado, lo cual refuerza (no debilita) la conclusión de refutación.
