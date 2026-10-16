"""Muestrea CPU cada segundo mientras corre k6, para saber si el generador o la máquina se saturan.

Uso: python3 muestreo_cpu.py <archivo_csv>   (se detiene con SIGTERM)
Columnas: t_s, cpu_total_pct (0-100 sobre todos los núcleos), k6_pct, java_pct, postgres_pct
(los porcentajes por proceso están en "% de un núcleo": 100 = un núcleo completo).
"""
import csv
import signal
import sys
import time

import psutil

GRUPOS = {"k6": ("k6",), "java": ("java",), "postgres": ("postgres",)}
corriendo = True


def detener(*_):
    global corriendo
    corriendo = False


def procesos(grupo):
    nombres = GRUPOS[grupo]
    return [p for p in psutil.process_iter(["name"]) if (p.info["name"] or "") in nombres]


def main(ruta):
    signal.signal(signal.SIGTERM, detener)
    signal.signal(signal.SIGINT, detener)
    psutil.cpu_percent(None)
    vistos = {}
    t0 = time.time()
    with open(ruta, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["t_s", "cpu_total_pct", "k6_pct", "java_pct", "postgres_pct"])
        while corriendo:
            time.sleep(1)
            fila = [round(time.time() - t0, 1), psutil.cpu_percent(None)]
            for g in GRUPOS:
                total = 0.0
                for p in procesos(g):
                    try:
                        if p.pid not in vistos:
                            vistos[p.pid] = p
                            p.cpu_percent(None)
                            continue
                        total += vistos[p.pid].cpu_percent(None)
                    except psutil.Error:
                        pass
                fila.append(round(total, 1))
            w.writerow(fila)
            f.flush()


if __name__ == "__main__":
    main(sys.argv[1])
