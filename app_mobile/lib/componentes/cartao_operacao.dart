import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api.dart';
import 'componentes.dart';

class CartaoOperacao extends StatefulWidget {
  final String numero;
  final String titulo;
  final bool pedirContaDestino;
  final Future<void> Function(double valor, int? idDestino) executar;

  const CartaoOperacao({
    super.key,
    required this.numero,
    required this.titulo,
    required this.executar,
    this.pedirContaDestino = false,
  });

  @override
  State<CartaoOperacao> createState() => _CartaoOperacaoState();
}

class _CartaoOperacaoState extends State<CartaoOperacao> {
  final _formulario = GlobalKey<FormState>();
  final _campoValor = TextEditingController();
  final _campoDestino = TextEditingController();

  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _campoValor.dispose();
    _campoDestino.dispose();
    super.dispose();
  }

  double? _lerValor(String texto) {
    return double.tryParse(texto.trim().replaceAll(',', '.'));
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await widget.executar(
        _lerValor(_campoValor.text)!,
        widget.pedirContaDestino ? int.parse(_campoDestino.text) : null,
      );
      _campoValor.clear();
      _campoDestino.clear();
    } on SessaoExpirada {
      return; 
    } on ErroApi catch (erro) {
      _erro = erro.mensagem;
    }

    if (!mounted) return;
    setState(() => _carregando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Cartao(
      child: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Rotulo(widget.numero),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Rotulo('Movimentação'),
                    const SizedBox(height: 2),
                    Text(
                      widget.titulo,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (widget.pedirContaDestino) ...[
              CampoComRotulo(
                rotulo: 'ID da conta de destino',
                campo: TextFormField(
                  controller: _campoDestino,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Digite o ID da conta',
                  ),
                  validator: (texto) => (texto == null || texto.isEmpty)
                      ? 'Informe a conta de destino.'
                      : null,
                ),
              ),
              const SizedBox(height: 16),
            ],
            CampoComRotulo(
              rotulo: 'Valor',
              campo: TextFormField(
                controller: _campoValor,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                ),
                validator: (texto) {
                  final valor = _lerValor(texto ?? '');
                  if (valor == null || valor <= 0) {
                    return 'Informe um valor maior que zero.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _carregando ? null : _enviar,
              child: _carregando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : Text(widget.titulo),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 16),
              MensagemErro(_erro!),
            ],
          ],
        ),
      ),
    );
  }
}
