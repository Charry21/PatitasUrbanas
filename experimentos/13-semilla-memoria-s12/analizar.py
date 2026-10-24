#!/usr/bin/env python3
"""Análisis del experimento 13 según README §6. Uso: python3 -I analizar.py <dir_resultados>"""
import csv, statistics as st, sys, os
R = sys.argv[1]
import re
def k6(c, n):
    # Desviación D1: los JSON de resumen no se guardaron (permiso denegado en el volumen de k6);
    # se usa la línea de resumen de k6 guardada en <condición>-c<n>.txt (misma fuente: handleSummary).
    t = open(os.path.join(R, f"{c}-c{n}.txt")).read()
    v = dict(re.findall(r"(\w+)=([\d.]+)", t))
    return {"p50": float(v["p50"]), "p95": float(v["p95"]), "p99": float(v["p99"]), "rps": float(v["rps"]),
            "fallos": float(v["fallos"]), "reqs": float(v["reqs"])}
def jvm(path):
    filas = list(csv.DictReader(open(path)))
    return [float(f["rss_mib"]) for f in filas], [float(f["cpu_pct_nucleo"]) for f in filas]
rss0, cpu0 = jvm(os.path.join(R, "reposo.csv"))
print(f"Reposo (30 s): RSS medio {st.mean(rss0):.1f} MiB (mín {min(rss0):.1f}, máx {max(rss0):.1f}); CPU media {st.mean(cpu0):.2f} % de un núcleo")
res = {}
for c in ("vacia", "sembrada"):
    print(f"\n== {c}")
    print("corrida | estado | p50 | p95 | p99 | req/s | fallos % | RSS máx MiB | CPU media % núcleo")
    val = []
    for n in (1, 2, 3, 4):
        m = k6(c, n); rss, cpu = jvm(os.path.join(R, f"{c}-c{n}.jvm.csv"))
        m["rss_max"], m["cpu_media"] = max(rss), st.mean(cpu[1:-1] if len(cpu) > 2 else cpu)
        estado = "descartada" if n == 1 else "válida"
        print(f"{n} | {estado} | {m['p50']:.2f} | {m['p95']:.2f} | {m['p99']:.2f} | {m['rps']:.2f} | {m['fallos']:.2f} | {m['rss_max']:.1f} | {m['cpu_media']:.1f}")
        if n > 1: val.append(m)
    res[c] = {k: st.median(v[k] for v in val) for k in val[0]}
    print("mediana válidas: " + ", ".join(f"{k}={v:.2f}" for k, v in res[c].items()))
dif = (res["sembrada"]["p95"] - res["vacia"]["p95"]) / res["vacia"]["p95"] * 100
print(f"\nHS1: diferencia relativa p95 (sembrada vs vacía) = {dif:+.1f} % -> {'REFUTADA' if abs(dif) >= 20 else 'no refutada'} (umbral 20 %)")
print(f"HS2: mediana de fallos vacía={res['vacia']['fallos']:.2f} % sembrada={res['sembrada']['fallos']:.2f} % -> {'REFUTADA' if max(res['vacia']['fallos'], res['sembrada']['fallos']) >= 1 else 'no refutada'} (umbral 1 %)")
