import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/config.dart';

class EstadoLideranca {
  final int? lider;
  final int? agenciaConsultada;
  final DateTime atualizadoEm;

  EstadoLideranca({
    required this.lider,
    required this.agenciaConsultada,
    required this.atualizadoEm,
  });

  bool get nenhumaRespondeu => agenciaConsultada == null;
}

class ServicoLideranca extends ChangeNotifier {
  static const Duration intervalo = Duration(seconds: 3);
  static const Duration tempoLimite = Duration(seconds: 2);

  EstadoLideranca? estado;
  Timer? _temporizador;
  bool _consultando = false;
  int _agenciaPreferida = 0;

  void iniciar() {
    if (_temporizador != null) return;
    consultar();
    _temporizador = Timer.periodic(intervalo, (_) => consultar());
  }

  void parar() {
    _temporizador?.cancel();
    _temporizador = null;
  }

  Future<void> consultar() async {
    if (_consultando) return;
    _consultando = true;

    try {
      estado = await _perguntarAsAgencias();
      notifyListeners();
    } finally {
      _consultando = false;
    }
  }

  Future<EstadoLideranca> _perguntarAsAgencias() async {
    for (var tentativa = 0; tentativa < numeroAgencias; tentativa++) {
      final idAgencia = (_agenciaPreferida + tentativa) % numeroAgencias;

      try {
        final resposta = await http
            .get(Uri.parse('${urlDaAgencia(idAgencia)}/bully/lider'))
            .timeout(tempoLimite);
        if (resposta.statusCode != 200) continue;

        final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
        _agenciaPreferida = idAgencia;
        return EstadoLideranca(
          lider: dados['liderAtual'] as int?,
          agenciaConsultada: idAgencia,
          atualizadoEm: DateTime.now(),
        );
      } on Exception {
        continue;
      }
    }

    return EstadoLideranca(
      lider: null,
      agenciaConsultada: null,
      atualizadoEm: DateTime.now(),
    );
  }
}

final lideranca = ServicoLideranca();
