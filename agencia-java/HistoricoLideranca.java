import java.io.IOException;
import java.io.PrintStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

public class HistoricoLideranca {

    private static final List<String> TIPOS_BULLY = List.of(
            "ELEICAO_INICIADA", "ELEICAO_RECEBIDA", "TORNOU_LIDER", "LIDER_ANUNCIADO", "LIDER_NAO_RESPONDEU");

    private record Evento(String agencia, String tipo, Instant horaParede, String horaTexto, String detalhes) {
    }

    public static void main(String[] args) throws IOException {
        PrintStream saida = System.console() != null
                ? System.out
                : new PrintStream(System.out, true, StandardCharsets.UTF_8);

        Path pastaDados = Paths.get("data");
        if (!Files.isDirectory(pastaDados)) {
            saida.println("Pasta 'data' não encontrada. Execute dentro da pasta agencia-java, depois de gerar eventos.");
            return;
        }

        List<Path> arquivos;
        try (Stream<Path> caminhos = Files.list(pastaDados)) {
            arquivos = caminhos.filter(c -> c.toString().endsWith(".jsonl")).sorted().toList();
        }

        List<Evento> eventosBully = new ArrayList<>();
        for (Path arquivo : arquivos) {
            for (String linha : Files.readAllLines(arquivo, StandardCharsets.UTF_8)) {
                if (linha.isBlank()) continue;
                Evento evento = lerEvento(linha);
                if (TIPOS_BULLY.contains(evento.tipo())) {
                    eventosBully.add(evento);
                }
            }
        }

        eventosBully.sort(Comparator.comparing(Evento::horaParede));

        saida.println("=== Histórico de eventos de eleição ===");
        for (Evento evento : eventosBully) {
            saida.println("(" + evento.horaTexto() + ") [" + evento.agencia() + "] "
                    + evento.tipo() + " " + evento.detalhes());
        }

        saida.println();
        saida.println("=== Linha do tempo de líderes ===");
        for (Evento evento : eventosBully) {
            if (!evento.tipo().equals("TORNOU_LIDER")) continue;
            saida.println("A partir de " + evento.horaTexto() + ": Agência "
                    + extrair(evento.detalhes(), "\"idAgencia\":(\\d+)") + " é a líder");
        }
    }

    private static Evento lerEvento(String linha) {
        String agencia = extrair(linha, "\"agencia\":\"([^\"]*)\"");
        String tipo = extrair(linha, "\"tipo\":\"([^\"]*)\"");
        String hora = extrair(linha, "\"horaParede\":\"([^\"]*)\"");
        String detalhes = extrair(linha, "\"detalhes\":(\\{.*\\})\\}\\s*$");
        return new Evento(agencia, tipo, Instant.parse(hora), hora, detalhes);
    }

    private static String extrair(String texto, String expressao) {
        Matcher m = Pattern.compile(expressao).matcher(texto);
        return m.find() ? m.group(1) : "";
    }
}
