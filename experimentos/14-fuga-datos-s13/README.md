# Prueba de fuga de datos — Semana 13

> **Estado: preregistro.** Este documento fija las sondas, las predicciones y los criterios **antes** de ejecutar. Los resultados se registran en `RESULTADOS.md` en commits posteriores. Las secciones 1 a 5 no se modifican después de ver los datos; cualquier desviación se anota en `RESULTADOS.md`.

- Fecha del preregistro: 2026-11-05 (America/Bogota)
- Código bajo prueba (`antes`): `main` en `3f4b124` (merge del PR #81), sin cambios en `app/`.
- Código bajo prueba (`despues`): la rama que proponga los controles de seguridad. Su hash se registra en `resultados/despues/entorno.txt`.
- Rama de trabajo: `experimento/s13-s14-seguridad-operacion`
- Lo prepara y lo ejecuta la IA (Claude). El equipo todavía no lo ha revisado.

## 1. Pregunta

¿Qué información que no debería quedar expuesta puede obtener alguien **sin credenciales**, desde fuera de la API, con el sistema tal como se despliega hoy con `docker-compose.yml`?

## 2. Qué se considera fuga

Hay **fuga** cuando la sonda obtiene alguno de estos elementos sin estar autorizada:

- datos de negocio: el contenido de `solicitud_adopcion` o `etapa_adopcion`;
- secretos: contraseñas o claves utilizables;
- detalles internos: estructura de la infraestructura, rutas del contenedor, excepciones, clases o SQL;
- capacidad de escribir o de saber el volumen de datos sin autorización (escenario 2 de `dossier/04-escenarios-calidad.md`).

**Límite importante:** hoy el sistema **no guarda datos personales**. `solicitud_adopcion` solo tiene `estado` y `fecha_creacion`; `etapa_adopcion`, `nombre_etapa` y `fecha_cambio`. El contexto de Identidad no existe. Por eso la prueba usa un **marcador** (`MARCADOR_FUGA_S13`) y demuestra qué caminos existen, no que se hayan expuesto datos reales.

## 3. Sondas y predicciones (preregistradas)

| Id | Sonda | Predicción para `antes` | Predicción para `despues` | Se considera fuga si |
|---|---|---|---|---|
| P01 | Leer solicitudes por la API: `GET` en `/api/adopciones`, `/api/adopciones/1`, `/api/solicitudes` | Sin fuga | Sin fuga | Alguna respuesta contiene el marcador |
| P02 | Endpoints internos de Actuator: `env`, `configprops`, `heapdump`, `threaddump`, `beans`, `mappings`, `metrics`, `loggers`, `prometheus` | Sin fuga | Sin fuga | Alguno responde 200 |
| P03 | Detalle de `/actuator/health` sin credenciales | **Fuga** | Sin fuga | El cuerpo contiene `components`, `database`, `diskSpace` o una ruta |
| P04 | Mensajes de error: tipo inválido, `estado` de 300 caracteres, `/api/adopciones/test-fallo` y ruta inexistente | **Fuga** (el mensaje de `test-fallo`) | Sin fuga | El cuerpo contiene `trace`, una clase `java.`/`org.`, SQL o el mensaje interno de la excepción |
| P05 | Inyección SQL en `estado` y `nombreEtapa`, con 3 cargas | Sin fuga | Sin fuga | La respuesta devuelve otras filas, o las tablas cambian más de lo que explican las peticiones aceptadas |
| P06 | Crear solicitudes sin credenciales y deducir el volumen por el `idSolicitud` | **Fuga** | Sin fuga | `POST /api/adopciones` sin token responde 2xx |
| P07 | Conectarse directamente a PostgreSQL desde **otra red** con la contraseña del repositorio | **Fuga** | Sin fuga | La consulta devuelve el marcador |
| P08 | Secretos en claro: archivos versionados, jar de la imagen y variables del contenedor | **Fuga** | **Fuga parcial**: el historial de Git no cambia | Aparece una contraseña utilizable en alguno de los tres lugares |
| P09 | Datos en los logs: el marcador y el token en `docker logs` | Sin fuga | Sin fuga | El marcador o un token aparecen en el log |
| P10 | Métodos y cabeceras: `TRACE`, CORS con un `Origin` ajeno, cabeceras que revelen tecnología | Sin fuga | Sin fuga | `TRACE` devuelve eco, o hay `Access-Control-Allow-Origin` para el origen ajeno |
| P11 | Transporte en claro: la API responde HTTP sin cifrar por una interfaz que no es *loopback* | **Fuga** | Sin fuga con el despliegue de producción | Hay respuesta HTTP en claro por esa interfaz |
| P12 | Usuario del proceso en el contenedor de la API | **Hallazgo**: root | Sin hallazgo | `id -u` devuelve 0 |
| P13 | Control de acceso con tokens: sin token, firma incorrecta, caducado, `alg=none`, emisor incorrecto, audiencia incorrecta y sin permiso | **Fuga**: no hay control | Sin fuga | Algún caso responde 2xx |

**Razonamiento previo (inferencia, no evidencia):** salen de leer `application.properties`, `docker-compose.yml` y `app/Dockerfile`. Ninguna sonda se ha ejecutado al escribir esta tabla.

**Escenario 2 (`dossier/04-escenarios-calidad.md`):** P06 y P13 lo verifican. La medida del escenario es el 100 % de los intentos bloqueados con 401 en menos de 500 ms. El tiempo se mide con carga en el experimento 15.

## 4. Procedimiento

1. Levantar el sistema con Compose. La imagen de la API se construye con `experimentos/10-crecimiento-s11/entorno/Dockerfile.runtime`, porque `app/Dockerfile` no construye detrás del proxy TLS de este entorno (F-08).
2. Crear una fila con el marcador: `POST /api/adopciones?estado=MARCADOR_FUGA_S13&nombreEtapa=MARCADOR_FUGA_S13`. En `despues` se hace con un token válido.
3. Ejecutar `ejecutar.sh <antes|despues>`, que corre P01–P13 una vez y guarda una tabla (`sondas.tsv`) y la evidencia cruda de cada sonda (`evidencia/`).
4. Repetir la serie **3 veces** para comprobar que el resultado no cambia entre ejecuciones.

La prueba se repite con estos comandos desde la raíz del repositorio:

```bash
docker compose up -d --build
python3 experimentos/14-fuga-datos-s13/generar_tokens.py /tmp/tokens   # clave de prueba y tokens de P13
bash experimentos/14-fuga-datos-s13/ejecutar.sh antes
```

## 5. Criterios y tratamiento de los datos

- Cada sonda se clasifica de forma automática: `FUGA`, `SIN_FUGA` o `HALLAZGO`, según la última columna de §3. Solo P08 admite `FUGA_PARCIAL`: la contraseña ya no está en los archivos versionados ni en el jar, pero sigue en el historial de Git o en las variables del contenedor.
- Una predicción se **refuta** si la clasificación observada no coincide con §3 en alguna de las 3 ejecuciones. Una predicción refutada no se corrige: se explica en `RESULTADOS.md`.
- `SIN_FUGA` significa que **esta sonda** no obtuvo nada. No significa que el sistema sea seguro.
- No se prueban: fuerza bruta de contraseñas, vulnerabilidades de dependencias, denegación de servicio, ataques a Docker o al sistema anfitrión.
- La prueba se ejecuta solo contra contenedores locales de este entorno. No toca ningún servicio externo.
