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
  // Reemplace por la ruta real de su API que ejecuta la búsqueda espacial
  const res = http.get('http://localhost:3000/api/mascotas/buscar?lat=4.6097&lng=-74.0817&radio=5');
  check(res, { 'status es 200': (r) => r.status === 200 });
}
