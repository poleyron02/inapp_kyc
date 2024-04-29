# InAppKYC Flutter Package

The InAppKYC Flutter package provides developers with a comprehensive solution for implementing Know Your Customer (KYC) verification directly within their Flutter applications. This package leverages machine learning techniques to enable facial recognition and liveness detection, ensuring secure and reliable identity verification.

## Features:

1. **Facial Recognition:** Utilize advanced facial recognition technology to compare the user's face captured via camera with the face on their identification card.

2. **Liveness Detection:** Conduct liveness tests to verify user presence and prevent spoofing, enhancing the security of the KYC process.

3. **Easy Integration:** Simple APIs for seamless integration into Flutter applications, minimizing development effort and time-to-market.

4. **Customizable UI:** Flexibility to customize the user interface to match your application's branding and design aesthetics.

## How to Use:

1. **Initialize InAppKYC:**
  ```dart
  var inAppKYC = await InAppKYC.initialize();
  ```
   
2. **Start KYC Process:**
  ```dart
  await inAppKYC.initID();
  await inAppKYC.initLiveness();
  ```

3. **Capture ID Image:**
  ```dart
  await inAppKYC.processID();
  ```

4. **Capture Liveness Image:**
  ```dart
  await inAppKYC.takePicture(kycResultNotifier);
  ```

5. **Start Liveness Detection:**
  ```dart
  await inAppKYC.startLiveness(kycResultNotifier);
  ```

6. **Compare ID and Liveness Images:**
  ```dart
  double result = await inAppKYC.compare();
  ```

## Sample Usage:
  ```dart
  var inAppKYC = await InAppKYC.initialize();
  await inAppKYC.initID();
  await inAppKYC.initLiveness();
  await inAppKYC.processID();
  await inAppKYC.takePicture(kycResultNotifier);
  await inAppKYC.startLiveness(kycResultNotifier);
  double result = await inAppKYC.compare();
  ```

## Requirements:
* Flutter: >=2.0.0
* Supported Platforms: Android, iOS

**Dependencies:**
* camera: ^0.9.4+5
* google_ml_kit: ^0.7.0
* tflite_flutter: ^0.7.0
