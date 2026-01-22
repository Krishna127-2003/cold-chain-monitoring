import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  static double height(BuildContext context) => MediaQuery.of(context).size.height;

  static bool isSmall(BuildContext context) => width(context) < 360;
  static bool isLarge(BuildContext context) => width(context) > 430;

  static double pad(BuildContext context) {
    if (isSmall(context)) return 14;
    if (isLarge(context)) return 22;
    return 18;
  }

  static int gridCols(BuildContext context) {
    if (isLarge(context)) return 2; // phones only
    return 2;
  }
}
