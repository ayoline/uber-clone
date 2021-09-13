import 'package:uber_clone/model/Destino.dart';
import 'package:uber_clone/model/Usuario.dart';

class Requisicao {
  String? _id;
  String? _status;

  Usuario? _passageiro;
  Usuario? _motorista;

  Destino? _destino;

  Requisicao();

  Map<String, dynamic> toMap() {
    Map<String, dynamic> dadosPassageiro = {
      "nome": this._passageiro!.nome,
      "email": this._passageiro!.email,
      "tipoUsuario": this._passageiro!.tipoUsuario,
      "idUsuario": this._passageiro!.idUsuario,
    };

    Map<String, dynamic> dadosDestino = {
      "rua": this._destino!.rua,
      "numero": this._destino!.numero,
      "bairro": this._destino!.bairro,
      "cep": this._destino!.cep,
      "latitude": this._destino!.latitude,
      "longitude": this._destino!.longitude,
    };

    Map<String, dynamic> dadosRequisicao = {
      "status": this.status,
      "passageiro": dadosPassageiro,
      "motorista": null,
      "destino": dadosDestino,
    };
    return dadosRequisicao;
  }

  get id => this._id;

  set id(value) => this._id = value;

  get status => this._status;

  set status(value) => this._status = value;

  get passageiro => this._passageiro;

  set passageiro(value) => this._passageiro = value;

  get motorista => this._motorista;

  set motorista(value) => this._motorista = value;

  get destino => this._destino;

  set destino(value) => this._destino = value;
}
