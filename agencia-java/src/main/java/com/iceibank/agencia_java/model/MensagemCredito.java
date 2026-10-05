package com.iceibank.agencia_java.model;

public record MensagemCredito(int idConta, double valor, int[] vetorEnvio, int origemAgencia) {
}