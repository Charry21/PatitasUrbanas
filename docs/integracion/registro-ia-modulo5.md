# Registro crítico de IA — Módulo 5 (dominio e integración)
## Entregable 10

**Herramienta:** Claude Code (Anthropic), usada para redactar los borradores
de `docs/dominio/` y `docs/integracion/` y para verificar el contrato contra
la aplicación en ejecución.

El trabajo delegado del spike 1 tiene su propia auditoría en
`experimentos/05-auditoria-ia-s9.md` (EDAV 2). Este registro cubre solo los
documentos del módulo 5 que no forman parte del spike.

La columna **Decisión del equipo** registra qué se aceptó, qué se rechazó y
por qué. Una propuesta no forma parte del dossier hasta que el equipo decide.

---

## 1. Propuestas de la IA y decisión del equipo

| # | Propuesta de la IA | Dónde | Decisión del equipo | Razón |
|---|---|---|---|---|
| IA-1 | Cinco contextos: Adopciones (núcleo), Mascotas y Veterinarias (soporte), Identidad y Notificaciones (genéricos) | `docs/dominio/subdominios.md` | Aceptado | Cada contexto tiene responsabilidad y datos propios distintos; coincide con los módulos de dossier/15 y ADR-03 |
| IA-2 | No crear contextos para "Etapas de adopción", "Búsqueda geoespacial" ni "Fundaciones" | `docs/dominio/subdominios.md` §3 | Aceptado | Separarlos rompería TRX-02 o no aportaría conceptos propios |
| IA-3 | Relaciones R1–R5 con Mascotas e Identidad como proveedores de Adopciones y ACL frente al Servicio de Mapas | `docs/dominio/responsabilidades-contextos.md` | Aceptado | Refleja quién necesita qué dato y protege los datos personales en Identidad |
| IA-4 | R1 (disponibilidad de mascota) síncrona en proceso, no por eventos | `docs/integracion/sincrono-vs-asincrono.md` | Aceptado | Una copia desactualizada permitiría asignar dos veces la misma mascota (QA-02) |
| IA-5 | Introducir `/api/v1` antes del primer cliente, no ahora | `docs/integracion/contrato-api.yaml` | Aceptado | No hay consumidores externos todavía; versionar ahora no protege a nadie |
| IA-6 | Eventos aceptados: `SolicitudAdopcionCreada`, `SolicitudAdopcionAvanzoDeEtapa`, `AdopcionConcretada`, `ConsentimientoRevocado` | `docs/integracion/eventos-candidatos.md` §1 | Aceptado | Son hechos del dominio con un consumidor concreto que puede enterarse después |
| IA-7 | Eventos rechazados: interacciones de interfaz, consultas, CRUD técnico y los que romperían QA-02 | `docs/integracion/eventos-candidatos.md` §2 | Aceptado | No son hechos del dominio o romperían QA-02 |
| IA-8 | No adoptar CQRS ni Event Sourcing | `docs/integracion/cqrs-event-sourcing.md` | Aceptado | Ninguno resuelve un problema medido y su costo es desproporcionado para el equipo (DA-03) |
| IA-9 | No introducir mensajería ni broker en ningún flujo actual | `docs/integracion/sincrono-vs-asincrono.md`, ADR-03 | Aceptado | Ningún flujo actual lo necesita; agregaría infraestructura (DA-03) |

---

## 2. Hallazgos verificados por ejecución (no son opinión de la IA)

| Hallazgo | Evidencia |
|---|---|
| `GET /api/mascotas/buscar` devuelve un cuerpo JSON con `Content-Type: text/plain` | `experimentos/spike-s10/contrato/verificacion-endpoints.txt` |
| No existe endpoint de lectura de solicitudes (`GET /api/adopciones` → 405) | Mismo archivo |
| Parámetros faltantes o no numéricos en la búsqueda → 400 con el error por defecto de Spring | Mismo archivo |

## 3. No verificado

- La respuesta 500 de `POST /api/adopciones` ante un fallo real de base de datos (no se puede provocar sin modificar el código).
- El costo de la llamada síncrona R1: `MascotaService` no existe todavía.
- Ninguna de las relaciones R1–R5 está implementada; el Context Map describe responsabilidades y decisiones, no código existente (salvo Adopciones y el endpoint simulado de Mascotas).

---

Revisado por: Charry Ríos Daniel Estiven · Fecha: 2026-10-03
