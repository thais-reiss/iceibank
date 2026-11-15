import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../modelos/conta_em_cache.dart';
import '../modelos/operacao_pendente.dart';
import 'api.dart';
import 'banco_local.dart';

enum TipoAviso { sincronizada, conflito, recusada, saldoBaixo, sessaoExpirada }

class AvisoConta {
  final TipoAviso tipo;
  final OperacaoPendente? operacao;
  final String? mensagem;

  AvisoConta(this.tipo, {this.operacao, this.mensagem});
}

class ResultadoOperacao {
  final bool enfileirada;
  final bool saldoBaixo;

  ResultadoOperacao({required this.enfileirada, required this.saldoBaixo});
}

class ServicoConta extends ChangeNotifier {
  static const Duration intervaloNovaTentativa = Duration(seconds: 8);
  static const String mensagemConflito =
      'O estado da conta mudou enquanto o app estava sem conexão.';

  BancoLocal banco = BancoLocal();

  ContaEmCache? cache;
  List<OperacaoPendente> operacoes = [];
  bool semConexao = false;
  bool sincronizando = false;
  String? erroLeitura;

  final StreamController<AvisoConta> _avisos =
      StreamController<AvisoConta>.broadcast();
  Timer? _temporizador;
  StreamSubscription<List<ConnectivityResult>>? _assinaturaConexao;
  int? _idConta;

  Stream<AvisoConta> get avisos => _avisos.stream;

  bool get temPendentes => operacoes.any((operacao) => operacao.estaPendente);

  double? get saldoConfirmado => cache?.saldo;

  double? get saldoProvisorio {
    final conta = cache;
    if (conta == null) return null;
    return operacoes
        .where((operacao) => operacao.estaPendente)
        .fold<double>(conta.saldo, (saldo, op) => saldo + op.efeitoNoSaldo);
  }

  Future<void> carregar(int idConta) async {
    _idConta = idConta;
    cache = await banco.lerConta(idConta);
    operacoes = await banco.listarOperacoes(idConta);
    notifyListeners();

    await atualizar();
    await sincronizar();
  }

  void iniciar() {
    _assinaturaConexao ??= Connectivity().onConnectivityChanged.listen((redes) {
      if (redes.any((rede) => rede != ConnectivityResult.none)) {
        _tentarDeNovo();
      }
    });
    _temporizador ??= Timer.periodic(intervaloNovaTentativa, (_) {
      if (semConexao || temPendentes) {
        _tentarDeNovo();
      }
    });
  }

  void parar() {
    _assinaturaConexao?.cancel();
    _assinaturaConexao = null;
    _temporizador?.cancel();
    _temporizador = null;
  }

  void limpar() {
    parar();
    _idConta = null;
    cache = null;
    operacoes = [];
    semConexao = false;
    erroLeitura = null;
  }

  Future<void> _tentarDeNovo() async {
    if (_idConta == null || !api.logado) return;
    await atualizar();
    await sincronizar();
  }

  Future<void> atualizar() async {
    final idConta = _idConta;
    if (idConta == null) return;

    try {
      final leitura = await api.consultarConta();
      await _guardarLeitura(idConta, leitura.saldo, leitura.vetorAtual);
      semConexao = false;
      erroLeitura = null;
    } on SemConexao {
      semConexao = true;
    } on SessaoExpirada catch (erro) {
      _avisos.add(AvisoConta(TipoAviso.sessaoExpirada, mensagem: erro.mensagem));
    } on ErroApi catch (erro) {
      erroLeitura = erro.mensagem;
    }
    notifyListeners();
  }

  Future<void> _guardarLeitura(int idConta, double saldo, List<int> vetor) async {
    final conta = ContaEmCache(
      idConta: idConta,
      saldo: saldo,
      vetor: vetor,
      atualizadoEm: DateTime.now(),
    );
    await banco.salvarConta(conta);
    cache = conta;
  }

  Future<ResultadoOperacao> executar(
    String tipo,
    double valor,
    int? idDestino,
  ) async {
    if (!temPendentes) {
      try {
        final resposta = await _enviarDireto(tipo, valor, idDestino);
        semConexao = false;
        await atualizar();
        return ResultadoOperacao(
          enfileirada: false,
          saldoBaixo: resposta['saldoBaixo'] == true,
        );
      } on SemConexao {
        semConexao = true;
      }
    }

    await _enfileirar(tipo, valor, idDestino);
    unawaited(sincronizar());
    return ResultadoOperacao(enfileirada: true, saldoBaixo: false);
  }

  Future<Map<String, dynamic>> _enviarDireto(
    String tipo,
    double valor,
    int? idDestino,
  ) {
    switch (tipo) {
      case OperacaoPendente.deposito:
        return api.depositar(valor);
      case OperacaoPendente.saque:
        return api.sacar(valor);
      default:
        return api.transferir(idDestino!, valor);
    }
  }

  Future<void> _enfileirar(String tipo, double valor, int? idDestino) async {
    final conta = cache;
    final idConta = _idConta;
    if (conta == null || idConta == null) {
      notifyListeners();
      throw ErroApi(
        'Sem conexão com a agência e sem dados salvos desta conta.',
      );
    }

    final saldoDisponivel = saldoProvisorio ?? conta.saldo;
    if (tipo != OperacaoPendente.deposito && valor > saldoDisponivel) {
      notifyListeners();
      throw ErroApi(
        'Sem conexão: o valor é maior que o saldo provisório da conta.',
      );
    }

    final operacao = await banco.inserirOperacao(
      OperacaoPendente(
        idConta: idConta,
        tipo: tipo,
        valor: valor,
        idDestino: idDestino,
        vetor: conta.vetor,
        criadaEm: DateTime.now(),
      ),
    );
    operacoes = [...operacoes, operacao];
    notifyListeners();
  }

  Future<void> sincronizar() async {
    if (sincronizando || !api.logado || !temPendentes) return;

    sincronizando = true;
    notifyListeners();

    try {
      while (true) {
        final proxima = operacoes
            .where((operacao) => operacao.estaPendente)
            .firstOrNull;
        if (proxima == null) break;

        final continuar = await _sincronizarUma(proxima);
        if (!continuar) break;
      }
    } finally {
      sincronizando = false;
      notifyListeners();
    }
  }

  Future<bool> _sincronizarUma(OperacaoPendente operacao) async {
    try {
      final resposta = await api.sincronizar(
        tipo: operacao.tipo,
        valor: operacao.valor,
        vetorConhecido: operacao.vetor,
        idDestino: operacao.idDestino,
      );

      await banco.removerOperacao(operacao.id!);
      semConexao = false;
      _avisos.add(AvisoConta(TipoAviso.sincronizada, operacao: operacao));
      if (resposta['saldoBaixo'] == true) {
        _avisos.add(AvisoConta(TipoAviso.saldoBaixo));
      }

      await _recarregarDepoisDoEnvio();
      return true;
    } on SemConexao {
      semConexao = true;
      return false;
    } on SessaoExpirada catch (erro) {
      _avisos.add(AvisoConta(TipoAviso.sessaoExpirada, mensagem: erro.mensagem));
      return false;
    } on ErroApi catch (erro) {
      if (erro.status == 409) {
        await _tratarConflito(erro);
        return false;
      }

      await banco.atualizarOperacao(
        operacao.copiar(
          situacao: OperacaoPendente.recusada,
          mensagem: erro.mensagem,
        ),
      );
      _avisos.add(
        AvisoConta(
          TipoAviso.recusada,
          operacao: operacao,
          mensagem: erro.mensagem,
        ),
      );

      await _recarregarDepoisDoEnvio();
      return true;
    }
  }

  Future<void> _recarregarDepoisDoEnvio() async {
    final idConta = _idConta;
    if (idConta == null) return;

    try {
      final leitura = await api.consultarConta();
      await _guardarLeitura(idConta, leitura.saldo, leitura.vetorAtual);
      await banco.atualizarVetorDasPendentes(idConta, leitura.vetorAtual);
    } on SemConexao {
      semConexao = true;
    } on SessaoExpirada catch (erro) {
      _avisos.add(AvisoConta(TipoAviso.sessaoExpirada, mensagem: erro.mensagem));
    } on ErroApi catch (erro) {
      erroLeitura = erro.mensagem;
    }

    operacoes = await banco.listarOperacoes(idConta);
    notifyListeners();
  }

  Future<void> _tratarConflito(ErroApi erro) async {
    final idConta = _idConta;
    if (idConta == null) return;

    final contaAtual = erro.dados['contaAtual'];
    final vetorAtual = erro.dados['vetorAtual'];
    if (contaAtual is Map && vetorAtual is List) {
      await _guardarLeitura(
        idConta,
        (contaAtual['saldo'] as num).toDouble(),
        vetorAtual.map((numero) => (numero as num).toInt()).toList(),
      );
    }

    await banco.marcarPendentesComoConflito(idConta, mensagemConflito);
    operacoes = await banco.listarOperacoes(idConta);
    semConexao = false;
    notifyListeners();

    _avisos.add(AvisoConta(TipoAviso.conflito, mensagem: erro.mensagem));
  }

  Future<void> tentarNovamente(OperacaoPendente operacao) async {
    final idConta = _idConta;
    if (idConta == null) return;

    await atualizar();
    final conta = cache;
    if (conta == null) return;

    await banco.atualizarOperacao(
      operacao.copiar(situacao: OperacaoPendente.pendente, vetor: conta.vetor),
    );
    operacoes = await banco.listarOperacoes(idConta);
    notifyListeners();

    await sincronizar();
  }

  Future<void> descartar(OperacaoPendente operacao) async {
    final idConta = _idConta;
    if (idConta == null) return;

    await banco.removerOperacao(operacao.id!);
    operacoes = await banco.listarOperacoes(idConta);
    notifyListeners();
  }
}

final servicoConta = ServicoConta();
