import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'telas/Home.dart';

void main() async {
  await Firebase.initializeApp();
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "Uber",
    home: Home(),
  ));
}
