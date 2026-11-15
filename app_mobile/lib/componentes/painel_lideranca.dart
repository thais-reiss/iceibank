import 'package:flutter/material.dart';

import '../services/lideranca.dart';
import '../telas/tela_lideranca.dart';
import '../tema/tema.dart';
import 'componentes.dart';

class PainelLideranca extends StatefulWidget {
  const PainelLideranca({super.key});

  @override
  State<PainelLideranca> createState() => _PainelLiderancaState();
}

class _PainelLiderancaState extends State<PainelLideranca>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    lideranca.iniciar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    lideranca.parar();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estadoDoApp) {
    if (estadoDoApp == AppLifecycleState.resumed) {
      lideranca.iniciar();
    } else if (estadoDoApp == AppLifecycleState.paused) {
      lideranca.parar();
    }
  }

  void _abrirHistorico() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TelaLideranca()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResumoLideranca(),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _abrirHistorico,
              style: TextButton.styleFrom(
                foregroundColor: corPrincipal,
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.history),
              label: const Text(
                'Ver histórico de líderes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResumoLideranca extends StatelessWidget {
  const ResumoLideranca({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: lideranca,
      builder: (context, _) {
        final estado = lideranca.estado;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Rotulo('Consenso'),
            const SizedBox(height: 2),
            const Text(
              'Líder atual',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            if (estado == null)
              const Text(
                'Consultando as agências...',
                style: TextStyle(color: corTextoSuave),
              )
            else if (estado.nenhumaRespondeu) ...[
              const MensagemErro('Nenhuma das 3 agências respondeu.'),
              const SizedBox(height: 10),
              Text(
                'Última tentativa às ${formatarHora(estado.atualizadoEm)}',
                style: const TextStyle(color: corTextoSuave, fontSize: 13),
              ),
            ] else ...[
              Row(
                children: [
                  Icon(
                    estado.lider == null
                        ? Icons.how_to_vote_outlined
                        : Icons.verified_outlined,
                    color: corPrincipal,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      estado.lider == null
                          ? 'Eleição em andamento'
                          : 'Agência ${estado.lider}',
                      style: const TextStyle(
                        color: corPrincipal,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Segundo a Agência ${estado.agenciaConsultada} · '
                'atualizado às ${formatarHora(estado.atualizadoEm)}',
                style: const TextStyle(color: corTextoSuave, fontSize: 13),
              ),
            ],
          ],
        );
      },
    );
  }
}
