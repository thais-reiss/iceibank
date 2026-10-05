package com.iceibank.agencia_java.service;

import com.iceibank.agencia_java.config.AgenciaEstado;
import com.iceibank.agencia_java.model.ContaModel;
import com.iceibank.agencia_java.model.MensagemCredito;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@Component
public class ConsumidorCreditos {

    private final AgenciaEstado estado;

    public ConsumidorCreditos(AgenciaEstado estado) {
        this.estado = estado;
    }

    @RabbitListener(queues = "fila-agencia-${agencia.id}")
    public void aoReceberCredito(MensagemCredito mensagem) throws IOException {
        int[] vetor = estado.getRelogio().aoReceber(mensagem.vetorEnvio());

        Map<String, Object> detalhes = new HashMap<>();
        detalhes.put("idConta", mensagem.idConta());
        detalhes.put("valor", mensagem.valor());
        detalhes.put("origemAgencia", mensagem.origemAgencia());

        ContaModel conta = estado.getContas().get(mensagem.idConta());

        if (conta == null) {
            detalhes.put("motivo", "conta nao encontrada");
            estado.getRegistro().registrar("CREDITO_REMOTO_FALHOU", vetor, detalhes);
            return;
        }

        if (mensagem.valor() <= 0) {
            detalhes.put("motivo", "valor invalido");
            estado.getRegistro().registrar("CREDITO_REMOTO_FALHOU", vetor, detalhes);
            return;
        }

        conta.setSaldo(conta.getSaldo() + mensagem.valor());
        estado.getRegistro().registrar("TRANSFERENCIA_CREDITO_REMOTO", vetor, detalhes);
    }
}