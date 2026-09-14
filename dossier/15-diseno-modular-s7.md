# 15 — Diseño Modular Objetivo · Semana 7
## Patitas Urbanas · Módulo 4

---

## 1. Propósito de este documento

Describir la organización modular propuesta para el sistema de Patitas
Urbanas, distinguiendo explícitamente entre el estado actual (as-is)
y el estado objetivo (to-be). Este documento no es el C4 as-is: el C4
describe lo que existe; este documento describe cómo debería
organizarse el sistema si se adopta la Alternativa B del documento
`14-comparacion-estilos-s7.md`.

---

## 2. Estado actual (as-is)

### Estructura de paquetes verificada

com.patitasurbanas.api
├── AdopcionController.java
├── AdopcionService.java
├── SolicitudAdopcionRepository.java
├── EtapaAdopcionRepository.java
├── MascotaController.java
├── SolicitudAdopcion.java
└── EtapaAdopcion.java


*Fuente: `dossier/07-c4-componentes.md`, auditoría sobre `main`.*

### Problemas identificados en el estado actual

**P-01 — Sin fronteras de módulo:** todas las clases están en el mismo
nivel de paquete. No hay separación visible entre el dominio de
adopciones y el de mascotas.

**P-02 — Dependencias no controladas:** cualquier clase puede importar
cualquier otra sin señal estructural. El compilador no impide que
`MascotaController` acceda directamente a `SolicitudAdopcionRepository`.

**P-03 — Dificultad de navegación:** a medida que se agreguen módulos
nuevos (veterinarias, donaciones, chat), el paquete único acumulará
decenas de clases sin organización visible.

**P-04 — Terminología incorrecta en C4:** el C4 Nivel 2 etiqueta el
backend como "Microservicio". El sistema es un monolito en capas. Esta
decisión corrige esa inconsistencia de terminología.

---

## 3. Estado objetivo (to-be)

### Estructura de paquetes propuesta

com.patitasurbanas.api
│
├── adopciones/
│ ├── AdopcionController.java (público — adaptador REST)
│ ├── AdopcionService.java (público — lógica de negocio)
│ ├── SolicitudAdopcionRepository.java (interno al módulo)
│ ├── EtapaAdopcionRepository.java (interno al módulo)
│ └── model/
│ ├── SolicitudAdopcion.java
│ └── EtapaAdopcion.java
│
├── mascotas/
│ ├── MascotaController.java (público — adaptador REST)
│ ├── MascotaService.java (público — lógica de negocio)
│ ├── MascotaRepository.java (interno al módulo)
│ └── model/
│ └── Mascota.java
│
├── veterinarias/
│ └── (por definir — sin código verificado aún)
│
├── shared/
│ ├── excepciones/
│ │ └── (excepciones base del sistema)
│ └── dto/
│ └── (tipos de respuesta compartidos entre módulos)
│
└── config/
└── (beans de infraestructura, seguridad, CORS)


---

## 4. Responsabilidad de cada módulo

| Módulo | Responsabilidad principal | Qué no debe hacer |
|---|---|---|
| `adopciones/` | Gestionar el ciclo completo de solicitudes de adopción y sus etapas | Conocer detalles internos de mascotas o veterinarias |
| `mascotas/` | Gestionar el registro y estado de mascotas | Conocer detalles internos de adopciones |
| `veterinarias/` | Gestionar citas y servicios veterinarios | Gestionar adopciones o donaciones |
| `shared/` | Proveer tipos y excepciones comunes reutilizables | Contener lógica de negocio de ningún dominio |
| `config/` | Configurar la infraestructura de Spring | Contener lógica de negocio ni acceso a datos |

---

## 5. Reglas de dependencia entre módulos

Las siguientes reglas definen qué dependencias están permitidas y
cuáles están explícitamente prohibidas:

### Permitidas

- Cualquier módulo puede depender de `shared/` para usar tipos
  comunes y excepciones base.
- Cualquier módulo puede depender de `config/` para recibir beans
  de infraestructura por inyección de dependencias.
- Un módulo puede invocar el **servicio público** de otro módulo
  si existe una relación de negocio justificada.

### Prohibidas

- Ningún módulo puede importar directamente un **repositorio**
  de otro módulo. Los repositorios son internos al módulo que
  los define.
- Ningún módulo puede importar directamente un **modelo** interno
  de otro módulo. Si se necesita compartir datos, se usa un DTO
  en `shared/`.
- `shared/` no puede importar ningún módulo de negocio.
- `config/` no puede importar lógica de negocio de ningún módulo.

### Diagrama de dependencias permitidas

adopciones ──→ shared
adopciones ──→ config
mascotas ──→ shared
mascotas ──→ config
adopciones ──→ mascotas (solo a través de MascotaService, si aplica)


Dependencias prohibidas:

adopciones ✗──→ MascotaRepository
mascotas ✗──→ SolicitudAdopcionRepository
shared ✗──→ adopciones
shared ✗──→ mascotas


---

## 6. Acoplamiento y cohesión esperados

### Acoplamiento

**Acoplamiento aferente (CA) por módulo:** número de módulos externos
que dependen de un módulo dado.

| Módulo | CA esperado | Observación |
|---|---|---|
| `shared/` | Alto | Es el único módulo del que todos dependen. Debe mantenerse estable y pequeño. |
| `adopciones/` | Bajo | Solo debería ser referenciado desde `config/` o tests. |
| `mascotas/` | Bajo-medio | Podría ser referenciado por `adopciones/` si la adopción necesita datos de la mascota. |
| `config/` | Bajo | Referenciado implícitamente por Spring, no por módulos de negocio. |

**Acoplamiento eferente (CE) por módulo:** número de módulos externos
de los que depende un módulo dado.

| Módulo | CE esperado | Observación |
|---|---|---|
| `adopciones/` | Bajo | Solo depende de `shared/` y posiblemente de `mascotas/` (servicio público). |
| `mascotas/` | Bajo | Solo depende de `shared/`. |
| `shared/` | Ninguno | No debe depender de ningún módulo de negocio. |

### Cohesión

El objetivo es que cada módulo tenga **cohesión funcional**: todas sus
clases existen para cumplir la misma responsabilidad de negocio.

Señal de baja cohesión a vigilar: si una clase dentro de `adopciones/`
tiene más lógica relacionada con mascotas que con adopciones, pertenece
al módulo equivocado.

---

## 7. Relación con el código actual

| Clase actual | Módulo objetivo | Estado |
|---|---|---|
| `AdopcionController` | `adopciones/` | Mover — sin cambios de lógica |
| `AdopcionService` | `adopciones/` | Mover — sin cambios de lógica |
| `SolicitudAdopcionRepository` | `adopciones/` | Mover — interno al módulo |
| `EtapaAdopcionRepository` | `adopciones/` | Mover — interno al módulo |
| `SolicitudAdopcion` | `adopciones/model/` | Mover — sin cambios de lógica |
| `EtapaAdopcion` | `adopciones/model/` | Mover — sin cambios de lógica |
| `MascotaController` | `mascotas/` | Mover — sin cambios de lógica |
| `MascotaService` | `mascotas/` | Crear — no existe aún |
| `MascotaRepository` | `mascotas/` | Crear — no existe aún |
| `Mascota` | `mascotas/model/` | Crear — no existe aún |

**Observación:** el módulo de mascotas actualmente solo tiene
`MascotaController` con respuesta estática. Las clases `MascotaService`,
`MascotaRepository` y `Mascota` deberán crearse cuando se implemente
la lógica real del dominio. No es un bloqueo para la reorganización
del módulo de adopciones.

---

## 8. Preguntas que este diseño permite responder

| Pregunta | Respuesta con el diseño modular |
|---|---|
| ¿Qué responsabilidad pertenece a cada módulo? | Definida en la sección 4 de este documento |
| ¿Qué módulo conoce a cuál? | Definido en las reglas de dependencia de la sección 5 |
| ¿Qué dependencia sería peligrosa? | Cualquier módulo importando un repositorio de otro módulo |
| ¿Qué cambio debería poder hacerse sin modificar todo el sistema? | Cambiar la lógica de adopciones sin tocar mascotas ni veterinarias |
| ¿Qué parte del diseño está observada hoy y cuál es propuesta? | As-is en sección 2; to-be en sección 3 |

---

## 9. Elementos sin suficiente evidencia

- El módulo `veterinarias/` no tiene código verificado en el
  repositorio. Su estructura interna se definirá cuando exista
  implementación real.
- No se conoce si existen tests unitarios que dependan de la
  estructura de paquetes actual. La reorganización debe verificar
  que los tests existentes siguen pasando.
- No se ha decidido si se usará ArchUnit para reforzar las reglas
  de dependencia estructuralmente. Esto queda como pregunta abierta
  para el mini-comité de Semana 8.

---

## 10. Referencias

| Artefacto | Ubicación | Relevancia |
|---|---|---|
| Comparación de estilos | `dossier/14-comparacion-estilos-s7.md` | Define la Alternativa B que este diseño implementa |
| C4 Nivel 3 (as-is) | `dossier/07-c4-componentes.md` | Estado actual verificado de los componentes |
| PR #22 | GitHub | Confirma cohesión natural del módulo de adopciones |
| PR #41 | GitHub | Confirma que adopciones opera de forma aislada |

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Fecha: 2026-09-13*
*Semana 7 · Módulo 4 · Arquitectura de Software*
