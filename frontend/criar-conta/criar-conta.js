document.getElementById('formAluno').addEventListener('submit', async function (evento) {
    evento.preventDefault();

    const nome = document.getElementById('nome').value;
    const senha = document.getElementById('senha').value;
    const idConta = document.getElementById('idConta').value;
    const saldo = document.getElementById('saldo').value;
    const agencia = document.getElementById('agencia').value;

    const mensagemErro = document.getElementById('mensagemErro');
    mensagemErro.textContent = '';

    const corpo = {
        id: Number(idConta),
        nomeAluno: nome,
        saldo: Number(saldo),
        senha: senha
    };

    try {
        const resposta = await fetch(`http://localhost:${agencia}/contas`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(corpo)
        });

        if (resposta.ok) {
            window.location.href = '../login/login.html';
        } else {
            const erro = await resposta.json();
            mensagemErro.textContent = erro.erro;
        }
    } catch (erro) {
        mensagemErro.textContent = 'Não foi possível conectar à agência selecionada.';
    }
});