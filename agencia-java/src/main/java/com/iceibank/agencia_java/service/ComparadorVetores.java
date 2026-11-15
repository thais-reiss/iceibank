package com.iceibank.agencia_java.service;

public final class ComparadorVetores {

    private ComparadorVetores() {
    }

    public static String comparar(int[] v1, int[] v2) {
        boolean v1MenorOuIgual = true;
        boolean v2MenorOuIgual = true;
        for (int i = 0; i < v1.length; i++) {
            if (v1[i] > v2[i]) v1MenorOuIgual = false;
            if (v2[i] > v1[i]) v2MenorOuIgual = false;
        }
        if (v1MenorOuIgual && v2MenorOuIgual) return "IGUAIS";
        if (v1MenorOuIgual) return "ANTES";
        if (v2MenorOuIgual) return "DEPOIS";
        return "CONCORRENTES";
    }
}
