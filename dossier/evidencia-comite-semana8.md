# Evidencia — Mini-comité Semana 8
## Rol de comité evaluando el ADR de otro equipo

---

## Datos de la sesión

| Campo | Valor |
|---|---|
| Fecha | 2026-09-18 |
| Equipo evaluado | Patitas Urbanas — https://github.com/Charry21/PatitasUrbanas.git |
| Rol asumido | ☐ CTO&nbsp;&nbsp;☒ Seguridad&nbsp;&nbsp;☐ Finanzas |
| ADR revisado del otro equipo | Patitas Urbanas — https://github.com/Charry21/PatitasUrbanas/tree/main/adr |
| Evaluador(es) | Kevin Steven Torres Caro · Charry Ríos Daniel Estiven |

---

## Resumen de la decisión evaluada

El equipo evaluado mantiene su monolito en capas (Spring Boot + PostgreSQL 16 vía Docker Compose) para el núcleo del sistema, pero extrae un **microservicio de notificaciones** que envía mensajes a usuarios y fundaciones (WhatsApp Business API y correo electrónico) cuando cambia el estado de una solicitud de adopción. Es el primer canal del sistema hacia un proveedor externo, lo que introduce superficie de red y de datos personales que el resto del monolito no maneja hoy.

---

## Preguntas realizadas

1. ¿Qué datos personales viajan hacia el microservicio de notificaciones y hacia el proveedor externo (WhatsApp/correo), y cómo se protegen en tránsito (TLS, cifrado de payload)?
   - **Respuesta del equipo:** Los datos que viajarían son el identificador del usuario/mascota, el nombre y el dato de contacto necesario para el canal (teléfono para WhatsApp, correo para email), más el contenido del mensaje (por ejemplo, el estado de una solicitud de adopción o un recordatorio). No se envían credenciales ni datos sensibles adicionales al proveedor. En tránsito se espera TLS en todos los saltos: monolito → microservicio de notificaciones (HTTPS interno) y microservicio → API del proveedor (WhatsApp Business API o SMTP con STARTTLS/TLS implícito), con el payload limitado a los campos estrictamente necesarios (minimización de datos); si el mensaje pasa por un broker (RabbitMQ/Kafka) antes de enviarse, ese canal también debe ir cifrado. A la fecha el microservicio de notificaciones no está en el repositorio, por lo que esto es el diseño previsto y el cifrado en tránsito se garantizará antes de exponer el canal a producción.

2. ¿Cómo se autentica el microservicio de notificaciones frente al monolito principal? ¿Cualquier proceso interno puede invocarlo sin control, o hay una interfaz de servicio explícita?
   - **Respuesta del equipo:** No debería poder invocarse desde cualquier proceso interno sin control. Se espera una interfaz de servicio explícita (REST interno o cola de eventos) protegida por uno de: API key/secret compartido, OAuth2 client credentials, o mTLS si los servicios comparten red de contenedores. Dado que hoy el proyecto es un monolito con una sola base de datos (`patitas_urbanas`) según el README, y el microservicio de notificaciones aún no existe como servicio separado, la respuesta es que se diseñará como servicio independiente con autenticación por API key/token, sin invocación abierta; actualmente no está desplegado.

3. Al introducir un canal nuevo hacia un tercero, ¿evaluaron el cumplimiento de la Ley 1581 de 2012 para el tratamiento de datos personales que salen del proceso hacia ese proveedor externo?
   - **Respuesta del equipo:** No se ha hecho una evaluación formal de cumplimiento de la Ley 1581 de 2012 para este canal; se identifica como pendiente antes de habilitar el envío a producción. Los puntos que esa evaluación deberá cubrir son: (a) si el envío a WhatsApp/proveedor de correo constituye una "transmisión" o "transferencia" de datos que requiera un contrato de encargo de tratamiento con ese tercero; (b) si la política de tratamiento de datos y la autorización que firma el usuario ya contemplan este nuevo canal y finalidad; (c) si se aplicó minimización de datos, enviando solo el dato de contacto necesario y no el histórico completo del usuario.

---

## Veredicto emitido

☐ **Confirmada** — la decisión está bien sustentada, sin condiciones.
☒ **Ajustada** — válida, pero con la siguiente condición:
   Definir y documentar cifrado en tránsito hacia el proveedor externo y un mecanismo explícito de autenticación entre el monolito y el microservicio de notificaciones, antes de integrar el proveedor en un ambiente con datos reales.
☐ **Reconsiderada** — falta evidencia o el costo no se justifica porque:
   _(no aplica)_

**Justificación breve del veredicto:**
Desde Seguridad, extraer las notificaciones a un servicio separado es razonable y no compromete por sí mismo el cumplimiento de la Ley 1581 de 2012, pero introduce el primer canal de red hacia un tercero del sistema. Mientras ese canal no tenga cifrado en tránsito y autenticación entre servicios documentados, el riesgo de exposición de datos personales queda sin control verificable, de ahí la condición y no una confirmación sin reservas.

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 8 · Módulo 4 · Arquitectura de Software*
