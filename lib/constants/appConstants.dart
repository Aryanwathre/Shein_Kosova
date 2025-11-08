

import 'package:flutter/cupertino.dart';

class Constant {
  static getTextScale(BuildContext context, double size) {
    return MediaQuery.of(context).textScaler.scale(size);
  }

  static height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
}