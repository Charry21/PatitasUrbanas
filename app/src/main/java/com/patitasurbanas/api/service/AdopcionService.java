package com.patitasurbanas.api.service;

import com.patitasurbanas.api.model.EtapaAdopcion;
import com.patitasurbanas.api.model.SolicitudAdopcion;
import com.patitasurbanas.api.repository.EtapaAdopcionRepository;
import com.patitasurbanas.api.repository.SolicitudAdopcionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class AdopcionService {

    private final SolicitudAdopcionRepository solicitudAdopcionRepository;
    private final EtapaAdopcionRepository etapaAdopcionRepository;

    public AdopcionService(SolicitudAdopcionRepository solicitudAdopcionRepository,
                          EtapaAdopcionRepository etapaAdopcionRepository) {
        this.solicitudAdopcionRepository = solicitudAdopcionRepository;
        this.etapaAdopcionRepository = etapaAdopcionRepository;
    }

    @Transactional
    public SolicitudAdopcion crearSolicitudConEtapaInicial(String estado, String nombreEtapa) {
        return crearSolicitudConEtapaInicial(estado, nombreEtapa, false);
    }

    @Transactional
    public SolicitudAdopcion crearSolicitudConEtapaInicial(String estado, String nombreEtapa, boolean simularFallo) {
        String estadoFinal = estado != null && !estado.isBlank() ? estado : "PENDIENTE";
        String etapaInicial = nombreEtapa != null && !nombreEtapa.isBlank() ? nombreEtapa : "SOLICITUD_RECIBIDA";

        SolicitudAdopcion solicitud = new SolicitudAdopcion(estadoFinal, LocalDateTime.now());
        solicitud = solicitudAdopcionRepository.save(solicitud);

        if (simularFallo) {
            throw new RuntimeException("Fallo simulado: rollback esperado");
        }

        EtapaAdopcion etapa = new EtapaAdopcion(solicitud, etapaInicial, LocalDateTime.now());
        etapaAdopcionRepository.save(etapa);

        return solicitud;
    }
}
