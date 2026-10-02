# EDAV 2 — Evidencia de Delegación, Auditoría y Validación
## Ciclo: Spike de fronteras modulares — Semana 9

> En Semana 9 se completan únicamente los campos que existen antes del resultado: metadatos de la especificación, §1 (especificación entregada) y las dos primeras filas de §2. El resto se completa después de la delegación y la auditoría en Semana 10.

## 0. Metadatos del ciclo

| Campo | Valor |
|---|---|
| Fecha de especificación | 2026-10-01 (versión inicial, `8a2a001`); completada 2026-10-02 (`99269dd`, `c16cd03`) |
| Fecha de auditoría | |
| Integrante(s) que redactan y firman este EDAV | |
| Herramienta/agente delegado | Claude Code (Anthropic) |
| Modelo/versión, si aplica | Se registra al iniciar la delegación (Semana 10) |
| Rama de trabajo | `spike/fronteras-modulares-s10` (control de Y2: `spike/control-y2-descartable`, no se integra) |
| Commit base | `887ccf1` |
| Commit del resultado delegado | |
| Artefacto(s) producido(s) por el agente | |

## 1. Especificación entregada al agente

### 1.1 Objetivo y alcance

Reorganizar las clases existentes de `com.patitasurbanas.api` en paquetes por dominio (`adopciones/`, `mascotas/`, `shared/`, `config/`; `veterinarias/` declarada sin clases) sin cambiar lógica, para probar ADR-01 y las reglas de ADR-02. Detalle: [04-spike-especificacion-s9.md §2 y §4](./04-spike-especificacion-s9.md).

### 1.2 Criterios de aceptación comunicados antes del resultado

Y4 = 100% de las 7 clases de producción en su módulo objetivo; Y5 = 0 paquetes que mezclan dominios; Y1 = 100% de los tests que pasaban antes siguen pasando; Y2 = 0 imports prohibidos; Y3 = 0 diferencias en S1–S3. Basta con que falle una métrica para refutar. Detalle: [04-spike-especificacion-s9.md §3](./04-spike-especificacion-s9.md).

### 1.3 Prompt exacto entregado

El prompt de [04-spike-especificacion-s9.md §6](./04-spike-especificacion-s9.md), en la versión del commit `c16cd03`. Si se entrega con cualquier variación, se copia aquí literalmente y se registra como desviación.

### 1.4 Entradas proporcionadas

Especificación del spike, ADR-01, ADR-02, `dossier/15-diseno-modular-s7.md`, árbol de clases bajo `app/src/main/java/com/patitasurbanas/api/`, suite de tests y solicitudes S1–S3 de §5. Detalle: [04-spike-especificacion-s9.md §6](./04-spike-especificacion-s9.md).

### 1.5 Restricciones e instrucciones de no modificar

No cambiar lógica, endpoints, `pom.xml`, `application.properties`, persistencia, Docker Compose ni infraestructura; no agregar ArchUnit, Spring Security, JPMS, bibliotecas ni microservicios; no editar ADRs ni documentos de semanas anteriores; no inventar código, mediciones ni evidencia; no cambiar criterios después de ver resultados. Detalle: [04-spike-especificacion-s9.md §4 y §6](./04-spike-especificacion-s9.md).

## 2. Evidencia temporal: especificación → commit → resultado

| Evento | Commit / hash | Fecha y hora | Evidencia verificable |
|---|---|---|---|
| Estado del repositorio antes de la delegación | `887ccf1` | 2026-10-01 22:48:50 -0500 | Merge del PR #45; último cambio en `app/`: `0a243b0` (2026-09-12) |
| Especificación registrada antes del resultado | `8a2a001`, `99269dd`, `c16cd03` | 2026-10-01 22:47:18 -0500; 2026-10-02 16:07:49 +0000; 2026-10-02 16:10:04 +0000 | `git log -- experimentos/04-spike-especificacion-s9.md`; ningún commit de `app/` posterior a `0a243b0` |
| Inicio de la delegación | | | |
| Primer resultado del agente | | | |
| Commit del resultado integrado en la rama de trabajo | | | |
| Auditoría humana | | | |
| Correcciones posteriores, si las hubo | | | |

### 2.1 Declaración de trazabilidad temporal


## 3. Resultado entregado por el agente antes de auditoría


## 4. Auditoría humana: hallazgos clasificados

### 4.1 Hallazgos sustantivos

| # | Hallazgo | Evidencia | Clasificación | Decisión (aceptado / rechazado / corregido) | Commit de corrección, si aplica |
|---|---|---|---|---|---|
| | | | | | |

### 4.2 Hallazgos cosméticos

| # | Hallazgo | Evidencia | Clasificación | Decisión (aceptado / rechazado / corregido) | Commit de corrección, si aplica |
|---|---|---|---|---|---|
| | | | | | |

## 5. Decisiones sobre las sugerencias

### 5.1 Aceptado tal cual


### 5.2 Rechazado


### 5.3 Corregido o modificado


## 6. Verificación del cambio

| Verificación | Comando o procedimiento | Evidencia/salida | Estado |
|---|---|---|---|
| Conteo antes de dependencias prohibidas | | | |
| Conteo después de dependencias prohibidas | | | |
| Cálculo de la métrica frente al umbral predefinido | | | |
| Suite de pruebas existente | | | |
| Comportamiento observable de endpoints | | | |

## 7. Qué no se alcanzó a verificar

-

## 8. Resultado integrado y responsabilidad de auditoría


Nombre(s): ______________________________

Fecha: ______________________________
