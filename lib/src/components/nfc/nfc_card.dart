import 'dart:typed_data';

import 'package:emrtd_reader/src/components/nfc/apdu/apdu_command.dart';

abstract interface class NFCCardInterface {
  Future<Uint8List> transceive({required Uint8List data});
}

typedef TransceiveFunction = Future<Uint8List> Function(
    {required Uint8List data});

/// Simple implementation of the [NFCCardInterface] that uses a function to transceive data.
class NFCCard implements NFCCardInterface {
  final TransceiveFunction _transceiveFn;

  @override
  Future<Uint8List> transceive({required Uint8List data}) async {
    print('Send: ${data.toHexString()}');
    final resp = await _transceiveFn(data: data);
    print('Recv: ${resp.toHexString()}');
    return resp;
  }

  NFCCard(TransceiveFunction transceiveFn) : _transceiveFn = transceiveFn;
}
