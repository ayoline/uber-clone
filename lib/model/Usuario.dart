class Usuario {
  String? _idUsuario;
  String? _nome;
  String? _email;
  String? _senha;
  String? _tipoUsuario;

  Usuario();

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      "nome": this.nome,
      "email": this.email,
      "tipoUsuario": this.tipoUsuario,
    };
    return map;
  }

  verificaTipoUsuario(bool tipoUsuario) {
    return tipoUsuario ? "motorista" : "passageiro";
  }

  get idUsuario => this._idUsuario;

  set idUsuario(value) => this._idUsuario = value;

  get nome => this._nome;

  set nome(value) => this._nome = value;

  get email => this._email;

  set email(value) => this._email = value;

  get senha => this._senha;

  set senha(value) => this._senha = value;

  get tipoUsuario => this._tipoUsuario;

  set tipoUsuario(value) => this._tipoUsuario = value;
}
