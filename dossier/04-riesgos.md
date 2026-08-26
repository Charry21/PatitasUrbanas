# 04 - Inventario y Clasificación de Riesgos Arquitectónicos

| ID | Riesgo Propuesto | Clasificación | Justificación Técnica |
|---|---|---|---|
| R01 | Latencia elevada al procesar consultas espaciales (geolocalización) de mascotas perdidas en PostgreSQL estándar sin extensiones adicionales. | **Válido** | PostgreSQL estándar no está optimizado para cálculos de proximidad geográfica. Se requerirá integrar PostGIS si el volumen de datos espaciales crece. |
| R02 | El servidor principal puede sufrir una caída debido a un corte de energía, dejando la plataforma inaccesible. | **Genérico** | Es un riesgo universal para cualquier sistema informático; no aporta valor específico al análisis de esta arquitectura de software. |
| R03 | Altos costos de licenciamiento corporativo por el uso del motor de base de datos relacional. | **Falso** | PostgreSQL es un sistema gestor de bases de datos de código abierto y licencia libre; no incurre en gastos de licenciamiento comercial. |
| R04 | Dificultad para renderizar componentes del frontend si el protocolo de comunicación con la base de datos no es directo. | **Irrelevante** | Las aplicaciones cliente modernas (web o móviles) no deben comunicarse directamente con la base de datos por principios básicos de seguridad; siempre deben interactuar mediante la API, por lo que este riesgo expone una mala práctica, no un riesgo de la arquitectura actual. |
