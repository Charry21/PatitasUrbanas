# Hipótesis 2 de Localización - Semana 6

## Contexto

dossier/10-resultado-hipotesis-s6.md refutó que la mayor parte del tiempo de POST /api/adopciones estuviera en las consultas SQL (solo 2-9% del tiempo total). Esta segunda hipótesis busca localizar dónde está el resto del tiempo: ¿dentro del procesamiento de la aplicación (controlador/servicio/framework), o fuera de ella (red, cliente PowerShell, reenvío de puertos de Docker)?

## Hipótesis

Para la operación POST /api/adopciones, bajo una petición única y controlada, **más del 50% del tiempo total observado por el cliente ocurre FUERA de la ejecución interna del método del controlador** (es decir, en red, cliente PowerShell, o reenvío de puertos de Docker), no dentro del procesamiento de la aplicación Spring Boot.

## Métrica y fórmula de contraste

```
tiempo_controlador = tiempo medido con timestamps al entrar y salir del metodo AdopcionController.crearSolicitud (en ms, via logs)
tiempo_total_cliente = tiempo medido con Measure-Command en PowerShell (en ms)
proporcion_externa = (tiempo_total_cliente - tiempo_controlador) / tiempo_total_cliente * 100
```

## Instrumentación requerida

Se agregará un log temporal de medición (timestamp al inicio y al final del método crearSolicitud en AdopcionController) exclusivamente para esta medición. Se documentará el cambio de código por separado antes de ejecutar la medición.

## Criterio de refutación

Si `proporcion_externa` ≤ 50%, la hipótesis se considera **refutada**: la mayor parte del tiempo estaría dentro del procesamiento de la aplicación, no en la red ni en el cliente.

Si `proporcion_externa` > 50%, la hipótesis se considera **soportada** bajo estas condiciones específicas.

## Condiciones de medición

Misma línea base que dossier/09-hipotesis-localizacion-s6.md, con el commit adicional que agregue el log de instrumentación (se indicará el hash exacto en el resultado). Mínimo 3 corridas válidas, descartando la primera si muestra un tiempo anómalo (lección aprendida en experimentos/01-metodologia-medicion.md).

## Limitación reconocida de antemano

El log dentro del controlador no captura el tiempo de serialización de la respuesta HTTP de salida ni el tiempo de Tomcat antes de invocar el método del controlador; por lo tanto, 'tiempo_controlador' es una aproximación por defecto (subestima ligeramente el tiempo real de la aplicación), lo cual, si acaso, favorece a la hipótesis en vez de perjudicarla.

## Estado

Especificación registrada antes de instrumentar el código y antes de ejecutar la medición. Fecha: 12 de septiembre de 2026. El resultado se documentará en dossier/12-resultado-hipotesis2-s6.md.
