import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

public class MesclarLogs {

    private static final List<String> TIPOS_BULLY = List.of(
            "ELEICAO_INICIADA", "ELEICAO_RECEBIDA", "TORNOU_LIDER", "LIDER_ANUNCIADO", "LIDER_NAO_RESPONDEU");

    private record Evento(String agencia, String tipo, int[] vetor, Instant horaParede, String detalhes) {
    }

    public static void main(String[] args) throws IOException {
        PrintStream saida = System.console() != null
                ? System.out
                : new PrintStream(System.out, true, StandardCharsets.UTF_8);

        boolean incluirTodos = Arrays.asList(args).contains("--todos");

        Path pastaDados = Paths.get("data");
        if (!Files.isDirectory(pastaDados)) {
            saida.println("Pasta 'data' não encontrada. Execute dentro da pasta agencia-java, depois de gerar eventos.");
            return;
        }

        List<Path> arquivos;
        try (Stream<Path> caminhos = Files.list(pastaDados)) {
            arquivos = caminhos.filter(c -> c.toString().endsWith(".jsonl")).sorted().toList();
        }

        List<Evento> eventos = new ArrayList<>();
        for (Path arquivo : arquivos) {
            for (String linha : Files.readAllLines(arquivo, StandardCharsets.UTF_8)) {
                if (linha.isBlank()) continue;
                Evento evento = lerEvento(linha);
                if (!incluirTodos && TIPOS_BULLY.contains(evento.tipo())) continue;
                eventos.add(evento);
            }
        }

        eventos.sort(Comparator.comparing(Evento::horaParede));

        saida.println("=== Linha do tempo (ordenada por hora de parede) ===");
        for (Evento evento : eventos) {
            saida.println("[" + evento.agencia() + "] vetor=" + Arrays.toString(evento.vetor())
                    + " " + evento.tipo() + " " + evento.detalhes());
        }

        saida.println();
        saida.println("=== Pares de eventos CONCORRENTES entre agências diferentes ===");
        boolean encontrouConcorrente = false;
        for (int i = 0; i < eventos.size(); i++) {
            for (int j = i + 1; j < eventos.size(); j++) {
                Evento e1 = eventos.get(i);
                Evento e2 = eventos.get(j);
                if (e1.agencia().equals(e2.agencia())) continue;

                if (compararVetores(e1.vetor(), e2.vetor()).equals("CONCORRENTES")) {
                    encontrouConcorrente = true;
                    saida.println("[" + e1.agencia() + "] " + e1.tipo() + " " + Arrays.toString(e1.vetor())
                            + "  x  [" + e2.agencia() + "] " + e2.tipo() + " " + Arrays.toString(e2.vetor()));
                }
            }
        }

        if (!encontrouConcorrente) {
            saida.println("(nenhum par concorrente encontrado nesta execução - gere mais eventos em paralelo e rode de novo)");
        }
    }

    // Mesma regra do ComparadorVetores da aplicação.
    private static String compararVetores(int[] v1, int[] v2) {
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

    private static Evento lerEvento(String linha) {
        String agencia = extrair(linha, "\"agencia\":\"([^\"]*)\"");
        String tipo = extrair(linha, "\"tipo\":\"([^\"]*)\"");
        String vetorTexto = extrair(linha, "\"timestampVetorial\":\\[([^\\]]*)\\]");
        String hora = extrair(linha, "\"horaParede\":\"([^\"]*)\"");
        String detalhes = extrair(linha, "\"detalhes\":(\\{.*\\})\\}\\s*$");

        int[] vetor = Arrays.stream(vetorTexto.split(","))
                .map(String::trim)
                .mapToInt(Integer::parseInt)
                .toArray();

        return new Evento(agencia, tipo, vetor, Instant.parse(hora), detalhes);
    }

    private static String extrair(String texto, String expressao) {
        Matcher m = Pattern.compile(expressao).matcher(texto);
        return m.find() ? m.group(1) : "";
    }
}
