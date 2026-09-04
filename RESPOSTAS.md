# Respostas

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
