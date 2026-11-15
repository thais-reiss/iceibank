import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/config.dart';

class ErroApi implements Exception {
  final String mensagem;
  final int? status;
  final Map<String, dynamic> dados;

  ErroApi(this.mensagem, {this.status, this.dados = const {}});

  @override
  String toString() => mensagem;
}

class SemConexao extends ErroApi {
  SemConexao(super.mensagem);
}

class SessaoExpirada extends ErroApi {
  SessaoExpirada()
      : super('Sua sessão expirou. Faça login novamente.', status: 401);
}

class Api {
  static const Duration tempoLimite = Duration(seconds: 5);

  String? token;
  int? idConta;

  bool get logado => token != null;

  String get _urlAgencia => urlDaAgencia(agenciaResponsavel(idConta!));

  Future<void> login(int id, String senha) async {
    final url = '${urlDaAgencia(agenciaResponsavel(id))}/auth/login';
    final dados = await _enviar('POST', url, corpo: {'id': id, 'senha': senha});

    token = dados['token'] as String;
    idConta = id;
  }

  void sair() {
    token = null;
    idConta = null;
  }

  Future<double> consultarSaldo() async {
    final conta = await _chamar('GET', '/contas/$idConta');
    return (conta['saldo'] as num).toDouble();
  }

  Future<Map<String, dynamic>> depositar(double valor) {
    return _chamar('POST', '/contas/$idConta/depositar', {'valor': valor});
  }

  Future<Map<String, dynamic>> sacar(double valor) {
    return _chamar('POST', '/contas/$idConta/sacar', {'valor': valor});
  }

  Future<Map<String, dynamic>> transferir(int idDestino, double valor) {
    return _chamar('POST', '/transferencias', {
      'idOrigem': idConta,
      'idDestino': idDestino,
      'valor': valor,
    });
  }

  Future<Map<String, dynamic>> _chamar(String metodo, String caminho,
      [Map<String, dynamic>? corpo]) async {
    try {
      return await _enviar(metodo, '$_urlAgencia$caminho',
          corpo: corpo, comToken: true);
    } on SessaoExpirada {
      sair();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _enviar(String metodo, String url,
      {Map<String, dynamic>? corpo, bool comToken = false}) async {
    final cabecalhos = {
      'Content-Type': 'application/json',
      if (comToken) 'Authorization': 'Bearer $token',
    };

    final http.Response resposta;
    try {
      final uri = Uri.parse(url);
      if (metodo == 'GET') {
        resposta = await http.get(uri, headers: cabecalhos).timeout(tempoLimite);
      } else {
        resposta = await http
            .post(uri, headers: cabecalhos, body: jsonEncode(corpo))
            .timeout(tempoLimite);
      }
    } on TimeoutException {
      throw SemConexao('A agência demorou demais para responder.');
    } on SocketException {
      throw SemConexao('Não foi possível conectar à agência.');
    } on http.ClientException {
      throw SemConexao('Não foi possível conectar à agência.');
    }

    final dados = _lerJson(resposta);

    if (resposta.statusCode == 401 && comToken) {
      throw SessaoExpirada();
    }
    if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
      throw ErroApi(dados['erro']?.toString() ?? 'Erro desconhecido.',
          status: resposta.statusCode, dados: dados);
    }
    return dados;
  }

  Map<String, dynamic> _lerJson(http.Response resposta) {
    if (resposta.bodyBytes.isEmpty) return {};
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      return dados is Map<String, dynamic> ? dados : {};
    } on FormatException {
      return {};
    }
  }
}

final api = Api();
