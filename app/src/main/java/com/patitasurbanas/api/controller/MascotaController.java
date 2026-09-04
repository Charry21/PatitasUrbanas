package com.patitasurbanas.api.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/mascotas")
public class MascotaController {

    @GetMapping("/buscar")
    public ResponseEntity<String> buscarMascotas(
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam double radio) {
        
        // Simulación de carga de respuesta para la medición de la línea base S4
        return ResponseEntity.ok("{\"status\":\"success\", \"mensaje\":\"Endpoint geoespacial activo\"}");
    }
}
