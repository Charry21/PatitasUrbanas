// Experimento de crecimiento - Semana 11
// Un escalón por ejecución. Parámetros por variables de entorno:
//   USUARIOS   número de usuarios virtuales concurrentes (50, 100, 150, 200)
//   OPERACION  "buscar" (operación de la línea base S4) o "adopcion" (operación secundaria, escribe en BD)
//   DURACION   duración del escalón (por defecto 40s, igual que la línea base)
//   BASE_URL   por defecto http://localhost:3000
//   SALIDA     ruta del JSON de resumen que se guarda al terminar
//
// Modelo de carga: cada usuario hace 1 petición y espera 1 s (tiempo de reflexión fijo).
// Así, 100 usuarios ≈ 100 req/s, la misma tasa de la línea base de la Semana 4.
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter } from 'k6/metrics';

// Conteo de códigos HTTP por clase (status 0 = sin respuesta: timeout o conexión rechazada)
const codigos = {
  c2xx: new Counter('codigos_2xx'),
  c4xx: new Counter('codigos_4xx'),
  c5xx: new Counter('codigos_5xx'),
  c0: new Counter('codigos_sin_respuesta'),
};

const USUARIOS = parseInt(__ENV.USUARIOS || '50', 10);
const OPERACION = __ENV.OPERACION || 'buscar';
const DURACION = __ENV.DURACION || '40s';
const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export const options = {
  scenarios: {
    escalon: {
      executor: 'constant-vus',
      vus: USUARIOS,
      duration: DURACION,
      gracefulStop: '10s',
    },
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
  // Umbrales preregistrados (README §3). No abortan la corrida; solo se informan.
  thresholds: {
    http_req_duration: ['p(95)<800'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  let res;
  if (OPERACION === 'adopcion') {
    res = http.post(`${BASE_URL}/api/adopciones`, null, { tags: { operacion: 'adopcion' } });
    check(res, { 'status 201': (r) => r.status === 201 });
  } else {
    res = http.get(`${BASE_URL}/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5`, {
      tags: { operacion: 'buscar' },
    });
    check(res, { 'status 200': (r) => r.status === 200 });
  }
  if (res.status === 0) codigos.c0.add(1);
  else if (res.status >= 500) codigos.c5xx.add(1);
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
  return `usuarios=${USUARIOS} operacion=${OPERACION} reqs=${reqs.count} rps=${reqs.rate.toFixed(2)} ` +
    `p50=${d.med.toFixed(2)}ms p95=${d['p(95)'].toFixed(2)}ms p99=${d['p(99)'].toFixed(2)}ms ` +
    `max=${d.max.toFixed(2)}ms fallos=${(fail.rate * 100).toFixed(2)}%\n`;
}
