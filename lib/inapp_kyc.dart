library inapp_kyc;

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:inapp_kyc/functions.dart';
import 'package:inapp_kyc/globals.dart';
import 'package:inapp_kyc/ml_service.dart';
import 'package:inapp_kyc/models/kyc_image.dart';
import 'package:inapp_kyc/models/kyc_result.dart';
import 'package:inapp_kyc/models/liveness_snapshot.dart';
import 'package:image/image.dart' as img;

class InAppKYC {
  late MLService _mlService;
  KYCImage? _id;
  KYCImage? _liveness;
  KYCImage? get id => _id;
  KYCImage? get liveness => _liveness;

  final _options = FaceDetectorOptions();
  late final FaceDetector _faceDetector;

  late CameraDescription _front;
  late CameraDescription _back;
  CameraController? _idCamera;
  CameraController? _livenessCamera;
  final StreamController<LivenessSnapshot> _streamController = StreamController.broadcast();
  Stream<LivenessSnapshot> get livenessStream => _streamController.stream;
  CameraPreview get idCamera => CameraPreview(_idCamera!);
  CameraPreview get livenessCamera => CameraPreview(_livenessCamera!);

  InAppKYC._initialize(MLService mlService, List<CameraDescription> cameras) {
    _mlService = mlService;

    if (!cameras.isEmpty) {
      try {
        _front = cameras.firstWhere((element) => element.lensDirection == CameraLensDirection.front);
      } catch (err) {
        _front = cameras.first;
      }
      try {
        _back = cameras.firstWhere((element) => element.lensDirection == CameraLensDirection.back);
      } catch (err) {
        _back = cameras.first;
      }
    }

    _faceDetector = FaceDetector(options: _options);
  }

  static Future<InAppKYC> initialize() async {
    var mlService = await MLService.initialize();
    var cameras = await availableCameras();
    return InAppKYC._initialize(mlService, cameras);
  }

  Future<void> initID() async {
    _idCamera = CameraController(
      _back,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    await _idCamera?.initialize();
    await _idCamera?.setFlashMode(FlashMode.off);
    await _idCamera?.lockCaptureOrientation(DeviceOrientation.landscapeLeft);
  }

  Future<void> disposeID() async {
    await _idCamera?.dispose();
  }

  Future<void> initLiveness() async {
    _livenessCamera = CameraController(
      _front,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    await _livenessCamera?.initialize();
    await _livenessCamera?.setFlashMode(FlashMode.off);
  }

  Future<void> disposeLiveness() async {
    await _livenessCamera?.dispose();
  }

  static Future<img.Image?> _rotateImage(Uint8List bytes) async {
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;
    return img.copyRotate(image, angle: -90);
  }

  Future<File?> processID() async {
    XFile file = await _idCamera!.takePicture();

    // Uint8List fileBytes = await file.readAsBytes();
    // img.Image? result = await compute(_rotateImage, fileBytes);
    // if (result == null) return null;
    // await File(file.path).writeAsBytes(img.encodeJpg(result));

    InputImage inputImage = InputImage.fromFilePath(file.path);

    final List<Face> faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return null;

    Face face = faces.first;

    _id = KYCImage(file: file, face: face);
    await _id!.cropImage();
    return File(file.path);
  }

  int tolerate = 0;

  bool _isFaceAtCenter(Face face, CameraImage image) {
    double imageCenterX = image.width / 2;
    double imageCenterY = image.height / 2;

    double threshold = 0.3;
    Rect boundingBox = face.boundingBox;

    double faceCenterX = boundingBox.left + (boundingBox.width / 2);
    double faceCenterY = boundingBox.top + (boundingBox.height / 2);

    double distanceX = (faceCenterX - imageCenterX).abs();
    double distanceY = (faceCenterY - imageCenterY).abs();

    if (distanceX < image.width * threshold && distanceY < image.height * threshold) return true;
    return false;
  }

  LivenessSnapshot snapshot = LivenessSnapshot(steps: []);

  void resetLiveness() {
    snapshot.retake();
    _streamController.sink.add(snapshot);
  }

  Future<void> takePicture(KYCResultNotifier kyc) async {
    if (_livenessCamera == null) return;

    XFile file = await _livenessCamera!.takePicture();
    snapshot.setImage(file);

    InputImage inputImage = InputImage.fromFilePath(file.path);
    final List<Face> faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return;

    _liveness = KYCImage(file: file, face: faces.first);
    await liveness!.cropImage();

    kyc.setFace(File(file.path));
  }

  Future<void> startLiveness(
    KYCResultNotifier kyc, {
    double distance = .3,
    int ignorance = 10,
    List<FaceDirection> steps = const [
      FaceDirection.top,
      FaceDirection.right,
      FaceDirection.bottom,
      FaceDirection.left
    ],
  }) async {
    List<FaceDirection> finalSteps = [];
    finalSteps.addAll(steps);
    finalSteps.add(FaceDirection.straight);

    snapshot = LivenessSnapshot(steps: finalSteps);

    await _livenessCamera!.startImageStream((image) async {
      InputImage? inputImage = image.toInputImage(_front, _livenessCamera!.value.deviceOrientation);
      if (snapshot.status == LivenessStatus.done) return;
      if (inputImage == null) return;

      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty || !_isFaceAtCenter(faces.first, image)) {
        if (tolerate > ignorance) {
          snapshot.addAttempt();
          if (snapshot.status != LivenessStatus.none) {
            snapshot.setStatus(LivenessStatus.none);
            _streamController.sink.add(snapshot);
          }
        }
        tolerate++;
        return;
      }
      if ((faces.first.boundingBox.width / ~image.width).abs() > distance) return;

      if (snapshot.status != LivenessStatus.done) snapshot.setStatus(LivenessStatus.verifying);

      if (snapshot.isStep(faces.first.getFaceDirection())) {
        if (snapshot.isLastStep) {
          snapshot.setStatus(LivenessStatus.done);
        } else {
          snapshot.addStepIndex();
        }
      }
      _streamController.sink.add(snapshot);
    });
  }

  Future<void> stopLiveness() async {
    await _livenessCamera!.stopImageStream();
  }

  Future<double?> compare() async {
    if (_id == null) return null;
    if (_liveness == null) return null;
    var idModel = await _mlService.createModel(_id!);
    var livenessModel = await _mlService.createModel(_liveness!);

    double result = _mlService.euclideanDistance(idModel, livenessModel);

    print(result);
    return result;
  }
}
