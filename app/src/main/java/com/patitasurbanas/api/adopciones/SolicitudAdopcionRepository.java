package com.patitasurbanas.api.adopciones;

import com.patitasurbanas.api.adopciones.model.SolicitudAdopcion;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SolicitudAdopcionRepository extends JpaRepository<SolicitudAdopcion, Long> {
}
