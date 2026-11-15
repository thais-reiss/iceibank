import 'package:flutter/material.dart';

import '../tema/tema.dart';

class Rotulo extends StatelessWidget {
  final String texto;
  final Color cor;

  const Rotulo(this.texto, {super.key, this.cor = corPrincipal});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: TextStyle(
        color: cor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }
}

class Cartao extends StatelessWidget {
  final Widget child;

  const Cartao({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class MensagemErro extends StatelessWidget {
  final String texto;

  const MensagemErro(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: corErroFundo,
        border: Border(left: BorderSide(color: corErroBorda, width: 4)),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: corErroTexto,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class CampoComRotulo extends StatelessWidget {
  final String rotulo;
  final Widget campo;

  const CampoComRotulo({super.key, required this.rotulo, required this.campo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        campo,
      ],
    );
  }
}
