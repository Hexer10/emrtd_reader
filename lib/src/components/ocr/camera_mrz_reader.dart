import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'mrz_recognizer.dart';
import '../../hooks/use_camera_controller.dart';

/// A widget that displays the camera view and processes the image stream to extract MRZ data.
/// When the MRZ data is extracted the [onData] callback is called.
class CameraMRZReader extends HookWidget {
  final void Function(MRZData) onData;
  final CameraDescription camera;
  final DeviceOrientation? orientation;

  const CameraMRZReader(
      {super.key,
      required this.camera,
      required this.onData,
      this.orientation});

  @override
  Widget build(BuildContext context) {
    final cameraController =
        useCameraController(camera, ResolutionPreset.high, enableAudio: false);
    final imageProcessor = useMemoized(() => MrzRecognizer(), const []);

    useEffect(() {
      return imageProcessor.dispose;
    }, const []);

    useEffect(() {
      if (cameraController != null) {
        cameraController.startImageStream((img) async {
          if (imageProcessor.processing) {
            return;
          }
          final result = await imageProcessor.processImage(
            InputImage.fromBytes(
              bytes: img.getNv21Uint8List(),
              metadata: InputImageMetadata(
                size: Size(img.width.toDouble(), img.height.toDouble()),
                rotation: InputImageRotation.rotation0deg,
                format: InputImageFormat.nv21, // only in android
                bytesPerRow: 0, // used in iOS
              ),
            ),
          );
          if (result != null) {
            onData(result);
          }
        });
      }
      return null;
    }, [cameraController, cameraController?.value.isInitialized]);

    useEffect(() {
      if (cameraController != null && orientation != null) {
        cameraController.lockCaptureOrientation(orientation);
      }
      return null;
    }, [cameraController, orientation]);

    if (cameraController == null || !cameraController.value.isInitialized) {
      return const CircularProgressIndicator();
    }

    return CameraPreview(
      cameraController,
    );
  }
}

// From: https://github.com/flutter/flutter/issues/145961#issuecomment-2134763818
extension _Nv21Converter on CameraImage {
  Uint8List getNv21Uint8List() {
    final width = this.width;
    final height = this.height;

    final yPlane = planes[0];
    final uPlane = planes[1];
    final vPlane = planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final numPixels = (width * height * 1.5).toInt();
    final nv21 = List<int>.filled(numPixels, 0);

    // Full size Y channel and quarter size U+V channels.
    var idY = 0;
    var idUV = width * height;
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;
    // Copy Y & UV channel.
    // NV21 format is expected to have YYYYVU packaging.
    // The U/V planes are guaranteed to have the same row stride and pixel stride.
    // getRowStride analogue??
    final uvRowStride = uPlane.bytesPerRow;
    // getPixelStride analogue
    final uvPixelStride = uPlane.bytesPerPixel ?? 0;
    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 0;

    for (int y = 0; y < height; ++y) {
      final uvOffset = y * uvRowStride;
      final yOffset = y * yRowStride;

      for (int x = 0; x < width; ++x) {
        nv21[idY++] = yBuffer[yOffset + x * yPixelStride];

        if (y < uvHeight && x < uvWidth) {
          final bufferIndex = uvOffset + (x * uvPixelStride);
          //V channel
          nv21[idUV++] = vBuffer[bufferIndex];
          //V channel
          nv21[idUV++] = uBuffer[bufferIndex];
        }
      }
    }
    return Uint8List.fromList(nv21);
  }
}
