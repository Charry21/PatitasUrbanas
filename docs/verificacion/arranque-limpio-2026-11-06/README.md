# Verificación del arranque en una máquina limpia (paso 2)

Fecha: 2026-11-06. El equipo pidió a la IA hacer esta verificación. **No la ejecutó una persona del equipo.**

| Dato | Valor |
|---|---|
| Dónde | GitHub Actions, `ubuntu-latest`, sin proxy TLS: Docker 28.0.4, Compose 2.38.2, Java 21.0.13 |
| Ejecución | [`42232989485`](https://github.com/Charry21/PatitasUrbanas/actions/runs/42232989485), *success* |
| Código | `f8533c3`: `feat/s13-capa-seguridad` en `df2d562`, integrada con `experimento/s13-s14-seguridad-operacion`, más este script |
| Por qué en Actions | En el entorno de la IA, `docker compose up --build` falla: el contenedor de build no puede descargar de Maven (F-08) |
| Evidencia | [`verificar.sh`](./verificar.sh), [`workflow-usado.yml`](./workflow-usado.yml) y [`salida-completa.txt`](./salida-completa.txt) |

La rama temporal `prueba/s14-verificacion-arranque` ya no hace falta y se puede borrar en GitHub. El workflow se conserva aquí para poder repetir la prueba.

## Resultado: 0 comprobaciones fallidas

| Parte | Qué se comprobó | Resultado |
|---|---|---|
| A | Pasos del README con `app/Dockerfile` | La API arrancó en 57 s |
| B | `health` sin detalles, 401 sin token, 201 con token, 400 con entrada inválida | Correcto |
| B | Filas tras `docker compose restart` y tras `kill -9` | 3 de 3 en ambos casos. Primer 200 tras `kill -9`: 5,16 s |
| B | Usuario 10001; API y BD solo en `127.0.0.1` | Correcto |
| C | `mvn test` contra la BD de Compose | 11/11. Las pruebas borran las tablas, como advierte el README |
| D | Volumen con la contraseña anterior | La API no conecta (`password authentication failed`); con `down -v` arranca |
| E | Compose de producción: HTTPS, 308 desde HTTP, 3000 y 5433 cerrados | Correcto |
| E | Prueba de fuga con la imagen real, 3 repeticiones | 0 de 13 predicciones refutadas |

## Lo no verificado

- **Windows con Docker Desktop y los comandos de PowerShell del README.** Se probó en Linux.
- El costo sobre el p95 con esta imagen: el experimento 15 usó `Dockerfile.runtime`.
- La revisión de una persona del equipo.
