package com.iceibank.agencia_java.controller;

import com.iceibank.agencia_java.model.ResultadoTransferencia;
import com.iceibank.agencia_java.service.TransferenciaService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.util.Map;

@RestController
public class TransferenciasController {

    private final TransferenciaService transferenciaService;

    public TransferenciasController(TransferenciaService transferenciaService) {
        this.transferenciaService = transferenciaService;
    }

    @PostMapping("/transferencias")
    public ResponseEntity<?> transferir(@RequestBody Map<String, Object> corpo, HttpServletRequest request) throws IOException {

        int idOrigem = Integer.parseInt(corpo.get("idOrigem").toString());
        int idDestino = Integer.parseInt(corpo.get("idDestino").toString());
        double valor = Double.parseDouble(corpo.get("valor").toString());

        Integer idAutenticado = (Integer) request.getAttribute("idContaAutenticada");

        if (idAutenticado == null || idAutenticado != idOrigem) {
            return ResponseEntity.status(403)
                    .body(Map.of("erro", "Você só pode transferir a partir da sua própria conta."));
        }

        ResultadoTransferencia resultado = transferenciaService.executar(idOrigem, idDestino, valor);
        return ResponseEntity.status(resultado.status()).body(resultado.corpo());
    }
}
