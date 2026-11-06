"""Análisis del experimento 15 según README.md §6. Se ejecuta desde la raíz del repositorio.

Uso: python3 experimentos/15-costo-seguridad-s13/analizar.py
Salida: resultados/corridas.csv, resultados/celdas.csv y resultados/analisis.txt
"""
import csv
import json
import statistics as st
from pathlib import Path

RES = Path("experimentos/15-costo-seguridad-s13/resultados")
OPERACIONES = ("buscar", "adopcion", "sin_token")
LIM_P95 = 800
LIM_FALLOS = 1.0
LIM_K6 = 80.0
LIM_TOTAL = 90.0
LIM_CS = 10.0
LIM_TC = 15.0


def contador(metricas, nombre):
    return int(metricas.get(nombre, {}).get("values", {}).get("count", 0))


def cpu(ruta):
    filas = list(csv.DictReader(ruta.open()))
    if not filas:
        return None, None, None
    return tuple(
        round(st.mean(float(f[c]) for f in filas), 1)
        for c in ("k6_pct", "cpu_total_pct", "java_pct")
    )


def leer_corridas():
    corridas = []
    for bloque in sorted(RES.glob("bloque-*")):
        _, numero, condicion = bloque.name.split("-")
        for archivo in sorted(bloque.glob("*-c?.json")):
            operacion, corrida = archivo.stem.rsplit("-c", 1)
            metricas = json.loads(archivo.read_text())["metrics"]
            duracion = metricas["http_req_duration"]["values"]
            k6, total, java = cpu(archivo.with_suffix(".cpu.csv"))
            corridas.append({
                "bloque": int(numero),
                "condicion": condicion,
                "operacion": operacion,
                "corrida": int(corrida),
                "valida": int(corrida) > 1,
                "reqs": int(metricas["http_reqs"]["values"]["count"]),
                "rps": round(metricas["http_reqs"]["values"]["rate"], 2),
                "p50": round(duracion["med"], 2),
                "p95": round(duracion["p(95)"], 2),
                "p99": round(duracion["p(99)"], 2),
                "max": round(duracion["max"], 2),
                "fallos_pct": round(metricas["http_req_failed"]["values"]["rate"] * 100, 3),
                "c2xx": contador(metricas, "codigos_2xx"),
                "c401": contador(metricas, "codigos_401"),
                "c4xx_otros": contador(metricas, "codigos_4xx_otros"),
                "c5xx": contador(metricas, "codigos_5xx"),
                "sin_respuesta": contador(metricas, "codigos_sin_respuesta"),
                "cpu_k6": k6,
                "cpu_total": total,
                "cpu_java": java,
            })
    return corridas


def escribir(ruta, filas):
    with ruta.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(filas[0]))
        w.writeheader()
        w.writerows(filas)


def celda(corridas, condicion, operacion):
    validas = [c for c in corridas if c["condicion"] == condicion and c["operacion"] == operacion and c["valida"]]
    if not validas:
        return None
    bloques = sorted({c["bloque"] for c in validas})
    por_bloque = [st.median(c["p95"] for c in validas if c["bloque"] == b) for b in bloques]
    return {
        "condicion": condicion,
        "operacion": operacion,
        "corridas_validas": len(validas),
        "p50": round(st.median(c["p50"] for c in validas), 2),
        "p95": round(st.median(c["p95"] for c in validas), 2),
        "p99": round(st.median(c["p99"] for c in validas), 2),
        "rps": round(st.median(c["rps"] for c in validas), 2),
        "fallos_pct": round(st.median(c["fallos_pct"] for c in validas), 3),
        "p95_bloque_a": round(por_bloque[0], 2),
        "p95_bloque_b": round(por_bloque[-1], 2),
        "ruido_ms": round(abs(por_bloque[0] - por_bloque[-1]), 2),
        "cpu_k6_max": max(c["cpu_k6"] for c in validas),
        "cpu_total_max": max(c["cpu_total"] for c in validas),
        "cpu_java_max": max(c["cpu_java"] for c in validas),
        "instrumento_ok": all(c["cpu_k6"] < LIM_K6 and c["cpu_total"] < LIM_TOTAL for c in validas),
    }


def comparar(a, b, limite, salida):
    delta = round(b["p95"] - a["p95"], 2)
    ruido = max(a["ruido_ms"], b["ruido_ms"])
    instrumento = a["instrumento_ok"] and b["instrumento_ok"]
    concluyente = instrumento and abs(delta) > ruido
    salida.append(
        f"  {a['operacion']}: Δ({b['condicion']}−{a['condicion']}) = {delta} ms; ruido = {ruido} ms; "
        f"instrumento_ok = {instrumento}; concluyente = {concluyente}; "
        f"límite = {limite} ms; {'REFUTADA' if delta > limite else 'NO REFUTADA'}"
    )
    return delta


def main():
    corridas = leer_corridas()
    escribir(RES / "corridas.csv", corridas)
    celdas = {}
    for condicion in "SCT":
        for operacion in OPERACIONES:
            c = celda(corridas, condicion, operacion)
            if c:
                celdas[condicion, operacion] = c
    escribir(RES / "celdas.csv", list(celdas.values()))

    s = ["Análisis del experimento 15 (reglas de README.md §6)", ""]
    s.append("HC1: p95 < 800 ms y fallos < 1 % en C y T")
    for (condicion, operacion), c in celdas.items():
        if condicion in "CT" and operacion != "sin_token":
            ok = c["p95"] < LIM_P95 and c["fallos_pct"] < LIM_FALLOS
            s.append(f"  {condicion}/{operacion}: p95 = {c['p95']} ms; fallos = {c['fallos_pct']} %; {'NO REFUTADA' if ok else 'REFUTADA'}")
    s += ["", "HC2: Δ(C−S) ≤ 10 ms"]
    for operacion in ("buscar", "adopcion"):
        comparar(celdas["S", operacion], celdas["C", operacion], LIM_CS, s)
    s += ["", "HC3: Δ(T−C) ≤ 15 ms"]
    for operacion in ("buscar", "adopcion"):
        comparar(celdas["C", operacion], celdas["T", operacion], LIM_TC, s)
    s += ["", "HC4: k6 < 80 % de un núcleo y total < 90 % en cada corrida válida"]
    for (condicion, operacion), c in celdas.items():
        s.append(f"  {condicion}/{operacion}: k6 máx = {c['cpu_k6_max']}; total máx = {c['cpu_total_max']}; {'NO REFUTADA' if c['instrumento_ok'] else 'REFUTADA'}")
    s += ["", "HC5: sin_token"]
    denegadas = celdas.get(("C", "sin_token"))
    if denegadas:
        filas_c = [c for c in corridas if c["condicion"] == "C" and c["operacion"] == "sin_token"]
        total = sum(c["reqs"] for c in filas_c)
        c401 = sum(c["c401"] for c in filas_c)
        auditoria = sum(int(p.read_text()) for p in RES.glob("bloque-*-C/lineas-auditoria.txt"))
        ok = c401 == total and denegadas["p95"] < 500 and auditoria == c401
        s.append(f"  peticiones = {total}; 401 = {c401}; líneas de auditoría = {auditoria}; p95 = {denegadas['p95']} ms; {'NO REFUTADA' if ok else 'REFUTADA'}")
    (RES / "analisis.txt").write_text("\n".join(s) + "\n")
    print("\n".join(s))


if __name__ == "__main__":
    main()
