#!/usr/bin/env python3
"""Medidor de Y2, Y4 e Y5 del spike de fronteras modulares (Semana 10).

Especificación: experimentos/04-spike-especificacion-s9.md (§2, §3 y §5).

- Clasificación de clases: mapeo de dossier/15-diseno-modular-s7.md §7
  (por nombre de clase, igual antes y después de reorganizar).
- Y2: imports de clases del proyecto que incumplen las reglas prohibidas de
  adr/adr-02-modularidad.md.
- Y4: % de las 7 clases de producción del mapeo ubicadas en su módulo objetivo.
- Y5: paquetes bajo com.patitasurbanas.api con clases de más de un dominio.

Uso: python3 experimentos/spike-s10/revisar_modulos.py [raiz_app]
Solo analiza app/src/main/java (código de producción).
"""
import os
import re
import sys

BASE_PKG = "com.patitasurbanas.api"

# Mapeo de dossier/15-diseno-modular-s7.md §7: clase -> (módulo, tipo)
# tipo: publico (controller/service), repositorio o modelo (internos al módulo)
MAPEO = {
    "AdopcionController": ("adopciones", "publico"),
    "AdopcionService": ("adopciones", "publico"),
    "SolicitudAdopcionRepository": ("adopciones", "repositorio"),
    "EtapaAdopcionRepository": ("adopciones", "repositorio"),
    "SolicitudAdopcion": ("adopciones", "modelo"),
    "EtapaAdopcion": ("adopciones", "modelo"),
    "MascotaController": ("mascotas", "publico"),
}
DOMINIOS = {"adopciones", "mascotas", "veterinarias"}
MODULOS = DOMINIOS | {"shared", "config"}

RE_PKG = re.compile(r"^\s*package\s+([\w.]+)\s*;", re.M)
RE_IMPORT = re.compile(r"^\s*import\s+(static\s+)?([\w.]+)(\.\*)?\s*;", re.M)


def modulo_por_paquete(pkg):
    """Módulo según el paquete (para clases fuera del mapeo)."""
    if not pkg.startswith(BASE_PKG + "."):
        return None
    seg = pkg[len(BASE_PKG) + 1:].split(".")[0]
    return seg if seg in MODULOS else None


def clasificar(nombre, pkg):
    if nombre in MAPEO:
        return MAPEO[nombre]
    mod = modulo_por_paquete(pkg)
    if mod is None:
        return (None, None)
    tipo = "publico"
    if nombre.endswith("Repository"):
        tipo = "repositorio"
    elif ".model" in pkg:
        tipo = "modelo"
    return (mod, tipo)


def leer_clases(raiz_java):
    clases = {}
    for dirpath, _, files in os.walk(raiz_java):
        for f in sorted(files):
            if not f.endswith(".java"):
                continue
            ruta = os.path.join(dirpath, f)
            src = open(ruta, encoding="utf-8").read()
            m = RE_PKG.search(src)
            pkg = m.group(1) if m else ""
            nombre = f[:-5]
            imports = [g[1] for g in RE_IMPORT.findall(src) if not g[0]]
            clases[pkg + "." + nombre] = {
                "nombre": nombre, "pkg": pkg, "ruta": ruta, "imports": imports,
            }
    return clases


def es_violacion(origen, destino):
    mod_o, _ = origen
    mod_d, tipo_d = destino
    if mod_o is None or mod_d is None or mod_o == mod_d:
        return None
    if mod_o == "shared" and mod_d in DOMINIOS:
        return "shared no puede depender de módulos de negocio"
    if mod_o == "config" and mod_d in DOMINIOS:
        return "config no puede depender de lógica de negocio"
    if tipo_d == "repositorio":
        return "repositorio interno de otro módulo"
    if tipo_d == "modelo":
        return "modelo interno de otro módulo"
    return None


def main():
    raiz_app = sys.argv[1] if len(sys.argv) > 1 else "app"
    raiz_java = os.path.join(raiz_app, "src", "main", "java")
    clases = leer_clases(raiz_java)

    print("== Clases de producción (paquete actual -> módulo según mapeo)")
    for fq, c in sorted(clases.items()):
        mod, tipo = clasificar(c["nombre"], c["pkg"])
        print(f"  {c['nombre']:<30} {c['pkg']:<45} -> {mod or '-'} ({tipo or 'fuera del mapeo'})")

    # Y2
    print("\n== Y2: imports del proyecto evaluados")
    violaciones = []
    for fq, c in sorted(clases.items()):
        origen = clasificar(c["nombre"], c["pkg"])
        for imp in c["imports"]:
            if not imp.startswith(BASE_PKG + "."):
                continue
            destino_c = clases.get(imp)
            nombre_d = imp.rsplit(".", 1)[1]
            pkg_d = imp.rsplit(".", 1)[0]
            destino = clasificar(nombre_d, pkg_d) if destino_c is None else clasificar(destino_c["nombre"], destino_c["pkg"])
            motivo = es_violacion(origen, destino)
            estado = f"PROHIBIDO ({motivo})" if motivo else "permitido"
            print(f"  {c['nombre']} [{origen[0]}] -> {nombre_d} [{destino[0]}/{destino[1]}]: {estado}")
            if motivo:
                violaciones.append((c["nombre"], imp, motivo))
    print(f"\nY2 = {len(violaciones)} import(s) prohibido(s)")

    # Y4
    print("\n== Y4: clases del mapeo en su módulo objetivo")
    en_modulo = 0
    for nombre, (mod, _) in MAPEO.items():
        c = next((c for c in clases.values() if c["nombre"] == nombre), None)
        if c is None:
            print(f"  {nombre:<30} NO ENCONTRADA")
            continue
        ok = c["pkg"] == f"{BASE_PKG}.{mod}" or c["pkg"].startswith(f"{BASE_PKG}.{mod}.")
        en_modulo += ok
        print(f"  {nombre:<30} {c['pkg']:<45} objetivo={mod:<11} {'SI' if ok else 'NO'}")
    y4 = 100.0 * en_modulo / len(MAPEO)
    print(f"\nY4 = {en_modulo}/{len(MAPEO)} = {y4:.1f}%")

    # Y5
    print("\n== Y5: dominios por paquete")
    por_pkg = {}
    for c in clases.values():
        if not c["pkg"].startswith(BASE_PKG):
            continue
        mod, _ = clasificar(c["nombre"], c["pkg"])
        if mod in DOMINIOS:
            por_pkg.setdefault(c["pkg"], set()).add(mod)
    mezclados = 0
    for pkg, doms in sorted(por_pkg.items()):
        mezcla = len(doms) > 1
        mezclados += mezcla
        print(f"  {pkg:<45} {sorted(doms)}{'  <- MEZCLA' if mezcla else ''}")
    print(f"\nY5 = {mezclados} paquete(s) que mezclan dominios")


if __name__ == "__main__":
    main()
