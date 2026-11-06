# Resultados — Reinicio automático (R-10) y conservación de datos (R-11)

Preregistro: [README.md](./README.md). Evidencia cruda: [`resultados/bitacora.txt`](./resultados/bitacora.txt) y [`resultados/entorno.txt`](./resultados/entorno.txt).

Fecha de ejecución: 2026-11-06 01:55–01:57 UTC (2026-11-05 en Bogotá). Imagen construida desde `main` (`3f4b124`). Ejecutado por la IA; pendiente de revisión del equipo.

## 1. Veredicto de las hipótesis

| Id | Predicción | Observado | Veredicto |
|---|---|---|---|
| HR1 | Primer 200 en ≤ 120 s en 5/5 ciclos | Con R-10 sola: 7,45 / 7,92 / 8,59 s (mín. / mediana / máx.), 5/5. Con R-10 + R-11: 7,41 / 7,90 / 9,00 s, 5/5 | **No refutada** |
| HR2 | Con `create-drop`, 0 filas después de cada reinicio automático | 5/5 ciclos: de `5,5` a `0,0` | **No refutada: la pérdida de datos es real** |
| HR3 | Con `update`, se conservan todas las filas | 5/5 ciclos: 5, 10, 15, 20 y 25 filas antes y después; 25 respuestas 201 y 25 filas | **No refutada** |
| HR4 | Tras `docker stop`, no vuelve sola en 30 s | `estado=exited`, 5 reinicios (sin cambio) | **No refutada** |
| HR5 | Sin `restart:`, sigue detenida a los 30 s | `estado=exited`, 0 reinicios | **No refutada** |

## 2. Hechos

1. **La condición del ADR-04 tiene evidencia:** con `restart: unless-stopped`, la API se recupera sola de un `kill -9` en menos de 10 s en los 10 ciclos.
2. **R-10 sola es peligrosa con la configuración actual:** en los 5 ciclos con `create-drop`, cada caída borró todos los datos sin intervención de nadie.
3. **R-10 + R-11 conserva los datos** y tarda lo mismo.
4. El tiempo medido es desde el `kill -9` hasta el primer 200 en `/api/mascotas/buscar`, sin tráfico.

## 3. Inferencias

- **El orden del plan M6-3 debería cambiar:** R-11 tiene que entrar junto con R-10, no en cuarto lugar. Con R-10 sola, F-13 deja de ser un riesgo de arranque manual y pasa a dispararse con cada caída.
- El tiempo de indisponibilidad queda dentro del RTO de 120 s del escenario reformulado 2. Falta probarlo con tráfico.

## 4. Lo no verificado

- La recuperación con tráfico concurrente, ni qué pasa con las peticiones en curso.
- Una API colgada que no termina: Docker no la reinicia (`README.md` §5).
- La caída de la máquina, del daemon de Docker o de PostgreSQL con esta política.
- `app/Dockerfile` original: se usó la variante `Dockerfile.runtime` (F-08).
- `update` frente a cambios incompatibles del esquema.

## 5. Desviaciones

Ninguna frente al preregistro.
