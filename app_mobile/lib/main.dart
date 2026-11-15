import 'package:flutter/material.dart';

import 'telas/tela_login.dart';
import 'tema/tema.dart';

void main() {
  runApp(const AppIceiBank());
}

class AppIceiBank extends StatelessWidget {
  const AppIceiBank({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICEIBank',
      debugShowCheckedModeBanner: false,
      theme: temaIceiBank,
      home: const TelaLogin(),
    );
  }
}
