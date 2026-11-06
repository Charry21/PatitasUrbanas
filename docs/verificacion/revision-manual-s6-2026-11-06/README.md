# Revisión manual de probabilidades, impactos y umbrales (S6 de la EDAV 3)

Fecha: 2026-11-06. Calificaron Kevin Torres y Daniel Charry; la IA preparó la hoja y transcribió el resultado.

## Cómo se hizo

1. La IA preparó [`hoja-S6-plantilla.xlsx`](./hoja-S6-plantilla.xlsx) con las 32 filas de riesgo y su evidencia, **sin sus calificaciones**.
2. Cada uno calificó por separado: [`hoja-S6-Kevin.xlsx`](./hoja-S6-Kevin.xlsx) y [`hoja-S6-Daniel.xlsx`](./hoja-S6-Daniel.xlsx).
3. Juntos llenaron la pestaña Consolidado. Coincidieron en 17 de 32 filas y acordaron las otras 15.
4. Después de ver la comparación con la IA, el equipo ajustó la justificación de RS-17 y RO-15 y eligió los umbrales.

Escala: la de `docs/10-seguridad.md` §4. Se califica el riesgo sin su control y suponiendo un despliegue público.

## Resultado de los riesgos

La matriz final difiere de la inicial de la IA en **14 filas: 13 suben y 1 baja** (RO-12). Las de mayor nivel quedan RO-02 (sin copias) y RO-06 (disco lleno por logs), con nivel 9.

| Id | Kevin | Daniel | **Final** (nivel) | Inicial de la IA (nivel) | Justificación del equipo |
|---|---|---|---|---|---|
| RS-01 | Alta / Alto | Alta / Alto | **Alta / Alto** (9) | Alta / Alto (9) | Coincidieron por separado |
| RS-02 | Alta / Medio | Alta / Medio | **Alta / Medio** (6) | Alta / Medio (6) | Coincidieron por separado |
| RS-03 | Alta / Alto | Alta / Bajo | **Alta / Medio** (6) | Alta / Bajo (3) | Aunque Daniel señala que no expone credenciales, revelar la arquitectura interna facilita ataques dirigidos (impacto medio). |
| RS-04 | Alta / Medio | Alta / Bajo | **Alta / Medio** (6) | Alta / Bajo (3) | Daniel indica que solo causa rollbacks, pero un endpoint abierto permite consumo malicioso de recursos del servidor. |
| RS-05 | Alta / Alto | Alta / Alto | **Alta / Alto** (9) | Alta / Alto (9) | Coincidieron por separado |
| RS-06 | Alta / Alto | Alta / Alto | **Alta / Alto** (9) | Alta / Alto (9) | Coincidieron por separado |
| RS-07 | Alta / Alto | Alta / Alto | **Alta / Alto** (9) | Alta / Alto (9) | Coincidieron por separado |
| RS-08 | Alta / Medio | Media / Medio | **Alta / Medio** (6) | Media / Medio (4) | La probabilidad es alta porque sin límites ni autenticación, cualquier script básico puede saturar la BD rápidamente. |
| RS-09 | Alta / Bajo | Media / Bajo | **Alta / Bajo** (3) | Media / Bajo (2) | Es un hecho verificable en cada petición (probabilidad alta), pero revelar el volumen actual tiene impacto bajo. |
| RS-10 | Media / Alto | Media / Medio | **Media / Alto** (6) | Media / Medio (4) | Requiere vulnerar la API primero (probabilidad media), pero si ocurre, el control total del contenedor es crítico. |
| RS-11 | Alta / Medio | Media / Medio | **Alta / Medio** (6) | Media / Medio (4) | La falta de validación asegura (probabilidad alta) errores 500 ante entradas malformadas, afectando la estabilidad. |
| RS-12 | Media / Alto | Media / Alto | **Media / Alto** (6) | Media / Alto (6) | Coincidieron por separado |
| RS-13 | Baja / Medio | Baja / Medio | **Baja / Medio** (2) | Baja / Medio (2) | Coincidieron por separado |
| RS-14 | Alta / Alto | Alta / Alto | **Alta / Alto** (9) | Alta / Alto (9) | Coincidieron por separado |
| RS-15 | Baja / Alto | Media / Alto | **Media / Alto** (6) | Media / Alto (6) | Aunque hoy no hay datos, el incumplimiento de la Ley 1581 al salir a producción tiene implicaciones legales graves (Alto). |
| RS-16 | Alta / Medio | Media / Bajo | **Alta / Bajo** (3) | Media / Bajo (2) | La IP se registra siempre (Alta), pero el impacto es bajo si se acuerda purgar los logs antes de salir a producción. |
| RS-17 | Alta / Medio | Alta / Bajo | **Alta / Medio** (6) | Alta / Bajo (3) | Los secretos en el historial son vectores de ataque pasivos, aunque la contraseña ya no sea la activa. Se acepta temporalmente en desarrollo, con purga obligatoria del historial (`git filter-repo`) antes de hacer público el repositorio. |
| RO-01 | Alta / Alto | Alta / Alto | **Alta / Alto** (9) | Alta sin R-11 / Alto (9) | Coincidieron por separado |
| RO-02 | Alta / Alto | Media / Alto | **Alta / Alto** (9) | Media / Alto (6) | Al no existir ningún mecanismo de copias, cualquier fallo menor garantiza la pérdida total de los datos. |
| RO-03 | Alta / Medio | Alta / Medio | **Alta / Medio** (6) | Alta / Medio (6) | Coincidieron por separado |
| RO-04 | Media / Alto | Media / Alto | **Media / Alto** (6) | Media / Alto (6) | Coincidieron por separado |
| RO-05 | Media / Medio | Baja / Alto | **Media / Alto** (6) | Baja / Alto (3) | Los bloqueos ocurren sin reiniciar el contenedor; la indisponibilidad total pasa desapercibida (Alto) sin healthchecks. |
| RO-06 | Alta / Alto | Media / Alto | **Alta / Alto** (9) | Media / Alto (6) | Con el SQL en nivel DEBUG (176 MB rápido), la saturación del disco ocurrirá inevitablemente con el tráfico normal. |
| RO-07 | Media / Medio | Media / Medio | **Media / Medio** (4) | Media / Medio (4) | Coincidieron por separado |
| RO-08 | Media / Alto | Media / Alto | **Media / Alto** (6) | Media / Alto (6) | Coincidieron por separado |
| RO-09 | Media / Medio | Media / Medio | **Media / Medio** (4) | Media / Medio (4) | Coincidieron por separado |
| RO-10 | Baja / Bajo | Baja / Bajo | **Baja / Bajo** (1) | Baja / Bajo (1) | Coincidieron por separado |
| RO-11 | Alta / Medio | Alta / Medio | **Alta / Medio** (6) | Alta / Medio (6) | Coincidieron por separado |
| RO-12 | Alta / Bajo | Alta / Alto | **Alta / Medio** (6) | Alta / Alto (9) | Un buscador simulado es un bloqueante funcional, pero no destruye la aplicación; frena la validación con clientes. |
| RO-13 | Media / Alto | Media / Medio | **Media / Alto** (6) | Media / Medio (4) | Depender de un equipo de 2 personas genera un impacto operativo muy alto si uno abandona el proyecto repentinamente. |
| RO-14 | Alta / Alto | Alta / Alto | **Alta / Alto** (9) | Alta / Alto (9) | Coincidieron por separado |
| RO-15 | Alta / Medio | Media / Alto | **Alta / Medio** (6) | Media / Alto (6) | Las pruebas S11 se limitaron a un entorno local aislado (Alta probabilidad de sesgo de red). Dado que la latencia dependerá del proveedor final, el margen de rendimiento exigido en el Escenario 1 podría no cumplirse en producción (Impacto Medio). |

Nota sobre RS-17: el mismo día, tras la segunda pasada de la preauditoría, el equipo quitó la condición de purgar el historial, porque el repositorio ya es público y la purga no borraría la contraseña de GitHub. La calificación (Alta / Medio) no cambia. Ver `docs/10-seguridad.md` §4.

Nota sobre RO-15: "entorno local" se refiere a que S11 corrió con el generador de carga y la API en la misma máquina, el contenedor en la nube de la IA, sin latencia de red.

## Umbrales

| Alerta | Kevin (independiente) | Daniel | **Elegido por el equipo** |
|---|---|---|---|
| AL-1 | Sin 200 o tiempo agotado, 1 min | 2 comprobaciones sin 200, espera de 35 s | **2 comprobaciones sin 200, espera de 35 s** |
| AL-2 | Más de 2 reinicios en 5 min | 1 aumento de `RestartCount` | **1 aumento, al ocurrir** |
| AL-3 | 5xx > 1 %, 5 min | 5xx > 1 %, 5 min | **5xx > 1 %, 5 min** |
| AL-4 | p95 > 800 ms, 5 min | p95 > 400 ms, 5 min | **p95 > 400 ms, 5 min** |
| AL-5 | Disco > 80 %, 15 min | Disco > 80 %, instantánea | **Disco > 80 %, instantánea** |
| AL-6 | > 100 denegaciones por IP, 1 min | > 100 por origen, 1 min | **> 100 por origen, 1 min (provisional)** |
| AL-7 | > 26 h | > 26 h | **> 26 h** |

Los valores elegidos son los que ya estaban en `docs/12-despliegue-observabilidad.md` §3.4. **Los de la hoja de Daniel no son independientes:** coinciden con ese documento, incluso en la redacción, porque las instrucciones de la hoja remitían a esa sección (error de la IA al preparar la hoja). Los de Kevin sí son independientes. El equipo comparó ambas propuestas y eligió estos valores.
