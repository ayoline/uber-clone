class Destino {
  String? _rua;
  String? _numero;
  String? _cidade;
  String? _bairro;
  String? _cep;

  double? _latitude;
  double? _longitude;

  Destino();

  get rua => this._rua;

  set rua(value) => this._rua = value;

  get numero => this._numero;

  set numero(value) => this._numero = value;

  get cidade => this._cidade;

  set cidade(value) => this._cidade = value;

  get bairro => this._bairro;

  set bairro(value) => this._bairro = value;

  get cep => this._cep;

  set cep(value) => this._cep = value;

  get latitude => this._latitude;

  set latitude(value) => this._latitude = value;

  get longitude => this._longitude;

  set longitude(value) => this._longitude = value;
}
