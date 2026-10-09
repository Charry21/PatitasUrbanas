# Trazabilidad temporal del spike 1 y del modelo del dominio
## Módulo 5 · Verificación del orden de los commits

---

## 1. Propósito

Comprobar con el historial de Git, y no solo con las fechas escritas en los
documentos, que:

1. la hipótesis del spike 1 se preregistró **antes** de medir;
2. las mediciones y el veredicto son posteriores a ese preregistro;
3. la especificación no cambió después de conocer el resultado;
4. el modelo del dominio (`docs/dominio/`) es **posterior** al spike y no
   pudo influir en su hipótesis.

La revisión del tutor del 2026-10-09 señaló que "la fecha del documento,
por sí sola, no demuestra el orden temporal".

---

## 2. Qué hora se usa como evidencia

| Hora | Quién la fija | Valor como evidencia |
|---|---|---|
| **Fusión del PR** (`merged_at`) | El servidor de GitHub | **Fuerte:** nadie del equipo puede alterarla |
| Hora del commit (`%ci`) | El computador de quien hace el commit | Débil: se puede cambiar localmente; sirve para ordenar commits dentro de una rama |

Todas las horas están en UTC.

---

## 3. Línea de tiempo

| # | Hecho | Commit | PR | Fusión del PR (servidor) | Hora del commit |
|---|---|---|---|---|---|
| 1 | Primera versión de la especificación del spike (hipótesis, criterios, alcance) | `8a2a001` | #45 → `887ccf1` | **2026-10-02 03:48:50** | 2026-10-02 03:47:18 |
| 2 | Especificación completada: condiciones de medición, métricas Y4/Y5, agente y ramas; ADR-03 en estado Propuesta | `99269dd`, `c16cd03`, `01f1c7b`, `403d7b5` | #48 → `3d458a2` | **2026-10-02 16:38:15** | 16:07:49 – 16:32:06 |
| 3 | Scripts de medición y línea base Y1–Y5 | `af02cce` | #50 (por error, ver §5) | **2026-10-02 17:11:50** | 17:05:08 |
| 4 | Reorganización de paquetes (único cambio de código) | `1e522df` | #49 | 2026-10-02 23:34:00 | 17:05:49 |
| 5 | Mediciones después y comparación Y3 | `d97cbf3` | #49 | 2026-10-02 23:34:00 | 17:07:22 |
| 6 | Resultado, desviaciones y veredicto | `e9bcd93` | #49 → `7b1f022` | **2026-10-02 23:34:00** | 17:08:31 |
| 7 | Primera versión del modelo del dominio y context map | `7b8f408` | #52 → `ed5aba1` | **2026-10-03 00:58:14** | 2026-10-03 00:54:15 |
| 8 | Modelo del dominio reescrito desde la evidencia | `91afab8` | #54 → `8f80b21` | **2026-10-09 15:15:20** | 2026-10-09 14:48:05 |
| 9 | Decisiones D6–D9 | `42c7c9c` | #56 → `9c84f21` | **2026-10-09 16:26:46** | 2026-10-09 16:23:15 |

---

## 4. Qué demuestra

**Preregistro antes de medir.** La versión completa de la especificación
(con Y4/Y5) entró a `main` en el PR #48 a las 16:38:15 (servidor). Las
mediciones de línea base (`af02cce`) existían a más tardar a las 17:11:50
(fusión del PR #50, servidor) y tienen hora de commit 17:05:08, después del
preregistro.

**Versión preregistrada de la hipótesis: `3d458a2`.** El commit base del
**código** del spike es `887ccf1` (así lo indica
`06-spike-resultado-s10.md`), pero las métricas Y4/Y5 y las condiciones de
medición se agregaron después, en `3d458a2`, todavía antes de medir. Para
auditar la hipótesis hay que leer la especificación en `3d458a2`:

```
git show 3d458a2:experimentos/04-spike-especificacion-s9.md
```

Entre `887ccf1` y `3d458a2` el directorio `app/` no cambió, así que el código
medido es el mismo.

**La especificación no cambió después del resultado.** Desde `3d458a2`, el
único cambio en `04-spike-especificacion-s9.md` es reemplazar
"Pendiente — se completa en Semana 10" por enlaces al resultado y a la
auditoría (secciones *Resultado*, *Veredicto* y una línea de §7). Las
secciones 1–6 (hipótesis, criterios, alcance, condiciones y tarea delegada)
son idénticas. Se comprueba con:

```
git diff 3d458a2 main -- experimentos/04-spike-especificacion-s9.md
```

**El modelo del dominio es posterior al spike.** La primera versión de
`docs/dominio/` se fusionó el 2026-10-03 a las 00:58:14, después del
veredicto del spike (2026-10-02 23:34:00). La reescritura basada en
evidencia es del 2026-10-09. Ninguna de las dos pudo influir en la hipótesis,
que se apoyó en `dossier/15-diseno-modular-s7.md` y en ADR-03.

---

## 5. Limitaciones

- Las horas de los pasos 4 y 5 (reorganización y mediciones después) solo
  están respaldadas por la hora del commit; el servidor las registra al
  fusionar el PR #49 (23:34:00). El orden entre ellas se apoya en la
  secuencia de commits de la rama `spike/fronteras-modulares-s10`.
- El PR #50 fusionó por error la rama de control `spike/control-y2-descartable`,
  que contenía `af02cce`. Eso ya está documentado como desviación D5 en
  `06-spike-resultado-s10.md` y, como efecto secundario, deja una hora de
  servidor para la línea base.
- Esta verificación no demuestra que nadie viera resultados parciales antes
  de las 16:38:15; solo demuestra que no hay mediciones commiteadas antes de
  esa hora.

---

## 6. Cómo reproducir esta verificación

```
git log --format="%h %ci %s" -- experimentos/04-spike-especificacion-s9.md
gh api repos/Charry21/PatitasUrbanas/pulls/48 --jq .merged_at
gh api repos/Charry21/PatitasUrbanas/pulls/49 --jq .merged_at
git diff 3d458a2 main -- experimentos/04-spike-especificacion-s9.md
git diff --stat 887ccf1 3d458a2 -- app
```

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Módulo 5 · Arquitectura de Software*
