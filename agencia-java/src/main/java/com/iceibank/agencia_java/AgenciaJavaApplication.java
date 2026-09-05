package com.iceibank.agencia_java;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class AgenciaJavaApplication {

    public static void main(String[] args) {

        int agenciaId = Integer.parseInt(
                System.getenv().getOrDefault("AGENCIA_ID", "0")
        );

        int offset = Integer.parseInt(
                System.getenv().getOrDefault("OFFSET", "22")
        );

        int porta = 4000 + offset + agenciaId;

        SpringApplication app = new SpringApplication(AgenciaJavaApplication.class);

        app.setDefaultProperties(
                java.util.Map.of("server.port", porta)
        );

        app.run(args);
    }
}