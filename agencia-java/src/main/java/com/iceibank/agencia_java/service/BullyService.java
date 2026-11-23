package com.iceibank.agencia_java.service;

import com.iceibank.agencia_java.config.AgenciaConfig;
import com.iceibank.agencia_java.config.AgenciaEstado;
import com.iceibank.agencia_java.config.AgenciaInfo;
import com.iceibank.agencia_java.model.MensagemCoordenador;
import com.iceibank.agencia_java.model.MensagemEleicao;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicBoolean;

@Service
public class BullyService {

    private static final int TIMEOUT_MS = 1000;
    
    private final AgenciaConfig agenciaConfig;
    private final AgenciaEstado estado;
    private final RestClient restClient;
    private volatile Integer liderAtual = null;
    private final AtomicBoolean eleicaoEmAndamento = new AtomicBoolean(false);

    public BullyService(AgenciaConfig agenciaConfig, AgenciaEstado estado) {
        this.agenciaConfig = agenciaConfig;
        this.estado = estado;

        SimpleClientHttpRequestFactory fabrica = new SimpleClientHttpRequestFactory();
        fabrica.setConnectTimeout(TIMEOUT_MS);
        fabrica.setReadTimeout(TIMEOUT_MS);
        this.restClient = RestClient.builder().requestFactory(fabrica).build();
    }

    @EventListener(ApplicationReadyEvent.class)
    public void aoSubir() {
        iniciarEleicao();
    }

    public void iniciarEleicao() {
        if (!eleicaoEmAndamento.compareAndSet(false, true)) 
            return;

        int idAgencia = agenciaConfig.getIdAgencia();
        boolean alguemRespondeu = false;

        try {
            registrar("ELEICAO_INICIADA", estado.getRelogio().eventoLocal(), Map.of("idAgencia", idAgencia));

            for (AgenciaInfo agencia : agenciaConfig.getAgencias()) {
                if (agencia.getId() <= idAgencia) 
                    continue; 

                try {
                    int[] vetorEnvio = estado.getRelogio().aoEnviar();
                    restClient.post()
                            .uri(agencia.getUrl() + "/bully/eleicao")
                            .contentType(MediaType.APPLICATION_JSON)
                            .body(new MensagemEleicao(idAgencia, vetorEnvio))
                            .retrieve()
                            .toBodilessEntity();
                    alguemRespondeu = true;
                } catch (RestClientException erro) {
            
                }
            }
        } finally {
            eleicaoEmAndamento.set(false);
        }

        if (!alguemRespondeu) {
            tornarMeLider();
        }
    }

    private void tornarMeLider() {
        int idAgencia = agenciaConfig.getIdAgencia();
        liderAtual = idAgencia;
        registrar("TORNOU_LIDER", estado.getRelogio().eventoLocal(), Map.of("idAgencia", idAgencia));

        for (AgenciaInfo agencia : agenciaConfig.getAgencias()) {
            if (agencia.getId() == idAgencia) continue;

            try {
                int[] vetorEnvio = estado.getRelogio().aoEnviar();
                restClient.post()
                        .uri(agencia.getUrl() + "/bully/coordenador")
                        .contentType(MediaType.APPLICATION_JSON)
                        .body(new MensagemCoordenador(idAgencia, vetorEnvio))
                        .retrieve()
                        .toBodilessEntity();
            } catch (RestClientException erro) {
                                        
            }
        }
    }

    public void receberEleicao(int origemId, int[] vetorRecebido) {
        int[] vetor = estado.getRelogio().aoReceber(vetorRecebido);
        registrar("ELEICAO_RECEBIDA", vetor,
                Map.of("de", origemId, "minhaId", agenciaConfig.getIdAgencia()));

        CompletableFuture.runAsync(this::iniciarEleicao);
    }

    public void receberCoordenador(int liderId, int[] vetorRecebido) {
        liderAtual = liderId;
        int[] vetor = estado.getRelogio().aoReceber(vetorRecebido);
        registrar("LIDER_ANUNCIADO", vetor,
                Map.of("liderId", liderId, "agencia", agenciaConfig.getIdAgencia()));
    }

    public Integer obterLiderAtual() {
        return liderAtual;
    }


    @Scheduled(initialDelay = 3000, fixedRate = 3000)
    public void verificarLider() {
        Integer lider = liderAtual;

        if (lider == null) {
            iniciarEleicao();
            return;
        }
        if (lider == agenciaConfig.getIdAgencia()) 
            return; 

        try {
            restClient.get()
                    .uri(agenciaConfig.buscarAgencia(lider).getUrl() + "/bully/lider")
                    .retrieve()
                    .toBodilessEntity();
        } catch (RestClientException erro) {
            registrar("LIDER_NAO_RESPONDEU", estado.getRelogio().eventoLocal(),
                    Map.of("liderAtual", lider, "agencia", agenciaConfig.getIdAgencia()));
            liderAtual = null;
            iniciarEleicao();
        }
    }

    private void registrar(String tipo, int[] vetor, Map<String, Object> detalhes) {
        try {
            estado.getRegistro().registrar(tipo, vetor, detalhes);
        } catch (IOException erro) {
            System.err.println("Falha ao registrar o evento " + tipo + ": " + erro.getMessage());
        }
    }
}
