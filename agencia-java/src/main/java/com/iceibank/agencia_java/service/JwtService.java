package com.iceibank.agencia_java.service;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Service
public class JwtService {

    private static final String CHAVE_SECRETA = "IceiBankSprint1ChaveSecretaMuitoSegura2026";
    private final SecretKey key;

    public JwtService() {
        this.key = Keys.hmacShaKeyFor(CHAVE_SECRETA.getBytes(StandardCharsets.UTF_8));
    }

    public String gerarToken(int idConta) {
        long tempoExpiracaoMillis = 3600000;
        Date agora = new Date();
        Date expiracao = new Date(agora.getTime() + tempoExpiracaoMillis);

        return Jwts.builder()
                .subject(String.valueOf(idConta)) 
                .issuedAt(agora) 
                .expiration(expiracao) 
                .signWith(key) 
                .compact(); 
    }

    public String extrairIdConta(String token) {
        Claims payload = Jwts.parser()
                .verifyWith(key) 
                .build()
                .parseSignedClaims(token)
                .getPayload();

        return payload.getSubject();
    }
}
