# EDAV 1 — Evidencia de Delegación, Auditoría y Validación
## Ciclo: Generación y auditoría del modelo C4 (Nivel 1, 2 y 3)

---

## 0. Metadatos del ciclo

| Campo | Valor |
|---|---|
| Fecha de esta auditoría | 2026-09-04 |
| Integrante(s) que redactan y firman este EDAV | [Kevin Torres / Daniel Charry] |
| Herramienta/agente delegado | Gemini / Tutor(Chatgpt) |
| Artefacto producido por el agente | Diagramas C4 Nivel 1, 2 y 3 (`docs/05-c4-contexto.md`, `docs/06-c4-contenedores.md`, `docs/07-c4-componentes.md`) |

---

## 1. Especificación entregada al agente (antes del resultado)

### 1.1 Objetivo y alcance declarados al agente
Generar la estructura y documentar el modelo C4 (Contexto, Contenedores, Componentes) del sistema Patitas Urbanas, asegurando la alineación con el código fuente implementado en Java 21, Spring Boot 3.3.4 y PostgreSQL con extensiones espaciales.

### 1.2 Criterios de aceptación que se le comunicaron
El modelo debía distinguir de forma estricta los elementos verificados en el código (backend actual) de los elementos planificados o en fase de diseño. Además, se exigió incluir tablas de trazabilidad arquitectónica que vincularan los componentes diagramados con el código fuente.

### 1.3 Qué se le indicó explícitamente que NO debía modificar o inventar
No debía asumir tecnologías no confirmadas en el archivo `pom.xml` o en el `docker-compose.yml`. Tampoco debía alterar las métricas de rendimiento ya obtenidas en las pruebas de estrés con k6 (latencia mediana p95 de 1.81 ms).

---

## 2. Evidencia temporal (especificación → commit → resultado)

| Evento | Commit / hash | Fecha | Evidencia |
|---|---|---|---|
| Estado del repo justo antes de pedir el C4 al agente | (sin commit de referencia — ver 2.1) | — | No se identificó un commit específico previo dedicado a la especificación |
| Especificación/prompt commiteado (si aplica) | No commiteado — ver 2.1 | — | — |
| Primer resultado del agente integrado al repo | 1375f7d6428c317e3f3b113a5ef871db212459c6 | 2026-09-04 16:16:30 -0500 | `git show 1375f7d --stat` |
| Commit(s) de corrección tras la auditoría | 18ed28e71c2c1a4b036d1f023652b28bc2fae2a7 | 2026-09-04 17:18:26 -0500 | `git show 18ed28e --stat` |

### 2.1 Declaración de trazabilidad temporal

No existe un commit donde la especificación original dada al agente (Copilot) haya quedado registrada *antes* del primer resultado defectuoso. El prompt inicial se dio fuera de Git (interfaz de chat) y no se guardó evidencia commiteada previa a la generación de los primeros diagramas C4. 

Sin embargo, para el ciclo de estabilización actual, la trazabilidad se establece mediante los commits de corrección (`6bd39c1`, `773d97a` y `18ed28e`), los cuales demuestran la depuración de las dependencias fantasma (Firestore, Next.js) y la consolidación de la arquitectura verificada (Java 21, Spring Boot, PostgreSQL) validada en los archivos `05-c4-contexto.md`, `06-c4-contenedores.md` y `07-c4-componentes.md`. Se declara explícitamente que la especificación inicial carece de trazabilidad temporal en Git, consultado con el docente sobre la validez de los registros de auditoría posteriores como evidencia compensatoria.

---

## 3. Resultado entregado por el agente (antes de auditoría/corrección)

Resumen de lo que el agente afirmó inicialmente que existía, sin haber sido todavía contrastado con el código:
*   Inclusión de Firestore/MongoDB como bases de datos activas en el entorno de contenedores.
*   Suposición de un framework de backend no correspondiente (ej. Next.js API Routes) en lugar de la implementación real.
*   Omisión de controladores específicos en el Nivel 3 (Componentes), declarando la inexistencia de los mismos en la capa de la API.

---

## 4. Auditoría humana: hallazgos clasificados

| # | Hallazgo | Clasificación | Commit de corrección | Evidencia que motivó el hallazgo |
|---|---|---|---|---|
| 1 | Firestore/MongoDB presentado como contenedor real | Sustantivo | 6bd39c1 | Sin dependencia, servicio ni configuración en `docker-compose.yml`/`pom.xml`; decisión de arquitectura documentada en `dossier/02-stakeholders-drivers.md` (riesgo R-03) |
| 2 | Backend asumido como Next.js API Routes | Sustantivo | 773d97a1502bcc1012110f70acd0578a2003d17a | `app/pom.xml` (Spring Boot 3.3.4) y `app/Dockerfile` (Java 21) confirman lo contrario |
| 3 | `07-c4-componentes.md` afirmaba que no existían controladores | Sustantivo | 18ed28e71c2c1a4b036d1f023652b28bc2fae2a7 | Existe `MascotaController.java` en `app/src/main/java/com/patitasurbanas/api/controller/` |
| 4 | Duplicación de C4 Nivel 1/2 en `dossier/` con contenido desactualizado y contradictorio (Firestore/MongoDB sin marcar como eliminado) | Sustantivo | 6bd39c1 | `dossier/05-c4-contexto.md` y `dossier/06-c4-contenedores.md` (ya eliminados) |
| 5 | Sintaxis de Mermaid generada con identificadores incompatibles que impedían la renderización correcta en GitHub | Cosmético | 18ed28e71c2c1a4b036d1f023652b28bc2fae2a7 | Visualización rota en la vista previa de Markdown del repositorio |

---

## 5. Qué aceptaron, qué rechazaron, qué corrigieron

### 5.1 Aceptado tal cual (sin cambios)
La estructura general de los tres niveles C4, la sintaxis base de los diagramas en Mermaid y la leyenda visual para distinguir elementos verificados en código de los planificados.

### 5.2 Rechazado por completo
La integración de bases de datos NoSQL (Firestore/MongoDB) como contenedores desplegados, dado que no existen en el entorno orquestado actual.

### 5.3 Corregido
Se corrigió la tecnología del backend, ajustándola a Java 21 y Spring Boot 3.3.4 (referencia a la tabla de la sección 4, hallazgos 2 y 3). Se eliminó la documentación duplicada en la carpeta `dossier/` para mantener una única fuente de verdad en `docs/`.

---

## 6. Qué NO se alcanzó a verificar

- La cronología exacta de si la hipótesis de S3 (`p95 < 800 ms bajo 100 req/s`) fue commiteada antes o después de tener resultados de medición (pendiente de revisar commit `e75b94d` y compararlo con la fecha de la primera corrida).
- Revisión exhaustiva de configuraciones residuales en directorios fuera del alcance principal (`app/`, `docs/`, `experimentos/`) que pudieran contradecir el modelo C4 actual.

---

## 7. Firma y responsabilidad de integración

Quien(es) suscribe(n) este documento confirma(n) haber revisado personalmente los hallazgos de la sección 4 contra el código fuente en `main`, y asume(n) la responsabilidad de defender cada fila de la tabla de trazado de `docs/07-c4-componentes.md` ante el docente, incluyendo poder señalar en menos de 30 segundos el archivo que sostiene cada elemento marcado como 'Verificado'.

Nombre(s): _______________________
Fecha: 2026-09-04

---

## Anexo: preguntas de auditoría abiertas (heredadas de revisiones previas del tutor)

1. ¿La hipótesis `p95 < 800 ms bajo 100 req/s` fue commiteada antes de tener resultados de medición? (Ver commit `e75b94d` y compararlo temporalmente con `experimentos/resultado-linea-base.txt`.)
2. ¿El equipo interpretó "mínimo tres corridas, descartar la primera" como tres corridas *totales* o tres corridas *válidas* además de la descartada? Esta es una pregunta de criterio que corresponde resolver con el docente, no unilateralmente.
3. Para cada fila "Verificado" de la tabla de trazado en `07-c4-componentes.md`: ¿puede el equipo, ante el profesor, abrir el archivo exacto en menos de 30 segundos?
