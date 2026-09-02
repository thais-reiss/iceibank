# Respostas

## Parte B - Relógio de Lamport e registro de eventos

**1. Por que o relógio de Lamport usa max(contador_local, timestampRecebido) + 1 ao receber uma mensagem, em vez de simplesmente adotar o timestamp recebido diretamente?**

Porque pode ter a possibilidade do timestamp recebido por um processo ser menor que seu contador local. Por exemplo, se a Agência 0 estiver no contador 8 e receber uma mensagem com timestamp 2, e adotasse esse valor, o contador dela regridiria de 8 para 2. Isso acabaria com a ordem de tudo que já tinha acontecido localmente até ali, pois os próximos eventos dessa agência ficariam com timestamps menores que eventos anteriores dela mesma. Por outro lado, se o timestamp recebido fosse maior que o local, ele não poderia ser adotado, pois o evento de recebimento precisa ter um timestamp maior que o do envio, já que receber a mensagem acontece depois de enviá-la. Assim, para garantir a causalidade o processo soma 1 ao timestamp de maior valor.

**2. Se a Agência 0 está no evento de contador 10 e recebe uma mensagem com timestamp 3 (de uma agência mais “atrasada”), qual o novo valor do contador da Agência 0? O que isso implica sobre agências que processam muitos eventos rapidamente versus agências mais lentas?**

O novo valor será 11, pois é somado 1 ao maior valor de timestamp, de acordo com max(contador_local, timestampRecebido) + 1. Isso implica que as agências mais rápidas e, consequententemente, com contadores mais altos arrastam as agências mais lentas para o futuro. O timestamp 3 da agência lenta não afeta a agência rápida, pois ela ignora o 3 e segue do 10 para o 11. Porém, se a agência rápida mandar uma mensagem com timestamp 11 para a agência lenta, a agência lenta será forçada a pular de 3 direto para 12. Isso mantém o sistema inteiro avançando no ritmo do processo mais rápido, garantindo que a causalidade não seja perdida.