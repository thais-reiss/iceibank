import * as config from '../config.js';
import compararVetores from '../services/compararVetores.js';

function criarConta(req, res) {
  const { id, nomeAluno, saldoInicial } = req.body;
  const { contas, relogio, registro, idAgencia } = req.app.locals;

  if (config.agenciaResponsavel(id) !== idAgencia) {
    return res.status(400).json({ erro: `Conta ${id} não pertence a esta agência.` });
  }
  if (contas.has(id)) {
    return res.status(409).json({ erro: 'Conta já existe.' });
  }

  const ts = relogio.eventoLocal();
  contas.set(id, { id, nomeAluno, saldo: saldoInicial || 0 });
  registro.registrar('CRIAR_CONTA', ts, { id, nomeAluno, saldoInicial });

  res.status(201).json(contas.get(id));
}

function consultarSaldo(req, res) {
  const { contas, relogio } = req.app.locals;
  const id = parseInt(req.params.id, 10);
  const conta = contas.get(id);
  if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });
  res.json({ ...conta, vetorAtual: relogio.obterVetorAtual() });
}

function depositar(req, res) {
  const { contas, relogio, registro } = req.app.locals;
  const id = parseInt(req.params.id, 10);
  const { valor } = req.body;
  const conta = contas.get(id);
  if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });

  const ts = relogio.eventoLocal();
  conta.saldo += valor;
  registro.registrar('DEPOSITO', ts, { id, valor, novoSaldo: conta.saldo });

  res.json(conta);
}

function sacar(req, res) {
  const { contas, relogio, registro } = req.app.locals;
  const id = parseInt(req.params.id, 10);
  const { valor } = req.body;
  const conta = contas.get(id);
  if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });
  if (conta.saldo < valor) return res.status(400).json({ erro: 'Saldo insuficiente.' });

  const ts = relogio.eventoLocal();
  conta.saldo -= valor;
  registro.registrar('SAQUE', ts, { id, valor, novoSaldo: conta.saldo });

  res.json(conta);
}

function sincronizarOperacaoPendente(req, res) {
  const { contas, relogio, registro } = req.app.locals;
  const id = parseInt(req.params.id, 10);
  const { tipo, valor, vetorConhecido } = req.body;

  const conta = contas.get(id);
  if (!conta) return res.status(404).json({ erro: 'Conta não encontrada nesta agência.' });

  const vetorAtual = relogio.obterVetorAtual();
  const relacao = compararVetores(vetorConhecido, vetorAtual);

  if (relacao !== 'IGUAIS') {
    return res.status(409).json({
      erro: 'Conflito detectado: o estado da conta mudou desde a última sincronização do app.',
      vetorConhecido,
      vetorAtual,
      contaAtual: conta,
    });
  }

  let vetor;
  if (tipo === 'DEPOSITO') {
    vetor = relogio.eventoLocal();
    conta.saldo += valor;
  } else if (tipo === 'SAQUE') {
    if (conta.saldo < valor) return res.status(400).json({ erro: 'Saldo insuficiente.' });
    vetor = relogio.eventoLocal();
    conta.saldo -= valor;
  } else {
    return res.status(400).json({ erro: 'Tipo de operação pendente não suportado.' });
  }

  registro.registrar('SINCRONIZACAO_OFFLINE', vetor, { id, tipo, valor });
  res.json(conta);
}

export { criarConta, consultarSaldo, depositar, sacar, sincronizarOperacaoPendente };