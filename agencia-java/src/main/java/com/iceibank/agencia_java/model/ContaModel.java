package com.iceibank.agencia_java.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class ContaModel {
    private int id;
    private String nomeAluno;
    private double saldo;
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    private String senha;

    public ContaModel() { }

    public ContaModel(int id, String nomeAluno, double saldo, String senha) {
        this.id = id;
        this.nomeAluno = nomeAluno;
        this.saldo = saldo;
        this.senha = senha;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getNomeAluno() {
        return nomeAluno;
    }

    public void setNomeAluno(String nomeAluno) {
        this.nomeAluno = nomeAluno;
    }

    public double getSaldo() {
        return saldo;
    }

    public void setSaldo(double saldo) {
        this.saldo = saldo;
    }

        public String getSenha() {
        return senha;
    }

    public void setSenha(String senha) {
        this.senha = senha;
    }

}
