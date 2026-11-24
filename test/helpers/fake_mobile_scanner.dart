import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Camera of `mobile_scanner` without a camera: the real [MobileScanner]
/// widget runs, and [scan] delivers a QR code as if the camera had read it.
///
/// [install] it for the test; it restores the previous instance at teardown.
class FakeMobileScanner extends MobileScannerPlatform
    with MockPlatformInterfaceMixin {
  final StreamController<BarcodeCapture?> _barcodes =
      StreamController.broadcast();

  /// Makes this fake the platform implementation until the end of the test.
  void install() {
    final previous = MobileScannerPlatform.instance;
    MobileScannerPlatform.instance = this;
    addTearDown(() {
      MobileScannerPlatform.instance = previous;
      // The camera session owner is static: never leak it to the next test.
      MobileScannerController.resetPlatformSessionOwner();
      unawaited(_barcodes.close());
    });
  }

  /// Delivers [code] as a decoded QR code.
  void scan(String code) {
    _barcodes.add(
      BarcodeCapture(
        barcodes: [Barcode(rawValue: code, format: BarcodeFormat.qrCode)],
      ),
    );
  }

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Widget buildCameraView() => const SizedBox.expand();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      numberOfCameras: 1,
      size: Size(1080, 1920),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> dispose() async {}
}
