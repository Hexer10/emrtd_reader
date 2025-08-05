
import 'dart:typed_data';


final hexStr = '7F 00 07 02 02 04 01 01';

void main() {
  final bytes = hexStr.split(' ').map((e) => int.parse(e, radix: 16)).toList();
  final oidString = oidToString(Uint8List.fromList(bytes));
  print('OID String: $oidString');
}
String oidToString(Uint8List bytes) {
  if (bytes.isEmpty) {
    throw ArgumentError('Input cannot be empty');
  }

  // Decode the first byte to get the first two nodes
  int firstByte = bytes[0];
  int firstNode = firstByte ~/ 40; // First node (X)
  int secondNode = firstByte % 40; // Second node (Y)

  // Start building the OID string
  List<int> oidParts = [firstNode, secondNode];

  // Decode the remaining bytes
  int value = 0;
  for (int i = 1; i < bytes.length; i++) {
    int byte = bytes[i];

    // If the MSB is set, this is part of a multi-byte value
    if (byte & 0x80 != 0) {
      value = (value << 7) | (byte & 0x7F);
    } else {
      // Last byte of the current value
      value = (value << 7) | byte;
      oidParts.add(value);
      value = 0; // Reset for the next value
    }
  }

  // Convert the OID parts to a string
  return oidParts.join('.');
}