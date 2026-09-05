package com.iceibank.agencia_java.config;

public class AgenciaInfo {
     private final int id;
    private final String url;

    public AgenciaInfo(int id, String url) {
        this.id = id;
        this.url = url;
    }

    public int getId() {
        return id;
    }

    public String getUrl() {
        return url;
    }
}
