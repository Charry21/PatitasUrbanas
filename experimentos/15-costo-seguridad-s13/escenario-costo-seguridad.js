// Costo de la capa de seguridad sobre el p95 - Semana 13 (preregistro: README.md).
// Mismo modelo de carga que experimentos/10-crecimiento-s11/escenario-crecimiento.js.
// Variables de entorno:
//   OPERACION  buscar | adopcion | sin_token
//   USUARIOS   usuarios virtuales (por defecto 200)
//   DURACION   duración de la corrida (por defecto 40s)
//   BASE_URL   por defecto http://localhost:3000
//   TOKEN      token que se envía en "adopcion" (misma cabecera en las condiciones S, C y T)
//   SALIDA     ruta del JSON de resumen
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter } from 'k6/metrics';

const codigos = {
  c2xx: new Counter('codigos_2xx'),
  c401: new Counter('codigos_401'),
  c4xx: new Counter('codigos_4xx_otros'),
  c5xx: new Counter('codigos_5xx'),
  c0: new Counter('codigos_sin_respuesta'),
};

const USUARIOS = parseInt(__ENV.USUARIOS || '200', 10);
const OPERACION = __ENV.OPERACION || 'buscar';
const DURACION = __ENV.DURACION || '40s';
const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const TOKEN = __ENV.TOKEN || '';

export const options = {
  scenarios: {
    corrida: { executor: 'constant-vus', vus: USUARIOS, duration: DURACION, gracefulStop: '10s' },
  },
  insecureSkipTLSVerify: true,
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
  thresholds: { http_req_duration: ['p(95)<800'] },
};

export default function () {
  let res;
  if (OPERACION === 'adopcion') {
    res = http.post(`${BASE_URL}/api/adopciones`, null, {
      headers: { Authorization: `Bearer ${TOKEN}` },
      tags: { operacion: 'adopcion' },
    });
    check(res, { 'status 201': (r) => r.status === 201 });
  } else if (OPERACION === 'sin_token') {
    res = http.post(`${BASE_URL}/api/adopciones`, null, {
      tags: { operacion: 'sin_token' },
      responseCallback: http.expectedStatuses(401),
    });
    check(res, { 'status 401': (r) => r.status === 401 });
  } else {
    res = http.get(`${BASE_URL}/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5`, {
      tags: { operacion: 'buscar' },
    });
    check(res, { 'status 200': (r) => r.status === 200 });
  }
  if (res.status === 0) codigos.c0.add(1);
  else if (res.status >= 500) codigos.c5xx.add(1);
  else if (res.status === 401) codigos.c401.add(1);
  else if (res.status >= 400) codigos.c4xx.add(1);
  else if (res.status >= 200 && res.status < 300) codigos.c2xx.add(1);
  sleep(1);
}

export function handleSummary(data) {
  const out = { stdout: textoResumen(data) };
  if (__ENV.SALIDA) out[__ENV.SALIDA] = JSON.stringify(data, null, 2);
  return out;
}

function textoResumen(data) {
  const d = data.metrics.http_req_duration.values;
  const reqs = data.metrics.http_reqs.values;
  const fail = data.metrics.http_req_failed.values;
  return `operacion=${OPERACION} reqs=${reqs.count} rps=${reqs.rate.toFixed(2)} ` +
    `p50=${d.med.toFixed(2)}ms p95=${d['p(95)'].toFixed(2)}ms p99=${d['p(99)'].toFixed(2)}ms ` +
    `max=${d.max.toFixed(2)}ms fallos=${(fail.rate * 100).toFixed(2)}%\n`;
}
