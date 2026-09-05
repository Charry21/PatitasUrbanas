package com.patitasurbanas.api.controller;

import com.patitasurbanas.api.model.SolicitudAdopcion;
import com.patitasurbanas.api.service.AdopcionService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/adopciones")
public class AdopcionController {

    private final AdopcionService adopcionService;

    public AdopcionController(AdopcionService adopcionService) {
        this.adopcionService = adopcionService;
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> crearSolicitud(
            @RequestParam(defaultValue = "PENDIENTE") String estado,
            @RequestParam(defaultValue = "SOLICITUD_RECIBIDA") String nombreEtapa) {

        SolicitudAdopcion solicitud = adopcionService.crearSolicitudConEtapaInicial(estado, nombreEtapa, false);

        Map<String, Object> response = new HashMap<>();
        response.put("idSolicitud", solicitud.getId());
        response.put("estado", solicitud.getEstado());
        response.put("etapaInicial", nombreEtapa);

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/test-fallo")
    public ResponseEntity<Map<String, Object>> crearSolicitudConFalloSimulado(
            @RequestParam(defaultValue = "PENDIENTE") String estado,
            @RequestParam(defaultValue = "SOLICITUD_RECIBIDA") String nombreEtapa) {

        try {
            adopcionService.crearSolicitudConEtapaInicial(estado, nombreEtapa, true);
            Map<String, Object> response = new HashMap<>();
            response.put("mensaje", "Solicitud creada sin fallos");
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (RuntimeException ex) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", ex.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
}
