let token;
let urlAgencia;
let idConta;

document.addEventListener('DOMContentLoaded', function () {
    token = localStorage.getItem('token');
    urlAgencia = localStorage.getItem('urlAgencia');
    idConta = localStorage.getItem('idConta');

    if (!token || !urlAgencia || !idConta) {
        window.location.href = '../login/login.html';
        return;
    }

    document.getElementById('idContaLogada').textContent = idConta;

    atualizarSaldo();
});

async function chamarApi(caminho, metodo, corpo) {
    const opcoes = {
        method: metodo,
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
        }
    };

    if (corpo) {
        opcoes.body = JSON.stringify(corpo);
    }

    const resposta = await fetch(`${urlAgencia}${caminho}`, opcoes);

    const dados = await resposta.json();

    if (resposta.status === 401) {
        alert('Sua sessão expirou. Você será redirecionado para a tela de login.');

        localStorage.removeItem('token');
        localStorage.removeItem('urlAgencia');
        localStorage.removeItem('idConta');

        window.location.href = '../login/login.html';

        throw new Error('Sessão expirada.');
    }

    if (!resposta.ok) {
        throw new Error(dados.erro || 'Erro desconhecido.');
    }

    return dados;
}

async function atualizarSaldo() {
    try {
        const conta = await chamarApi(`/contas/${idConta}`, 'GET');

        document.getElementById('saldoAtual').textContent =
            `R$ ${conta.saldo.toFixed(2).replace('.', ',')}`;

    } catch (erro) {
        if (erro.message !== 'Sessão expirada.') {
            alert(erro.message);
        }
    }
}

document.getElementById('btnAtualizarSaldo').addEventListener('click', async function () {
    await atualizarSaldo();
});

document.getElementById('formDeposito').addEventListener('submit', async function (evento) {
    evento.preventDefault();

    const valor = Number(
        document.getElementById('valorDeposito').value
    );

    try {
        await chamarApi(
            `/contas/${idConta}/depositar`,
            'POST',
            {
                valor: valor
            }
        );

        evento.target.reset();

        await atualizarSaldo();

        alert('Depósito concluído com sucesso.');

    } catch (erro) {
        if (erro.message !== 'Sessão expirada.') {
            alert(erro.message);
        }
    }
});

document.getElementById('formSaque').addEventListener('submit', async function (evento) {
    evento.preventDefault();

    const valor = Number(
        document.getElementById('valorSaque').value
    );

    try {
        await chamarApi(
            `/contas/${idConta}/sacar`,
            'POST',
            {
                valor: valor
            }
        );

        evento.target.reset();

        await atualizarSaldo();

        alert('Saque concluído com sucesso.');

    } catch (erro) {
        if (erro.message !== 'Sessão expirada.') {
            alert(erro.message);
        }
    }
});

document.getElementById('formTransferencia').addEventListener('submit', async function (evento) {
    evento.preventDefault();

    const idDestino = Number(
        document.getElementById('idContaDestino').value
    );

    const valor = Number(
        document.getElementById('valorTransferencia').value
    );

    try {
        await chamarApi(
            '/transferencias',
            'POST',
            {
                idOrigem: Number(idConta),
                idDestino: idDestino,
                valor: valor
            }
        );

        evento.target.reset();

        await atualizarSaldo();

        alert('Transferência concluída com sucesso.');

    } catch (erro) {
        if (erro.message !== 'Sessão expirada.') {
            alert(erro.message);
        }
    }
});

document.getElementById('btnSair').addEventListener('click', function () {
    localStorage.removeItem('token');
    localStorage.removeItem('urlAgencia');
    localStorage.removeItem('idConta');

    window.location.href = '../login/login.html';
});