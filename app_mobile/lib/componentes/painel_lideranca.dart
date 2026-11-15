import 'package:flutter/material.dart';

import '../services/lideranca.dart';
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

  String _hora(DateTime momento) {
    String doisDigitos(int n) => n.toString().padLeft(2, '0');
    return '${doisDigitos(momento.hour)}:${doisDigitos(momento.minute)}:'
        '${doisDigitos(momento.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return Cartao(
      child: ListenableBuilder(
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
                  'Última tentativa às ${_hora(estado.atualizadoEm)}',
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
                  'atualizado às ${_hora(estado.atualizadoEm)}',
                  style: const TextStyle(color: corTextoSuave, fontSize: 13),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
