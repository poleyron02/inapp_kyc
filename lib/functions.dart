import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:inapp_kyc/globals.dart';
import 'package:image/image.dart' as img;

double allowance = 10;
double center = 0;

bool isInsideBounds(double value, double min, double max) => value > min && value < max;

extension GetFaceDirection on Face {
  FaceDirection getFaceDirection() {
    double minX = center - allowance;
    double maxX = center + allowance;
    double minY = center - allowance;
    double maxY = center + allowance;
    double minZ = center - allowance;
    double maxZ = center + allowance;

    if (isInsideBounds(headEulerAngleX!, minX, maxX) && isInsideBounds(headEulerAngleY!, minY, maxY) && isInsideBounds(headEulerAngleZ!, minZ, maxZ)) return FaceDirection.straight;
    if (headEulerAngleX! >= maxX) return FaceDirection.top;
    if (headEulerAngleX! <= minX) return FaceDirection.bottom;
    if (headEulerAngleY! >= maxY) return FaceDirection.left;
    if (headEulerAngleY! <= minY) return FaceDirection.right;
    if (headEulerAngleZ! >= maxZ) return FaceDirection.tiltRight;
    if (headEulerAngleZ! <= minZ) return FaceDirection.tiltLeft;
    return FaceDirection.none;
  }
}

extension InputImageParsing on CameraImage {
  InputImage? toInputImage(
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = orientations[deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(this.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null || (Platform.isAndroid && format != InputImageFormat.nv21) || (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (planes.length != 1) return null;
    final plane = planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }
}

extension ImageToFloat32List on img.Image {
  Float32List toFloat32List() {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        img.Pixel pixel = getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - 128) / 128;
        buffer[pixelIndex++] = (pixel.g - 128) / 128;
        buffer[pixelIndex++] = (pixel.b - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }
}
