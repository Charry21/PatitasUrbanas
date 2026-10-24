#!/usr/bin/env python3
"""FF-01 — Fronteras modulares (ADR-02). Contrato: docs/fitness/ff-01-fronteras-modulares.md

Falla (código de salida 1) si alguna clase de producción bajo com.patitasurbanas.api:
  R1. depende de un repositorio o de un modelo de OTRO módulo;
  R2. está en shared/ o config/ y depende de un módulo de negocio;
  R3. está en un paquete de capa técnica (controller, service, repository, model)
      en lugar de un módulo.
Detecta imports explícitos, con comodín y estáticos, y nombres totalmente calificados
en el cuerpo del código. Uso: python3 tools/fitness/fronteras_modulares.py [raiz_app]
"""
import os
import re
import sys

BASE = "com.patitasurbanas.api"
TECNICOS = {"controller", "service", "repository", "model"}
TRANSVERSALES = {"shared", "config"}

RE_PKG = re.compile(r"^\s*package\s+([\w.]+)\s*;", re.M)
RE_IMPORT = re.compile(r"^\s*import\s+(?:static\s+)?([\w.]+?)(\.\*)?\s*;", re.M)
RE_FQN = re.compile(re.escape(BASE) + r"\.([a-z]\w*)((?:\.[a-z]\w*)*)\.([A-Z]\w*)")


def modulo(pkg):
    if not pkg.startswith(BASE + "."):
        return None
    return pkg[len(BASE) + 1:].split(".")[0]


def destino(texto):
    """De 'com.patitasurbanas.api.mod.sub.Clase' o 'com...api.mod.sub' (comodín) -> (mod, es_interno, nombre)."""
    resto = texto[len(BASE) + 1:].split(".")
    mod = resto[0]
    clase = next((p for p in resto[1:] if p[:1].isupper()), None)
    subpaquetes = [p for p in resto[1:] if p[:1].islower()]
    es_modelo = "model" in subpaquetes
    es_repo = bool(clase and clase.endswith("Repository"))
    comodin_sin_clase = clase is None
    return mod, es_modelo or es_repo or comodin_sin_clase, (clase or ".".join(resto) + ".*")


def sin_comentarios(src):
    src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
    return re.sub(r"//[^\n]*", "", src)


def revisar(raiz_app):
    raiz = os.path.join(raiz_app, "src", "main", "java")
    violaciones, clases = [], 0
    for d, _, fs in os.walk(raiz):
        for f in sorted(fs):
            if not f.endswith(".java"):
                continue
            ruta = os.path.join(d, f)
            src = sin_comentarios(open(ruta, encoding="utf-8").read())
            m = RE_PKG.search(src)
            pkg = m.group(1) if m else ""
            origen = modulo(pkg)
            if origen is None:
                continue
            clases += 1
            if origen in TECNICOS:
                violaciones.append((ruta, "R3", f"clase en el paquete técnico '{origen}', fuera de un módulo"))
            refs = set()
            for imp, comodin in RE_IMPORT.findall(src):
                if imp.startswith(BASE + "."):
                    refs.add(imp if not comodin else imp)
            for mod, sub, cls in RE_FQN.findall(src):
                refs.add(f"{BASE}.{mod}{sub}.{cls}")
            for ref in sorted(refs):
                mod_d, interno, nombre = destino(ref)
                if mod_d == origen:
                    continue
                if origen in TRANSVERSALES and mod_d not in TRANSVERSALES:
                    violaciones.append((ruta, "R2", f"'{origen}' depende del módulo de negocio '{mod_d}' ({nombre})"))
                elif interno and mod_d not in TRANSVERSALES:
                    violaciones.append((ruta, "R1", f"'{origen}' depende de un elemento interno de '{mod_d}' ({nombre})"))
    return clases, violaciones


def main():
    raiz_app = sys.argv[1] if len(sys.argv) > 1 else "app"
    clases, v = revisar(raiz_app)
    print(f"FF-01 fronteras modulares: {clases} clases revisadas bajo {BASE}")
    for ruta, regla, msg in v:
        print(f"  VIOLACIÓN {regla}: {ruta}: {msg}")
    if clases == 0:
        print("  ERROR: no se encontró ninguna clase; revise la ruta")
        return 2
    print("RESULTADO: " + ("FALLA" if v else "CUMPLE") + f" ({len(v)} violación(es))")
    return 1 if v else 0


if __name__ == "__main__":
    sys.exit(main())
