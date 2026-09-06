package com.iceibank.agencia_java.controller;

import com.iceibank.agencia_java.config.AgenciaConfig;
import com.iceibank.agencia_java.config.AgenciaEstado;
import com.iceibank.agencia_java.model.ContaModel;
import com.iceibank.agencia_java.service.JwtService;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/contas")
public class ContasController {

    private final AgenciaConfig agenciaConfig;
    private final AgenciaEstado estado;
    private static final double LIMITE_SAQUE = 2000;
    private final JwtService jwtService;

    public ContasController(AgenciaConfig agenciaConfig, AgenciaEstado estado, JwtService jwtService) {
        this.agenciaConfig = agenciaConfig;
        this.estado = estado;
        this.jwtService = jwtService;
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

        int ts = estado.getRelogio().eventoLocal();
        estado.getContas().put(id, contaRecebida);

        Map<String, Object> detalhes = new HashMap<>();
        detalhes.put("id", contaRecebida.getId());
        detalhes.put("nomeAluno", contaRecebida.getNomeAluno());
        detalhes.put("saldoInicial", contaRecebida.getSaldo());
        estado.getRegistro().registrar("CRIAR_CONTA", ts, detalhes);

        return ResponseEntity.status(201).body(contaRecebida);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> consultarSaldo(@PathVariable int id) {
        ContaModel conta = estado.getContas().get(id);
        if (conta == null) {
            return ResponseEntity.status(404).body(Map.of("erro", "Conta não encontrada nesta agência."));
        }
        return ResponseEntity.ok(conta);
    }

    @PostMapping("/{id}/depositar")
    public ResponseEntity<?> depositar(@PathVariable int id, @RequestBody Map<String, Object> corpo) throws IOException {
        ContaModel conta = estado.getContas().get(id);
        if (conta == null) {
            return ResponseEntity.status(404).body(Map.of("erro", "Conta não encontrada nesta agência."));
        }

        double valor = Double.parseDouble(corpo.get("valor").toString());

        int ts = estado.getRelogio().eventoLocal();
        conta.setSaldo(conta.getSaldo() + valor);

        Map<String, Object> detalhes = new HashMap<>();
        detalhes.put("id", id);
        detalhes.put("valor", valor);
        detalhes.put("novoSaldo", conta.getSaldo());
        estado.getRegistro().registrar("DEPOSITO", ts, detalhes);

        return ResponseEntity.ok(conta);
    }

    @PostMapping("/{id}/sacar")
    public ResponseEntity<?> sacar(@PathVariable int id, @RequestBody Map<String, Object> corpo) throws IOException {
        ContaModel conta = estado.getContas().get(id);
        if (conta == null) {
            return ResponseEntity.status(404).body(Map.of("erro", "Conta não encontrada nesta agência."));
        }

        double valor = Double.parseDouble(corpo.get("valor").toString());
        if (valor > LIMITE_SAQUE) {
            return ResponseEntity.status(400).body(Map.of("erro", "Saque não pode ser superior a R$ 2000,00."));
        }
        
        if (conta.getSaldo() < valor) {
            return ResponseEntity.status(400).body(Map.of("erro", "Saldo insuficiente."));
        }

        int ts = estado.getRelogio().eventoLocal();
        conta.setSaldo(conta.getSaldo() - valor);

        Map<String, Object> detalhes = new HashMap<>();
        detalhes.put("id", id);
        detalhes.put("valor", valor);
        detalhes.put("novoSaldo", conta.getSaldo());
        estado.getRegistro().registrar("SAQUE", ts, detalhes);

        return ResponseEntity.ok(conta);
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credenciais) {
        String idStr = credenciais.get("id");
        String senha = credenciais.get("senha");

        if (idStr == null || senha == null) {
            return ResponseEntity.status(400).body(Map.of("erro", "ID e senha são obrigatórios."));
        }

        int id = Integer.parseInt(idStr);
        ContaModel conta = estado.getContas().get(id);

        if (conta == null || !conta.getSenha().equals(senha)) {
            return ResponseEntity.status(401).body(Map.of("erro", "Credenciais inválidas."));
        }

        String token = jwtService.gerarToken(id);
        return ResponseEntity.ok(Map.of(
                "mensagem", "Login bem-sucedido.",
                "token", token
        ));
    }
}