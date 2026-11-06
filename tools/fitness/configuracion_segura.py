"""FF-02: la configuración desplegable respeta los controles de seguridad y operación.

Uso: python3 -I tools/fitness/configuracion_segura.py [raiz_del_repositorio]
Código de salida: 0 = cumple; 1 = hay violaciones; 2 = falta un archivo que debía existir.
Contrato: docs/fitness/ff-02-configuracion-segura.md
"""
import re
import sys
from pathlib import Path

CLAVE_LITERAL = re.compile(r"(?i)password\s*[:=]\s*(?!\$\{)[^\s#]+")
RUTA_PROPIEDADES = "app/src/main/resources/application.properties"
RUTA_COMPOSE = "docker-compose.yml"
RUTA_PRODUCCION = "docker-compose.produccion.yml"
RUTA_DOCKERFILE = "app/Dockerfile"
RUTA_POM = "app/pom.xml"
RUTA_CONFIG = "app/src/main/java/com/patitasurbanas/api/config/SeguridadConfig.java"


def propiedades(texto):
    pares = {}
    for linea in texto.splitlines():
        linea = linea.strip()
        if linea and not linea.startswith("#") and "=" in linea:
            clave, valor = linea.split("=", 1)
            pares[clave.strip()] = valor.strip()
    return pares


def bloque_servicio(compose, servicio):
    """Texto del servicio dentro de `services:` (indentación de dos espacios)."""
    coincidencia = re.search(rf"^  {servicio}:\n((?:(?:    .*)?\n)+)", compose, re.M)
    return coincidencia.group(1) if coincidencia else ""


def puertos(bloque):
    return re.findall(r'^\s*-\s*"?([^"\n]*:\d+)"?\s*$', bloque, re.M)


def revisar_propiedades(texto):
    p = propiedades(texto)
    v = []
    if p.get("management.endpoints.web.exposure.include", "health") != "health":
        v.append("S1 Actuator solo puede exponer health")
    if p.get("management.endpoint.health.show-details", "never") != "never":
        v.append("S2 health no puede mostrar detalles a un anónimo")
    clave = p.get("spring.datasource.password", "")
    if clave and not clave.startswith("${"):
        v.append("S3 la contraseña de la BD no puede estar en application.properties")
    return v


def revisar_compose(texto):
    v = []
    if CLAVE_LITERAL.search(texto):
        v.append("S3 docker-compose.yml no puede llevar contraseñas literales")
    bd = bloque_servicio(texto, "postgres_db")
    api = bloque_servicio(texto, "api_app")
    if not bd or not api:
        v.append("S0 faltan los servicios postgres_db o api_app")
        return v
    for puerto in puertos(bd):
        if not puerto.startswith("127.0.0.1:"):
            v.append(f"S4 el puerto de la BD debe publicarse solo en 127.0.0.1 (encontrado: {puerto})")
    if not re.search(r"^\s*restart:\s*(unless-stopped|always|on-failure)", api, re.M):
        v.append("O1 la API necesita reinicio automático (R-10)")
    if not re.search(r"SPRING_JPA_HIBERNATE_DDL_AUTO=(update|validate)", api):
        v.append("O2 el reinicio automático exige ddl-auto update o validate (R-11)")
    return v


def revisar_produccion(texto):
    v = []
    if CLAVE_LITERAL.search(texto):
        v.append("S3 docker-compose.produccion.yml no puede llevar contraseñas literales")
    for servicio in ("postgres_db", "api_app"):
        bloque = bloque_servicio(texto, servicio)
        if "ports: !reset []" not in bloque:
            v.append(f"S5 {servicio} no debe publicar puertos en producción")
    if "caddy" not in texto:
        v.append("S6 producción necesita el proxy TLS")
    return v


def revisar_dockerfile(texto):
    ultima = texto.split("FROM ")[-1]
    usuario = re.findall(r"^USER\s+(\S+)", ultima, re.M)
    if not usuario or usuario[-1] in ("root", "0"):
        return ["S7 la etapa final de la imagen no puede ejecutarse como root"]
    return []


def revisar_capa(pom, config):
    v = []
    if "spring-boot-starter-oauth2-resource-server" not in pom:
        v.append("S8 falta la dependencia de la capa de seguridad")
    if ".anyRequest().denyAll()" not in config:
        v.append("S9 toda ruta no declarada debe denegarse")
    return v


def main(raiz):
    base = Path(raiz)
    rutas = [RUTA_PROPIEDADES, RUTA_COMPOSE, RUTA_PRODUCCION, RUTA_DOCKERFILE, RUTA_POM, RUTA_CONFIG]
    faltan = [r for r in rutas if not (base / r).is_file()]
    if faltan:
        print("FF-02 sin evaluar. Faltan:", ", ".join(faltan))
        return 2
    leer = lambda ruta: (base / ruta).read_text(encoding="utf-8")
    violaciones = (
        revisar_propiedades(leer(RUTA_PROPIEDADES))
        + revisar_compose(leer(RUTA_COMPOSE))
        + revisar_produccion(leer(RUTA_PRODUCCION))
        + revisar_dockerfile(leer(RUTA_DOCKERFILE))
        + revisar_capa(leer(RUTA_POM), leer(RUTA_CONFIG))
    )
    for violacion in violaciones:
        print("VIOLACIÓN", violacion)
    print(f"FF-02: {len(violaciones)} violaciones")
    return 1 if violaciones else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "."))
