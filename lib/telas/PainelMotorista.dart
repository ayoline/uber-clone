import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Rotas.dart';

class PainelMotorista extends StatefulWidget {
  const PainelMotorista({Key? key}) : super(key: key);

  @override
  _PainelMotoristaState createState() => _PainelMotoristaState();
}

class _PainelMotoristaState extends State<PainelMotorista>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Painel Motorista"),
        actions: [
          PopupMenuButton<int>(
            color: Colors.white,
            onSelected: (item) => onSelected(context, item),
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 0,
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Text("Deslogar"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(),
    );
  }

  void onSelected(BuildContext context, int item) {
    switch (item) {
      case 0:
        _deslogarUsuario();
        break;
    }
  }

  _deslogarUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();

    Navigator.pushNamedAndRemoveUntil(
      context,
      Rotas.ROTA_HOME,
      (_) => false,
    );
  }
}
