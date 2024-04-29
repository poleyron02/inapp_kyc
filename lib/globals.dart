import 'package:flutter/services.dart';

final orientations = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

enum FaceDirection {
  straight('Look forward'),
  top('Look up'),
  bottom('Look down'),
  left('Look to your left'),
  right('Look to your right'),
  tiltRight('Tilt to your right'),
  tiltLeft('Tilt to your left'),
  none('None');

  final String display;

  const FaceDirection(this.display);
}

enum IDType {
  philsys('Philsys ID'),
  ephill('ePhilID'),
  postal('Postal ID'),
  passport('Passport'),
  sss('SSS ID'),
  prc('PRC ID'),
  pagibig('Pag-ibig ID'),
  driversLicense('Driver\'s License'),
  umid('UMID'),
  other('Other');

  final String displayName;

  const IDType(this.displayName);
}
