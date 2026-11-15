const int offset = 22;
const int portaBase = 4000 + offset;
const int numeroAgencias = 3;

const String host = '10.0.2.2';

String urlDaAgencia(int idAgencia) {
  return 'http://$host:${portaBase + idAgencia}';
}

int agenciaResponsavel(int idConta) {
  return idConta % numeroAgencias;
}
