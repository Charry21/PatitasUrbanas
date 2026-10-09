# Subdominios de Patitas Urbanas
## Módulo 5 · Entregable 1 — Modelo del dominio y Context Map

---

## 1. Origen y alcance de este documento

Los subdominios se derivan del análisis de
[`modelo-dominio.md`](./modelo-dominio.md): responsabilidades observables
en el código (RO1–RO6) y decisiones de negocio del equipo (D1–D9). **No** se
derivan del diseño modular to-be.

| Fuente | Qué aporta |
|---|---|
| Código de `main` (`app/src/main/java/com/patitasurbanas/api/`) | Lo único implementado: solicitud, etapa y TRX-02 (RO1–RO3) |
| `dossier/01-contexto-sistema.md`, `dossier/02-stakeholders-drivers.md` | Propósito del sistema, QA-01 (consentimiento), QA-02 (TRX-02), QA-03 (catálogo) |
| Decisiones D1–D9 (`modelo-dominio.md` §5) | Reglas de negocio que el código todavía no demuestra |
| `dossier/15-diseno-modular-s7.md`, ADR-03 | **Solo para contrastar**: el resultado coincide en parte con esos módulos, pero no se tomó de ellos |

**Contraste con el diseño modular previo:** `dossier/15` y ADR-03 declaran
`adopciones/`, `mascotas/` y `veterinarias/`. El análisis confirma los dos
primeros con argumentos propios (D3), redefine el tercero como *Atención
veterinaria* (D4: la veterinaria es un participante; lo que se modela es la
atención clínica) y agrega *Identidad*, que el diseño previo no tenía
aunque QA-01 lo exigía.

**Nota de temporalidad:** este documento se reescribió el 2026-10-09,
después del spike de Semana 10. No modifica ninguna hipótesis ni resultado
del spike, que se preregistró sobre `dossier/15` y ADR-03. El orden se
verifica con los commits y las horas de fusión de los PR, no solo con esta
fecha: [`experimentos/07-trazabilidad-temporal.md`](../../experimentos/07-trazabilidad-temporal.md).

Cada contexto se marca como **implementado**, **parcial** o **planificado**
según el código de `main`.

---

## 2. Clasificación de subdominios

| Subdominio | Tipo | Por qué ese tipo | Estado en el código |
|---|---|---|---|
| **Adopciones** | **Núcleo (core)** | Es el propósito del sistema (`dossier/01`: "transparentar los procesos de adopción"). Contiene la única regla crítica implementada (TRX-02, QA-02) y las reglas de proceso propias de Patitas Urbanas: etapas (D1), custodio que aprueba (D4) y compromiso de adopción (D5). | **Implementado** parcialmente: solicitud, etapa inicial y TRX-02; tablas `solicitud_adopcion` y `etapa_adopcion` |
| **Mascotas** | Soporte | Necesario para adoptar (D2: toda solicitud es por una mascota; D6: solo si está Disponible), con ciclo de vida propio (D3), pero no es lo que diferencia al sistema. | **Parcial**: solo `MascotaController` con respuesta simulada; no hay entidad `Mascota` |
| **Atención veterinaria** | Soporte | Complementa el cuidado de la mascota (D4: historial clínico, tratamientos, certificados) sin intervenir en la decisión de adopción. | **Planificado**: ninguna clase |
| **Identidad** | Genérico | Participantes, roles y autorización de tratamiento de datos (QA-01, Ley 1581; D5). Es un problema resuelto en cualquier plataforma; no aporta diferenciación. | **Planificado**: no hay autenticación ni entidad de usuario |

**Fuera del dominio modelado:**

- **Servicio de Mapas y Geolocalización** (`dossier/05-c4-contexto.md`):
  sistema externo, planificado y simulado.
- **Notificaciones:** consumidor futuro de eventos, sin reglas de negocio
  propias ni código (`modelo-dominio.md` §6).

`shared/` y `config/` **no son subdominios**: son módulos técnicos
(excepciones, DTOs comunes y configuración de Spring) sin conceptos de
negocio propios, según el criterio de admisión de ADR-02.

---

## 3. Por qué no se definen más contextos

| Candidato descartado | Razón |
|---|---|
| "Etapas de adopción" como contexto propio | D1: la etapa es el historial de la solicitud, no un concepto independiente. Además, solicitud y etapa deben escribirse en la misma transacción (TRX-02); separarlas rompería QA-02. |
| "Fundaciones" o "Refugios" como contexto propio | D4: fundación y refugio cumplen el mismo rol (custodio). Son participantes de Identidad y la custodia de cada animal la registra Mascotas. Se reconsidera si aparecen reglas propias de fundaciones (cupos, verificación). |
| "Consentimiento" como contexto propio | D5: hay dos consentimientos con dueños distintos. La autorización de datos es de Identidad; el compromiso de adopción, de Adopciones. Un contexto aparte no tendría reglas propias. |
| "Búsqueda geoespacial" como contexto propio | La búsqueda es una consulta sobre mascotas (R5). La única regla de ubicación —mismo municipio (D8)— es del proceso de adopción y vive en Adopciones; no queda nada propio para un contexto aparte. |
| "Notificaciones" como contexto | No tiene reglas de negocio: solo reaccionaría a hechos de otros contextos. Queda como consumidor futuro. |
| Contexto por tabla de base de datos | Un contexto se define por responsabilidad y lenguaje, no por tabla. |

---

## 4. Referencias

- [`modelo-dominio.md`](./modelo-dominio.md) — evidencia, glosario, inconsistencias y decisiones D1–D9.
- [`responsabilidades-contextos.md`](./responsabilidades-contextos.md) — qué posee y qué no posee cada contexto, relaciones y Context Map.
- [`context-map.puml`](./context-map.puml) ([PNG](./context-map.png)).
- `dossier/01-contexto-sistema.md`, `dossier/02-stakeholders-drivers.md`, `dossier/05-c4-contexto.md`
- `dossier/15-diseno-modular-s7.md`, `adr/adr-02-modularidad.md`, `adr/adr-03-limites-y-comunicacion-modulos.md`

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 10 · Módulo 5 · Arquitectura de Software*
