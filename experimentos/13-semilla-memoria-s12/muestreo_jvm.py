#!/usr/bin/env python3
"""Muestrea cada segundo la memoria residente (RSS, MiB) y la CPU (% de un núcleo) del
proceso de la API. Uso: python3 muestreo_jvm.py <pid> <csv> [segundos]  (o hasta SIGTERM)."""
import csv, signal, sys, time
import psutil
pid, salida = int(sys.argv[1]), sys.argv[2]
limite = float(sys.argv[3]) if len(sys.argv) > 3 else None
p = psutil.Process(pid); p.cpu_percent(None); seguir = True
signal.signal(signal.SIGTERM, lambda *_: globals().__setitem__("seguir", False))
t0 = time.time()
with open(salida, "w", newline="") as f:
    w = csv.writer(f); w.writerow(["t_s", "rss_mib", "cpu_pct_nucleo"])
    while seguir and (limite is None or time.time() - t0 < limite):
        time.sleep(1)
        w.writerow([round(time.time() - t0, 1), round(p.memory_info().rss / 2**20, 1), p.cpu_percent(None)]); f.flush()
