import 'dart:convert';

class ContaEmCache {
  final int idConta;
  final double saldo;
  final List<int> vetor;
  final DateTime atualizadoEm;

  ContaEmCache({
    required this.idConta,
    required this.saldo,
    required this.vetor,
    required this.atualizadoEm,
  });

  Map<String, Object?> paraLinha() {
    return {
      'id_conta': idConta,
      'saldo': saldo,
      'vetor': jsonEncode(vetor),
      'atualizado_em': atualizadoEm.millisecondsSinceEpoch,
    };
  }

  factory ContaEmCache.deLinha(Map<String, Object?> linha) {
    return ContaEmCache(
      idConta: linha['id_conta'] as int,
      saldo: (linha['saldo'] as num).toDouble(),
      vetor: (jsonDecode(linha['vetor'] as String) as List).cast<int>(),
      atualizadoEm:
          DateTime.fromMillisecondsSinceEpoch(linha['atualizado_em'] as int),
    );
  }
}
