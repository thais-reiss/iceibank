document.getElementById('formAluno').addEventListener('submit', async function (evento) {
    evento.preventDefault();

    const idConta = document.getElementById('idConta').value;
    const senha = document.getElementById('senha').value;
    const agencia = document.getElementById('agencia').value;

    const mensagemErro = document.getElementById('mensagemErro');
    mensagemErro.textContent = '';

    const corpo = {
        id: Number(idConta),
        senha: senha
    };

    try {
        const resposta = await fetch(`http://localhost:${agencia}/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(corpo)
        });

        const dados = await resposta.json();

        if (resposta.ok) {
            localStorage.setItem('token', dados.token);
            localStorage.setItem('urlAgencia', `http://localhost:${agencia}`);
            localStorage.setItem('idConta', idConta);

            window.location.href = '../painel/painel.html';
        } else {
            mensagemErro.textContent = dados.erro;
        }
    } catch (erro) {
        mensagemErro.textContent = 'Não foi possível conectar à agência selecionada.';
    }
});