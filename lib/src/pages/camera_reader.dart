import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../components/ocr/camera_mrz_reader.dart';
import 'nfc_reader.dart';

class CameraReader extends StatelessWidget {
  final CameraDescription camera;

  const CameraReader({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Scan your ID / Passport'),
      ),
      body: Container(
        decoration: appDecoration,
        width: size.width,
        height: size.height,
        child: Column(
          children: [
            const Spacer(),
            SizedBox(
              height: size.height - 120,
              child: CameraMRZReader(
                camera: camera,
                onData: (data) {
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => NFCReader(mrz: data),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
