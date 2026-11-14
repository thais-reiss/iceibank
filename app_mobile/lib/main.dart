import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

// Tela temporaria, so para testar a rede (etapa 2).
// Sera substituida pelas telas de verdade nas proximas etapas.
void main() {
  runApp(const MaterialApp(home: TesteRede()));
}

class TesteRede extends StatelessWidget {
  const TesteRede({super.key});

  Future<String> consultarLider() async {
    final resposta = await http
        .get(Uri.parse('${urlDaAgencia(0)}/bully/lider'))
        .timeout(const Duration(seconds: 3));
    return resposta.body;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teste de rede')),
      body: Center(
        child: FutureBuilder<String>(
          future: consultarLider(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Erro: ${snapshot.error}');
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return Text(snapshot.data!);
          },
        ),
      ),
    );
  }
}
