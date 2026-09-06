package com.iceibank.agencia_java.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Component
public class JwtUtil {

    @Value("${jwt.secret}")
    private String segredo;

    @Value("${jwt.expiracao-minutos}")
    private int expiracaoMinutos;

    private SecretKey chave() {
        return Keys.hmacShaKeyFor(segredo.getBytes(StandardCharsets.UTF_8));
    }

    public String gerarToken(int idConta) {
        Date agora = new Date();
        Date expiracao = new Date(agora.getTime() + expiracaoMinutos * 60 * 1000L);

        return Jwts.builder()
                .subject(String.valueOf(idConta))
                .issuedAt(agora)
                .expiration(expiracao)
                .signWith(chave())
                .compact();
    }

    public int validarTokenEExtrairId(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(chave())
                .build()
                .parseSignedClaims(token)
                .getPayload();

        return Integer.parseInt(claims.getSubject());
    }
}