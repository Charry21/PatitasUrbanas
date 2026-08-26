# 03 - Drivers Arquitectónicos Priorizados

## 1. Atributos de Calidad (Prioridad Alta)
* **Seguridad y Privacidad:** Protección de datos sensibles de usuarios, adoptantes y fundaciones, garantizando el cumplimiento estricto de la Ley 1581 de 2012 (Protección de Datos Personales en Colombia).
* **Disponibilidad:** El sistema debe garantizar un *uptime* elevado, especialmente crítico para el módulo de rastreo de mascotas perdidas, donde el tiempo de respuesta es vital.
* **Interoperabilidad:** La API base debe soportar el consumo concurrente desde múltiples clientes (interfaces web y aplicaciones móviles nativas).

## 2. Restricciones Técnicas
* Uso mandatorio de contenedores Docker para estandarizar los entornos de desarrollo e integración.
* Motor relacional PostgreSQL como única fuente de verdad transaccional.
