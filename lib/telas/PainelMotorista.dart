import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/util/StatusRequisicao.dart';
import 'package:uber_clone/util/UsuarioFirebase.dart';
import '../Rotas.dart';

class PainelMotorista extends StatefulWidget {
  const PainelMotorista({Key? key}) : super(key: key);

  @override
  _PainelMotoristaState createState() => _PainelMotoristaState();
}

class _PainelMotoristaState extends State<PainelMotorista>
    with SingleTickerProviderStateMixin {
  final _controller = StreamController<QuerySnapshot>();
  FirebaseFirestore db = FirebaseFirestore.instance;
  Map<String, dynamic>? _dadosRequisicao;

  @override
  void initState() {
    super.initState();
    // Adiciona listenet para recuperar requisições
    //_adicionarListenerRequisicoes();

    // Recuperar requisição ativa para verificar se o motorista está
    // atendendo alguma requisição e envia ele para tela de corrida
    _recuperaRequisicaoAtivaMotorista();
  }

  @override
  Widget build(BuildContext context) {
    var mensagemCarregando = Center(
      child: Column(
        children: [
          Text("Carregando requisições"),
          CircularProgressIndicator(),
        ],
      ),
    );

    var mensagemNaoTemDados = Center(
      child: Text(
        "Você não tem nenhuma requisição",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

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
      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return mensagemCarregando;
            case ConnectionState.active:
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Text("Erro ao carregar dados!");
              } else {
                QuerySnapshot? querySnapshot = snapshot.data;
                if (querySnapshot!.docs.length == 0) {
                  return mensagemNaoTemDados;
                } else {
                  return ListView.separated(
                    itemCount: querySnapshot.docs.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 2,
                      color: Colors.grey,
                    ),
                    itemBuilder: (context, index) {
                      List<DocumentSnapshot> requisicoes =
                          querySnapshot.docs.toList();
                      DocumentSnapshot item = requisicoes[index];

                      String idRequisicao = item["id"];
                      String nomePassageiro = item["passageiro"]["nome"];
                      String rua = item["destino"]["rua"];
                      String numero = item["destino"]["numero"];

                      return ListTile(
                        title: Text(nomePassageiro),
                        subtitle: Text("destino: $rua, $numero"),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            "/corrida",
                            arguments: idRequisicao,
                          );
                        },
                      );
                    },
                  );
                }
              }
          }
        },
      ),
    );
  }

  _recuperaRequisicaoAtivaMotorista() async {
    // Recupera dados do usuario logado
    User? firebaseUser = await UsuarioFirebase.getUsuarioAtual();
    // Recupera requisição ativa
    DocumentSnapshot documentSnapshot = await db
        .collection("requisicao_ativa_motorista")
        .doc(firebaseUser!.uid)
        .get();

    _dadosRequisicao = documentSnapshot.data() as Map<String, dynamic>?;

    if (_dadosRequisicao == null) {
      _adicionarListenerRequisicoes();
    } else {
      String idRequisicao = _dadosRequisicao!["id_requisicao"];
      Navigator.pushReplacementNamed(
        context,
        "/corrida",
        arguments: idRequisicao,
      );
    }
  }

  Stream<QuerySnapshot>? _adicionarListenerRequisicoes() {
    final stream = db
        .collection("requisicoes")
        .where("status", isEqualTo: StatusRequisicao.AGUARDANDO)
        .snapshots();

    stream.listen((dados) {
      _controller.add(dados);
    });
    return null;
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
