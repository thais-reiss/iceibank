package com.iceibank.agencia_java.service;

import com.iceibank.agencia_java.config.AgenciaConfig;
import com.iceibank.agencia_java.config.AgenciaEstado;
import com.iceibank.agencia_java.config.MensageriaConfig;
import com.iceibank.agencia_java.model.ContaModel;
import com.iceibank.agencia_java.model.MensagemCredito;
import com.iceibank.agencia_java.model.ResultadoTransferencia;
import org.springframework.amqp.AmqpException;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@Service
public class TransferenciaService {

    private final AgenciaConfig agenciaConfig;
    private final AgenciaEstado estado;
    private final RabbitTemplate rabbitTemplate;
    private final AlertaSaldoBaixo alertaSaldoBaixo;

    public TransferenciaService(AgenciaConfig agenciaConfig, AgenciaEstado estado,
                                RabbitTemplate rabbitTemplate, AlertaSaldoBaixo alertaSaldoBaixo) {
        this.agenciaConfig = agenciaConfig;
        this.estado = estado;
        this.rabbitTemplate = rabbitTemplate;
        this.alertaSaldoBaixo = alertaSaldoBaixo;
    }

    private Map<String, Object> detalhesTransferencia(int idOrigem, int idDestino, double valor) {
        Map<String, Object> detalhes = new HashMap<>();
        detalhes.put("idOrigem", idOrigem);
        detalhes.put("idDestino", idDestino);
        detalhes.put("valor", valor);
        return detalhes;
    }

    private ResultadoTransferencia erro(int status, String mensagem) {
        return new ResultadoTransferencia(status, Map.of("erro", mensagem));
    }

    public ResultadoTransferencia executar(int idOrigem, int idDestino, double valor) throws IOException {
        if (valor <= 0) {
            return erro(400, "O valor da transferência deve ser maior que zero.");
        }

        ContaModel contaOrigem = estado.getContas().get(idOrigem);

        if (contaOrigem == null) {
            return erro(404, "Conta de origem não encontrada nesta agência.");
        }

        if (contaOrigem.getSaldo() < valor) {
            return erro(400, "Saldo insuficiente.");
        }

        int agenciaDestino = agenciaConfig.agenciaResponsavel(idDestino);

        if (agenciaDestino == agenciaConfig.getIdAgencia()) {
            ContaModel contaDestino = estado.getContas().get(idDestino);

            if (contaDestino == null) {
                return erro(404, "Conta de destino não encontrada.");
            }

            int[] vetorDebito = estado.getRelogio().eventoLocal();
            contaOrigem.setSaldo(contaOrigem.getSaldo() - valor);
            estado.getRegistro().registrar("TRANSFERENCIA_DEBITO", vetorDebito,
                    detalhesTransferencia(idOrigem, idDestino, valor));

            int[] vetorCredito = estado.getRelogio().eventoLocal();
            contaDestino.setSaldo(contaDestino.getSaldo() + valor);
            estado.getRegistro().registrar("TRANSFERENCIA_CREDITO", vetorCredito,
                    detalhesTransferencia(idOrigem, idDestino, valor));

            boolean saldoBaixo = alertaSaldoBaixo.verificar(contaOrigem);

            return new ResultadoTransferencia(200, Map.of(
                    "mensagem", "Transferência concluída (mesma agência).",
                    "saldoBaixo", saldoBaixo));
        }

        int[] vetorDebito = estado.getRelogio().eventoLocal();
        contaOrigem.setSaldo(contaOrigem.getSaldo() - valor);
        estado.getRegistro().registrar("TRANSFERENCIA_DEBITO", vetorDebito,
                detalhesTransferencia(idOrigem, idDestino, valor));

        int[] vetorEnvio = estado.getRelogio().aoEnviar();
        MensagemCredito mensagem = new MensagemCredito(idDestino, valor, vetorEnvio, agenciaConfig.getIdAgencia());

        try {
            rabbitTemplate.convertAndSend(
                    MensageriaConfig.EXCHANGE,
                    MensageriaConfig.routingKeyCreditar(agenciaDestino),
                    mensagem);
        } catch (AmqpException erro) {
            Map<String, Object> detalhesFalha = detalhesTransferencia(idOrigem, idDestino, valor);
            detalhesFalha.put("erro", erro.getMessage());
            estado.getRegistro().registrar("TRANSFERENCIA_FALHOU", estado.getRelogio().eventoLocal(), detalhesFalha);

            return erro(502, "Falha ao publicar a mensagem no RabbitMQ. "
                    + "Débito já aplicado - inconsistência conhecida (ver Sprint 4).");
        }

        boolean saldoBaixo = alertaSaldoBaixo.verificar(contaOrigem);

        return new ResultadoTransferencia(200, Map.of(
                "mensagem", "Transferência publicada para a agência de destino (entrega assíncrona).",
                "saldoBaixo", saldoBaixo));
    }
}
