import 'package:flutter/material.dart';

import '../componentes/componentes.dart';
import '../componentes/painel_lideranca.dart';
import '../services/lideranca.dart';
import '../tema/tema.dart';

class TelaLideranca extends StatelessWidget {
  const TelaLideranca({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Liderança',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: corFundo,
        foregroundColor: corTexto,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Cartao(child: ResumoLideranca()),
              const SizedBox(height: 20),
              Cartao(
                child: ListenableBuilder(
                  listenable: lideranca,
                  builder: (context, _) => _historico(lideranca.historico),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historico(List<TrocaLideranca> trocas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Rotulo('Histórico'),
        const SizedBox(height: 2),
        const Text(
          'Trocas de liderança',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Trocas observadas pelo app desde que foi aberto, '
          'da mais recente para a mais antiga.',
          style: TextStyle(color: corTextoSuave, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (trocas.isEmpty)
          const Text(
            'Nenhuma líder registrada ainda.',
            style: TextStyle(color: corTextoSuave),
          )
        else
          for (var i = 0; i < trocas.length; i++) ...[
            if (i > 0) const Divider(height: 24),
            _linhaDaTroca(trocas[i]),
          ],
      ],
    );
  }

  Widget _linhaDaTroca(TrocaLideranca troca) {
    final primeira = troca.liderAnterior == null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          primeira ? Icons.flag_outlined : Icons.swap_horiz,
          color: corPrincipal,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primeira
                    ? 'Agência ${troca.novaLider}'
                    : 'Agência ${troca.liderAnterior} → '
                        'Agência ${troca.novaLider}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                primeira
                    ? 'Líder na primeira consulta · '
                        '${formatarHora(troca.momento)}'
                    : 'Troca observada às ${formatarHora(troca.momento)}',
                style: const TextStyle(color: corTextoSuave, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
