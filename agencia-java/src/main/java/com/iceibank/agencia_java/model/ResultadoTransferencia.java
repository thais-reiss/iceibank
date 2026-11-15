package com.iceibank.agencia_java.model;

import java.util.Map;

public record ResultadoTransferencia(int status, Map<String, Object> corpo) {

    public boolean sucesso() {
        return status == 200;
    }
}
