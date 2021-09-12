import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_clone/Rotas.dart';

class PainelPassageiro extends StatefulWidget {
  const PainelPassageiro({Key? key}) : super(key: key);

  @override
  _PainelPassageiroState createState() => _PainelPassageiroState();
}

class _PainelPassageiroState extends State<PainelPassageiro>
    with SingleTickerProviderStateMixin {
  Completer<GoogleMapController> _controller = Completer();

  CameraPosition _cameraPosition = CameraPosition(
    target: LatLng(-11.095173932052713, -37.13397389842669),
    zoom: 15,
  );

  Set<Marker> _marcadores = {};

  @override
  void initState() {
    super.initState();
    _recuperarUltimaPosicaoConhecida();
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
                    decoration: InputDecoration(
                      icon: Container(
                        margin: EdgeInsets.only(left: 20, bottom: 10),
                        width: 10,
                        height: 10,
                        child: Icon(Icons.local_taxi, color: Colors.black),
                      ),
                      hintText: "Digite o destino",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(left: 10, top: 10),
                    ),
                  ),
                ),
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
                    primary: Color(0xff1ebbd8),
                  ),
                  onPressed: () {},
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    child: Text(
                      "Chamar Uber",
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

    if (position != null) {
      _exibirMarcadorPassageiro(position);

      _cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 15,
      );
      _movimentarCamera(_cameraPosition);
    }
  }

  _adicionarListenerLocalizacao() {
    Geolocator.getPositionStream(
      distanceFilter: 5, // atualiza a localização a cada 5 metros
      desiredAccuracy: LocationAccuracy.best,
    ).listen((Position position) {
      setState(() {
        _exibirMarcadorPassageiro(position);
        _cameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        );
        _movimentarCamera(_cameraPosition);
      });
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
}
