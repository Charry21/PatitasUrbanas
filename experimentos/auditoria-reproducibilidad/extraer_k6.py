#!/usr/bin/env python3
"""Extrae de las salidas originales de k6 los valores que transcribe
experimentos/01-metodologia-medicion.md (§4 y §6).

Lee UTF-16 (corridas 1-3, línea base: salida de PowerShell) y UTF-8.
Uso: python3 -I experimentos/auditoria-reproducibilidad/extraer_k6.py <archivo>...
"""
import codecs
import re
import sys


def leer(ruta):
    b = open(ruta, "rb").read()
    if b.startswith(codecs.BOM_UTF16_LE):
        return b.decode("utf-16")
    if b.startswith(codecs.BOM_UTF8):
        return b.decode("utf-8-sig")
    return b.decode("utf-8", errors="replace")


def buscar(patron, texto, grupo=1):
    m = re.search(patron, texto, re.M)
    return m.group(grupo).strip() if m else "-"


print("| Archivo | Script | Escenario | Iteraciones | http_req_failed | checks_succeeded | p95 http_req_duration |")
print("|---|---|---|---:|---|---|---:|")
for ruta in sys.argv[1:]:
    t = leer(ruta)
    script = buscar(r"script:\s*(\S+)", t)
    escenario = buscar(r"^\s*\*\s*(\w+:.*)$", t)
    iteraciones = buscar(r"^\s*iterations\.*:\s*(\d+)", t)
    fallos = buscar(r"^\s*http_req_failed\.*:\s*([^\n]+)", t)
    checks = buscar(r"^\s*checks_succeeded\.*:\s*([^\n]+)", t)
    if checks == "-":
        checks = buscar(r"^\s*checks\.*:\s*([^\n]+)", t)
    p95 = buscar(r"^\s*http_req_duration\.*:.*p\(95\)=(\S+)", t)
    print(f"| `{ruta.split('/')[-1]}` | `{script}` | {escenario[:60]} | {iteraciones} | {re.sub(chr(32)+'+',' ',fallos)} | {re.sub(chr(32)+'+',' ',checks)} | {p95} |")
