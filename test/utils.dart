import 'dart:typed_data';

import 'package:emrtd_reader/src/components/nfc/3des.dart';
import 'package:emrtd_reader/src/components/nfc/asn1_utils.dart';
import 'package:emrtd_reader/src/components/nfc/mrtd_interface.dart';
import 'package:emrtd_reader/src/models/travel_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test_isopadding', () {
    final data = Uint8List.fromList([23, 54, 9, 123]);
    final result = data.withPadding();
    expect(result, Uint8List.fromList([23, 54, 9, 123, 128, 0, 0, 0]));
  });
  test('test_checkdigit', () {
    int result = TravelDocument.computeCheckDigit('AB<');
    expect(result + 0x30, equals(51)); // Add 0x30 to convert to ASCII
  });

  test('test_stringXor', () {
    final a = Uint8List.fromList([0, 1, 2, 3, 4]);
    final b = Uint8List.fromList([5, 6, 7, 8, 9]);
    final result = stringXor(a, b);
    expect(result, equals(Uint8List.fromList([5, 7, 5, 11, 13])));
  });

  test('test_lenToBytes', () {
    int value = 180;
    final result = lenToBytes(value);
    expect(result, equals([129, 180]));
  });

  test('test_asn1Tag', () {
    final array = Uint8List.fromList([1, 2, 3, 4]);
    int tag = 19;
    final result = asn1Tag(array, tag);
    expect(result, equals(Uint8List.fromList([19, 4, 1, 2, 3, 4])));
  });

  test('test_tagToByte', () {
    int value = 1530;
    final result = intToBytes(value);
    expect(result, equals(Uint8List.fromList([5, 250])));
  });
}
