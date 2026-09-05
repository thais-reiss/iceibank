package com.iceibank.agencia_java.config;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
public class AgenciaConfig {

    public static final int NUMERO_AGENCIAS = 3;

    @Value("${agencia.id}")
    private int idAgencia;

    @Value("${agencia.offset}")
    private int offset;

    private List<AgenciaInfo> agencias;

    @PostConstruct
    public void inicializar() {
        int portaBase = 4000 + offset;
        agencias = new ArrayList<>();
        for (int i = 0; i < NUMERO_AGENCIAS; i++) {
            agencias.add(new AgenciaInfo(i, "http://localhost:" + (portaBase + i)));
        }
    }

    public int getIdAgencia() {
        return idAgencia;
    }

    public List<AgenciaInfo> getAgencias() {
        return agencias;
    }

    public int agenciaResponsavel(int idConta) {
        return idConta % NUMERO_AGENCIAS;
    }

    public AgenciaInfo buscarAgencia(int id) {
        return agencias.stream()
                .filter(a -> a.getId() == id)
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Agência " + id + " não configurada."));
    }
}
