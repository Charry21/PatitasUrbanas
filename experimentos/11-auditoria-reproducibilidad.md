# Auditoría de reproducibilidad — Línea base S4/S5 y Spike 1 (S10)

> Revisión de **método y trazabilidad**, hecha el 2026-10-24 sobre `main` = `f0c4ea5`,
> a partir de la auditoría del tutor. No selecciona métricas, no interpreta
> resultados, no diagnostica el sistema ni emite un veredicto arquitectónico.
> Su objeto es comprobar si las afirmaciones numéricas y el orden temporal
> **se pueden reproducir** con los artefactos del repositorio.

Estados:

- **Demostrado:** hay evidencia identificable y reproducida que satisface el control.
- **Parcial:** parte del control está demostrada y parte no.
- **Faltante:** el artefacto no contiene la evidencia exigida, o la evidencia la contradice.
- **No verificable:** la información disponible no permite confirmarlo ni refutarlo.

Toda la evidencia está en [`auditoria-reproducibilidad/`](./auditoria-reproducibilidad/). Los comandos de §5 la regeneran.

---

## 1. Resumen

| Conjunto | Controles demostrados | Hallazgos que cambian el estado de la auditoría del tutor |
|---|---|---|
| Línea base S4 (corridas 1–3) | Transcripción, códigos HTTP, hipótesis previa | **A1** fecha de ejecución contradicha; **A2** el hash declarado no contiene el código medido; **A3** el script versionado apuntaba a otro endpoint |
| Línea base S5 (corridas 4–8) | Transcripción, códigos HTTP, código y script en un mismo commit, reproducción del procedimiento | **A4** el informe no cita el commit (es identificable por Git: `1ac4c37`) |
| Spike 1 (S10) | Preregistro previo, especificación sin cambios, correspondencia código–resultados, rama de control | **A5** los hashes citados ya no son ancestros de `main` por una reescritura del historial |

---

## 2. Línea base de las semanas 4 y 5 (`01-metodologia-medicion.md`)

### 2.1 Controles

| Control | Estado | Evidencia reproducida | Límite |
|---|---|---|---|
| Transcripción de las corridas (p95, iteraciones, fallos) | **Demostrado** | Los 9 valores de §4 y §6 coinciden exactamente con los archivos originales `resultado-corrida-{1..8}.txt` (`transcripcion-k6.txt`). Las medianas se recalculan iguales: 1.81 ms (corridas 2–3) y 2.49 ms (6–8). | Los originales 1–3 están en UTF-16 (salida de PowerShell); el extractor lee ambas codificaciones. |
| Códigos de respuesta | **Demostrado** | En las 8 corridas: check `status es 200` al 100% y `http_req_failed` = 0.00%. | El check solo verifica el código, no el cuerpo. |
| Herramienta y carga | **Demostrado** | Las 8 salidas registran el script `experimentos/escenario-rendimiento.js` y `carga_constante: 100.00 iterations/s for 40s`. | Las salidas no registran la versión de k6. |
| Hipótesis S3 registrada antes de medir | **Demostrado** | `p95 < 800 ms` entra en `dossier/04-escenarios-calidad.md` en `510c1a4`, fusionado por el PR #3 el **2026-08-28 04:25:01 UTC** (servidor). Las corridas 1–3 entran con el PR #7 el **2026-08-28 20:49:10 UTC**; las 4–8, con el PR #35 el 2026-09-12 17:34:18 UTC. | Demuestra que no había resultados commiteados antes; no que nadie hubiera medido antes. |
| Fecha de ejecución (ronda 1) | **Faltante** (A1) | §1 declara "31 de agosto de 2026", pero los archivos de las corridas 1–3 ya estaban en GitHub el 28 de agosto a las 20:49 UTC (PR #7). | La fecha real de ejecución no está registrada; solo se sabe que fue anterior a esa hora. |
| Versión exacta del código (ronda 1) | **Faltante** (A2) | El hash declarado `8c7b9f5` es **posterior** a los resultados (commit 2026-08-28 17:05 -0500 frente a 15:44 -0500 de `789ed21`). Ni en `8c7b9f5` ni en `789ed21` hay un endpoint `/api/mascotas/buscar`: `app/` solo contiene `PatitasUrbanasApplication.java`. El primer commit con ese endpoint es `22b0ac0` (2026-09-04). | El código que sirvió las corridas 1–3 no está en el repositorio. |
| Operación medida (ronda 1) | **No verificable** (A3) | En `789ed21`, el commit que añade las corridas 1–3, el script versionado llama a `/actuator/health`; el cambio a `/api/mascotas/buscar` llega después, en `8c7b9f5`. **Indicio:** las corridas 1–3 registran ~175 B por solicitud, igual que las 4–8; hoy `/api/mascotas/buscar` responde 114 + 61 = 175 B y `/actuator/health` 142 + 296 = 438 B (`tamano-respuestas.txt`). | El tamaño es compatible con `/api/mascotas/buscar` servido por código no versionado, pero no lo demuestra. |
| Versión exacta del código (ronda 2) | **Demostrado**, con A4 | En `1ac4c37` (commit de las corridas 4–8) existen `MascotaController` y el script con `/api/mascotas/buscar`; el script es idéntico al de `main`. | §6 de `01` no cita este hash; se identifica solo por Git. |
| Volumen y distribución de la semilla | **Faltante** | No hay ningún archivo `.sql`, de semilla o de datos en todo el historial (`git log --all`). El endpoint medido no consulta la base de datos. | Sin semilla, la medición no permite afirmar nada sobre una búsqueda geoespacial real (§5 de `01` ya lo declara). |
| Condiciones comparables entre corridas | **No verificable** | Las salidas no registran entorno ni hora; `01` §1 describe el entorno una sola vez para todas las corridas. | — |
| Reproducción por un tercero | **Parcial** | Ronda 2: se reprodujo el **procedimiento** sobre `1ac4c37` con el mismo script (5 corridas): 100% `status es 200`, 0% de fallos, 4000–4001 iteraciones y los mismos 701 kB recibidos que los originales (`k6-ronda2-1ac4c37/`). Ronda 1: no reproducible, porque su código no está versionado (A2). | Entorno distinto (contenedor Linux con 4 CPU, k6 v2.3.0, API con `mvn spring-boot:run` y no en imagen Docker). Los p95 reproducidos **no se comparan** con los originales ni con el umbral. |

### 2.2 Hallazgos

- **A1 — Fecha contradicha.** La fecha "31 de agosto" de `01` §1 es incompatible con el historial: los resultados existían el 28 de agosto.
- **A2 — El hash declarado no es el código medido.** `8c7b9f5` es posterior a los resultados y no contiene el endpoint medido. Su mensaje ("…semillas y mediana p95 de 2.64ms") corresponde a la versión del documento que la corrección de S5 (§2 de `01`) declaró inexacta.
- **A3 — Script versionado distinto del ejecutado.** En el momento de commitear los resultados, el script del repositorio apuntaba a `/actuator/health`. El script que generó las corridas 1–3 no quedó versionado en ese commit.
- **A4 — Ronda 2 sin hash en el informe.** Es identificable (`1ac4c37`), pero `01` §6 no lo cita.

Ninguno de estos hallazgos cambia los valores transcritos, que coinciden con los originales. Afectan a qué se puede afirmar sobre **qué código y qué operación** produjeron la ronda 1.

---

## 3. Spike 1 (semana 10)

### 3.1 Controles

| Control | Estado | Evidencia reproducida |
|---|---|---|
| Preregistro antes de medir | **Demostrado** | PR #48 (especificación completa con Y4/Y5) fusionado el **2026-10-02 16:38:15 UTC**; la línea base `af02cce` llega a GitHub con el PR #50 a las 17:11:50 UTC. Horas del servidor (`gh api …/pulls/N --jq .merged_at`), que coinciden con `07-trazabilidad-temporal.md` §3. |
| Especificación sin cambios después del resultado | **Demostrado** | `git diff 3d458a2 main -- experimentos/04-spike-especificacion-s9.md`: solo cambian 3 líneas, que añaden enlaces al resultado y a la auditoría (`git-spike.txt`). |
| Código base identificable | **Demostrado** | `git diff --stat 887ccf1 3d458a2 -- app` vacío. |
| Cambio dentro del alcance | **Demostrado** | `887ccf1..1e522df`: 8 archivos, 15 inserciones y 18 eliminaciones; ninguna línea cambiada fuera de `package`/`import`. |
| Correspondencia código–resultados | **Demostrado** | `app/` en `main` tiene el mismo árbol que `1e522df`. Las salidas `spike-s10/antes`, `despues`, `control-y2` e `y3-comparacion.txt` no cambian desde `d97cbf3`. La re-medición de Y1–Y5 ya está registrada en `09-cierre-spike-s10.md` §3.2 y §3.6. |
| Integridad de la rama de control | **Demostrado** | `main` no contiene el import de control (`git grep "CONTROL Y2"`: 0). Los commits que tocan `app/` después del spike tienen un efecto neto nulo. La rama `spike/control-y2-descartable` sigue en `4883f9c`. |
| Ningún resultado parcial antes del preregistro | **No verificable** | Ya declarado en `07` §5: Git demuestra que no hay mediciones commiteadas antes, no que nadie las viera. |
| Construcción de la imagen Docker de la API | **Parcial** | Ya registrado en `09` §3.4: el `Dockerfile` original falla en este tipo de entorno por TLS y una variante construye. Sin cambios en esta auditoría. |
| Windows/WSL2 | **No verificable** | No se dispone de ese entorno. |

### 3.2 Hallazgo A5 — los hashes citados ya no están en la historia de `main`

`main` se reescribió el 2026-10-09 y el 2026-10-10 para corregir la autoría. Esa reescritura **ya está documentada** en `09-cierre-spike-s10.md`, Anexo A, con su propia tabla de equivalencias; esta auditoría la confirma de forma independiente y añade lo que el Anexo A no recoge: **la pérdida de la firma de GitHub** en los merges recreados. El resultado (`hashes-citados.txt`):

- Los 15 hashes del spike que citan los documentos 04, 05, 06, 07 y 09 (`887ccf1`, `3d458a2`, `af02cce`, `1e522df`, `d97cbf3`, `e9bcd93`…) **no son ancestros de `main`**. En `main` hay copias con **el mismo árbol**, es decir, el mismo contenido, y las mismas fechas, con otros hashes (`1e522df` → `44ede36`, `3d458a2` → `dd451cf`…).
- Los originales siguen existiendo en 12 ramas remotas (entre ellas `spike/fronteras-modulares-s10`) y en los PR de GitHub: el `merge_commit_sha` de los PR #45, #48, #49 y #50 apunta a los originales.
- Los merges recreados conservan el nombre `GitHub` como committer, pero **no la firma**: `3d458a2` tiene firma (`%G?` = `E`) y su copia `dd451cf` no (`N`). La hora de servidor válida es la de la API de los PR, no la de los commits de `main`.

**Consecuencia para la reproducción:** los comandos de `07` §6 funcionan solo porque los originales siguen en otras ramas. Si esas ramas se borran, los hashes citados dejan de poder resolverse en un clon nuevo, salvo a través de las referencias de los PR. Las conclusiones de contenido no cambian, porque los árboles son idénticos.

---

## 4. Lo que esta auditoría no hace

- No interpreta los p95, ni los originales ni los reproducidos, y no los compara con el umbral.
- No decide qué se corrige en `01-metodologia-medicion.md` ni en los documentos del spike. Las decisiones del equipo quedan en §6.
- No reproduce Y1–Y5, porque ya está hecho en `09` §3.2 y §3.6.

---

## 5. Cómo reproducir

```bash
# Transcripción k6 (S4/S5)
python3 -I experimentos/auditoria-reproducibilidad/extraer_k6.py experimentos/resultado-linea-base.txt experimentos/resultado-corrida-{1..8}.txt

# A1-A3: hash declarado, script y código de la ronda 1
git log --diff-filter=A --format='%h %ci' -- experimentos/resultado-corrida-1.txt   # 789ed21, 2026-08-28 15:44 -0500
git log -1 --format='%h %ci' 8c7b9f5                                               # posterior
git ls-tree -r --name-only 8c7b9f5 -- app/src/main                                 # sin MascotaController
git show 789ed21:experimentos/escenario-rendimiento.js | grep http.get             # /actuator/health
git diff 789ed21 8c7b9f5 -- experimentos/escenario-rendimiento.js

# Horas de servidor
for n in 3 7 35 45 48 49 50; do gh api repos/Charry21/PatitasUrbanas/pulls/$n --jq '"#'$n' \(.merged_at) \(.merge_commit_sha[0:7])"'; done

# Semilla
git log --all --format='' --name-only | grep -iE '\.sql$|seed|semilla' | sort -u

# A5: ancestría de los hashes citados
for h in 887ccf1 3d458a2 af02cce 1e522df d97cbf3 e9bcd93; do echo "$h $(git merge-base --is-ancestor $h main && echo sí || echo no)"; done
git log -1 --format=%G? 3d458a2; git log -1 --format=%G? dd451cf

# Reproducción del procedimiento de la ronda 2
git worktree add --detach /tmp/wt 1ac4c37 && cd /tmp/wt
docker compose up -d postgres_db && (cd app && mvn spring-boot:run &)
docker run --rm --network host -v "$PWD/experimentos:/scripts" grafana/k6 run /scripts/escenario-rendimiento.js
```

---

## 6. Decisiones pendientes del equipo

| # | Pendiente | Opciones |
|---|---|---|
| E1 | A1 y A2: fecha y hash de `01` §1 | Añadir una aclaración fechada, sin reescribir el documento, que indique que la fecha real es anterior al 2026-08-28 20:49 UTC y que el código de la ronda 1 no está versionado; o retirar la ronda 1 como evidencia y usar solo la ronda 2. |
| E2 | A3: operación medida en la ronda 1 | Declarar la operación como "no verificable por Git" y citar el indicio del tamaño de respuesta, o no usar la ronda 1. |
| E3 | A4: hash de la ronda 2 | Añadir `1ac4c37` a `01` §6 mediante una aclaración. |
| E4 | A5: hashes del spike | Conservar las ramas que contienen los originales, o crear etiquetas (por ejemplo, `evidencia/spike1-*`) que los fijen; y/o añadir a `07` una tabla de equivalencias original → copia (`hashes-citados.txt`). |
| E5 | Política de historial | Decidir si `main` se vuelve a reescribir. Cada reescritura invalida los hashes citados y quita la firma de GitHub a los merges. |

### 6.1 Decisiones del equipo (2026-10-24)

| # | Decisión | Dónde queda |
|---|---|---|
| E1 | Aclaración fechada en `01` sin reescribirlo; la ronda 2 pasa a ser la evidencia de línea base y la ronda 1 queda como registro histórico | `01-metodologia-medicion.md` §7 |
| E2 | Operación de la ronda 1 declarada "no verificable por Git", con el indicio del tamaño de respuesta | `01-metodologia-medicion.md` §7 |
| E3 | Se añade el hash `1ac4c37` de la ronda 2 | `01-metodologia-medicion.md` §7 |
| E4 | Preservar los commits originales y la tabla de equivalencias | Tabla en `07-trazabilidad-temporal.md` §7 y en `09`, Anexo A. **Ya preservados:** los 10 originales del spike están en las referencias `refs/pull/45…50/head`, que GitHub no borra, y el merge `7b1f022` lo resuelve la API (comprobado el 2026-10-24). Las etiquetas `evidencia/spike1-*` son **opcionales**: refuerzo que se publica con `auditoria-reproducibilidad/crear-etiquetas-evidencia.sh` |
| E5 | `main` no se vuelve a reescribir; las correcciones se hacen con commits nuevos | `07-trazabilidad-temporal.md` §7 |

---

## 7. Respuesta a la segunda revisión del tutor (2026-10-24)

La segunda revisión pide comprobar directamente seis controles. Todos se ejecutaron sobre los archivos originales y el historial; la evidencia nueva está en [`auditoria-reproducibilidad/correspondencia-salidas.txt`](./auditoria-reproducibilidad/correspondencia-salidas.txt).

| # | Control de la lista del tutor | Estado | Evidencia |
|---|---|---|---|
| 1 | Hash de cada versión de código frente al historial | **Demostrado** para el spike y para la ronda 2 de S4/S5; **falta evidencia** para la ronda 1 de S4 | Spike: §3.1 y `hashes-citados.txt`. S4/S5: §2.1, hallazgos A2 y A4 |
| 2 | Orden temporal entre preregistro, mediciones y resultado | **Demostrado** con horas de servidor de los PR | §2.1 (PR #3 → #7 → #35) y §3.1 (PR #45 → #48 → #50 → #49) |
| 3 | Comandos declarados frente a salidas originales | **Demostrado** | Cada conjunto de salidas del spike se commiteó con un `app/` idéntico al estado que dice medir: `antes` (`b52207e`) = árbol de `887ccf1`; `control-y2` (`6508379`) = `4883f9c`, con el import inyectado; `despues` (`ac85955`) = `1e522df`. Las salidas Y2/Y4/Y5 nombran los paquetes de cada estado (`api.controller` antes, `api.adopciones` después). Además, `09` §3.2 y §3.6 las re-midieron con el mismo resultado. **Límite:** los logs de Y1 no registran el hash ni nombres de paquete; su vínculo con el estado se apoya en el commit que los añadió y en la re-medición. |
| 4 | Códigos HTTP y cuerpos por solicitud | **Demostrado** | Las 9 solicitudes S1–S3: el mismo código antes y después (S1, S2: 201; S3: 200), el mismo cuerpo normalizado y los mismos tipos. Las 8 corridas k6: 100% `status es 200` (§2.1). |
| 5 | Condiciones de ejecución antes y después | **Parcial** | `spike-s10/entorno.txt` se registró una vez, al inicio de la sesión (17:02 UTC). Antes y después se midieron en esa misma sesión, entre 17:02 y 17:08 UTC (horas de commit), sin reinstalar nada. **No verificable:** no hay un segundo registro de versiones tomado después del cambio. |
| 6 | Desviaciones y límites de lo no verificado | **Demostrado** | D1–D5 de `06` §5 contrastadas con el historial: D5 en §3.1 (PR #50 = merge `af92e3f`, que contenía `af02cce` y `4883f9c`; corrección en `36e2e97`). Los límites que siguen abiertos están en `09` §4–§5 (Windows/WSL2, `Dockerfile` original, casos límite) y en esta auditoría (A1–A5). |

**Aclaración sobre el Control D del tutor:** el commit de fusión del PR #50 es `af92e3f` (no `af92cce`). Ese PR integró dos commits de la rama descartable: `af02cce` (scripts y línea base, medidos antes de la fusión) y `4883f9c` (import de control). Las mediciones son de 17:05–17:07 UTC y la fusión del PR #50, de las 17:11:50 UTC (servidor).

**Aclaración sobre rutas:** las respuestas de Y3 están en `spike-s10/antes/y3/` y `spike-s10/despues/y3/` (no en `y3-antes/` ni `y3-despues/`).

---

Auditoría preparada con Claude Code (Anthropic) para revisión del equipo.

Revisado por: Charry Ríos Daniel Estiven · Fecha: 2026-10-24
