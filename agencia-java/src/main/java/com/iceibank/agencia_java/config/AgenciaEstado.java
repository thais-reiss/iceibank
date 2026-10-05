package com.iceibank.agencia_java.config;

import com.iceibank.agencia_java.model.ContaModel;
import com.iceibank.agencia_java.service.RegistroEventos;
import com.iceibank.agencia_java.service.RelogioLamport;
import com.iceibank.agencia_java.service.RelogioVetorial;
import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class AgenciaEstado {

    private final AgenciaConfig agenciaConfig;
    private final RelogioVetorial relogio;
    private final Map<Integer, ContaModel> contas = new ConcurrentHashMap<>();
    private RegistroEventos registro;

    public AgenciaEstado(AgenciaConfig agenciaConfig) {
        this.agenciaConfig = agenciaConfig;
        this.relogio = new RelogioVetorial(agenciaConfig.getIdAgencia(), AgenciaConfig.NUMERO_AGENCIAS);
    }

    @PostConstruct
    public void inicializar() throws IOException {
        this.registro = new RegistroEventos("agencia-" + agenciaConfig.getIdAgencia());
    }

    public RelogioVetorial getRelogio() {
    return relogio;
}

    public RegistroEventos getRegistro() {
        return registro;
    }

    public Map<Integer, ContaModel> getContas() {
        return contas;
    }
}