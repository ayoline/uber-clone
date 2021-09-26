import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber_clone/model/Usuario.dart';

class UsuarioFirebase {
  static Future<User?> getUsuarioAtual() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    return auth.currentUser;
  }

  static Future<Usuario> getDadosUsuarioLogado() async {
    User? user = await getUsuarioAtual();
    String idUsuario = user!.uid;

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot snapshot =
        await db.collection("uberUsers").doc(idUsuario).get();

    Map<String, dynamic> dados = snapshot.data() as Map<String, dynamic>;
    String tipoUsuario = dados["tipoUsuario"];
    String nome = dados["nome"];
    String email = dados["email"];

    Usuario usuario = Usuario();
    usuario.tipoUsuario = tipoUsuario;
    usuario.idUsuario = idUsuario;
    usuario.email = email;
    usuario.nome = nome;

    return usuario;
  }

  static atualizarDadosLocalizacao(
      String idRequisicao, double lat, double lon, String tipo) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    Usuario usuario = await getDadosUsuarioLogado();

    usuario.latitude = lat;
    usuario.longitude = lon;

    db.collection("requisicoes").doc(idRequisicao).update({
      "$tipo": usuario.toMap(),
    });
  }
}
