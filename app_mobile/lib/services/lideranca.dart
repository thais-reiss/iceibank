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

class TrocaLideranca {
  final int? liderAnterior;
  final int novaLider;
  final DateTime momento;

  TrocaLideranca({
    required this.liderAnterior,
    required this.novaLider,
    required this.momento,
  });
}

class ServicoLideranca extends ChangeNotifier {
  static const Duration intervalo = Duration(seconds: 3);
  static const Duration tempoLimite = Duration(seconds: 2);
  static const int tamanhoMaximoHistorico = 50;

  EstadoLideranca? estado;
  final List<TrocaLideranca> historico = [];

  Timer? _temporizador;
  bool _consultando = false;
  int _agenciaPreferida = 0;
  int? _ultimaLiderConhecida;

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
      final novoEstado = await _perguntarAsAgencias();
      _registrarTroca(novoEstado);
      estado = novoEstado;
      notifyListeners();
    } finally {
      _consultando = false;
    }
  }

  void _registrarTroca(EstadoLideranca novoEstado) {
    final lider = novoEstado.lider;
    if (lider == null || lider == _ultimaLiderConhecida) return;

    historico.insert(
      0,
      TrocaLideranca(
        liderAnterior: _ultimaLiderConhecida,
        novaLider: lider,
        momento: novoEstado.atualizadoEm,
      ),
    );
    if (historico.length > tamanhoMaximoHistorico) {
      historico.removeLast();
    }
    _ultimaLiderConhecida = lider;
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
