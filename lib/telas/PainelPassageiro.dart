import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_clone/Rotas.dart';
import 'package:uber_clone/model/Destino.dart';
import 'package:uber_clone/model/Marcador.dart';
import 'package:uber_clone/model/Requisicao.dart';
import 'package:uber_clone/model/Usuario.dart';
import 'package:uber_clone/util/StatusRequisicao.dart';
import 'package:uber_clone/util/UsuarioFirebase.dart';

class PainelPassageiro extends StatefulWidget {
  const PainelPassageiro({Key? key}) : super(key: key);

  @override
  _PainelPassageiroState createState() => _PainelPassageiroState();
}

class _PainelPassageiroState extends State<PainelPassageiro>
    with SingleTickerProviderStateMixin {
  TextEditingController _controllerDestino = TextEditingController(
    text: "joão deboni, 106",
  );
  Completer<GoogleMapController> _controller = Completer();

  CameraPosition _cameraPosition = CameraPosition(
    target: LatLng(-11.095173932052713, -37.13397389842669),
    zoom: 15,
  );

  Set<Marker> _marcadores = {};
  String? _idRequisicao;
  Position? _localPassageiro;
  Map<String, dynamic>? _dadosRequisicao;
  StreamSubscription<DocumentSnapshot>? _streamSubscriptionRequisicoes;

  // Controles para exibicao na tela
  bool _exibirCaixaEnderecoDestino = true;
  String _textoBotao = "Chamar Uber";
  Color _corBotao = Color(0xff1ebbd8);

  @override
  void initState() {
    super.initState();
    // Adicionar listener para requisição ativa
    _recuperaRequisicaoAtiva();

    //_recuperarUltimaPosicaoConhecida();
    _adicionarListenerLocalizacao();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Painel Passageiro"),
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
      body: Container(
        child: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _cameraPosition,
              onMapCreated: _onMapCreated,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              myLocationEnabled: false,
              markers: _marcadores,
            ),
            Visibility(
              visible: _exibirCaixaEnderecoDestino,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.white,
                        ),
                        child: TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                            icon: Container(
                              margin: EdgeInsets.only(left: 20, bottom: 10),
                              width: 10,
                              height: 10,
                              child: Icon(
                                Icons.location_on,
                                color: Colors.green,
                              ),
                            ),
                            hintText: "Meu local",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(left: 10, top: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 55,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.white,
                        ),
                        child: TextField(
                          controller: _controllerDestino,
                          decoration: InputDecoration(
                            icon: Container(
                              margin: EdgeInsets.only(left: 20, bottom: 10),
                              width: 10,
                              height: 10,
                              child:
                                  Icon(Icons.local_taxi, color: Colors.black),
                            ),
                            hintText: "Digite o destino",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(left: 10, top: 10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: _corBotao,
                  ),
                  onPressed:
                      _exibirCaixaEnderecoDestino ? _chamarUber : _cancelarUber,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    child: Text(
                      _textoBotao,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _recuperaRequisicaoAtiva() async {
    User? firebaseUser = await UsuarioFirebase.getUsuarioAtual();
    FirebaseFirestore db = FirebaseFirestore.instance;

    DocumentSnapshot documentSnapshot =
        await db.collection("requisicao_ativa").doc(firebaseUser!.uid).get();

    if (documentSnapshot.data() != null) {
      Map<String, dynamic> dados =
          documentSnapshot.data() as Map<String, dynamic>;
      _idRequisicao = dados["id_requisicao"];
      _adicionarListenerRequisicao(_idRequisicao!);
    } else {
      _statusUberNaoChamado();
    }
  }

  _adicionarListenerRequisicao(String idRequisicao) async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    _streamSubscriptionRequisicoes = await db
        .collection("requisicoes")
        .doc(idRequisicao)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.data() != null) {
        Map<String, dynamic>? dados = snapshot.data();
        _dadosRequisicao = dados;
        String status = dados!["status"];
        _idRequisicao = dados["id_requisicao"];

        switch (status) {
          case StatusRequisicao.AGUARDANDO:
            _statusAguardando();
            break;
          case StatusRequisicao.A_CAMINHO:
            _statusACaminho();
            break;
          case StatusRequisicao.VIAGEM:
            break;
          case StatusRequisicao.FINALIZADA:
            break;
        }
      }
    });
  }

  _alterarBotaoPrincipal(bool caixaDestino, String texto, Color cor) {
    setState(() {
      _exibirCaixaEnderecoDestino = caixaDestino;
      _textoBotao = texto;
      _corBotao = cor;
    });
  }

  _statusUberNaoChamado() {
    _alterarBotaoPrincipal(
      true,
      "Chamar Uber",
      Color(0xff1ebbd8),
    );

    if (_localPassageiro != null) {
      Position position = Position(
        longitude: _localPassageiro!.longitude,
        latitude: _localPassageiro!.latitude,
        timestamp: null,
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
      _exibirMarcadorPassageiro(position);
      CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16,
      );
      _movimentarCamera(cameraPosition);
    }
  }

  _statusAguardando() {
    _alterarBotaoPrincipal(
      false,
      "Cancelar",
      Colors.red,
    );
    double passageiroLat = _dadosRequisicao!["passageiro"]["latitude"];
    double passageiroLon = _dadosRequisicao!["passageiro"]["longitude"];

    Position position = Position(
      longitude: passageiroLon,
      latitude: passageiroLat,
      timestamp: null,
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
    _exibirMarcadorPassageiro(position);
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 16,
    );
    _movimentarCamera(cameraPosition);
  }

  _statusACaminho() {
    _alterarBotaoPrincipal(
      false,
      "Motorista a caminho",
      Colors.grey,
    );

    double latitudePassageiro = _dadosRequisicao!["passageiro"]["latitude"];
    double longitudePassageiro = _dadosRequisicao!["passageiro"]["longitude"];

    double latitudeOrigem = _dadosRequisicao!["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequisicao!["motorista"]["longitude"];

    Marcador marcadorOrigem = Marcador(
      LatLng(latitudeOrigem, longitudeOrigem),
      "images/motorista.png",
      "Local Motorista",
    );

    Marcador marcadorDestino = Marcador(
      LatLng(latitudePassageiro, longitudePassageiro),
      "images/passageiro.png",
      "Local Destino",
    );

    _exibirCentralizarDoisMarcadores(marcadorOrigem, marcadorDestino);
  }

  _statusEmViagem() {
    _alterarBotaoPrincipal(
      false,
      "Em viagem",
      Colors.grey,
    );
    double latitudeDestino = _dadosRequisicao!["destino"]["latitude"];
    double longitudeDestino = _dadosRequisicao!["destino"]["longitude"];

    double latitudeOrigem = _dadosRequisicao!["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequisicao!["motorista"]["longitude"];

    Marcador marcadorOrigem = Marcador(
      LatLng(latitudeOrigem, longitudeOrigem),
      "images/motorista.png",
      "Local Motorista",
    );

    Marcador marcadorDestino = Marcador(
      LatLng(latitudeDestino, longitudeDestino),
      "images/destino.png",
      "Local Destino",
    );

    _exibirCentralizarDoisMarcadores(marcadorOrigem, marcadorDestino);
  }

  _exibirCentralizarDoisMarcadores(
      Marcador marcadorOrigem, Marcador marcadorDestino) {
    double latitudeOrigem = marcadorOrigem.local.latitude;
    double longitudeOrigem = marcadorOrigem.local.longitude;

    double latitudeDestino = marcadorDestino.local.latitude;
    double longitudeDestino = marcadorDestino.local.longitude;

    // Exibir dois marcadores
    _exibirDoisMarcadores(
      marcadorOrigem,
      marcadorDestino,
    );

    var nLat, nLon, sLat, sLon;

    if (latitudeOrigem <= latitudeDestino) {
      sLat = latitudeOrigem;
      nLat = latitudeDestino;
    } else {
      sLat = latitudeDestino;
      nLat = latitudeOrigem;
    }

    if (longitudeOrigem <= longitudeDestino) {
      sLon = longitudeOrigem;
      nLon = longitudeDestino;
    } else {
      sLon = longitudeDestino;
      nLon = longitudeOrigem;
    }

    _movimentarCameraBounds(
      LatLngBounds(
        northeast: LatLng(nLat, nLon),
        southwest: LatLng(sLat, sLon),
      ),
    );
  }

  _movimentarCameraBounds(LatLngBounds latLngBounds) async {
    GoogleMapController googleMapController = await _controller.future;

    googleMapController.animateCamera(CameraUpdate.newLatLngBounds(
      latLngBounds,
      100,
    ));
  }

  _exibirDoisMarcadores(Marcador marcadorOrigem, Marcador marcadorDestino) {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    LatLng latLngOrigem = marcadorOrigem.local;
    LatLng latLngDestino = marcadorDestino.local;

    Set<Marker> _listaMarcadores = {};
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: pixelRatio),
            marcadorOrigem.caminhoImagem)
        .then((BitmapDescriptor icone) {
      Marker mOrigem = Marker(
        markerId: MarkerId(marcadorOrigem.caminhoImagem),
        position: LatLng(latLngOrigem.latitude, latLngOrigem.longitude),
        infoWindow: InfoWindow(title: marcadorOrigem.titulo),
        icon: icone,
      );
      _listaMarcadores.add(mOrigem);
    });
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      marcadorDestino.caminhoImagem,
    ).then((BitmapDescriptor icone) {
      Marker mDestino = Marker(
        markerId: MarkerId(marcadorDestino.caminhoImagem),
        position: LatLng(latLngDestino.latitude, latLngDestino.longitude),
        infoWindow: InfoWindow(title: marcadorDestino.titulo),
        icon: icone,
      );
      _listaMarcadores.add(mDestino);
    });

    setState(() {
      _marcadores = _listaMarcadores;
    });
  }

  _cancelarUber() async {
    Usuario firebaseUser = await UsuarioFirebase.getDadosUsuarioLogado();
    FirebaseFirestore db = FirebaseFirestore.instance;

    db.collection("requisicoes").doc(_idRequisicao).update({
      "status": StatusRequisicao.CANCELADA,
    });

    db.collection("requisicao_ativa").doc(firebaseUser.idUsuario).delete();
  }

  _salvarRequisicao(Destino destino) async {
    Requisicao requisicao = Requisicao();
    Usuario passageiro = await UsuarioFirebase.getDadosUsuarioLogado();
    FirebaseFirestore db = FirebaseFirestore.instance;
    passageiro.latitude = _localPassageiro!.latitude;
    passageiro.longitude = _localPassageiro!.longitude;

    requisicao.destino = destino;
    requisicao.passageiro = passageiro;
    requisicao.status = StatusRequisicao.AGUARDANDO;

    // Salvar requisição
    db.collection("requisicoes").doc(requisicao.id).set(requisicao.toMap());

    // salvar requisição ativa
    Map<String, dynamic> dadosRequisicaoAtiva = {};
    dadosRequisicaoAtiva["id_requisicao"] = requisicao.id;
    dadosRequisicaoAtiva["id_usuario"] = passageiro.idUsuario;
    dadosRequisicaoAtiva["status"] = StatusRequisicao.AGUARDANDO;

    db
        .collection("requisicao_ativa")
        .doc(passageiro.idUsuario)
        .set(dadosRequisicaoAtiva);

    // Adicionar listener requisição
    if (_streamSubscriptionRequisicoes == null) {
      _adicionarListenerRequisicao(requisicao.id);
    }
  }

  _chamarUber() async {
    String enderecoDestino = _controllerDestino.text;

    if (enderecoDestino.isNotEmpty) {
      List<Location> locations = await locationFromAddress(enderecoDestino);
      List<Placemark> listaEnderecos = await placemarkFromCoordinates(
        locations.first.latitude,
        locations.first.longitude,
      );

      if (listaEnderecos.length > 0) {
        Placemark endereco = listaEnderecos[0];
        Destino destino = Destino();
        destino.cidade = endereco.subAdministrativeArea;
        destino.cep = endereco.postalCode;
        destino.bairro = endereco.subLocality;
        destino.rua = endereco.thoroughfare;
        destino.numero = endereco.subThoroughfare;
        destino.latitude = locations.first.latitude;
        destino.longitude = locations.first.longitude;

        String enderecoConfirmacao;
        enderecoConfirmacao = "\n Cidade: " + destino.cidade;
        enderecoConfirmacao += "\n Rua: " + destino.rua + ", " + destino.numero;
        enderecoConfirmacao += "\n Bairro: " + destino.bairro;
        enderecoConfirmacao += "\n CEP: " + destino.cep;

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Confirmação de endereço"),
              content: Text(enderecoConfirmacao),
              contentPadding: EdgeInsets.all(16),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  onPressed: () {
                    //Salvar requisição
                    _salvarRequisicao(destino);
                    //Fecha o AlertDialog
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            );
          },
        );
      }
    }
  }

  _exibirMarcadorPassageiro(Position local) async {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      "images/passageiro.png",
    ).then((BitmapDescriptor icone) {
      Marker marcadorPassageiro = Marker(
        markerId: MarkerId("marcador-passageiro"),
        position: LatLng(local.latitude, local.longitude),
        infoWindow: InfoWindow(title: "Meu local"),
        icon: icone,
      );

      setState(() {
        _marcadores.add(marcadorPassageiro);
      });
    });
  }

  _movimentarCamera(CameraPosition cameraPosition) async {
    GoogleMapController googleMapController = await _controller.future;

    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  }

  _recuperarUltimaPosicaoConhecida() async {
    Position? position = await Geolocator.getLastKnownPosition();

    setState(() {
      if (position != null) {
        _exibirMarcadorPassageiro(position);

        _cameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        );
        _localPassageiro = position;
        _movimentarCamera(_cameraPosition);
      }
    });
  }

  _adicionarListenerLocalizacao() {
    Geolocator.getPositionStream(
      distanceFilter: 5, // atualiza a localização a cada 5 metros
      desiredAccuracy: LocationAccuracy.best,
    ).listen((Position position) {
      if (_idRequisicao != null && _idRequisicao!.isNotEmpty) {
        // Atualiza local do passageiro
        UsuarioFirebase.atualizarDadosLocalizacao(
          _idRequisicao!,
          position.latitude,
          position.longitude,
        );
      } else {
        setState(() {
          _localPassageiro = position;
        });
        _statusUberNaoChamado();
      }
    });
  }

  _onMapCreated(GoogleMapController googleMapController) {
    _controller.complete(googleMapController);
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

  @override
  void dispose() {
    super.dispose();

    _streamSubscriptionRequisicoes!.cancel();
  }
}
