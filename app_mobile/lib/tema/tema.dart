import 'package:flutter/material.dart';

const Color corPrincipal = Color(0xFF6A00FF);
const Color corPrincipalClara = Color(0xFFDDD2FF);
const Color corFundo = Color(0xFFF5F5FB);
const Color corTexto = Color(0xFF222238);
const Color corTextoSuave = Color(0xFF686879);
const Color corBordaCampo = Color(0xFFCCCCCC);
const Color corErroBorda = Color(0xFFC5163D);
const Color corErroFundo = Color(0xFFFFF0F3);
const Color corErroTexto = Color(0xFF8C1632);

OutlineInputBorder _bordaCampo(Color cor, double largura) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: BorderSide(color: cor, width: largura),
  );
}

final ThemeData temaIceiBank = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: corPrincipal,
    primary: corPrincipal,
    surface: Colors.white,
    onSurface: corTexto,
  ),
  scaffoldBackgroundColor: corFundo,
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(14),
    border: _bordaCampo(corBordaCampo, 1),
    enabledBorder: _bordaCampo(corBordaCampo, 1),
    focusedBorder: _bordaCampo(corPrincipal, 2),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: corPrincipal,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: corPrincipal,
      backgroundColor: Colors.white,
      side: const BorderSide(color: corPrincipal),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
);

String formatarReais(double valor) {
  return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
}

String formatarHora(DateTime momento) {
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${doisDigitos(momento.hour)}:${doisDigitos(momento.minute)}:'
      '${doisDigitos(momento.second)}';
}
