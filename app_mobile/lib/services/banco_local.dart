import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../modelos/conta_em_cache.dart';
import '../modelos/operacao_pendente.dart';

class BancoLocal {
  Database? _banco;

  Future<Database> _abrir() async {
    final aberto = _banco;
    if (aberto != null) return aberto;

    final caminho = join(await getDatabasesPath(), 'iceibank.db');
    final novo = await openDatabase(
      caminho,
      version: 1,
      onCreate: (banco, versao) async {
        await banco.execute('''
          CREATE TABLE contas_cache (
            id_conta INTEGER PRIMARY KEY,
            saldo REAL NOT NULL,
            vetor TEXT NOT NULL,
            atualizado_em INTEGER NOT NULL
          )
        ''');
        await banco.execute('''
          CREATE TABLE operacoes_pendentes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_conta INTEGER NOT NULL,
            tipo TEXT NOT NULL,
            valor REAL NOT NULL,
            id_destino INTEGER,
            vetor TEXT NOT NULL,
            criada_em INTEGER NOT NULL,
            situacao TEXT NOT NULL,
            mensagem TEXT
          )
        ''');
      },
    );
    _banco = novo;
    return novo;
  }

  Future<ContaEmCache?> lerConta(int idConta) async {
    final banco = await _abrir();
    final linhas = await banco.query(
      'contas_cache',
      where: 'id_conta = ?',
      whereArgs: [idConta],
    );
    if (linhas.isEmpty) return null;
    return ContaEmCache.deLinha(linhas.first);
  }

  Future<void> salvarConta(ContaEmCache conta) async {
    final banco = await _abrir();
    await banco.insert(
      'contas_cache',
      conta.paraLinha(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<OperacaoPendente>> listarOperacoes(int idConta) async {
    final banco = await _abrir();
    final linhas = await banco.query(
      'operacoes_pendentes',
      where: 'id_conta = ?',
      whereArgs: [idConta],
      orderBy: 'id',
    );
    return linhas.map(OperacaoPendente.deLinha).toList();
  }

  Future<OperacaoPendente> inserirOperacao(OperacaoPendente operacao) async {
    final banco = await _abrir();
    final linha = operacao.paraLinha()..remove('id');
    final id = await banco.insert('operacoes_pendentes', linha);
    return operacao.copiar(id: id, mensagem: operacao.mensagem);
  }

  Future<void> atualizarOperacao(OperacaoPendente operacao) async {
    final banco = await _abrir();
    await banco.update(
      'operacoes_pendentes',
      operacao.paraLinha(),
      where: 'id = ?',
      whereArgs: [operacao.id],
    );
  }

  Future<void> removerOperacao(int id) async {
    final banco = await _abrir();
    await banco.delete('operacoes_pendentes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> atualizarVetorDasPendentes(int idConta, List<int> vetor) async {
    final banco = await _abrir();
    await banco.update(
      'operacoes_pendentes',
      {'vetor': jsonEncode(vetor)},
      where: 'id_conta = ? AND situacao = ?',
      whereArgs: [idConta, OperacaoPendente.pendente],
    );
  }

  Future<void> marcarPendentesComoConflito(int idConta, String mensagem) async {
    final banco = await _abrir();
    await banco.update(
      'operacoes_pendentes',
      {'situacao': OperacaoPendente.conflito, 'mensagem': mensagem},
      where: 'id_conta = ? AND situacao = ?',
      whereArgs: [idConta, OperacaoPendente.pendente],
    );
  }
}
