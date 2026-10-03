# Subdominios de Patitas Urbanas
## Módulo 5 · Entregable 1 — Modelo del dominio

---

## 1. Origen y alcance de este documento

Este documento formaliza como **subdominios y bounded contexts** los
límites que el equipo ya había declarado:

| Artefacto previo | Commit | Qué aportó |
|---|---|---|
| `dossier/15-diseno-modular-s7.md` | `bfeee97` (2026-09-13) | Módulos `adopciones/`, `mascotas/`, `veterinarias/`, `shared/`, `config/` y su responsabilidad |
| `adr/adr-02-modularidad.md` | Semana 7 | Reglas de dependencia entre módulos |
| `adr/adr-03-limites-y-comunicacion-modulos.md` | `403d7b5` (2026-10-02, S9) | Límites, API pública y comunicación entre módulos |
| `experimentos/06-spike-resultado-s10.md` | `e9bcd93` (S10) | Evidencia de que los límites de `adopciones/` y `mascotas/` se materializan sin coste funcional |

**Nota de temporalidad:** el Context Map se redacta en Semana 10, después
del spike. El preregistro del spike (`experimentos/04-spike-especificacion-s9.md`)
no dependió de este documento: se apoyó en `dossier/15` y en ADR-03, que
ya existían. Este documento no modifica ninguna hipótesis ni resultado.

Cada contexto se marca como **implementado**, **parcial** o **planificado**
según el código real de `main` (`app/src/main/java/com/patitasurbanas/api/`).

---

## 2. Clasificación de subdominios

| Subdominio | Tipo | Por qué ese tipo | Estado en el código |
|---|---|---|---|
| **Adopciones** | **Núcleo (core)** | Es el propósito del sistema (`dossier/01`: "transparentar los procesos de adopción"). Contiene la única regla de negocio crítica: TRX-02 (solicitud + etapa inicial atómicas, QA-02). Es lo que diferencia a Patitas Urbanas de un directorio de mascotas. | **Implementado**: paquete `adopciones/`, tablas `solicitud_adopcion` y `etapas_adopcion` |
| **Mascotas** | Soporte | Necesario para que haya adopciones (qué mascota se adopta, si está disponible, dónde está), pero no es la razón de ser del sistema. | **Parcial**: solo `MascotaController` con búsqueda geoespacial simulada; no hay entidad `Mascota` |
| **Veterinarias** | Soporte | Complementa el ciclo de vida de la mascota (`dossier/01`: "integrando servicios veterinarios"), sin intervenir en la decisión de adopción. | **Planificado**: módulo declarado sin clases |
| **Identidad y consentimiento** | Genérico | Usuarios, entidades (fundaciones, refugios, veterinarias) y Opt-In de la Ley 1581 (QA-01). Es un problema resuelto en cualquier sistema; no aporta diferenciación. | **Planificado**: no hay autenticación ni entidad de usuario |
| **Notificaciones** | Genérico | Avisar a usuarios y fundaciones de cambios de estado. Discutido en el mini-comité de Semana 8. | **Planificado**: no existe |

**Sistema externo (fuera del dominio):** Servicio de Mapas y Geolocalización
(`dossier/05-c4-contexto.md`), planificado y simulado; sin integración real.

`shared/` y `config/` **no son subdominios**: son módulos técnicos
(excepciones, DTOs comunes y configuración de Spring) sin conceptos de
negocio propios, según el criterio de admisión de ADR-02.

---

## 3. Por qué no se definen más contextos

| Candidato descartado | Razón |
|---|---|
| "Etapas de adopción" como contexto propio | `EtapaAdopcion` no tiene sentido sin `SolicitudAdopcion` y ambas deben escribirse en la misma transacción (TRX-02). Separarlas rompería QA-02. |
| "Búsqueda geoespacial" como contexto propio | Es una consulta sobre mascotas; no tiene conceptos propios distintos de `Mascota` y su ubicación. |
| "Fundaciones" separado de Identidad | Hoy la fundación solo aparece como actor que opera el sistema; no hay reglas propias que lo justifiquen. Se reconsidera si aparecen reglas de negocio de fundaciones (por ejemplo, cupos o verificación). |
| Contexto por tabla de base de datos | Un contexto se define por responsabilidad y lenguaje, no por tabla. |

---

## 4. Referencias

- [`responsabilidades-contextos.md`](./responsabilidades-contextos.md) — qué posee y qué no posee cada contexto.
- [`context-map.puml`](./context-map.puml) — Context Map con las relaciones.
- `dossier/01-contexto-sistema.md`, `dossier/02-stakeholders-drivers.md`, `dossier/05-c4-contexto.md`
- `dossier/15-diseno-modular-s7.md`, `adr/adr-02-modularidad.md`, `adr/adr-03-limites-y-comunicacion-modulos.md`

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 10 · Módulo 5 · Arquitectura de Software*
