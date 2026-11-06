# Verificación del README en Windows (pendiente de ADR-05 y EDAV 3)

| Dato | Valor |
|---|---|
| Fecha | 2026-11-06, hacia las 15:50 (Bogotá); las respuestas HTTP marcan 20:54–20:55 UTC |
| Quién | Kevin Torres, en su computador con Windows y Docker Desktop, con PowerShell desde la terminal de VS Code |
| Código | `main` en `6429da9`, clonado en una carpeta nueva (`PatitasUrbanas-s14`) |
| Evidencia | [`salida-terminal.txt`](./salida-terminal.txt), copia de la terminal sin cambios |

## Resultado: todo según lo esperado

| Comprobación | Esperado | Obtenido |
|---|---|---|
| `docker compose up -d --build` con `app/Dockerfile` | Construye y arranca | Imagen construida en 85,5 s; BD `healthy` y API arriba |
| Puertos | Solo `127.0.0.1` | `127.0.0.1:3000` y `127.0.0.1:5433` |
| `GET /actuator/health` | `{"status":"UP"}` | `{"status":"UP"}` |
| `POST /api/adopciones` sin token | 401 | 401, con `WWW-Authenticate: Bearer` |
| `POST /api/adopciones` con `secretos/valido.jwt` | 201 | 201, `idSolicitud` 1 |
| Filas antes y después de `docker compose restart api_app` | Iguales | 1 y 1 |

## Diferencias con el README que aparecieron

1. **Python no estaba instalado** (`py` y `python` no existen; Windows ofrece la Microsoft Store). Las claves se generaron con Docker, sin instalar Python:

   ```powershell
   docker run --rm -v "${PWD}:/w" -w /w python:3.12-slim sh -c "pip install -q pyjwt cryptography && python experimentos/14-fuga-datos-s13/generar_tokens.py secretos"
   ```

   Esta alternativa se añadió al README.
2. **`Start-Transcript` falló la segunda vez** porque la transcripción ya estaba activa desde el primer intento. No afecta a la prueba: la evidencia se copió de la terminal.

## Lo no verificado en Windows

- `mvn test`: Java y Maven no hacían falta para levantar el proyecto y no se ejecutaron.
- El caso del volumen con la contraseña anterior (`docker compose down -v`): se evitó usando una carpeta nueva, que crea un volumen nuevo.
- El Compose de producción con el proxy TLS.

Estos tres puntos sí se verificaron en Linux: [`../arranque-limpio-2026-11-06/`](../arranque-limpio-2026-11-06/).
