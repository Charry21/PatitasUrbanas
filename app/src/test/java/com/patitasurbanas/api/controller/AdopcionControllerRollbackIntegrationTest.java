package com.patitasurbanas.api.controller;

import com.patitasurbanas.api.model.SolicitudAdopcion;
import com.patitasurbanas.api.repository.EtapaAdopcionRepository;
import com.patitasurbanas.api.repository.SolicitudAdopcionRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AdopcionControllerRollbackIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private SolicitudAdopcionRepository solicitudAdopcionRepository;

    @Autowired
    private EtapaAdopcionRepository etapaAdopcionRepository;

    @Test
    void testFalloSimuladoHaceRollbackCompleto() throws Exception {
        long solicitudesAntes = solicitudAdopcionRepository.count();
        long etapasAntes = etapaAdopcionRepository.count();

        mockMvc.perform(post("/api/adopciones/test-fallo")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isInternalServerError());

        assertThat(solicitudAdopcionRepository.count()).isEqualTo(solicitudesAntes);
        assertThat(etapaAdopcionRepository.count()).isEqualTo(etapasAntes);

        // Evidencia para el escenario QA-02 del dossier: el rollback debe devolver la base de datos
        // a un estado consistente, sin dejar SolicitudAdopcion ni EtapaAdopcion huérfanas tras el fallo simulado.
    }
}
