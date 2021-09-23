import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_clone/model/Usuario.dart';
import 'package:uber_clone/util/StatusRequisicao.dart';
import 'package:uber_clone/util/UsuarioFirebase.dart';

class Corrida extends StatefulWidget {
  String idRequisicao = "";
  Corrida(this.idRequisicao);

  @override
  _CorridaState createState() => _CorridaState();
}

class _CorridaState extends State<Corrida> {
  Completer<GoogleMapController> _controller = Completer();

  CameraPosition _cameraPosition = CameraPosition(
    target: LatLng(-11.095173932052713, -37.13397389842669),
    zoom: 15,
  );

  bool _statusBotao = true;
  Set<Marker> _marcadores = {};
  Map<String, dynamic>? _dadosRequisicao;

  // Controles para exibicao na tela
  String _textoBotao = "Aceitar corrida";
  Color _corBotao = Color(0xff1ebbd8);
  String _mensagemStatus = "";
  String? _idRequisicao;
  Position? _localMotorista;
  String _statusRequisicao = StatusRequisicao.AGUARDANDO;

  @override
  void initState() {
    super.initState();
    _idRequisicao = widget.idRequisicao;

    // adicionar listener para mudança na requisição
    _adicionarListenerRequisicao();

    //_recuperarUltimaPosicaoConhecida();
    _adicionarListenerLocalizacao();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Painel Corrida - " + _mensagemStatus),
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
                  onPressed: _statusBotao
                      ? _aceitarCorrida
                      : () {
                          _iniciarCorrida();
                        },
                  //_exibirCaixaEnderecoDestino ? _chamarUber : _cancelarUber,
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

  _aceitarCorrida() async {
    // Recuperar dados motorista
    Usuario motorista = await UsuarioFirebase.getDadosUsuarioLogado();
    motorista.latitude = _localMotorista!.latitude;
    motorista.longitude = _localMotorista!.longitude;

    FirebaseFirestore db = FirebaseFirestore.instance;
    String idRequisicao = _dadosRequisicao!["id"];

    db.collection("requisicoes").doc(idRequisicao).update({
      "motorista": motorista.toMap(),
      "status": StatusRequisicao.A_CAMINHO,
    });

    // Atualiza requisição ativa
    String idPassageiro = _dadosRequisicao!["passageiro"]["idUsuario"];
    db.collection("requisicao_ativa").doc(idPassageiro).update({
      "status": StatusRequisicao.A_CAMINHO,
    });

    // Salvar requisição ativa para motorista
    String idMotorista = motorista.idUsuario;
    db.collection("requisicao_ativa_motorista").doc(idMotorista).set({
      "id_requisicao": idRequisicao,
      "id_usuario": idMotorista,
      "status": StatusRequisicao.A_CAMINHO,
    });
  }

  _cancelarCorrida() {}

  _statusAguardando() {
    _alterarBotaoPrincipal(
      true,
      "Aceitar Corrida",
      Color(0xff1ebbd8),
    );

    if (_localMotorista != null) {
      double motoristaLat = _localMotorista!.latitude;
      double motoristaLon = _localMotorista!.longitude;

      Position position = Position(
        speedAccuracy: 0.0,
        altitude: 0.0,
        speed: 0.0,
        accuracy: 0.0,
        heading: 0.0,
        timestamp: null,
        longitude: motoristaLat,
        latitude: motoristaLon,
      );
      _exibirMarcador(
        position,
        "images/motorista.png",
        "Motorista",
      );
      CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16,
      );
      _movimentarCamera(cameraPosition);
    }
  }

  _statusACaminho() {
    _mensagemStatus = "A caminho do passageiro";
    _alterarBotaoPrincipal(
      false,
      "Iniciar corrida",
      Color(0xff1ebbd8),
    );
    double latitudePassageiro = _dadosRequisicao!["passageiro"]["latitude"];
    double longitudePassageiro = _dadosRequisicao!["passageiro"]["longitude"];

    double latitudeMotorista = _dadosRequisicao!["motorista"]["latitude"];
    double longitudeMotorista = _dadosRequisicao!["motorista"]["longitude"];

    // Exibir dois marcadores
    _exibirDoisMarcadores(
      LatLng(latitudeMotorista, longitudeMotorista),
      LatLng(latitudePassageiro, longitudePassageiro),
    );
    var nLat, nLon, sLat, sLon;

    if (latitudeMotorista <= latitudePassageiro) {
      sLat = latitudeMotorista;
      nLat = latitudePassageiro;
    } else {
      sLat = latitudePassageiro;
      nLat = latitudeMotorista;
    }

    if (longitudeMotorista <= longitudePassageiro) {
      sLon = longitudeMotorista;
      nLon = longitudePassageiro;
    } else {
      sLon = longitudePassageiro;
      nLon = longitudeMotorista;
    }

    _movimentarCameraBounds(
      LatLngBounds(
        northeast: LatLng(nLat, nLon),
        southwest: LatLng(sLat, sLon),
      ),
    );
  }

  _iniciarCorrida() {
    FirebaseFirestore db = FirebaseFirestore.instance;

    db.collection("requisicoes").doc(_idRequisicao).update({
      "origem": {
        "latitude": _dadosRequisicao!["motorista"]["latitude"],
        "longitude": _dadosRequisicao!["motorista"]["longitude"],
      },
      "status": StatusRequisicao.VIAGEM,
    });
    String idPassageiro = _dadosRequisicao!["passageiro"]["idUsuario"];
    db.collection("requisicao_ativa").doc(idPassageiro).update({
      "status": StatusRequisicao.VIAGEM,
    });

    String idMotorista = _dadosRequisicao!["motorista"]["idUsuario"];
    db.collection("requisicao_ativa_motorista").doc(idMotorista).update({
      "status": StatusRequisicao.VIAGEM,
    });
  }

  _movimentarCameraBounds(LatLngBounds latLngBounds) async {
    GoogleMapController googleMapController = await _controller.future;

    googleMapController.animateCamera(CameraUpdate.newLatLngBounds(
      latLngBounds,
      100,
    ));
  }

  _exibirDoisMarcadores(LatLng latLngM, LatLng latLngP) {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    Set<Marker> _listaMarcadores = {};
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      "images/motorista.png",
    ).then((BitmapDescriptor icone) {
      Marker marcadorM = Marker(
        markerId: MarkerId("marcador-motorista"),
        position: LatLng(latLngM.latitude, latLngM.longitude),
        infoWindow: InfoWindow(title: "Local motorista"),
        icon: icone,
      );
      _listaMarcadores.add(marcadorM);
    });
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      "images/passageiro.png",
    ).then((BitmapDescriptor icone) {
      Marker marcadorP = Marker(
        markerId: MarkerId("marcador-passageiro"),
        position: LatLng(latLngP.latitude, latLngP.longitude),
        infoWindow: InfoWindow(title: "Local passageiro"),
        icon: icone,
      );
      _listaMarcadores.add(marcadorP);
    });

    setState(() {
      _marcadores = _listaMarcadores;
    });
  }

  _alterarBotaoPrincipal(bool statusBotao, String texto, Color cor) {
    setState(() {
      statusBotao = true;
      _textoBotao = texto;
      _corBotao = cor;
    });
  }

  _adicionarListenerRequisicao() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    await db
        .collection("requisicoes")
        .doc(_idRequisicao)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.data() != null) {
        _dadosRequisicao = snapshot.data();

        Map<String, dynamic>? dados = snapshot.data();
        _statusRequisicao = dados!["status"];

        switch (_statusRequisicao) {
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

  _recuperarRequisicao() async {
    String idRequisicao = widget.idRequisicao;
    FirebaseFirestore db = FirebaseFirestore.instance;

    DocumentSnapshot documentSnapshot =
        await db.collection("requisicoes").doc(idRequisicao).get();
  }

  _adicionarListenerLocalizacao() {
    Geolocator.getPositionStream(
      distanceFilter: 5, // atualiza a localização a cada 5 metros
      desiredAccuracy: LocationAccuracy.best,
    ).listen((Position position) {
      // ignore: unrelated_type_equality_checks
      if (position.latitude.toString().isNotEmpty) {
        if (_idRequisicao != null && _idRequisicao!.isNotEmpty) {
          if (_statusRequisicao != StatusRequisicao.AGUARDANDO) {
            // Atualiza local do passageiro
            UsuarioFirebase.atualizarDadosLocalizacao(
              _idRequisicao!,
              position.latitude,
              position.longitude,
            );
          } else {
            // Requisição aguardando
            setState(() {
              _localMotorista = position;
            });
            _statusAguardando();
          }
        }
      }
    });
  }

  _exibirMarcador(Position local, String icone, String infoWindow) async {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      icone,
    ).then((BitmapDescriptor bitmapDescriptor) {
      Marker marcador = Marker(
        markerId: MarkerId(icone),
        position: LatLng(local.latitude, local.longitude),
        infoWindow: InfoWindow(title: infoWindow),
        icon: bitmapDescriptor,
      );

      setState(() {
        _marcadores.add(marcador);
      });
    });
  }

  _onMapCreated(GoogleMapController googleMapController) {
    _controller.complete(googleMapController);
  }

  _recuperarUltimaPosicaoConhecida() async {
    Position? position = await Geolocator.getLastKnownPosition();

    if (position != null) {
      // Atualizar localização em tempo real do motorista

    }
  }

  _movimentarCamera(CameraPosition cameraPosition) async {
    GoogleMapController googleMapController = await _controller.future;

    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  }
}
