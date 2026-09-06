package com.iceibank.agencia_java.controller;

import com.iceibank.agencia_java.config.AgenciaConfig;
import com.iceibank.agencia_java.config.AgenciaEstado;
import com.iceibank.agencia_java.config.AgenciaInfo;
import com.iceibank.agencia_java.model.ContaModel;

import jakarta.servlet.http.HttpServletRequest;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@RestController
public class TransferenciasController {

    private final AgenciaConfig agenciaConfig;
    private final AgenciaEstado estado;
    private final RestTemplate restTemplate;

    @Value("${agencia.token-interno}")
    private String tokenInterno;

    public TransferenciasController(AgenciaConfig agenciaConfig, AgenciaEstado estado, RestTemplate restTemplate) {
        this.agenciaConfig = agenciaConfig;
        this.estado = estado;
        this.restTemplate = restTemplate;
    }

    @PostMapping("/transferencias")
    public ResponseEntity<?> transferir(@RequestBody Map<String, Object> corpo, HttpServletRequest request)
            throws IOException {
        int idOrigem = Integer.parseInt(corpo.get("idOrigem").toString());
        int idDestino = Integer.parseInt(corpo.get("idDestino").toString());
        double valor = Double.parseDouble(corpo.get("valor").toString());

        Integer idAutenticado = (Integer) request.getAttribute("idContaAutenticada");
        if (idAutenticado == null || idAutenticado != idOrigem) {
            return ResponseEntity.status(403)
                    .body(Map.of("erro", "Você só pode transferir a partir da sua própria conta."));
        }
        
        ContaModel contaOrigem = estado.getContas().get(idOrigem);
        if (contaOrigem == null) {
            return ResponseEntity.status(404).body(Map.of("erro", "Conta de origem não encontrada nesta agência."));
        }
        if (contaOrigem.getSaldo() < valor) {
            return ResponseEntity.status(400).body(Map.of("erro", "Saldo insuficiente."));
        }

        int agenciaDestino = agenciaConfig.agenciaResponsavel(idDestino);

        int tsDebito = estado.getRelogio().eventoLocal();
        contaOrigem.setSaldo(contaOrigem.getSaldo() - valor);

        Map<String, Object> detalhesDebito = new HashMap<>();
        detalhesDebito.put("idOrigem", idOrigem);
        detalhesDebito.put("idDestino", idDestino);
        detalhesDebito.put("valor", valor);
        estado.getRegistro().registrar("TRANSFERENCIA_DEBITO", tsDebito, detalhesDebito);

        if (agenciaDestino == agenciaConfig.getIdAgencia()) {
            ContaModel contaDestino = estado.getContas().get(idDestino);
            if (contaDestino == null) {
                contaOrigem.setSaldo(contaOrigem.getSaldo() + valor);
                return ResponseEntity.status(404).body(Map.of("erro", "Conta de destino não encontrada."));
            }
            int tsCredito = estado.getRelogio().eventoLocal();
            contaDestino.setSaldo(contaDestino.getSaldo() + valor);

            Map<String, Object> detalhesCredito = new HashMap<>();
            detalhesCredito.put("idOrigem", idOrigem);
            detalhesCredito.put("idDestino", idDestino);
            detalhesCredito.put("valor", valor);
            estado.getRegistro().registrar("TRANSFERENCIA_CREDITO", tsCredito, detalhesCredito);

            return ResponseEntity.ok(Map.of("mensagem", "Transferência concluída (mesma agência)."));
        }

        int tsEnvio = estado.getRelogio().aoEnviar();
        AgenciaInfo destino = agenciaConfig.buscarAgencia(agenciaDestino);

        Map<String, Object> corpoRemoto = new HashMap<>();
        corpoRemoto.put("valor", valor);
        corpoRemoto.put("timestampLamport", tsEnvio);
        corpoRemoto.put("origemAgencia", agenciaConfig.getIdAgencia());

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.set("X-Internal-Token", tokenInterno);
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> requisicao = new HttpEntity<>(corpoRemoto, headers);

            restTemplate.exchange(
                    destino.getUrl() + "/contas/" + idDestino + "/creditar-remoto",
                    HttpMethod.POST,
                    requisicao,
                    Map.class);

            return ResponseEntity.ok(Map.of("mensagem", "Transferência concluída (entre agências)."));
        } catch (RestClientException erro) {
            Map<String, Object> detalhesFalha = new HashMap<>();
            detalhesFalha.put("idOrigem", idOrigem);
            detalhesFalha.put("idDestino", idDestino);
            detalhesFalha.put("valor", valor);
            detalhesFalha.put("erro", erro.getMessage());
            estado.getRegistro().registrar("TRANSFERENCIA_FALHOU", estado.getRelogio().eventoLocal(), detalhesFalha);

            return ResponseEntity.status(502).body(Map.of(
                    "erro",
                    "Falha ao contatar agência de destino. Débito já aplicado - inconsistência conhecida (ver Sprint 4)."));
        }
    }

    @PostMapping("/contas/{id}/creditar-remoto")
    public ResponseEntity<?> creditarRemoto(@PathVariable int id, @RequestBody Map<String, Object> corpo)
            throws IOException {
        double valor = Double.parseDouble(corpo.get("valor").toString());
        int timestampLamport = Integer.parseInt(corpo.get("timestampLamport").toString());
        int origemAgencia = Integer.parseInt(corpo.get("origemAgencia").toString());

        int ts = estado.getRelogio().aoReceber(timestampLamport);

        ContaModel conta = estado.getContas().get(id);
        if (conta == null) {
            return ResponseEntity.status(404).body(Map.of("erro", "Conta não encontrada nesta agência."));
        }

        conta.setSaldo(conta.getSaldo() + valor);

        Map<String, Object> detalhes = new HashMap<>();
        detalhes.put("idConta", id);
        detalhes.put("valor", valor);
        detalhes.put("origemAgencia", origemAgencia);
        estado.getRegistro().registrar("TRANSFERENCIA_CREDITO_REMOTO", ts, detalhes);

        return ResponseEntity.ok(Map.of("mensagem", "Crédito remoto aplicado.", "saldoAtual", conta.getSaldo()));
    }
}