import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/telas/Cadastro.dart';
import 'package:uber_clone/telas/Home.dart';
import 'package:uber_clone/telas/PainelMotorista.dart';
import 'package:uber_clone/telas/PainelPassageiro.dart';

class Rotas {
  static const String ROTA_HOME = "/home";
  static const String ROTA_CADASTRO = "/cadastro";

  static Route<dynamic> gerarRotas(RouteSettings settings) {
    switch (settings.name) {
      case "/":
        return MaterialPageRoute(
          builder: (_) => Home(),
        );
      case "/home":
        return MaterialPageRoute(
          builder: (_) => Home(),
        );
      case "/cadastro":
        return MaterialPageRoute(
          builder: (_) => Cadastro(),
        );
      case "/painel-motorista":
        return MaterialPageRoute(
          builder: (_) => PainelMotorista(),
        );
      case "/painel-passageiro":
        return MaterialPageRoute(
          builder: (_) => PainelPassageiro(),
        );
      default:
        _erroRota();
    }
    return _erroRota();
  }

  static Route<dynamic> _erroRota() {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Tela não encontrada!"),
          ),
          body: Center(
            child: Text("Tela não encontrada!"),
          ),
        );
      },
    );
  }
}
