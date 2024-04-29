import 'dart:math';

import 'package:inapp_kyc/functions.dart';
import 'package:inapp_kyc/models/kyc_image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class MLService {
  late Interpreter _interpreter;

  MLService._initialize(Interpreter interpreter) {
    _interpreter = interpreter;
  }

  static Future<MLService> initialize() async {
    Interpreter interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
    return MLService._initialize(interpreter);
  }

  Future<List?> createModel(KYCImage kycImage) async {
    img.Image? croppedImage = await kycImage.cropImage();
    if (croppedImage == null) return null;

    List input = croppedImage.toFloat32List();

    input = input.reshape([
      1,
      112,
      112,
      3
    ]);
    List output = List.generate(1, (index) => List.filled(192, 0));

    _interpreter.run(input, output);
    output = output.reshape([
      192
    ]);

    return List.from(output);
  }

  double euclideanDistance(List? e1, List? e2) {
    if (e1 == null || e2 == null) throw Exception("Null argument");

    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }
}
