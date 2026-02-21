import 'package:flutter/foundation.dart';

void logSafe(String msg) {
  if (kDebugMode) {
    // ignore: avoid_print
    print(msg);
  }
}
