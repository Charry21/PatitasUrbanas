package com.patitasurbanas.api.config;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.server.resource.web.BearerTokenAuthenticationEntryPoint;
import org.springframework.security.oauth2.server.resource.web.access.BearerTokenAccessDeniedHandler;
import org.springframework.security.web.SecurityFilterChain;

import java.security.interfaces.RSAPublicKey;

/**
 * Capa de seguridad candidata (escenario 2 de dossier/04-escenarios-calidad.md).
 *
 * <p>La API solo valida tokens: el emisor (contexto de Identidad) todavía no existe.
 * Propuesta para ADR-05; medida en experimentos/15-costo-seguridad-s13.
 */
@Configuration
public class SeguridadConfig {

    private static final Logger auditoria = LoggerFactory.getLogger("AUDITORIA");
    private static final String PERMISO_ESCRIBIR = "SCOPE_adopciones:escribir";
    private static final String PERMISO_PRUEBAS = "SCOPE_adopciones:pruebas";

    @Bean
    SecurityFilterChain cadenaDeSeguridad(HttpSecurity http) throws Exception {
        BearerTokenAuthenticationEntryPoint noAutenticado = new BearerTokenAuthenticationEntryPoint();
        BearerTokenAccessDeniedHandler sinPermiso = new BearerTokenAccessDeniedHandler();

        http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(AbstractHttpConfigurer::disable)
                .sessionManagement(sesion -> sesion.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(reglas -> reglas
                        .requestMatchers(HttpMethod.GET, "/actuator/health").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/mascotas/buscar").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/adopciones/test-fallo").hasAuthority(PERMISO_PRUEBAS)
                        .requestMatchers(HttpMethod.POST, "/api/adopciones").hasAuthority(PERMISO_ESCRIBIR)
                        .anyRequest().denyAll())
                .oauth2ResourceServer(servidor -> servidor
                        .jwt(jwt -> { })
                        .authenticationEntryPoint((peticion, respuesta, excepcion) -> {
                            registrarDenegacion(peticion, 401);
                            noAutenticado.commence(peticion, respuesta, excepcion);
                        })
                        .accessDeniedHandler((peticion, respuesta, excepcion) -> {
                            registrarDenegacion(peticion, 403);
                            sinPermiso.handle(peticion, respuesta, excepcion);
                        }));
        return http.build();
    }

    @Bean
    JwtDecoder decodificadorJwt(
            @Value("${patitas.seguridad.jwt.clave-publica}") RSAPublicKey clavePublica,
            @Value("${patitas.seguridad.jwt.emisor}") String emisor,
            @Value("${patitas.seguridad.jwt.audiencia}") String audiencia) {

        NimbusJwtDecoder decodificador = NimbusJwtDecoder.withPublicKey(clavePublica)
                .signatureAlgorithm(SignatureAlgorithm.RS256)
                .build();
        OAuth2TokenValidator<Jwt> validarAudiencia = jwt -> jwt.getAudience().contains(audiencia)
                ? OAuth2TokenValidatorResult.success()
                : OAuth2TokenValidatorResult.failure(
                        new OAuth2Error("invalid_token", "Audiencia no válida", null));
        decodificador.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                JwtValidators.createDefaultWithIssuer(emisor), validarAudiencia));
        return decodificador;
    }

    /** Registra el intento sin datos del token ni de la consulta, y sin saltos de línea del cliente. */
    private static void registrarDenegacion(HttpServletRequest peticion, int estado) {
        auditoria.warn("AUDITORIA_ACCESO_DENEGADO estado={} metodo={} ruta={} origen={}",
                estado,
                peticion.getMethod(),
                peticion.getRequestURI().replaceAll("[\\r\\n\\t]", "_"),
                peticion.getRemoteAddr());
    }
}
