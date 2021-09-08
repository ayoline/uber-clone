import 'package:flutter/material.dart';
import 'telas/Home.dart';

final ThemeData temaPadrao = ThemeData(
  primaryColor: Color(0xff37474f),
  accentColor: Color(0xff546e7a),
);

void main() async {
  //await Firebase.initializeApp();
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "Uber",
    home: Home(),
    theme: temaPadrao,
  ));
}
