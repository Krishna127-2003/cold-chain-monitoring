import 'package:flutter/material.dart';

class AppSnackBar {
  static GlobalKey<ScaffoldMessengerState>? _key;

  static void init(GlobalKey<ScaffoldMessengerState> key) {
    _key = key;
  }

  static void show(SnackBar snackBar) {
    _key?.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static void hide() {
    _key?.currentState?.removeCurrentSnackBar();
  }
}
