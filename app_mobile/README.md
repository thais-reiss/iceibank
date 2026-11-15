# ICEIBank - app mobile

App Flutter do ICEIBank. Ele consome a mesma API REST das agências que o frontend web usa.

As instruções para rodar o app estão no [README principal](../README.md), na seção "Como rodar o app mobile (Flutter)".

## O que o app faz

- Login com JWT, consulta de saldo, depósito, saque e transferência.
- Painel de liderança: mostra a agência líder atual, consultando `GET /bully/lider` a cada 3 segundos, e se atualiza sozinho quando há uma nova eleição.
- Histórico de líderes: lista as trocas de liderança observadas pelo app.
- Modo offline-first: guarda o último saldo conhecido, enfileira operações feitas sem conexão e as sincroniza automaticamente ao reconectar.
- Tratamento de conflito: se a conta mudou enquanto o app estava offline, a operação não é aplicada sozinha. O app mostra o saldo real e deixa a pessoa escolher entre tentar novamente ou descartar.

## Organização do código

| Pasta em `lib/` | Conteúdo |
| --------------- | -------- |
| `config/`       | Endereços das agências |
| `services/`     | Comunicação com as agências, liderança, banco local e sincronização |
| `modelos/`      | Dados guardados no celular: conta em cache e operação pendente |
| `telas/`        | Login, painel principal e tela de liderança |
| `componentes/`  | Cartões e peças reaproveitadas nas telas |
| `tema/`         | Cores e estilos |

## Bibliotecas

- `http`: requisições para as agências.
- `sqflite`: banco de dados local, com o saldo em cache e a fila de operações pendentes.
- `connectivity_plus`: detecta quando a conexão volta, para sincronizar a fila.
