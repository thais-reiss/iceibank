package com.iceibank.agencia_java.controller;

import com.iceibank.agencia_java.config.AgenciaEstado;
import com.iceibank.agencia_java.model.ContaModel;
import com.iceibank.agencia_java.security.JwtUtil;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AgenciaEstado estado;
    private final JwtUtil jwtUtil;

    public AuthController(AgenciaEstado estado, JwtUtil jwtUtil) {
        this.estado = estado;
        this.jwtUtil = jwtUtil;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, Object> corpo) {
        int id = Integer.parseInt(corpo.get("id").toString());
        String senha = corpo.get("senha").toString();

        ContaModel conta = estado.getContas().get(id);

        if (conta == null || !conta.getSenha().equals(senha)) {
            return ResponseEntity.status(401).body(Map.of("erro", "Credenciais inválidas."));
        }

        String token = jwtUtil.gerarToken(id);
        return ResponseEntity.ok(Map.of("token", token));
    }
}