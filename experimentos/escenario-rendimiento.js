import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: {
    carga_constante: {
      executor: 'constant-arrival-rate',
      rate: 100, // 100 peticiones
      timeUnit: '1s', // por segundo
      duration: '40s', // duración total de la prueba
      preAllocatedVUs: 20, // VUs iniciales
      maxVUs: 100, // Límite máximo de VUs si la API se degrada
    },
  },
};

export default function () {
  const res = http.get('http://localhost:3000/actuator/health');
  check(res, { 'status es 200': (r) => r.status === 200 });
}
