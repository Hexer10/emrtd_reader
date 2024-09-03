import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nfc_manager/nfc_manager.dart';

import 'src/pages/camera_loader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MRTD Reader',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('MRTD Reader',
                style: TextStyle(color: Colors.white))),
        body: FutureBuilder<bool>(
          future: NfcManager.instance.isAvailable(),
          builder: (context, snapshot) => switch (snapshot) {
            AsyncSnapshot(connectionState: ConnectionState.done, data: true) =>
              const MainView(),
            AsyncSnapshot(connectionState: ConnectionState.done, data: false) =>
              const Center(child: Text('NFC is not available on this device')),
            AsyncSnapshot(
              connectionState: ConnectionState.done,
              error: Object()
            ) =>
              const Center(child: Text('An error occurred')),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class MainView extends HookWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CameraLoader()),
        );
      },
      child: Container(
        width: size.width,
        height: size.height,
        decoration: appDecoration,
        child: Center(
          child: Text(
            'Tap anywhere to\nstart scanning!',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 30, color: Colors.black.withOpacity(0.8)),
          ),
        ),
      ),
    );
  }
}

final appGradient = LinearGradient(
  colors: [Colors.blue[200]!, Colors.blue[100]!],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

final appDecoration = BoxDecoration(
  gradient: appGradient,
);
