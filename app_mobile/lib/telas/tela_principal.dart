import 'package:flutter/material.dart';

import '../componentes/cartao_operacao.dart';
import '../componentes/componentes.dart';
import '../componentes/painel_lideranca.dart';
import '../services/api.dart';
import '../tema/tema.dart';
import 'tela_login.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  double? _saldo;
  String? _erroSaldo;

  @override
  void initState() {
    super.initState();
    _atualizarSaldo();
  }

  Future<void> _atualizarSaldo() async {
    try {
      final saldo = await api.consultarSaldo();
      if (!mounted) return;
      setState(() {
        _saldo = saldo;
        _erroSaldo = null;
      });
    } on SessaoExpirada catch (erro) {
      _voltarParaLogin(aviso: erro.mensagem);
    } on ErroApi catch (erro) {
      if (!mounted) return;
      setState(() => _erroSaldo = erro.mensagem);
    }
  }

  Future<void> _executar(
    String mensagemSucesso,
    Future<Map<String, dynamic>> Function() operacao,
  ) async {
    try {
      final resposta = await operacao();
      await _atualizarSaldo();
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(mensagemSucesso)));

      if (resposta['saldoBaixo'] == true) {
        _avisarSaldoBaixo();
      }
    } on SessaoExpirada catch (erro) {
      _voltarParaLogin(aviso: erro.mensagem);
      rethrow;
    }
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

  void _sair() {
    api.sair();
    _voltarParaLogin();
  }

  void _voltarParaLogin({String? aviso}) {
    if (!mounted) return;
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
              if (_erroSaldo != null) ...[
                MensagemErro(_erroSaldo!),
                const SizedBox(height: 20),
              ],
              _cartaoSaldo(),
              const SizedBox(height: 20),
              CartaoOperacao(
                numero: '01',
                titulo: 'Depositar',
                executar: (valor, _) => _executar(
                  'Depósito concluído com sucesso.',
                  () => api.depositar(valor),
                ),
              ),
              const SizedBox(height: 20),
              CartaoOperacao(
                numero: '02',
                titulo: 'Sacar',
                executar: (valor, _) => _executar(
                  'Saque concluído com sucesso.',
                  () => api.sacar(valor),
                ),
              ),
              const SizedBox(height: 20),
              CartaoOperacao(
                numero: '03',
                titulo: 'Transferir',
                pedirContaDestino: true,
                executar: (valor, idDestino) => _executar(
                  'Transferência concluída com sucesso.',
                  () => api.transferir(idDestino!, valor),
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
          const Text(
            'Saldo disponível',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _saldo == null ? 'R\$ --' : formatarReais(_saldo!),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
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
}
