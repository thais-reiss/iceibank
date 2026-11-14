package com.iceibank.agencia_java.controller;

import com.iceibank.agencia_java.config.AgenciaConfig;
import com.iceibank.agencia_java.model.MensagemCoordenador;
import com.iceibank.agencia_java.model.MensagemEleicao;
import com.iceibank.agencia_java.service.BullyService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/bully")
public class BullyController {

    private final AgenciaConfig agenciaConfig;
    private final BullyService bullyService;

    public BullyController(AgenciaConfig agenciaConfig, BullyService bullyService) {
        this.agenciaConfig = agenciaConfig;
        this.bullyService = bullyService;
    }

    @PostMapping("/eleicao")
    public ResponseEntity<Void> eleicao(@RequestBody MensagemEleicao mensagem) {
        bullyService.receberEleicao(mensagem.origemId(), mensagem.vetorEnvio());
        return ResponseEntity.ok().build();
    }

    @PostMapping("/coordenador")
    public ResponseEntity<Void> coordenador(@RequestBody MensagemCoordenador mensagem) {
        bullyService.receberCoordenador(mensagem.liderId(), mensagem.vetorEnvio());
        return ResponseEntity.ok().build();
    }

    @GetMapping("/lider")
    public Map<String, Object> lider() {
        // LinkedHashMap em vez de Map.of, porque liderAtual pode ser null
        Map<String, Object> resposta = new LinkedHashMap<>();
        resposta.put("idAgencia", agenciaConfig.getIdAgencia());
        resposta.put("liderAtual", bullyService.obterLiderAtual());
        return resposta;
    }
}
