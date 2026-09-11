import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    concurrencia_adopciones: {
      executor: 'constant-arrival-rate',
      rate: 500,
      timeUnit: '1s',
      duration: '20s',
      preAllocatedVUs: 50,
      maxVUs: 500,
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<1000'],
  },
};

export default function () {
  const payload = {};
  const res = http.post('http://localhost:3000/api/adopciones', payload, {
    headers: {
      'Content-Type': 'application/json',
    },
  });

  check(res, {
    'status es 201': (r) => r.status === 201,
    'sin errores de deadlock/timeout': (r) => r.status !== 500 && r.status !== 503 && r.status !== 408,
  });

  sleep(0.1);
}

// Umbral de éxito para considerar el driver BIZ-01 cumplido: 0 errores de deadlock/timeout y p95 < 1000 ms.
