# Respostas - Sprint 1

## Parte B - Relógio de Lamport e registro de eventos

**1. Por que o relógio de Lamport usa max(contador_local, timestampRecebido) + 1 ao receber uma mensagem, em vez de simplesmente adotar o timestamp recebido diretamente?**

Porque pode ter a possibilidade do timestamp recebido por um processo ser menor que seu contador local. Por exemplo, se a Agência 0 estiver no contador 8 e receber uma mensagem com timestamp 2, e adotasse esse valor, o contador dela regridiria de 8 para 2. Isso acabaria com a ordem de tudo que já tinha acontecido localmente até ali, pois os próximos eventos dessa agência ficariam com timestamps menores que eventos anteriores dela mesma. Por outro lado, se o timestamp recebido fosse maior que o local, ele não poderia ser adotado, pois o evento de recebimento precisa ter um timestamp maior que o do envio, já que receber a mensagem acontece depois de enviá-la. Assim, para garantir a causalidade o processo soma 1 ao timestamp de maior valor.

**2. Se a Agência 0 está no evento de contador 10 e recebe uma mensagem com timestamp 3 (de uma agência mais “atrasada”), qual o novo valor do contador da Agência 0? O que isso implica sobre agências que processam muitos eventos rapidamente versus agências mais lentas?**

O novo valor será 11, pois é somado 1 ao maior valor de timestamp, de acordo com max(contador_local, timestampRecebido) + 1. Isso implica que as agências mais rápidas e, consequententemente, com contadores mais altos arrastam as agências mais lentas para o futuro. O timestamp 3 da agência lenta não afeta a agência rápida, pois ela ignora o 3 e segue do 10 para o 11. Porém, se a agência rápida mandar uma mensagem com timestamp 11 para a agência lenta, a agência lenta será forçada a pular de 3 direto para 12. Isso mantém o sistema inteiro avançando no ritmo do processo mais rápido, garantindo que a causalidade não seja perdida.

## Parte D: Transferências (local, entre agências, e a limitação conhecida)

**1. No trecho agenciaDestino === idAgencia, por que a transferência local não precisa da lógica de aoEnviar()/aoReceber() do relógio de Lamport, enquanto a transferência entre agências precisa?**

As regras aoEnviar() e aoReceber() do relógio de Lamport são utilizadas quando uma mensagem é enviada de um processo para outro, pois, nesse caso, cada processo possui seu próprio relógio lógico e é necessário manter a ordem causal entre os eventos dos dois processos. Na transferência local, tanto o débito quanto o crédito acontecem dentro do mesmo processo, utilizando o mesmo relógio e sendo executados sequencialmente. Assim, não existe uma comunicação entre processos diferentes que precise da atualização do relógio por meio das regras de envio e recebimento. Por isso, nesse caso, os dois eventos são registrados apenas com eventoLocal(), mantendo a ordem natural de execução, onde primeiro ocorre o débito e depois o crédito.

**2. Reproduza a falha conhecida (tarefa 5) e observe o saldo da conta de origem depois do erro. Ele foi revertido? O que isso significa em termos de consistência do sistema bancário?**

Ele não foi revertido, realizei uma transferência no valor de 100, em uma conta que inicialmente tinha 800. Depois da transferência ter falhado, a conta tinha o saldo de 700, não retornando ao valor inicial de 800. Isso significa que o sistema não está garantindo consistência e atomicidade na transferência entre agências. Uma operação desse tipo deveria ser atômica, ou seja, todas as etapas da transferência deveriam ser concluídas com sucesso ou, caso alguma falhe, todas as alterações realizadas deveriam ser desfeitas, sem um meio-termo.

**3. Pensando à frente para o Sprint 4: cite, em alto nível, duas formas possíveis de corrigir esse problema (não precisa implementar agora, só descrever a ideia).**

Duas formas possíveis seria usando os padrões 2PC, Two-Phase Commit, ou Saga. No 2PC, em vez de a agência de origem já aplicar o débito de forma definitiva antes de saber se o destino vai conseguir creditar, o processo seria dividido em duas fases e coordenado por um coordenador. Na primeira, as agências votariam VOTE-COMMIT se estiverem prontas ou VOTE-ABORT se não puderem realizar a operação. Na segunda, se todas votarem COMMIT, o coordenador confirma a operação nas duas agências. Se alguma votar ABORT, a transferência inteira é cancelada. Assim, ou todas as operações são efetivadas ou nenhuma é, garantindo atomicidade. Já no Saga, a transferência também é dividida em etapas, mas, em vez de manter uma transação única, cada etapa possui uma operação de compensação, e não há necessidade de esperar por uma confirmação global. Por exemplo, se o débito na origem for realizado, mas o crédito no destino falhar, uma operação de compensação faria o estorno do valor debitado. Dessa forma, caso alguma etapa falhe, as operações anteriores são desfeitas para que o sistema volte a um estado consistente.

## Parte E - Linha do tempo unificada

### Seção 10.2 - tópico 3

**Para esse par de eventos empatados: eles são realmente causalmente relacionados (um influenciou o outro) ou são concorrentes (aconteceram de forma independente)? Compare também com o campo horaParede de cada um - a ordem por hora de parede bate com a ordem por Lamport?**

Encontrei vários eventos com o mesmo valor de timestampLamport, vindos de agências diferentes. Um par que encontrei foi o criar conta na agência 0 e o criar conta na agência 1. Também encontrei um trio, que foi um evento de depósito na agência 0, outro na agência 1 e outro na agência 2, todos com o mesmo lamport igual a 2. Entre si, esses eventos em agências diferentes ocorreram de forma independente, não tendo nenhuma relação causal. A ordem em que esses eventos específicos aparecem no terminal está batendo com a hora parede, os eventos que tem um valor de hora parede maior estão abaixo dos que tem um valor menor, mas o relógio de Lamport é igual para todos, dando a entender que aconteceram ao mesmo tempo. 

### Seção 10.3 - Perguntas

**1. O relógio de Lamport garante que, se A aconteceu antes de B causalmente, timestamp(A) < timestamp(B). Ele não garante a volta. O que isso significa na prática quando você vê dois eventos com timestamps diferentes na linha do tempo, mas sem saber se um realmente influenciou o outro?**

Significa que, se um evento causou outro, o evento causador terá um timestamp menor que o evento causado. Porém, não posso afirmar que um evento causou outro apenas porque seu timestamp é menor. No log que postei, acontecem os dois casos. Em um deles, existe causalidade real, que é a transferência entre uma conta da agência 0 e outra da agência 1. Nesse caso, o débito na agência 0 causou o crédito remoto na agência 1, e o timestamp do débito é menor que o timestamp do crédito. Já no outro caso, não existe causalidade entre os eventos. Por exemplo, a criação de uma conta na agência 2 possui um timestamp menor que o depósito realizado na agência 0, mas isso não significa que a criação da conta causou o depósito. Os dois eventos apenas possuem uma ordem determinada pelos timestamps, sem que exista necessariamente uma relação causal entre eles.

**2.Baseado no que você observou no passo 3 da tarefa: o relógio de Lamport, sozinho, seria suficiente para um sistema que precisa distinguir com certeza “A e B são concorrentes” de “A aconteceu antes de B”? Por que isso motiva o relógio vetorial do Sprint 2?**

Ele não seria suficiente, porque só pelos timestamps não dá pra afirmar que um evento causou outro. Porque o relógio vetorial consegue, sozinho, demonstrar se um evento causou outro ou se eles são concorrentes. O que permite isso é que, nesse padrão, cada processo guarda um vetor com um contador para cada processo do sistema. Assim, o vetor registra o que aquele processo já realizou ou recebeu de cada outro processo. Ao comparar os vetores de dois eventos, é possível determinar se existe uma relação de causalidade ou se os eventos são concorrentes. 

## Parte F - Autenticação (JWT)

### Seção 11.1 

- **Um endpoint de login (ex.: POST /auth/login) que recebe credenciais e, se válidas, retorna um token JWT. O formato das credenciais (usuário e senha, id de conta e senha, ou outro modelo) é decisão sua - documente e justifique a escolha em RESPOSTAS.md.**

Eu escolhi usar o formato id da conta e senha porque usar o id da conta como identificador principal permite encontrar os dados de forma direta e rápida na memória, usando estado.getContas().get(id) no AuthController. Isso evita passos extras, como ter que buscar um usuário pelo e-mail ou nome para só depois achar a sua conta. Assim, o código do sistema fica mais simples e o token gerado já fica ligado direto à conta que fará as transações financeiras.

- **Pense e decida: essa chamada interna, agência-a-agência, deveria carregar um token igual às chamadas vindas do frontend, ou é aceitável tratá-la de forma diferente? Justifique sua decisão em RESPOSTAS.md.**

Não é necessário utilizar o mesmo token das chamadas vindas do frontend, pois o token enviado pelo frontend é um JWT usado para autenticar o usuário, identificando qual conta está realizando a operação. Já a comunicação entre agências ocorre entre serviços do sistema, e não diretamente entre um usuário e a aplicação. Por isso, é aceitável tratar essa comunicação de forma diferente, porém ela não deve ficar sem autenticação, pois isso permitiria que requisições externas tentassem se passar por outra agência. Assim,para proteger essa comunicação, eu implementei um token interno compartilhado entre as agências, enviado no cabeçalho das requisições agência-a-agência. Isso mantém a comunicação interna protegida sem misturar a autenticação do usuário com a autenticação entre serviços.

### Seção 11.2 - Perguntas

**1. Qual a diferença entre autenticação e autorização? Sua implementação verifica só uma das duas, ou as duas? Por exemplo: um usuário autenticado consegue sacar de uma conta que não é dele, na sua implementação atual?**

Autenticação é o processo de verificar a identidade do usuário, por exemplo, validando se o token JWT é válido. Autorização é verificar se esse usuário autenticado possui permissão para realizar determinada ação ou acessar determinado recurso. Na minha implementação são verificadas as duas. O sistema primeiro autentica o usuário por meio do token e em cada método do controller de contas é verificado se ele é o dono da conta que ele quer acessar. Assim, um usuário autenticado não consegue sacar, depositar ou consultar o saldo de uma conta que não pertence a ele, pois a implementação verifica se a conta está associada ao usuário autenticado.

**2. Por que o servidor não precisa consultar um banco de dados para validar a assinatura de um JWT a cada requisição? O que isso implica sobre escalabilidade, comparado a guardar sessões em memória no servidor?**

Porque o token possui as informações do usuário e uma assinatura que pode ser validada usando a chave secreta. No meu código, isso acontece na classe JwtUtil, no método validarTokenEExtrairId(), que verifica a assinatura do token e extrai o ID da conta. Na classe JwtFilter, o token é recebido e essa validação é feita antes de liberar a requisição. Isso facilita a escalabilidade, porque o servidor não precisa gastar memória guardando a sessão de cada pessoa que está logada, ficando mais leve e rápido. Além disso, se for preciso colocar novos servidores no ar para aguentar muitos acessos, qualquer um deles consegue validar o token na mesma hora só usando a chave secreta, sem precisar ficar sincronizando dados ou dependendo de um banco central.

**3. O que aconteceria com a segurança do sistema se a chave secreta usada para assinar o JWT vazasse?**

Se a chave secreta usada para assinar o JWT vazasse, a segurança do sistema seria comprometida. Uma pessoa que tivesse essa chave poderia criar novos tokens com assinaturas válidas e se passar por outras contas, alterando o ID da conta no token. Se isso acontecesse, seria necessário trocar a chave secreta e invalidar os tokens antigos para recuperar a segurança do sistema.

## Parte G - FrontEnd

**1. Como o frontend “lembra” de reenviar o token em cada requisição depois do login? Descreva, em alto nível, o mecanismo que você implementou.**

Ao realizar o login, o token retornado é armazenado no LocalStorage. Na tela de painel, o JavaScript pega o token da LocalStorage e armazena ele em uma variável, passando ele em cada requisição que exige o token. 

**2. Se o token expirar enquanto alguém está usando o frontend no meio de uma operação, o que acontece na sua implementação? A interface avisa a pessoa usuária, ou ela só vê um erro genérico?**

A interface avisa o usuário por meio de um alert e rediciona ele para a tela de login, para que ele faça o login novamente.

**3.Esta unidade da disciplina trata de arquitetura MVC. No seu frontend, onde fica o “M” (Model), o “V” (View) e o “C” (Controller)? Eles existem de forma clara na sua implementação, ou o código ficou mais misturado do que o padrão sugere?**

O View está principalmente nos arquivos HTML, pois eles são responsáveis pela interface que o usuário visualiza. O Controller está nos arquivos JavaScript, que recebem as ações do usuário, fazem as requisições para a API e controlam o que acontece depois das respostas. Já o Model não existe de forma tão clara no frontend. Os objetos JavaScript criados para enviar e receber dados, como o objeto corpo no cadastro e os objetos de conta retornados pela API, representam os dados do sistema, mas não existe uma classe ou arquivo específico responsável pelo Model. O modelo de fato está mais presente no backend, por meio da classe de modelo, que é ContaModel. Portanto, meu código segue parcialmente a ideia do MVC, onde o HTML representa a View, os arquivos JavaScript funcionam como Controllers e os dados recebidos e enviados pela API representam parcialmente o Model.

## Funcionalidade adicional 

Não é permitido saque superior a 2000 por operação.

## Link do vídeo: https://www.youtube.com/watch?v=6BMDYmC4tvo

---

# Respostas - Sprint 2

## Parte B

**1. Com 3 agências, o vetor tem 3 posições. Se o sistema crescesse para 10 agências, o que aconteceria com o tamanho de cada vetor anexado a cada mensagem? Isso é um problema? Por quê (ou por que não)?**

O vetor cresceria proporcionalmente o número de agências, passando a ter 10 posições. Isso é um problema, pois prejudicaria a escalabilidade do sistema. Com muitas agências, a maior parte das posições seria zero e irrelevante para a mensagem em questão, consumindo banda e espaço desnecessários. Além disso, o relógio vetorial exige saber de antemão quantos processos existem, de forma que se uma agência nova entrasse depois, todas as outras precisariam redimensionar seus vetores.

**2. Dado V1 = [3, 1, 0] e V2 = [3, 2, 0]: qual evento aconteceu primeiro, ou eles são concorrentes? Justifique comparando posição a posição.**

V1 aconteceu primeiro, porque todas as suas posições são menores ou iguais às de V2, com pelo menos uma estritamente menor, no caso a segunda posição.

**3. Dado V1 = [3, 1, 0] e V2 = [1, 3, 0]: qual evento aconteceu primeiro, ou eles são concorrentes? Justifique.**

São concorrentes, porque V1 é maior na primeira posição, V2 é maior na segunda, e na terceira são iguais. Como nenhum vetor domina o outro em todas as posições, não há relação de causa e efeito entre eles.

---

## Parte C

**1. No passo 4 da tarefa, o que aconteceu exatamente quando a Agência 1 voltou? Se a mensagem "sumiu" (não foi aplicada), isso foi porque a mensageria falhou, ou por outro motivo? Explique com base no que você observou no log.**

Eu derrubei a Agência 0 e enviei uma transferência com ela fora do ar. Quando ela voltou, o log mostrou CREDITO_REMOTO_FALHOU, com o motivo "conta nao encontrada". A mensagem não sumiu por causa da mensageria, ela foi entregue corretamente assim que a agência voltou ao ar, o que prova que o RabbitMQ reteve a mensagem na fila durante toda a queda. A falha foi devido as contas da agência serem guardadas em memória (new Map()), e esse mapa é recriado do zero toda vez que o processo reinicia, sem nenhum mecanismo que reconstrua as contas a partir do log de eventos. Então a mensagem chegou certa, mas não havia mais conta nenhuma para aplicar o crédito.

**2. Compare esse comportamento com o do Sprint 1 (chamada REST direta): o que melhorou com a mensageria, e o que continua sendo um problema em aberto (dica: pense na diferença entre "a mensagem não se perde" e "o sistema está correto")?**

O que melhorou em relação a Sprint 1 foi que lá, se a agência de destino estivesse fora do ar no instante exato da chamada HTTP, a chamada falhava na hora e a mensagem desaparecia de vez, sem nenhum registro do que deveria ter acontecido. Com o RabbitMQ isso não acontece mais, porque a mensagem fica na fila até alguém vir buscar, pois a entrega não depende mais do destino estar disponível no momento exato do envio. O que continua em aberto é que, apesar da mensagem ter chegado, o crédito não foi aplicado, e o valor debitado da origem ficou sem destino, a mesma inconsistência da Sprint 1. A diferença é que agora existe um registro em log do que aconteceu, mas não existe nenhum mecanismo que desfaça o débito na origem ou tente a entrega de novo. 

**3. O consumidor de mensagens (assinar) processa créditos sem passar por nenhuma verificação de token JWT. Isso é um problema de segurança? Por que sim, ou por que não - pense em quem consegue publicar uma mensagem na exchange do RabbitMQ hoje, no seu ambiente de desenvolvimento.**

Sim, é um problema de segurança, porque o consumidor da fila processa qualquer mensagem que chegue, sem checar quem a publicou. Isso significa que qualquer um com a URL AMQP da minha instância CloudAMQP conseguiria se conectar direto ao RabbitMQ e publicar uma mensagem com a routing key agencia.X.creditar, inventando valor e conta, sem nunca ter feito login em nenhuma agência.

---

## Parte D

**1. No Sprint 1, o relógio de Lamport não permitia essa análise (dois timestamps diferentes não davam certeza sobre concorrência). O que exatamente, no relógio vetorial, torna possível essa comparação confiável?**

O fato de que ele guarda um timestamp por processo, em vez de um único número. Isso possibilita comparar vetor por vetor, posição por posição. Se um vetor domina o outro em todas as posições, existe uma cadeia de causa e efeito entre os eventos, porque, pela regra do aoReceber, quem recebeu uma mensagem absorve o conhecimento que o remetente tinha sobre todas as agências até aquele momento. Se nenhum vetor domina o outro, isso prova que nenhum dos dois eventos sabia da existência do outro, indicando uma ausência de relação causal que o Lamport não conseguia garantir, porque com um número só, dois timestamps diferentes não garantiam relação de causa e efeito.

**2. Encontre, no seu próprio teste, um par de eventos que o script classificou como concorrente. Faz sentido, olhando para o que cada evento representa? Explique por que eles realmente não têm relação de causa e efeito entre si.**

No meu teste, um par classificado como concorrente foi a criação da conta na Agência 0 (vetor [1,0,0]) e a criação da conta na Agência 1 (vetor [0,1,0]). Isso faz sentido, porque comparando posição por posição, a Agência 0 tem valor maior na primeira posição (1 contra 0), e a Agência 1 tem valor maior na segunda (1 contra 0). Assim, nenhum vetor domina o outro em todas as posições, então, pela regra de comparação, são concorrentes. Isso reflete exatamente o que aconteceu na prática, pois as duas contas foram criadas de forma totalmente independente, sem nenhuma mensagem trocada entre as agências até aquele momento.

**3. O algoritmo de comparação de vetores neste script é O(n²) no número de eventos (compara todos os pares). Isso seria um problema em um sistema real com milhões de eventos? O que se poderia fazer para tornar essa análise mais escalável?**

Sim, seria um problema, pois O(n²) significa que, quando o número de eventos dobra, o número de comparações aumenta quatro vezes. Para tornar o sistema escalável, uma opção seria limitar as comparações a uma janela de tempo relevante, comparando cada evento apenas com eventos recentes. Assim, eventos muito antigos não precisariam ser comparados novamente, reduzindo bastante o número de comparações. Outra opção seria fazer o processamento de forma incremental, armazenando os resultados das comparações que já foram realizadas. Dessa forma, quando novos eventos chegassem, o sistema compararia apenas esses novos eventos com os eventos antigos necessários, sem precisar analisar todo o histórico novamente.

## Funcionalidade Adicional

**Notificação de saldo baixo.** Quando uma operação deixa o saldo de uma conta abaixo de R$ 50,00, o sistema avisa o cliente no painel e publica um alerta no RabbitMQ.

**Como funciona:**

1. As operações que reduzem o saldo (saque e transferência) verificam o saldo da conta depois de aplicadas. A regra e o limite de R$ 50,00 ficam em um único lugar, na classe `AlertaSaldoBaixo`.
2. Se o saldo ficou abaixo do limite, a agência publica uma mensagem na exchange `iceibank.eventos` com a routing key `alertas.saldo-baixo`. A mensagem leva o id da conta, o saldo atual e o vetor do relógio vetorial (gerado com `aoEnviar`).
3. Cada agência tem a sua própria fila de alertas (`fila-alertas-agencia-<id>`), ligada a essa mesma routing key. Por isso, uma única publicação é entregue às três agências (Publish/Subscribe, um para muitos). Preferi fazer dessa forma porque, se o alerta fosse somente para a agência dona da conta, ela estaria enviando a mensagem para si mesma e não haveria necessidade de usar o RabbitMQ, bastaria registrar em log. Uma limitação dessa escolha é que, no estado atual do sistema, as outras duas agências apenas registram o alerta no log. Porém, essa escolha permite acrescentar um novo assinante sem alterar o código de quem publica.
4. O consumidor `ConsumidorAlertas` de cada agência executa o `aoReceber` do relógio vetorial e registra no log um evento `ALERTA_SALDO_BAIXO`. Após fechar o alerta, o saldo é atualizado na tela.
5. As respostas de depósito, saque e transferência passaram a trazer o campo `saldoBaixo` (`true` ou `false`). O front lê esse campo e, quando é `true`, mostra um `alert` com a mensagem "Atenção: seu saldo está baixo." depois do alerta de sucesso da operação. O depósito apenas informa o campo, sem publicar alerta, porque só aumenta o saldo.
