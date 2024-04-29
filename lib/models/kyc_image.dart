import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class KYCImage {
  XFile file;
  Face face;
  img.Image? croppedImage;

  KYCImage({
    required this.file,
    required this.face,
  });

  Future<img.Image?> _cropImage(XFile file) async {
    img.Image? image = await img.decodeImageFile(file.path);
    if (image == null) return null;
    double x = face.boundingBox.left - 10.0;
    double y = face.boundingBox.top - 10.0;
    double w = face.boundingBox.width + 10.0;
    double h = face.boundingBox.height + 10.0;

    img.Image croppedImage = img.copyCrop(image, x: x.round(), y: y.round(), width: w.round(), height: h.round());
    img.Image squareImage = img.copyResizeCropSquare(croppedImage, size: 112);
    return squareImage;
  }

  Future<img.Image?> cropImage() async {
    if (croppedImage != null) return croppedImage;
    var result = await compute(_cropImage, file);
    croppedImage = result;
    return croppedImage;
  }
}
