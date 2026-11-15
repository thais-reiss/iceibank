package com.iceibank.agencia_java.controller;

import com.iceibank.agencia_java.config.AgenciaConfig;
import com.iceibank.agencia_java.config.AgenciaEstado;
import com.iceibank.agencia_java.model.ContaModel;
import com.iceibank.agencia_java.model.OperacaoPendente;
import com.iceibank.agencia_java.model.ResultadoTransferencia;
import com.iceibank.agencia_java.service.AlertaSaldoBaixo;
import com.iceibank.agencia_java.service.ComparadorVetores;
import com.iceibank.agencia_java.service.TransferenciaService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/contas")
public class ContasController {

    private final AgenciaConfig agenciaConfig;
    private final AgenciaEstado estado;
    private final AlertaSaldoBaixo alertaSaldoBaixo;
    private final TransferenciaService transferenciaService;

    public ContasController(AgenciaConfig agenciaConfig, AgenciaEstado estado, AlertaSaldoBaixo alertaSaldoBaixo,
                            TransferenciaService transferenciaService) {
        this.agenciaConfig = agenciaConfig;
        this.estado = estado;
        this.alertaSaldoBaixo = alertaSaldoBaixo;
        this.transferenciaService = transferenciaService;
    }

    private boolean naoEDono(int id, HttpServletRequest request) {
        Integer idAutenticado = (Integer) request.getAttribute("idContaAutenticada");
        return idAutenticado == null || idAutenticado != id;
    }

    private Map<String, Object> respostaConta(ContaModel conta, boolean saldoBaixo) {
        Map<String, Object> resposta = new HashMap<>();
        resposta.put("id", conta.getId());
        resposta.put("nomeAluno", conta.getNomeAluno());
        resposta.put("saldo", conta.getSaldo());
        resposta.put("saldoBaixo", saldoBaixo);
        return resposta;
    }

    @PostMapping
    public ResponseEntity<?> criarConta(@RequestBody ContaModel contaRecebida) throws IOException {
        int id = contaRecebida.getId();

        if (agenciaConfig.agenciaResponsavel(id) != agenciaConfig.getIdAgencia()) {
            return ResponseEntity.status(400)
                    .body(Map.of("erro", "Conta " + id + " não pertence a esta agência."));
        }
        if (estado.getContas().containsKey(id)) {
            return ResponseEntity.status(409).body(Map.of("erro", "Conta já existe."));
        }

        int[] ts = estado.getRelogio().eventoLocal();
        estado.getContas().put(id, contaRecebida);

        Map<String, Object> detalhes = new HashMap<>();
        detalhes.put("id", contaRecebida.getId());
        detalhes.put("nomeAluno", contaRecebida.getNomeAluno());
        detalhes.put("saldoInicial", contaRecebida.getSaldo());
        estado.getRegistro().registrar("CRIAR_CONTA", ts, detalhes);

        return ResponseEntity.status(201).body(contaRecebida);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> consultarSaldo(@PathVariable int id, HttpServletRequest request) {
        if (naoEDono(id, request)) {
            return ResponseEntity.status(403).body(Map.of("erro", "Você não tem permissão para acessar esta conta."));
        }
        ContaModel conta = estado.getContas().get(id);
        if (conta == null) {
            return ResponseEntity.status(404).body(Map.of("erro", "Conta não encontrada nesta agência."));
        }

        Map<String, Object> resposta = new LinkedHashMap<>();
        resposta.put("id", conta.getId());
        resposta.put("nomeAluno", conta.getNomeAluno());
        resposta.put("saldo", conta.getSaldo());
        resposta.put("vetorAtual", estado.getRelogio().obterVetorAtual());
        return ResponseEntity.ok(resposta);
    }

    @PostMapping("/{id}/depositar")
    public ResponseEntity<?> depositar(@PathVariable int id, @RequestBody Map<String, Object> corpo, HttpServletRequest request) throws IOException {
        if (naoEDono(id, request)) {
            return ResponseEntity.status(403).body(Map.of("erro", "Você não tem permissão para acessar esta conta."));
        }
        ContaModel conta = estado.getContas().get(id);
        if (conta == null) {
            return ResponseEntity.status(404).body(Map.of("erro", "Conta não encontrada nesta agência."));
        }

        double valor = Double.parseDouble(corpo.get("valor").toString());

        int[] ts = estado.getRelogio().eventoLocal();
        conta.setSaldo(conta.getSaldo() + valor);

        Map<String, Object> detalhes = new HashMap<>();
        detalhes.put("id", id);
        detalhes.put("valor", valor);
        detalhes.put("novoSaldo", conta.getSaldo());
        estado.getRegistro().registrar("DEPOSITO", ts, detalhes);

        return ResponseEntity.ok(respostaConta(conta, alertaSaldoBaixo.saldoEstaBaixo(conta)));
    }

    @PostMapping("/{id}/sacar")
    public ResponseEntity<?> sacar(@PathVariable int id, @RequestBody Map<String, Object> corpo, HttpServletRequest request) throws IOException {
        if (naoEDono(id, request)) {
            return ResponseEntity.status(403).body(Map.of("erro", "Você não tem permissão para acessar esta conta."));
        }
        ContaModel conta = estado.getContas().get(id);
        if (conta == null) {
            return ResponseEntity.status(404).body(Map.of("erro", "Conta não encontrada nesta agência."));
        }

        double valor = Double.parseDouble(corpo.get("valor").toString());
        if (valor > 2000) {
            return ResponseEntity.status(400).body(Map.of("erro", "Saque não pode ser superior a R$ 2000,00."));
        }
        if (conta.getSaldo() < valor) {
            return ResponseEntity.status(400).body(Map.of("erro", "Saldo insuficiente."));
        }

        int[] ts = estado.getRelogio().eventoLocal();
        conta.setSaldo(conta.getSaldo() - valor);

        Map<String, Object> detalhes = new HashMap<>();
        detalhes.put("id", id);
        detalhes.put("valor", valor);
        detalhes.put("novoSaldo", conta.getSaldo());
        estado.getRegistro().registrar("SAQUE", ts, detalhes);

        boolean saldoBaixo = alertaSaldoBaixo.verificar(conta);

        return ResponseEntity.ok(respostaConta(conta, saldoBaixo));
    }

    @PostMapping("/{id}/sincronizar")
    public ResponseEntity<?> sincronizarOperacaoPendente(@PathVariable int id, @RequestBody OperacaoPendente operacao, HttpServletRequest request) throws IOException {
        if (naoEDono(id, request)) {
            return ResponseEntity.status(403).body(Map.of("erro", "Você não tem permissão para acessar esta conta."));
        }
        ContaModel conta = estado.getContas().get(id);
        if (conta == null) {
            return ResponseEntity.status(404).body(Map.of("erro", "Conta não encontrada nesta agência."));
        }
        if (operacao.vetorConhecido() == null || operacao.vetorConhecido().length != AgenciaConfig.NUMERO_AGENCIAS) {
            return ResponseEntity.status(400).body(Map.of("erro", "Vetor conhecido ausente ou inválido."));
        }

        int[] vetorAtual = estado.getRelogio().obterVetorAtual();
        String relacao = ComparadorVetores.comparar(operacao.vetorConhecido(), vetorAtual);

        if (!relacao.equals("IGUAIS")) {
            Map<String, Object> conflito = new LinkedHashMap<>();
            conflito.put("erro", "Conflito detectado: o estado da conta mudou desde a última sincronização do app.");
            conflito.put("vetorConhecido", operacao.vetorConhecido());
            conflito.put("vetorAtual", vetorAtual);
            conflito.put("contaAtual", conta);
            return ResponseEntity.status(409).body(conflito);
        }

        double valor = operacao.valor();
        boolean saldoBaixo;
        int[] vetor;

        Map<String, Object> detalhes = new HashMap<>();
        detalhes.put("id", id);
        detalhes.put("tipo", operacao.tipo());
        detalhes.put("valor", valor);

        if ("DEPOSITO".equals(operacao.tipo())) {
            vetor = estado.getRelogio().eventoLocal();
            conta.setSaldo(conta.getSaldo() + valor);
            saldoBaixo = alertaSaldoBaixo.saldoEstaBaixo(conta);
        } else if ("SAQUE".equals(operacao.tipo())) {
            if (valor > 2000) {
                return ResponseEntity.status(400).body(Map.of("erro", "Saque não pode ser superior a R$ 2000,00."));
            }
            if (conta.getSaldo() < valor) {
                return ResponseEntity.status(400).body(Map.of("erro", "Saldo insuficiente."));
            }
            vetor = estado.getRelogio().eventoLocal();
            conta.setSaldo(conta.getSaldo() - valor);
            saldoBaixo = alertaSaldoBaixo.verificar(conta);
        } else if ("TRANSFERENCIA".equals(operacao.tipo())) {
            if (operacao.idDestino() == null) {
                return ResponseEntity.status(400).body(Map.of("erro", "Conta de destino não informada."));
            }
            ResultadoTransferencia resultado = transferenciaService.executar(id, operacao.idDestino(), valor);
            if (!resultado.sucesso()) {
                return ResponseEntity.status(resultado.status()).body(resultado.corpo());
            }
            vetor = estado.getRelogio().eventoLocal();
            saldoBaixo = Boolean.TRUE.equals(resultado.corpo().get("saldoBaixo"));
            detalhes.put("idDestino", operacao.idDestino());
        } else {
            return ResponseEntity.status(400).body(Map.of("erro", "Tipo de operação pendente não suportado."));
        }

        estado.getRegistro().registrar("SINCRONIZACAO_OFFLINE", vetor, detalhes);

        return ResponseEntity.ok(respostaConta(conta, saldoBaixo));
    }
}
