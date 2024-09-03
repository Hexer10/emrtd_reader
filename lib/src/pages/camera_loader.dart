import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../hooks/use_memo_future.dart';
import 'camera_reader.dart';

class CameraLoader extends HookWidget {
  const CameraLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final cameras = useMemoFuture(availableCameras);

    useEffect(() {
      if (cameras != null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CameraReader(
                  camera: cameras.firstWhere(
                      (e) => e.lensDirection == CameraLensDirection.back,
                      orElse: () => cameras.first)),
            ),
          );
        });
      }
      return null;
    }, [cameras]);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading cameras...'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
