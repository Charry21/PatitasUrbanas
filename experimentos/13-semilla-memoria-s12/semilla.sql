-- Semilla del experimento 13. Volumen: 79 810 solicitudes y 79 810 etapas, el número de
-- filas con que terminó la serie B de S11. Distribución: la misma que produce
-- POST /api/adopciones sin parámetros: 100 % estado PENDIENTE y etapa SOLICITUD_RECIBIDA,
-- una etapa por solicitud, fechas consecutivas (una por segundo hacia atrás).
TRUNCATE etapa_adopcion, solicitud_adopcion RESTART IDENTITY;
INSERT INTO solicitud_adopcion (estado, fecha_creacion)
  SELECT 'PENDIENTE', now() - make_interval(secs => g) FROM generate_series(1, 79810) g;
INSERT INTO etapa_adopcion (solicitud_adopcion_id, nombre_etapa, fecha_cambio)
  SELECT id, 'SOLICITUD_RECIBIDA', fecha_creacion FROM solicitud_adopcion;
ANALYZE solicitud_adopcion; ANALYZE etapa_adopcion;
