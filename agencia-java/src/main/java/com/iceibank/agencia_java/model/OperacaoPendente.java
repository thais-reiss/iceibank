package com.iceibank.agencia_java.model;

public record OperacaoPendente(String tipo, double valor, int[] vetorConhecido, Integer idDestino) {
}
