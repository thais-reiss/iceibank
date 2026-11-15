import 'dart:convert';

class OperacaoPendente {
  static const String deposito = 'DEPOSITO';
  static const String saque = 'SAQUE';
  static const String transferencia = 'TRANSFERENCIA';

  static const String pendente = 'PENDENTE';
  static const String conflito = 'CONFLITO';
  static const String recusada = 'RECUSADA';

  final int? id;
  final int idConta;
  final String tipo;
  final double valor;
  final int? idDestino;
  final List<int> vetor;
  final DateTime criadaEm;
  final String situacao;
  final String? mensagem;

  OperacaoPendente({
    this.id,
    required this.idConta,
    required this.tipo,
    required this.valor,
    this.idDestino,
    required this.vetor,
    required this.criadaEm,
    this.situacao = pendente,
    this.mensagem,
  });

  bool get estaPendente => situacao == pendente;
  bool get emConflito => situacao == conflito;
  bool get foiRecusada => situacao == recusada;

  double get efeitoNoSaldo => tipo == deposito ? valor : -valor;

  OperacaoPendente copiar({
    int? id,
    List<int>? vetor,
    String? situacao,
    String? mensagem,
  }) {
    return OperacaoPendente(
      id: id ?? this.id,
      idConta: idConta,
      tipo: tipo,
      valor: valor,
      idDestino: idDestino,
      vetor: vetor ?? this.vetor,
      criadaEm: criadaEm,
      situacao: situacao ?? this.situacao,
      mensagem: mensagem,
    );
  }

  Map<String, Object?> paraLinha() {
    return {
      'id': id,
      'id_conta': idConta,
      'tipo': tipo,
      'valor': valor,
      'id_destino': idDestino,
      'vetor': jsonEncode(vetor),
      'criada_em': criadaEm.millisecondsSinceEpoch,
      'situacao': situacao,
      'mensagem': mensagem,
    };
  }

  factory OperacaoPendente.deLinha(Map<String, Object?> linha) {
    return OperacaoPendente(
      id: linha['id'] as int,
      idConta: linha['id_conta'] as int,
      tipo: linha['tipo'] as String,
      valor: (linha['valor'] as num).toDouble(),
      idDestino: linha['id_destino'] as int?,
      vetor: (jsonDecode(linha['vetor'] as String) as List).cast<int>(),
      criadaEm: DateTime.fromMillisecondsSinceEpoch(linha['criada_em'] as int),
      situacao: linha['situacao'] as String,
      mensagem: linha['mensagem'] as String?,
    );
  }
}
