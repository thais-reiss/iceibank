package com.iceibank.agencia_java.service;

import com.iceibank.agencia_java.config.AgenciaConfig;
import com.iceibank.agencia_java.config.AgenciaEstado;
import com.iceibank.agencia_java.config.AlertasConfig;
import com.iceibank.agencia_java.config.MensageriaConfig;
import com.iceibank.agencia_java.model.ContaModel;
import com.iceibank.agencia_java.model.MensagemAlertaSaldoBaixo;
import org.springframework.amqp.AmqpException;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

@Component
public class AlertaSaldoBaixo {

    private static final double LIMITE_SALDO_BAIXO = 50.0;

    private final AgenciaConfig agenciaConfig;
    private final AgenciaEstado estado;
    private final RabbitTemplate rabbitTemplate;

    public AlertaSaldoBaixo(AgenciaConfig agenciaConfig, AgenciaEstado estado, RabbitTemplate rabbitTemplate) {
        this.agenciaConfig = agenciaConfig;
        this.estado = estado;
        this.rabbitTemplate = rabbitTemplate;
    }

    public boolean saldoEstaBaixo(ContaModel conta) {
        return conta.getSaldo() < LIMITE_SALDO_BAIXO;
    }

    public boolean verificar(ContaModel conta) {
        if (!saldoEstaBaixo(conta)) {
            return false;
        }

        int[] vetorEnvio = estado.getRelogio().aoEnviar();
        MensagemAlertaSaldoBaixo alerta = new MensagemAlertaSaldoBaixo(
                conta.getId(), conta.getSaldo(), vetorEnvio, agenciaConfig.getIdAgencia());

        try {
            rabbitTemplate.convertAndSend(MensageriaConfig.EXCHANGE, AlertasConfig.ROUTING_KEY_ALERTA, alerta);
        } catch (AmqpException erro) {
            System.out.println("Falha ao publicar alerta de saldo baixo: " + erro.getMessage());
        }

        return true;
    }
}