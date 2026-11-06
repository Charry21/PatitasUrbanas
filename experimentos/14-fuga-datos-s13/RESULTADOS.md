# Resultados — Prueba de fuga de datos

Preregistro: [README.md](./README.md), commit `3c2b010` y PR #82, abierto el 2026-11-06 a las 01:52:53 UTC. La primera sonda corrió a las 01:53:58 UTC. Las secciones 1 a 5 del README no cambian.

Ejecutado por la IA. Fusionado en `main` con el PR #82 y auditado por el equipo en la EDAV 3 (2026-11-06).

## 1. Cómo se obtuvo cada dato

| | `antes` | `despues` |
|---|---|---|
| Código | `main`, `3f4b124` | `feat/s13-capa-seguridad`, `94f2acf` |
| Despliegue | `docker-compose.yml` | `docker-compose.yml` + `docker-compose.produccion.yml` |
| URL | `http://localhost:3000` | `https://localhost`, con certificado interno de Caddy |
| Repeticiones | 3 | 3 |
| Evidencia | [`resultados/antes/`](./resultados/antes/) | [`resultados/despues/`](./resultados/despues/) |

La imagen se construyó con `Dockerfile.runtime` (F-08). En `despues`, con la línea `USER 10001`, igual que `app/Dockerfile` en esa rama.

## 2. Resultado

Las 3 repeticiones dieron la misma clasificación. **Ninguna de las 26 predicciones se refutó.**

| Sonda | Qué se intentó | `antes` | Detalle `antes` | `despues` | Detalle `despues` |
|---|---|---|---|---|---|
| P01 | Leer solicitudes por la API | Sin fuga | 405 y 404 | Sin fuga | 401 |
| P02 | Actuator interno | Sin fuga | 404 en los 9 | Sin fuga | 401 en los 9 |
| P03 | Detalle de `health` | **Fuga** | Motor de BD, `/app/.` y disco | Sin fuga | `{"status":"UP"}` |
| P04 | Mensajes de error | **Fuga** | `test-fallo` devuelve el mensaje interno | Sin fuga | 400, 400, 403 y 401 |
| P05 | Inyección SQL | Sin fuga | 6/6 guardadas como texto; tablas intactas | Sin fuga | Igual, con token |
| P06 | Crear sin credenciales | **Fuga** | 201, con `idSolicitud` 18 y 19 | Sin fuga | 401 |
| P07 | BD desde otra red | **Fuga** | Leyó el marcador | Sin fuga | Conexión rechazada |
| P08 | Secretos | **Fuga** | 4 líneas versionadas, jar, variables e historial | **Fuga parcial** | Variables del contenedor e historial |
| P09 | Marcador y tokens en logs | Sin fuga | 0 y 0 | Sin fuga | 0 y 0 |
| P10 | `TRACE` y CORS | Sin fuga | 405; sin cabeceras CORS | Sin fuga | 400; sin cabeceras CORS |
| P11 | HTTP en claro hacia fuera | **Fuga** | 200 por `192.0.2.2:3000` | Sin fuga | Sin conexión |
| P12 | Usuario del proceso | **Hallazgo** | root | Sin hallazgo | uid 10001 |
| P13 | 7 tokens inválidos y sin token | **Fuga** | 201 en todos | Sin fuga | 401 en 7, 403 en `sin_permiso`, 201 con el válido |

Tablas completas: [`antes/comparacion.tsv`](./resultados/antes/comparacion.tsv) y [`despues/comparacion.tsv`](./resultados/despues/comparacion.tsv).

## 3. Conclusión

### Hechos

1. En `main`, cualquiera crea solicitudes y, desde otra red, cualquiera lee la BD con la contraseña del repositorio.
2. Hoy esos caminos solo llevan al marcador, porque el sistema no guarda datos personales. El camino existe.
3. La inyección SQL no prosperó: JPA parametriza las consultas.
4. Con los controles de la rama, las 7 sondas con fuga dejan de filtrar, salvo P08, y el hallazgo de P12 desaparece.
5. **Escenario 2:** en `despues`, todos los intentos sin token válido se bloquean. El tiempo de respuesta está en el experimento 15.

### Inferencias

- P07 es el hallazgo más grave, porque da lectura y escritura total sin pasar por la API.
- P08 no llega a cero: la contraseña tiene que estar en algún lugar del servidor, y sigue en el historial de Git. Si esa contraseña no se reutiliza, ya no sirve.

### Lo no verificado

- `SIN_FUGA` solo significa que estas sondas no obtuvieron nada.
- Vulnerabilidades de dependencias, fuerza bruta, denegación de servicio y ataques al anfitrión (README §5).
- El comportamiento con un dominio y un certificado reales.
- La fuga de datos personales: todavía no existen.

## 4. Hallazgos que la prueba destapó y no estaban previstos

| Id | Hallazgo | Evidencia | Qué se hizo |
|---|---|---|---|
| H1 | **Un `estado` de 300 caracteres da 500.** Contradice R-06 ("nunca 500"), que figuraba como **Probada** | `resultados/antes/ejecucion-1/sondas.tsv`, P04, `largo=500` | Nuevo F-14 y R-06 pasa a **Parcial**. Validación en la rama |
| H2 | **La primera versión de la capa rompía los errores 400.** La entrada inválida respondía 401 o 403 porque la denegación por defecto también bloqueaba el reenvío a `/error`. La prueba con MockMvc pasaba: no hace ese reenvío | Primer intento de `despues`, ver D3 | Corregido en `94f2acf`, con una prueba sobre Tomcat real. Sin la corrección, esa prueba falla |

H2 muestra por qué hace falta la prueba de caja negra: las 8 pruebas de integración estaban en verde con el error presente. Además, la sonda clasificó ese intento como `SIN_FUGA`, porque no se filtraba nada. El error se vio al leer los códigos, así que **una clasificación verde no basta**.

## 5. Desviaciones

| Id | Qué pasó | Efecto |
|---|---|---|
| D1 | `ejecutar.sh` tenía dos errores de Bash (variable local y comillas en `filas`). Abortaba antes de terminar. Se corrigió en `03e4c74` y se borraron esas salidas parciales antes de la serie válida | No cambian las sondas ni las predicciones. La salida parcial llegó hasta P05 de la primera repetición |
| D2 | P08 detectaba mal el historial: `grep -q` con `pipefail` podía dar "no". Corregido en `7953fc0` | La clasificación no cambió. `antes` registró `historial=si`, que es correcto, y no se repitió |
| D3 | Hubo un primer intento de `despues` sobre `68f01c1`, que destapó H2. Sus archivos **no se conservaron**: se borraron al limpiar la carpeta temporal | Clasificación igual a la serie válida. Resultado de P04: `tipo=401 largo=403 test_fallo=403 ruta=401`; P08 con `historial=no`. Esos valores se conservan en este documento, no como archivos crudos |
| D4 | `despues` se ejecutó con una copia de la carpeta del experimento dentro de la rama `feat/s13-capa-seguridad`, para que P08 revisara los archivos de esa rama. Los resultados se copiaron después a esta rama | `entorno.txt` registra el hash y la rama reales |

Revisado por el equipo en la EDAV 3 (2026-11-06).
