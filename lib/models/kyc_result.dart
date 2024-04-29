import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:inapp_kyc/globals.dart';

class KYCResult {
  File? id;
  IDType? idType;
  String? otherID;
  File? face;
  double? distance;
  int retry;

  bool get isComplete => id != null && (idType != null || (idType == IDType.other && (otherID != null || otherID!.isNotEmpty))) && face != null && distance != null;

  KYCResult({
    this.id,
    this.idType,
    this.otherID,
    this.face,
    this.distance,
    this.retry = 0,
  });

  int get index => id == null
      ? 0
      : face == null
          ? 1
          : 2;
}

class KYCResultNotifier extends ValueNotifier<KYCResult> {
  KYCResultNotifier(super.value);

  void setId(File? file) {
    value.id = file;
    notifyListeners();
  }

  void setIdType(IDType? type) {
    value.idType = type;
    notifyListeners();
  }

  void setOtherId(String? string) {
    if (string!.isEmpty) string = null;
    value.otherID = string;
    notifyListeners();
  }

  void setFace(File? file) {
    value.face = file;
    notifyListeners();
  }

  void setDistance(double? d) {
    value.distance = d;
    notifyListeners();
  }

  void retry() {
    value.retry++;
    notifyListeners();
  }

  void reset() {
    value.id = null;
    value.idType = null;
    value.otherID = null;
    value.face = null;
    value.distance = null;
    value.retry = 0;
    notifyListeners();
  }
}
