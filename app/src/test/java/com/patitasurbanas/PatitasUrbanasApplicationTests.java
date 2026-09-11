package com.patitasurbanas; // Asegúrese de que coincida con la ruta de su paquete

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class PatitasUrbanasApplicationTests {

    @Test
    void contextLoads() {
        // Este bloque pasa exitosamente si el aplicativo logra 
        // conectarse al motor de base de datos sin errores de configuración.
    }
}
