# ICEIBank

## Contexto

O ICEIBank é um sistema bancário distribuído, composto por três agências que
funcionam como serviços independentes. Cada agência é responsável por um
conjunto de contas e disponibiliza operações como criação de conta, consulta
de saldo, depósitos, saques e transferências.

As transferências entre agências são feitas por mensageria: a agência de origem
publica o crédito no RabbitMQ e a agência de destino o consome quando estiver
disponível. As requisições dos clientes são autenticadas por JWT. Cada agência
mantém um relógio vetorial, e os eventos são armazenados em arquivos JSONL,
permitindo analisar a ordem e a causalidade das operações.

As agências elegem uma líder entre si com o algoritmo de Bully: a agência de
maior ID entre as ativas vence. Um heartbeat periódico detecta a queda da líder
e dispara uma nova eleição automaticamente. Por enquanto, a líder é apenas
informativa.

O sistema tem dois clientes: o frontend web e um app mobile em Flutter. O app
mostra a líder atual em tempo real e funciona em modo offline-first: guarda o
último saldo conhecido, enfileira operações feitas sem conexão e as sincroniza
quando a conexão volta. Na sincronização, a agência usa o relógio vetorial para
detectar se a conta mudou enquanto o app estava offline.

A pasta `agencia-java` contém o backend do projeto. A pasta `agencia` contém o
código de referência em Node.js usado durante o desenvolvimento.

Vídeo: https://www.youtube.com/watch?v=6BMDYmC4tvo

## Como rodar o sistema (Java)

### Pré-requisitos

- Java 21
- Maven (ou o `mvnw` que já vem na pasta `agencia-java`)
- Uma instância do RabbitMQ no CloudAMQP (plano gratuito Little Lemur) e a sua **AMQP URL**, no formato `amqps://usuario:senha@host.cloudamqp.com/vhost`

> A AMQP URL contém usuário e senha. Ela é lida de uma variável de ambiente.

### 1. Subir as 3 agências

Abra **3 terminais**, um por agência. Em cada um, rode os comandos abaixo, trocando apenas o `AGENCIA_ID` (`0`, `1` e `2`):

```powershell
cd agencia-java
$env:RABBITMQ_URL = 'amqps://usuario:senha@host.cloudamqp.com/vhost'
$env:AGENCIA_ID = '0'
mvn spring-boot:run
```

No Git Bash, seria:

```bash
cd agencia-java
export RABBITMQ_URL='amqps://usuario:senha@host.cloudamqp.com/vhost'
export AGENCIA_ID=0
mvn spring-boot:run
```

As variáveis valem apenas para o terminal onde foram definidas. A porta de cada agência é `4000 + OFFSET + AGENCIA_ID`, com `OFFSET` igual a 22:

| Agência | Porta |
| ------- | ----- |
| 0       | 4022  |
| 1       | 4023  |
| 2       | 4024  |

Na primeira subida, cada agência cria no RabbitMQ a exchange `iceibank.eventos` (topic) e as suas filas: `fila-agencia-<id>` (créditos entre agências) e `fila-alertas-agencia-<id>` (alertas de saldo baixo).

## Como rodar o app mobile (Flutter)

O app fica na pasta `app_mobile` e consome a mesma API das agências Java. Ele não substitui o frontend web: é um cliente a mais.

### Pré-requisitos

- Flutter SDK instalado (`flutter doctor` sem erros críticos)
- Um emulador Android configurado
- As agências Java no ar, conforme a seção anterior

### 1. Abrir o emulador

Liste os emuladores disponíveis e abra um deles:

```bash
flutter emulators
flutter emulators --launch <id-do-emulador>
```

Espere a tela inicial do Android aparecer antes do próximo passo.

### 2. Rodar o app

```bash
cd app_mobile
flutter pub get
flutter run
```

A primeira execução demora alguns minutos, porque o Flutter prepara as ferramentas do Android.

### 3. Criar uma conta e fazer login

O app não tem tela de criação de conta. Crie a conta pelo frontend web (`frontend/criar-conta/criar-conta.html`) ou pelo terminal, na agência responsável por ela:

```bash
curl -X POST http://localhost:4023/contas -H "Content-Type: application/json" -d '{"id":1,"nomeAluno":"Aluno","saldo":100,"senha":"123"}'
```

A agência responsável é definida pelo resto da divisão do ID da conta por 3: resto 0 é a agência 0 (porta 4022), resto 1 é a agência 1 (porta 4023) e resto 2 é a agência 2 (porta 4024).

No app, informe o ID da conta e a senha. O app descobre a agência sozinho, pelo ID da conta. As contas ficam em memória nas agências, então precisam ser criadas de novo quando uma agência é reiniciada.

### Endereço das agências

Dentro do emulador, `localhost` aponta para o próprio emulador, e não para o computador. Por isso, o app usa o endereço `10.0.2.2`, que o emulador Android reserva para chegar ao computador. O endereço e o `OFFSET` das portas ficam em `app_mobile/lib/config/config.dart`.

### O que testar no app

- **Painel de liderança:** com as 3 agências no ar, o cartão "Líder atual" mostra a agência 2. Ao derrubar a agência líder, o painel muda sozinho para a nova líder em alguns segundos. O botão "Ver histórico de líderes" abre a lista das trocas observadas pelo app.
- **Modo offline:** com o app logado, ligue o modo avião do emulador e faça um depósito. A operação entra no cartão "Operações pendentes" e o saldo aparece como provisório. Ao desligar o modo avião, o app sincroniza a operação sozinho.
- **Conflito de sincronização:** faça uma operação com o app em modo avião e, antes de reconectar, altere o saldo da mesma conta pelo frontend web. Ao reconectar, o app avisa que a operação não foi aplicada, mostra o saldo real e oferece as opções "Tentar novamente" e "Descartar".



