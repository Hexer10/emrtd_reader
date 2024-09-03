import 'dart:typed_data';

abstract interface class NFCCardInterface {
  Future<Uint8List> transceive({required Uint8List data});
}

typedef TransceiveFunction = Future<Uint8List> Function(
    {required Uint8List data});

/// Simple implementation of the [NFCCardInterface] that uses a function to transceive data.
class NFCCard implements NFCCardInterface {
  final TransceiveFunction _transceiveFn;

  @override
  Future<Uint8List> transceive({required Uint8List data}) {
    return _transceiveFn(data: data);
  }

  NFCCard(TransceiveFunction transceiveFn) : _transceiveFn = transceiveFn;
}
