package com.patitasurbanas.api.config;

import com.nimbusds.jose.JOSEObjectType;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.interfaces.RSAPublicKey;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Verifica el escenario 2 con el decodificador real: la clave de prueba se crea en cada ejecución. */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SeguridadIntegrationTest {

    private static final String EMISOR = "https://emisor.prueba";
    private static final String AUDIENCIA = "patitas-urbanas-api";

    private static KeyPair claves;
    private static KeyPair clavesAjenas;

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TestRestTemplate cliente;

    private static KeyPair generar() throws Exception {
        KeyPairGenerator generador = KeyPairGenerator.getInstance("RSA");
        generador.initialize(2048);
        return generador.generateKeyPair();
    }

    @DynamicPropertySource
    static void propiedades(DynamicPropertyRegistry registro) throws Exception {
        claves = generar();
        clavesAjenas = generar();
        Path archivo = Files.createTempFile("jwt-publica", ".pem");
        archivo.toFile().deleteOnExit();
        String cuerpo = Base64.getMimeEncoder(64, "\n".getBytes())
                .encodeToString(((RSAPublicKey) claves.getPublic()).getEncoded());
        Files.writeString(archivo, "-----BEGIN PUBLIC KEY-----\n" + cuerpo + "\n-----END PUBLIC KEY-----\n");
        registro.add("patitas.seguridad.jwt.clave-publica", () -> "file:" + archivo);
        registro.add("patitas.seguridad.jwt.emisor", () -> EMISOR);
        registro.add("patitas.seguridad.jwt.audiencia", () -> AUDIENCIA);
    }

    private static String token(KeyPair par, String emisor, String audiencia, String permiso, Instant caducidad)
            throws Exception {
        JWTClaimsSet reclamos = new JWTClaimsSet.Builder()
                .subject("prueba")
                .issuer(emisor)
                .audience(audiencia)
                .claim("scope", permiso)
                .issueTime(Date.from(caducidad.minusSeconds(3600)))
                .expirationTime(Date.from(caducidad))
                .build();
        SignedJWT jwt = new SignedJWT(
                new JWSHeader.Builder(JWSAlgorithm.RS256).type(JOSEObjectType.JWT).build(), reclamos);
        jwt.sign(new RSASSASigner(par.getPrivate()));
        return jwt.serialize();
    }

    private static String valido(String permiso) throws Exception {
        return token(claves, EMISOR, AUDIENCIA, permiso, Instant.now().plusSeconds(600));
    }

    @Test
    void sinTokenResponde401() throws Exception {
        mockMvc.perform(post("/api/adopciones")).andExpect(status().isUnauthorized());
    }

    @Test
    void tokenValidoConPermisoCrea() throws Exception {
        mockMvc.perform(post("/api/adopciones")
                        .header("Authorization", "Bearer " + valido("adopciones:escribir")))
                .andExpect(status().isCreated());
    }

    @Test
    void tokensInvalidosResponden401() throws Exception {
        Instant futuro = Instant.now().plusSeconds(600);
        String[] invalidos = {
                token(clavesAjenas, EMISOR, AUDIENCIA, "adopciones:escribir", futuro),
                token(claves, "https://otro.emisor", AUDIENCIA, "adopciones:escribir", futuro),
                token(claves, EMISOR, "otra-api", "adopciones:escribir", futuro),
                token(claves, EMISOR, AUDIENCIA, "adopciones:escribir", Instant.now().minusSeconds(600)),
        };
        for (String invalido : invalidos) {
            mockMvc.perform(post("/api/adopciones").header("Authorization", "Bearer " + invalido))
                    .andExpect(status().isUnauthorized());
        }
    }

    @Test
    void tokenSinPermisoResponde403() throws Exception {
        mockMvc.perform(post("/api/adopciones")
                        .header("Authorization", "Bearer " + valido("mascotas:leer")))
                .andExpect(status().isForbidden());
    }

    @Test
    void elEndpointDePruebasNoAceptaElPermisoDeEscritura() throws Exception {
        mockMvc.perform(post("/api/adopciones/test-fallo")
                        .header("Authorization", "Bearer " + valido("adopciones:escribir")))
                .andExpect(status().isForbidden());
    }

    @Test
    void laBusquedaYElEstadoSonPublicos() throws Exception {
        mockMvc.perform(get("/api/mascotas/buscar").param("lat", "4.6").param("lng", "-74.0").param("radio", "5"))
                .andExpect(status().isOk());
        mockMvc.perform(get("/actuator/health")).andExpect(status().isOk());
    }

    @Test
    void cualquierOtraRutaSeDeniega() throws Exception {
        mockMvc.perform(get("/actuator/env")).andExpect(status().isUnauthorized());
    }

    @Test
    void entradaDemasiadoLargaResponde400() throws Exception {
        mockMvc.perform(post("/api/adopciones").param("estado", "x".repeat(300))
                        .header("Authorization", "Bearer " + valido("adopciones:escribir")))
                .andExpect(status().isBadRequest());
    }

    /** Con Tomcat real: MockMvc no hace el reenvío a /error, por eso no detecta este fallo. */
    @Test
    void conServidorRealLaEntradaInvalidaSigueSiendo400() throws Exception {
        ResponseEntity<String> tipoInvalido =
                cliente.getForEntity("/api/mascotas/buscar?lat=abc&lng=0&radio=0", String.class);
        assertThat(tipoInvalido.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);

        HttpHeaders cabeceras = new HttpHeaders();
        cabeceras.setBearerAuth(valido("adopciones:escribir"));
        ResponseEntity<String> largo = cliente.postForEntity(
                "/api/adopciones?estado=" + "x".repeat(300), new HttpEntity<>(cabeceras), String.class);
        assertThat(largo.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
    }
}
