package com.iceibank.agencia_java.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Declarables;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AlertasConfig {

    public static final String ROUTING_KEY_ALERTA = "alertas.saldo-baixo";

    @Value("${agencia.id}")
    private int idAgencia;

    @Bean
    public Declarables alertasDestaAgencia(TopicExchange exchange) {
        Queue fila = QueueBuilder.durable("fila-alertas-agencia-" + idAgencia).build();
        Binding binding = BindingBuilder.bind(fila).to(exchange).with(ROUTING_KEY_ALERTA);
        return new Declarables(fila, binding);
    }
}