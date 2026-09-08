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

## Como rodar o sistema

### Agências Java

Abra três terminais do PowerShell. Em cada terminal, navegue até a pasta
`caminho\até\agencia-java` e execute os comandos correspondentes.

**Terminal 1 - Agência 0 - porta: 4022**

```powershell
cd caminho\até\agencia-java
$env:AGENCIA_ID=0
$env:OFFSET=22
mvn spring-boot:run
```

**Terminal 2 - Agência 1 - porta: 4023**

```powershell
cd caminho\até\agencia-java
$env:AGENCIA_ID=1
$env:OFFSET=22
mvn spring-boot:run
```

**Terminal 3 - Agência 2 - porta: 4024**

```powershell
cd caminho\até\agencia-java
$env:AGENCIA_ID=2
$env:OFFSET=22
mvn spring-boot:run
```

Com isso, as instâncias do backend das agências estarão rodando e será 
possível fazer requisições para o sistema.

