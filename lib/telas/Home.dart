import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/model/Usuario.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController _controllerEmail = TextEditingController();
  TextEditingController _controllerSenha = TextEditingController();
  String _mensagemErro = "";
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _verificaUsuarioLogado();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              "images/fundo.png",
            ),
            fit: BoxFit.cover,
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: Image.asset(
                    "images/logo.png",
                    width: 200,
                    height: 150,
                  ),
                ),
                TextField(
                  controller: _controllerEmail,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    hintText: "e-mail",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                TextField(
                  controller: _controllerSenha,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    hintText: "senha",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xff1ebbd8),
                    ),
                    onPressed: () {
                      _validarCampos();
                    },
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      child: Text(
                        "Entrar",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        "/cadastro",
                      );
                    },
                    child: Text(
                      "Não tem conta? Cadastre-se!",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                _carregando
                    ? Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.white,
                        ),
                      )
                    : Container(),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      _mensagemErro,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _verificaUsuarioLogado() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    String usuarioLogado = auth.currentUser!.uid.toString();

    if (usuarioLogado != "") {
      _redirecionaPainelPorTipoUsuario(usuarioLogado);
    }
  }

  _redirecionaPainelPorTipoUsuario(String idUsuario) async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    DocumentSnapshot snapshot =
        await db.collection("uberUsers").doc(idUsuario).get();

    Map<String, dynamic> dados = snapshot.data() as Map<String, dynamic>;
    String tipoUsuario = dados["tipoUsuario"];

    setState(() {
      _carregando = false;
    });

    switch (tipoUsuario) {
      case "motorista":
        Navigator.pushReplacementNamed(context, "/painel-motorista");
        break;
      case "passageiro":
        Navigator.pushReplacementNamed(context, "/painel-passageiro");
        break;
    }
  }

  _logarUsuario(Usuario usuario) {
    setState(() {
      _carregando = true;
    });

    FirebaseAuth auth = FirebaseAuth.instance;
    auth
        .signInWithEmailAndPassword(
      email: usuario.email,
      password: usuario.senha,
    )
        .then((firebaseUser) {
      _redirecionaPainelPorTipoUsuario(auth.currentUser!.uid.toString());
    }).catchError((error) {
      setState(() {
        _mensagemErro =
            "Erro ao autenticar usuário. Confira usuario e senha e tente novamente.";
      });
    });
  }

  _validarCampos() {
// Recuperar dados dos campos
    String email = _controllerEmail.text;
    String senha = _controllerSenha.text;

    // Validar campos
    if (email.contains("@")) {
      if (senha.length >= 6) {
        Usuario usuario = Usuario();
        usuario.email = email;
        usuario.senha = senha;

        _logarUsuario(usuario);
      } else {
        setState(() {
          _mensagemErro = "Preencha a senha com pelos menos 6 caracteres";
        });
      }
    } else {
      setState(() {
        _mensagemErro = "Preencha com um email válido";
      });
    }
  }
}
