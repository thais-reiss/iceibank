package com.iceibank.agencia_java.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class JwtFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

    public JwtFilter(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response, @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        if (request.getMethod().equals("OPTIONS")) {
            filterChain.doFilter(request, response);
            return;
        }

        String caminho = request.getRequestURI();
        String metodo = request.getMethod();

        boolean rotaPublica = (caminho.equals("/contas") && metodo.equals("POST"))
                || caminho.equals("/auth/login");

        if (rotaPublica) {
            filterChain.doFilter(request, response);
            return;
        }

        String cabecalho = request.getHeader("Authorization");

        if (cabecalho == null || !cabecalho.startsWith("Bearer ")) {
            response.setStatus(401);
            response.setContentType("application/json");
            response.getWriter().write("{\"erro\":\"Token ausente.\"}");
            return;
        }

        String token = cabecalho.substring(7);

        try {
            int idConta = jwtUtil.validarTokenEExtrairId(token);
            request.setAttribute("idContaAutenticada", idConta);
        } catch (Exception erro) {
            response.setStatus(401);
            response.setContentType("application/json");
            response.getWriter().write("{\"erro\":\"Token inválido ou expirado.\"}");
            return;
        }

        filterChain.doFilter(request, response);
    }
}