import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '10s', target: 20 }, // Rampa de subida a 20 usuarios
    { duration: '30s', target: 20 }, // Carga sostenida
    { duration: '10s', target: 0 },  // Rampa de bajada
  ],
};

export default function () {
  const res = http.get('http://localhost:3000/actuator/health');
  check(res, {
    'status es 200': (r) => r.status === 200,
  });
  sleep(1);
}
