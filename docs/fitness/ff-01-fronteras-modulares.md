# Contrato de fitness function FF-01 — Fronteras modulares (A6)

| Campo | Contenido |
|---|---|
| **Decisión arquitectónica** | ADR-02 (reglas de dependencia entre módulos, Alternativa A: convención + revisión de PR) y ADR-01 (monolito modular por dominio). Veredicto del spike 1: "se adopta con condiciones"; la primera condición es reevaluar automatizar las fronteras (`experimentos/09-cierre-spike-s10.md` §6.2) |
| **Propiedad comprobable** | Las fronteras entre módulos declaradas en ADR-02 se respetan en el código de producción |
| **Alcance** | Clases Java de `app/src/main/java` bajo `com.patitasurbanas.api`. No incluye tests ni `PatitasUrbanasApplication` (paquete raíz) |
| **Condición de cumplimiento** | 0 violaciones de las reglas R1–R3 |
| **Condición de fallo** | 1 o más violaciones → la comprobación termina con código 1 y el job de CI falla. Código 2 si no encuentra ninguna clase (ruta mal configurada) |
| **Mecanismo de ejecución** | `tools/fitness/fronteras_modulares.py`, ejecutado por el workflow `.github/workflows/fitness-functions.yml` en cada `push` a `main` y en cada pull request |
| **Prueba negativa** | `tools/fitness/prueba_negativa.sh` inyecta en una copia de `app/` cinco violaciones (una por regla y forma de dependencia) y exige que cada una haga fallar la comprobación. Se ejecuta en el mismo job de CI |

## Reglas (tomadas de ADR-02 §"Prohibidas" y §"Regla general")

| Regla | Texto en ADR-02 | Qué comprueba el script |
|---|---|---|
| R1 | "Ningún módulo puede importar clases internas (repositorios, modelos) de otro módulo" | Dependencias de un módulo hacia una clase `…Repository`, hacia el subpaquete `model` de otro módulo, o hacia otro módulo con un comodín |
| R2 | "`shared/` ✗──→ adopciones/ · mascotas/ · veterinarias/" y "`config/` ✗──→ lógica de negocio de ningún módulo" | Dependencias de `shared` o `config` hacia cualquier módulo de negocio |
| R3 | Organización por módulos de ADR-01 (sustituye los paquetes por capa técnica) | Ninguna clase en `api.controller`, `api.service`, `api.repository` ni `api.model` |

**Formas de dependencia detectadas:** imports explícitos, con comodín y estáticos, y nombres totalmente calificados en el cuerpo del código (sin contar los comentarios). Esto corrige las limitaciones del medidor Y2 del spike (P8 de `09-cierre-spike-s10.md` §4.2).

## Evidencia de la calibración (2026-10-24)

| Prueba | Resultado esperado | Resultado obtenido |
|---|---|---|
| `main` actual | Cumple | 7 clases, 0 violaciones, código 0 |
| Prueba negativa (5 casos) | Los 5 fallan | 5/5 fallan con código 1 |
| `app/` en `887ccf1` (antes de la reorganización) | Falla | 9 violaciones (R3), código 1 |

## Limitaciones declaradas

- No ve dependencias por reflexión, por inyección declarada solo en configuración ni dentro de cadenas de texto.
- Un comodín hacia otro módulo cuenta como violación aunque solo se usen clases públicas (criterio conservador).
- El dueño de cada clase es el primer segmento del paquete bajo `com.patitasurbanas.api`. Una clase de un dominio puesta en el paquete de otro **no** se detecta: eso sigue dependiendo de la revisión de PR (ADR-02).
- La regla R3 lista las capas técnicas que existían antes del spike. Si aparece otro nombre de capa (por ejemplo, `dto`), hay que añadirlo al script.

## Calendario del curso

- Definición: Semana 12 (este documento).
- Ejecución en CI: activa desde su integración en `main`; el curso exige que esté a más tardar en la Semana 14.

## Información que falta para comprobarla completamente

- Que el workflow se haya ejecutado en GitHub Actions y aparezca en verde en `main`. Se verifica en la pestaña **Actions** del repositorio después de fusionar.
- Que el equipo confirme R3 como regla de ADR-01 o la retire.

---

*Autores: Kevin Steven Torres Caro · Charry Ríos Daniel Estiven*
*Semana 12 · Módulo 6 · Arquitectura de Software*
