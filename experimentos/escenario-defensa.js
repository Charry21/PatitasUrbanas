import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: {
    carga_constante: {
      executor: 'constant-arrival-rate',
      rate: 100,
      timeUnit: '1s',
      duration: '40s',
      preAllocatedVUs: 20,
      maxVUs: 100,
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<800'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const payload = JSON.stringify({
    estado: 'PENDIENTE',
    nombreEtapa: 'Solicitud inicial',
  });

  const params = {
    headers: { 'Content-Type': 'application/json' },
  };

  const res = http.post(
    'http://localhost:3000/api/adopciones',
    payload,
    params
  );

  check(res, {
    'status es 201': (r) => r.status === 201,
  });
}
