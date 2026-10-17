"""Análisis del experimento de crecimiento S11 (reglas fijadas en README §6).

Uso: python3 analizar.py            -> lee resultados/<operacion>/ y escribe
     resultados/corridas.csv, resultados/escalones.csv, resultados/verificacion-hipotesis.txt
     y resultados/grafica-crecimiento.png
"""
import csv
import json
import statistics as st
from pathlib import Path

DIR = Path(__file__).resolve().parent / "resultados"
OPERACIONES = ["buscar", "adopcion"]
ESCALONES = [50, 100, 150, 200]
CORRIDAS = [1, 2, 3, 4]
VALIDAS = [2, 3, 4]
UMBRAL_P95 = 800.0
UMBRAL_FALLOS = 0.01
LIM_K6 = 80.0       # % de un núcleo
LIM_TOTAL = 90.0    # % de la máquina


def contador(m, nombre):
    return int(m.get(nombre, {}).get("values", {}).get("count", 0))


def cpu(ruta):
    filas = list(csv.DictReader(open(ruta)))
    # descarta el primer segundo (arranque de k6) y lo posterior a los 40 s del escalón
    filas = [f for f in filas if 2.0 <= float(f["t_s"]) <= 41.0] or filas
    media = lambda c: round(st.mean(float(f[c]) for f in filas), 1)
    return {"cpu_total": media("cpu_total_pct"), "cpu_k6": media("k6_pct"),
            "cpu_java": media("java_pct"), "cpu_pg": media("postgres_pct"),
            "cpu_total_max": max(float(f["cpu_total_pct"]) for f in filas)}


def corrida(op, n, c):
    base = DIR / op / f"u{n}-c{c}"
    m = json.load(open(f"{base}.json"))["metrics"]
    d = m["http_req_duration"]["values"]
    r = {"operacion": op, "usuarios": n, "corrida": c, "estado": "valida" if c in VALIDAS else "descartada",
         "peticiones": int(m["http_reqs"]["values"]["count"]), "rps": round(m["http_reqs"]["values"]["rate"], 2),
         "lat_media_ms": round(d["avg"], 2), "p50_ms": round(d["med"], 2), "p95_ms": round(d["p(95)"], 2),
         "p99_ms": round(d["p(99)"], 2), "max_ms": round(d["max"], 2),
         "fallos_pct": round(m["http_req_failed"]["values"]["rate"] * 100, 3),
         "c2xx": contador(m, "codigos_2xx"), "c4xx": contador(m, "codigos_4xx"),
         "c5xx": contador(m, "codigos_5xx"), "sin_respuesta": contador(m, "codigos_sin_respuesta"),
         "iter_p95_ms": round(m["iteration_duration"]["values"]["p(95)"], 1)}
    r.update(cpu(f"{base}.cpu.csv"))
    return r


def main():
    corridas, escalones, texto = [], [], []
    for op in OPERACIONES:
        if not (DIR / op).exists():
            continue
        for n in ESCALONES:
            rs = [corrida(op, n, c) for c in CORRIDAS if (DIR / op / f"u{n}-c{c}.json").exists()]
            corridas += rs
            v = [r for r in rs if r["estado"] == "valida"]
            if len(v) < len(VALIDAS):
                texto.append(f"{op} u{n}: solo {len(v)} corridas válidas, escalón incompleto")
                continue
            med = lambda k: round(st.median(r[k] for r in v), 2)
            e = {"operacion": op, "usuarios": n, "rps_mediana": med("rps"), "p50_mediana_ms": med("p50_ms"),
                 "p95_mediana_ms": med("p95_ms"), "p99_mediana_ms": med("p99_ms"),
                 "fallos_mediana_pct": med("fallos_pct"), "lat_media_mediana_ms": med("lat_media_ms"),
                 "c2xx_total": sum(r["c2xx"] for r in v), "c4xx_total": sum(r["c4xx"] for r in v),
                 "c5xx_total": sum(r["c5xx"] for r in v), "sin_respuesta_total": sum(r["sin_respuesta"] for r in v),
                 "cpu_k6_max_media": max(r["cpu_k6"] for r in v), "cpu_total_max_media": max(r["cpu_total"] for r in v),
                 "cpu_java_max_media": max(r["cpu_java"] for r in v), "cpu_pg_max_media": max(r["cpu_pg"] for r in v)}
            e["rps_teorico"] = round(n / (1 + e["lat_media_mediana_ms"] / 1000), 2)
            e["rps_pct_teorico"] = round(100 * e["rps_mediana"] / e["rps_teorico"], 1)
            e["cumple_latencia_fallos"] = e["p95_mediana_ms"] < UMBRAL_P95 and e["fallos_mediana_pct"] < UMBRAL_FALLOS * 100
            e["cumple_throughput"] = e["rps_pct_teorico"] >= 90
            e["instrumento_ok"] = e["cpu_k6_max_media"] < LIM_K6 and e["cpu_total_max_media"] < LIM_TOTAL
            escalones.append(e)

    escribir(DIR / "corridas.csv", corridas)
    escribir(DIR / "escalones.csv", escalones)

    def veredicto(op, campo):
        es = [e for e in escalones if e["operacion"] == op]
        if len(es) < len(ESCALONES):
            return "sin datos completos"
        malos = [str(e["usuarios"]) for e in es if not e[campo]]
        return "NO refutada" if not malos else "REFUTADA en escalón(es) " + ", ".join(malos)

    texto += [f"H1 (buscar, p95<800 ms y fallos<1 %): {veredicto('buscar', 'cumple_latencia_fallos')}",
              f"H2 (buscar, rps >= 90 % del teórico): {veredicto('buscar', 'cumple_throughput')}",
              f"H3 (adopcion, p95<800 ms y fallos<1 %): {veredicto('adopcion', 'cumple_latencia_fallos')}"]
    h4 = [f"{e['operacion']} u{e['usuarios']}" for e in escalones if not e["instrumento_ok"]]
    texto.append("H4 (instrumento no saturado): " + ("NO refutada" if not h4 else "REFUTADA en " + ", ".join(h4)))
    (DIR / "verificacion-hipotesis.txt").write_text("\n".join(texto) + "\n")
    print("\n".join(texto))
    graficar(escalones)


def escribir(ruta, filas):
    if not filas:
        return
    with open(ruta, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(filas[0].keys()))
        w.writeheader()
        w.writerows(filas)


def graficar(escalones):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    color = {"buscar": "#2a78d6", "adopcion": "#eb6834"}
    nombre = {"buscar": "A · GET /buscar", "adopcion": "B · POST /adopciones"}
    tinta, tinta2, grid, fondo = "#0b0b0b", "#52514e", "#e4e3df", "#fcfcfb"
    paneles = [("p95_mediana_ms", "p95 (ms), mediana de 3 corridas"),
               ("rps_mediana", "Throughput (req/s), mediana"),
               ("cpu_total_max_media", "CPU total de la máquina (%), peor corrida")]
    fig, ejes = plt.subplots(1, 3, figsize=(13, 4.2), facecolor=fondo)
    for ax, (campo, titulo) in zip(ejes, paneles):
        ax.set_facecolor(fondo)
        for op in OPERACIONES:
            es = [e for e in escalones if e["operacion"] == op]
            if not es:
                continue
            xs, ys = [e["usuarios"] for e in es], [e[campo] for e in es]
            ax.plot(xs, ys, color=color[op], lw=2, marker="o", ms=7, mec=fondo, mew=2, label=nombre[op])
            if campo != "rps_mediana":  # en throughput las dos series se superponen
                ax.annotate(f"{ys[-1]:g}", (xs[-1], ys[-1]), xytext=(6, 0), textcoords="offset points",
                            va="center", fontsize=9, color=tinta)
        if campo == "rps_mediana":
            ax.plot(ESCALONES, ESCALONES, color=tinta2, lw=1, ls="--", label="≈ 1 req/s por usuario")
        if campo == "cpu_total_max_media":
            ax.axhline(LIM_TOTAL, color=tinta2, lw=1, ls="--")
            ax.text(52, LIM_TOTAL - 4, "límite H4 (90 %)", fontsize=8, color=tinta2, va="top")
            ax.set_ylim(0, 100)
        ax.set_title(titulo, fontsize=10.5, color=tinta, loc="left")
        ax.set_xticks(ESCALONES)
        ax.set_xlabel("usuarios concurrentes", fontsize=9, color=tinta2)
        ax.set_ylim(bottom=0)
        ax.grid(axis="y", color=grid, lw=0.8)
        for s in ("top", "right"):
            ax.spines[s].set_visible(False)
        for s in ("left", "bottom"):
            ax.spines[s].set_color(grid)
        ax.tick_params(colors=tinta2, labelsize=9)
    ejes[0].legend(frameon=False, fontsize=9, labelcolor=tinta)
    ejes[1].legend(frameon=False, fontsize=8.5, labelcolor=tinta)
    fig.suptitle("Experimento de crecimiento S11 · umbral del escenario: p95 < 800 ms", x=0.01, ha="left",
                 fontsize=12, color=tinta)
    fig.tight_layout()
    fig.savefig(DIR / "grafica-crecimiento.png", dpi=150)


if __name__ == "__main__":
    main()
