# Contexto del Sistema: Patitas Urbanas

## 1. Propósito del Sistema

Patitas Urbanas es una plataforma digital centralizada orientada a optimizar y transparentar los procesos de adopción de mascotas, integrando servicios veterinarios y redes de fundaciones. El sistema operará bajo una arquitectura cliente-servidor, apoyado en una base de datos relacional (PostgreSQL) para asegurar la integridad de las transacciones y aplicaciones cliente nativas (Android) y web, garantizando alta cohesión y bajo acoplamiento entre la capa de presentación y la persistencia de datos.

## 2. Mapeo de Stakeholders (Partes Interesadas)

Se identifican los siguientes actores clave que interactúan, regulan o se ven afectados por la arquitectura del sistema:

### Usuarios Finales (Adoptantes y Ciudadanos)

Interactúan principalmente a través de la aplicación móvil nativa. Sus atributos de calidad prioritarios son la usabilidad, el rendimiento de la interfaz gráfica y la privacidad de sus datos de ubicación (GeoPoints).

### Operadores (Fundaciones, Refugios y Veterinarias)

Utilizan la plataforma (especialmente el cliente web) para gestionar el ciclo de vida de las mascotas, procesar solicitudes de adopción (flujo TRX-02) y administrar perfiles de entidades. Requieren alta disponibilidad e integridad absoluta en los registros transaccionales.

### Equipo de Desarrollo e Ingeniería

Estudiantes de la Universidad de Bogotá Jorge Tadeo Lozano encargados del diseño, implementación y mantenimiento arquitectónico. Sus intereses técnicos radican en la mantenibilidad, trazabilidad del código, modularidad y adopción de patrones de diseño escalables.

### Entidades Regulatorias (Estado Colombiano)

Actores pasivos con alta influencia que imponen restricciones legales sobre el tratamiento de datos personales y la seguridad de la información.

## 3. Restricciones del Sistema

El diseño, la implementación y la evolución de Patitas Urbanas están limitados por las siguientes restricciones ineludibles:

### 3.1 Restricciones Técnicas

**Infraestructura de Datos:** Migración a un esquema relacional utilizando PostgreSQL. Las transacciones deben garantizar las propiedades ACID (Atomicidad, Consistencia, Aislamiento y Durabilidad), especialmente en operaciones de tablas interdependientes como `solicitud_adopcion` y `etapas_adopcion`.

**Cliente Móvil:** Desarrollo restringido a tecnologías nativas de Android (Kotlin y Jetpack Compose).

**Despliegue Web:** El cliente web debe ser compatible con la red de distribución de Vercel.

### 3.2 Restricciones Regulatorias y Legales

**Privacidad y Tratamiento de Datos:** Cumplimiento estricto de la normativa legal vigente (Ley 1581 de 2012 sobre Protección de Datos Personales). Es obligatorio implementar mecanismos técnicos de auditoría y consentimiento explícito (Opt-In) para el almacenamiento y procesamiento de datos sensibles.

### 3.3 Restricciones Organizacionales y de Tiempo

**Cronograma Operativo:** El desarrollo está sujeto a iteraciones de tiempo estricto. Se requiere alcanzar el hito de "Línea base operativa" (sistema ejecutándose y pruebas pasando) para la culminación de la Semana 2.

**Metodología de Integración:** Uso obligatorio de control de versiones con un flujo de trabajo centralizado en revisiones de código. Los documentos del dossier deben integrarse exclusivamente mediante Pull Requests fusionados.

### 3.4 Restricciones Económicas

**Presupuesto de Infraestructura:** El proyecto debe minimizar los costos operativos, lo que obliga a maximizar el uso de tecnologías de código abierto y arquitecturas que puedan operar dentro de los límites de las capas gratuitas (Free Tier) de los proveedores de nube durante las fases de desarrollo y pruebas.