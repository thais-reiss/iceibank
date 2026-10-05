package com.iceibank.agencia_java.service;

import com.iceibank.agencia_java.config.AgenciaEstado;
import com.iceibank.agencia_java.model.MensagemAlertaSaldoBaixo;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@Component
public class ConsumidorAlertas {

    private final AgenciaEstado estado;

    public ConsumidorAlertas(AgenciaEstado estado) {
        this.estado = estado;
    }

    @RabbitListener(queues = "fila-alertas-agencia-${agencia.id}")
    public void aoReceberAlerta(MensagemAlertaSaldoBaixo alerta) throws IOException {
        int[] vetor = estado.getRelogio().aoReceber(alerta.vetorEnvio());

        Map<String, Object> detalhes = new HashMap<>();
        detalhes.put("idConta", alerta.idConta());
        detalhes.put("saldoAtual", alerta.saldoAtual());
        detalhes.put("origemAgencia", alerta.origemAgencia());

        estado.getRegistro().registrar("ALERTA_SALDO_BAIXO", vetor, detalhes);
    }
}