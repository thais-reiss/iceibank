import 'dart:async';

import 'package:flutter/material.dart';

import '../componentes/cartao_operacao.dart';
import '../componentes/cartao_pendentes.dart';
import '../componentes/componentes.dart';
import '../componentes/painel_lideranca.dart';
import '../modelos/operacao_pendente.dart';
import '../services/api.dart';
import '../services/conta_offline.dart';
import '../tema/tema.dart';
import 'tela_login.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  StreamSubscription<AvisoConta>? _assinaturaAvisos;

  @override
  void initState() {
    super.initState();
    _assinaturaAvisos = servicoConta.avisos.listen(_mostrarAviso);
    servicoConta.iniciar();
    servicoConta.carregar(api.idConta!);
  }

  @override
  void dispose() {
    _assinaturaAvisos?.cancel();
    servicoConta.parar();
    super.dispose();
  }

  Future<void> _atualizarSaldo() async {
    await servicoConta.atualizar();
    await servicoConta.sincronizar();
  }

  Future<void> _executar(
    String tipo,
    String mensagemSucesso,
    double valor,
    int? idDestino,
  ) async {
    try {
      final resultado = await servicoConta.executar(tipo, valor, idDestino);
      if (!mounted) return;

      _mostrarFaixa(
        resultado.enfileirada
            ? 'Sem conexão: a operação foi guardada e será sincronizada '
                'automaticamente.'
            : mensagemSucesso,
      );

      if (resultado.saldoBaixo) {
        _avisarSaldoBaixo();
      }
    } on SessaoExpirada catch (erro) {
      _voltarParaLogin(aviso: erro.mensagem);
      rethrow;
    }
  }

  void _mostrarAviso(AvisoConta aviso) {
    if (!mounted) return;

    switch (aviso.tipo) {
      case TipoAviso.sincronizada:
        _mostrarFaixa(
          'Sincronizado com a agência: ${descreverOperacao(aviso.operacao!)}.',
        );
      case TipoAviso.recusada:
        _mostrarFaixa(
          '${descreverOperacao(aviso.operacao!)} foi recusado pela agência: '
          '${aviso.mensagem}',
        );
      case TipoAviso.saldoBaixo:
        _avisarSaldoBaixo();
      case TipoAviso.conflito:
        _avisarConflito();
      case TipoAviso.sessaoExpirada:
        api.sair();
        _voltarParaLogin(aviso: aviso.mensagem);
    }
  }

  void _mostrarFaixa(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  void _avisarSaldoBaixo() {
    showDialog<void>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Atenção'),
        content: const Text('Seu saldo está baixo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _avisarConflito() {
    final saldoReal = servicoConta.saldoConfirmado;

    showDialog<void>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Operação não sincronizada'),
        content: Text(
          'A conta foi alterada enquanto o app estava sem conexão, por isso '
          'as operações pendentes não foram aplicadas automaticamente.\n\n'
          'Saldo real da conta: '
          '${saldoReal == null ? '--' : formatarReais(saldoReal)}\n\n'
          'No cartão "Operações pendentes", escolha entre tentar novamente '
          'ou descartar cada operação.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _sair() {
    api.sair();
    _voltarParaLogin();
  }

  void _voltarParaLogin({String? aviso}) {
    if (!mounted) return;
    servicoConta.limpar();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => TelaLogin(aviso: aviso)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cabecalho(),
              const SizedBox(height: 24),
              const PainelLideranca(),
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: servicoConta,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (servicoConta.erroLeitura != null) ...[
                      MensagemErro(servicoConta.erroLeitura!),
                      const SizedBox(height: 20),
                    ],
                    _cartaoSaldo(),
                    if (servicoConta.operacoes.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const CartaoPendentes(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CartaoOperacao(
                numero: '01',
                titulo: 'Depositar',
                executar: (valor, _) => _executar(
                  OperacaoPendente.deposito,
                  'Depósito concluído com sucesso.',
                  valor,
                  null,
                ),
              ),
              const SizedBox(height: 20),
              CartaoOperacao(
                numero: '02',
                titulo: 'Sacar',
                executar: (valor, _) => _executar(
                  OperacaoPendente.saque,
                  'Saque concluído com sucesso.',
                  valor,
                  null,
                ),
              ),
              const SizedBox(height: 20),
              CartaoOperacao(
                numero: '03',
                titulo: 'Transferir',
                pedirContaDestino: true,
                executar: (valor, idDestino) => _executar(
                  OperacaoPendente.transferencia,
                  'Transferência concluída com sucesso.',
                  valor,
                  idDestino,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Rotulo('ICEIBank'),
              const SizedBox(height: 4),
              const Text(
                'Painel principal',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  text: 'Conta ',
                  style: const TextStyle(color: corTextoSuave),
                  children: [
                    TextSpan(
                      text: '${api.idConta}',
                      style: const TextStyle(
                        color: corTexto,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        OutlinedButton(onPressed: _sair, child: const Text('Sair')),
      ],
    );
  }

  Widget _cartaoSaldo() {
    final saldo = servicoConta.saldoProvisorio;
    final saldoConfirmado = servicoConta.saldoConfirmado;
    final temPendentes = servicoConta.temPendentes;
    final leitura = servicoConta.cache;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: corPrincipal,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x296A00FF),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Rotulo('Visão geral', cor: corPrincipalClara),
          const SizedBox(height: 4),
          Text(
            temPendentes ? 'Saldo provisório' : 'Saldo disponível',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            saldo == null ? 'R\$ --' : formatarReais(saldo),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (temPendentes && saldoConfirmado != null) ...[
            const SizedBox(height: 10),
            _avisoNoSaldo(
              Icons.schedule,
              'Pendente de sincronização · saldo confirmado pela agência: '
              '${formatarReais(saldoConfirmado)}',
            ),
          ],
          if (servicoConta.semConexao) ...[
            const SizedBox(height: 10),
            _avisoNoSaldo(
              Icons.cloud_off,
              leitura == null
                  ? 'Sem conexão com a agência.'
                  : 'Sem conexão com a agência · último saldo conhecido às '
                      '${formatarHora(leitura.atualizadoEm)}',
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _atualizarSaldo,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: corPrincipal,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Atualizar saldo'),
          ),
        ],
      ),
    );
  }

  Widget _avisoNoSaldo(IconData icone, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, color: corPrincipalClara, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(color: corPrincipalClara, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
