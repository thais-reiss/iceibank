package com.iceibank.agencia_java.model;

public record MensagemAlertaSaldoBaixo(int idConta, double saldoAtual, int[] vetorEnvio, int origemAgencia) {
}