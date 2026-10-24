Seguimiento del hallazgo S1 (P5 de 09-cierre-spike-s10.md)
Fecha: 2026-10-24T01:15:20Z
Cambio: mover AdopcionControllerRollbackIntegrationTest de api.controller a api.adopciones (solo package e imports del mismo paquete).
Solo cambia app/src/test; app/src/main sigue idéntico al código medido (1e522df): sí
Protocolo: docker compose down -v && up -d postgres_db; mvn -B clean test x3
SO: Ubuntu 24.04.4 LTS
openjdk version "21.0.11" 2026-04-21
Apache Maven 3.9.11 (3e54c93a704957b63ee3494413a2b544fd3d825b)
Resultado: 2/2 tests en 3/3 corridas; Y2=0, Y4=7/7, Y5=0
