import 'package:camera/camera.dart';
import 'package:inapp_kyc/globals.dart';

enum LivenessStatus {
  none,
  verifying,
  done
}

class LivenessSnapshot {
  LivenessStatus status;
  List<FaceDirection> steps;
  int _stepIndex = 0;
  int attempts;
  XFile? image;

  double get progress => _stepIndex / (steps.length - 1);
  FaceDirection get nextStep => steps[_stepIndex];
  bool get isLastStep => _stepIndex >= steps.length - 1;
  bool isStep(FaceDirection direction) => direction == steps[_stepIndex];

  LivenessSnapshot({
    this.status = LivenessStatus.none,
    required this.steps,
    this.attempts = 0,
    this.image,
  });

  void retake() {
    status = LivenessStatus.none;
    attempts = 0;
    _stepIndex = 0;
    image = null;
  }

  void addStepIndex() => _stepIndex++;
  void addAttempt() {
    if (status == LivenessStatus.none) return;
    _stepIndex = 0;
    attempts++;
  }

  void setImage(XFile bytes) => image = bytes;
  void setStatus(LivenessStatus s) => status = s;
}
