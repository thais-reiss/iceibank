import 'package:flutter/material.dart';

import '../modelos/operacao_pendente.dart';
import '../services/conta_offline.dart';
import '../tema/tema.dart';
import 'componentes.dart';

String descreverOperacao(OperacaoPendente operacao) {
  final valor = formatarReais(operacao.valor);
  switch (operacao.tipo) {
    case OperacaoPendente.deposito:
      return 'Depósito de $valor';
    case OperacaoPendente.saque:
      return 'Saque de $valor';
    default:
      return 'Transferência de $valor para a conta ${operacao.idDestino}';
  }
}

class CartaoPendentes extends StatelessWidget {
  const CartaoPendentes({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: servicoConta,
      builder: (context, _) => _conteudo(),
    );
  }

  Widget _conteudo() {
    final operacoes = servicoConta.operacoes;

    return Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Rotulo('Offline-first'),
          const SizedBox(height: 2),
          const Text(
            'Operações pendentes',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            servicoConta.sincronizando
                ? 'Sincronizando com a agência...'
                : 'Operações feitas sem conexão, ainda não confirmadas '
                    'pela agência.',
            style: const TextStyle(color: corTextoSuave, fontSize: 13),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < operacoes.length; i++) ...[
            if (i > 0) const Divider(height: 28),
            _LinhaDaOperacao(operacoes[i]),
          ],
        ],
      ),
    );
  }
}

class _LinhaDaOperacao extends StatelessWidget {
  final OperacaoPendente operacao;

  const _LinhaDaOperacao(this.operacao);

  @override
  Widget build(BuildContext context) {
    final IconData icone;
    final Color cor;
    final String situacao;

    if (operacao.emConflito) {
      icone = Icons.warning_amber_rounded;
      cor = corErroBorda;
      situacao = 'Conflito: não aplicada automaticamente';
    } else if (operacao.foiRecusada) {
      icone = Icons.cancel_outlined;
      cor = corErroBorda;
      situacao = 'Recusada pela agência';
    } else {
      icone = Icons.schedule;
      cor = corPrincipal;
      situacao = 'Pendente de sincronização';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: cor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descreverOperacao(operacao),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$situacao · feita às ${formatarHora(operacao.criadaEm)}',
                    style: TextStyle(
                      color: operacao.estaPendente ? corTextoSuave : cor,
                      fontSize: 13,
                    ),
                  ),
                  if (operacao.mensagem != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      operacao.mensagem!,
                      style: const TextStyle(
                        color: corTextoSuave,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (!operacao.estaPendente) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (operacao.emConflito) ...[
                Expanded(
                  child: FilledButton(
                    onPressed: () => servicoConta.tentarNovamente(operacao),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Tentar novamente'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () => servicoConta.descartar(operacao),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Descartar'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
