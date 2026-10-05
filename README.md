# ICEIBank

## Contexto

O ICEIBank é um sistema bancário distribuído, composto por três agências que
funcionam como serviços independentes. Cada agência é responsável por um
conjunto de contas e disponibiliza operações como criação de conta, consulta
de saldo, depósitos, saques e transferências.

As transferências entre agências são feitas por comunicação entre os serviços.
O sistema também utiliza autenticação por JWT para as requisições do frontend,
um token interno para a comunicação entre agências e relógios de Lamport para
registrar a ordem lógica dos eventos distribuídos. Os eventos são armazenados
em arquivos JSONL, permitindo analisar a ordem e a causalidade das operações.

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



