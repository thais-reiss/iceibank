import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api.dart';
import '../componentes/componentes.dart';
import 'tela_principal.dart';

class TelaLogin extends StatefulWidget {
  final String? aviso;

  const TelaLogin({super.key, this.aviso});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _formulario = GlobalKey<FormState>();
  final _campoConta = TextEditingController();
  final _campoSenha = TextEditingController();

  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _erro = widget.aviso;
  }

  @override
  void dispose() {
    _campoConta.dispose();
    _campoSenha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formulario.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await api.login(int.parse(_campoConta.text), _campoSenha.text);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TelaPrincipal()),
      );
    } on ErroApi catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro.mensagem;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Cartao(
              child: Form(
                key: _formulario,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: Rotulo('ICEIBank')),
                    const SizedBox(height: 6),
                    const Text(
                      'Faça seu login',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    CampoComRotulo(
                      rotulo: 'ID da conta:',
                      campo: TextFormField(
                        controller: _campoConta,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textInputAction: TextInputAction.next,
                        validator: (texto) => (texto == null || texto.isEmpty)
                            ? 'Informe o ID da conta.'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CampoComRotulo(
                      rotulo: 'Senha:',
                      campo: TextFormField(
                        controller: _campoSenha,
                        obscureText: true,
                        onFieldSubmitted: (_) => _entrar(),
                        validator: (texto) => (texto == null || texto.isEmpty)
                            ? 'Informe a senha.'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _carregando ? null : _entrar,
                      child: _carregando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : const Text('Entrar'),
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 20),
                      MensagemErro(_erro!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
