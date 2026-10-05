package com.iceibank.agencia_java.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class MensageriaConfig {

    public static final String EXCHANGE = "iceibank.eventos";

    @Value("${agencia.id}")
    private int idAgencia;

    public static String routingKeyCreditar(int idAgencia) {
        return "agencia." + idAgencia + ".creditar";
    }

    @Bean
    public TopicExchange exchange() {
        return new TopicExchange(EXCHANGE, true, false);
    }

    @Bean
    public Queue filaDestaAgencia() {
        return QueueBuilder.durable("fila-agencia-" + idAgencia).build();
    }

    @Bean
    public Binding bindingDestaAgencia(Queue filaDestaAgencia, TopicExchange exchange) {
        return BindingBuilder
                .bind(filaDestaAgencia)
                .to(exchange)
                .with(routingKeyCreditar(idAgencia));
    }

    @Bean
    public MessageConverter conversorJson() {
        return new Jackson2JsonMessageConverter();
    }
}