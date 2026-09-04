# EDAV 1 — Evidencia de Delegación, Auditoría y Validación
## Ciclo: Generación y auditoría del modelo C4 (Nivel 1, 2 y 3)

> **Instrucciones de uso de esta plantilla:** cada sección tiene un bloque `> [RELLENAR]` con lo que deben completar. No borren las secciones aunque no tengan contenido para alguna — si algo no se puede demostrar, se declara explícitamente como "no verificable" en vez de omitirse. Eso es parte de lo que exige la ficha del curso: la honestidad sobre los límites de la auditoría es tan evaluable como la auditoría misma.

---

## 0. Metadatos del ciclo

| Campo | Valor |
|---|---|
| Fecha de esta auditoría | > [RELLENAR — fecha en que se llena este documento] |
| Integrante(s) que redactan y firman este EDAV | > [RELLENAR — nombre(s)] |
| Herramienta/agente delegado | > [RELLENAR — ej. "Claude", "Copilot Agent", "ChatGPT", etc.] |
| Artefacto producido por el agente | Diagramas C4 Nivel 1, 2 y 3 (`docs/05-c4-contexto.md`, `docs/06-c4-contenedores.md`, `docs/07-c4-componentes.md`) |

---

## 1. Especificación entregada al agente (antes del resultado)

> **[RELLENAR]** Pegar aquí, textualmente, el prompt o instrucción que le dieron al agente para que generara el primer C4. Si lo tienen en un historial de chat, cópienlo tal cual, sin reescribirlo con lo que "debieron haber pedido". Si no lo guardaron literal, escriban un resumen honesto de lo que recuerdan haber pedido y dejen constancia de que no es la cita exacta.

### 1.1 Objetivo y alcance declarados al agente
> [RELLENAR] — ej.: "Generar un modelo C4 (contexto, contenedores, componentes) del sistema Patitas Urbanas a partir del dossier arquitectónico existente."

### 1.2 Criterios de aceptación que se le comunicaron
> [RELLENAR] — ej.: "Debía distinguir elementos verificados en código de elementos planificados"; si no se le comunicó explícitamente este criterio antes de generar el primer resultado, decláralo aquí ("este criterio se aplicó recién en la fase de auditoría, no formaba parte de la especificación original").

### 1.3 Qué se le indicó explícitamente que NO debía modificar o inventar
> [RELLENAR] — ej.: "No debía asumir tecnologías no confirmadas en el pom.xml". Si no se le dio esta restricción de forma explícita, declárenlo — es un hallazgo válido para la sección 5 (qué no se verificó a tiempo).

---

## 2. Evidencia temporal (especificación → commit → resultado)

Esta sección es la que responde directamente a la pregunta de auditoría del tutor: *¿dónde está en Git la evidencia de que la especificación fue anterior al resultado?*

| Evento | Commit / hash | Fecha | Evidencia |
|---|---|---|---|
| Estado del repo justo antes de pedir el C4 al agente | (sin commit de referencia — ver 2.1) | — | No se identificó un commit específico previo dedicado a la especificación |
| Especificación/prompt commiteado (si aplica) | No commiteado — ver 2.1 | — | — |
| Primer resultado del agente integrado al repo | 1375f7d6428c317e3f3b113a5ef871db212459c6 | 2026-09-04 16:16:30 -0500 | `git show 1375f7d --stat` |
| Commit(s) de corrección tras la auditoría | 18ed28e71c2c1a4b036d1f023652b28bc2fae2a7 | 2026-09-04 17:18:26 -0500 | `git show 18ed28e --stat` |

### 2.1 Declaración de trazabilidad temporal

> **[RELLENAR — elegir una de las dos opciones y borrar la otra]**
>
> **Opción A (si la secuencia es demostrable):** "La especificación fue documentada/commiteada en `<hash>` con fecha `<fecha>`, anterior al commit `<hash>` donde se integró el resultado del agente (`<fecha>`). La secuencia hipótesis/especificación → resultado es reconstruible desde el historial de Git."
>
> **Opción B (si NO es demostrable):** "No existe un commit donde la especificación dada al agente haya quedado registrada antes del resultado. El prompt se dio fuera de Git (chat externo / conversación no versionada) y no se guardó evidencia commiteada previa al primer C4 generado. Se declara esta limitación de trazabilidad de forma explícita y no se reconstruye artificialmente una secuencia que no puede demostrarse. Consultado con el docente sobre cómo registrar este vacío: > [RELLENAR resultado de esa consulta, o 'pendiente de consultar']."

**Nota importante:** si aplica la Opción B, no reescriban ni reordenen commits para simular una secuencia que no ocurrió así. El propio mensaje del tutor lo advierte explícitamente: *"no borren ni reescriban la historia: documenten el problema de trazabilidad."*

---

## 3. Resultado entregado por el agente (antes de auditoría/corrección)

> **[RELLENAR]** Describir o adjuntar (como referencia a un commit específico, no como archivo nuevo) cómo era el C4 tal como lo entregó el agente, antes de que el equipo lo corrigiera. Si el archivo actual en `docs/` ya está corregido, señalen el commit anterior a las correcciones donde se puede ver la versión "cruda":

```
git show <hash-del-primer-resultado>:docs/06-c4-contenedores.md
```

Resumen de lo que el agente afirmó inicialmente que existía, sin haber sido todavía contrastado con el código:
> [RELLENAR — lista breve]

---

## 4. Auditoría humana: hallazgos clasificados

Reutilicen aquí lo que ya está en el "Registro de correcciones" de `docs/06-c4-contenedores.md` y `docs/07-c4-componentes.md`, pero clasificado explícitamente como pide la ficha (sustantivo vs. cosmético), con el commit donde se corrigió cada uno.

| # | Hallazgo | Clasificación | Commit de corrección | Evidencia que motivó el hallazgo |
|---|---|---|---|---|
| 1 | Firestore/MongoDB presentado como contenedor real | Sustantivo | > [RELLENAR hash] | Sin dependencia, servicio ni configuración en `docker-compose.yml`/`pom.xml`; decisión de arquitectura documentada en `dossier/02-stakeholders-drivers.md` (riesgo R-03) |
| 2 | Backend asumido como Next.js API Routes | Sustantivo | > [RELLENAR hash] | `app/pom.xml` (Spring Boot 3.3.4) y `app/Dockerfile` (Java 21) confirman lo contrario |
| 3 | `07-c4-componentes.md` afirmaba que no existían controladores | Sustantivo | > [RELLENAR hash — commit donde se corrigió, ver conversación previa] | Existe `MascotaController.java` en `app/src/main/java/com/patitasurbanas/api/controller/` |
| 4 | Duplicación de C4 Nivel 1/2 en `dossier/` con contenido desactualizado y contradictorio (Firestore/MongoDB sin marcar como eliminado) | Sustantivo | > [RELLENAR hash del `git rm`] | `dossier/05-c4-contexto.md` y `dossier/06-c4-contenedores.md` (ya eliminados) |
| 5 | > [RELLENAR — agregar cualquier hallazgo cosmético: redacción, formato, nombres de secciones, etc.] | Cosmético | > [RELLENAR] | > [RELLENAR] |

---

## 5. Qué aceptaron, qué rechazaron, qué corrigieron

### 5.1 Aceptado tal cual (sin cambios)
> [RELLENAR] — ej.: la estructura general de tres niveles C4, el uso de mermaid, la leyenda verificado/planificado.

### 5.2 Rechazado por completo
> [RELLENAR] — ej.: si el agente propuso algún contenedor o relación que se descartó enteramente sin integrarlo ni como "planificado".

### 5.3 Corregido
> [RELLENAR] — referencia a la tabla de la sección 4.

---

## 6. Qué NO se alcanzó a verificar

Esta sección es obligatoria y debe quedar honesta, no vacía. Ejemplos de lo que ya sabemos que sigue pendiente según las auditorías anteriores:

- > [RELLENAR] La cronología exacta de si la hipótesis de S3 (`p95 < 800 ms bajo 100 req/s`) fue commiteada antes o después de tener resultados de medición (pendiente de revisar commit `e75b94d` y compararlo con la fecha de la primera corrida).
- > [RELLENAR] Si existen más archivos o carpetas fuera de `app/`, `docs/`, `dossier/`, `experimentos/` que no fueron auditados en este ciclo.
- > [RELLENAR] Cualquier otro punto que el equipo sepa que no alcanzó a comprobar contra código antes de esta entrega.

---

## 7. Firma y responsabilidad de integración

> **[RELLENAR]**
>
> "Quien(es) suscribe(n) este documento confirma(n) haber revisado personalmente los hallazgos de la sección 4 contra el código fuente en `main`, y asume(n) la responsabilidad de defender cada fila de la tabla de trazado de `docs/07-c4-componentes.md` ante el docente, incluyendo poder señalar en menos de 30 segundos el archivo que sostiene cada elemento marcado como 'Verificado'."
>
> Nombre(s): _______________________
> Fecha: _______________________

---

## Anexo: preguntas de auditoría abiertas (heredadas de revisiones previas del tutor)

Estas preguntas quedaron señaladas por el tutor y no se resuelven solo con este documento — requieren que el equipo las conteste con evidencia de código o de Git:

1. ¿La hipótesis `p95 < 800 ms bajo 100 req/s` fue commiteada antes de tener resultados de medición? (Ver commit `e75b94d` y compararlo temporalmente con `experimentos/resultado-linea-base.txt`.)
2. ¿El equipo interpretó "mínimo tres corridas, descartar la primera" como tres corridas *totales* o tres corridas *válidas* además de la descartada? Esta es una pregunta de criterio que corresponde resolver con el docente, no unilateralmente.
3. Para cada fila "Verificado" de la tabla de trazado en `07-c4-componentes.md`: ¿puede el equipo, ante el profesor, abrir el archivo exacto en menos de 30 segundos?
