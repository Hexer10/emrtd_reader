import 'dart:typed_data';

import 'package:emrtd_reader/src/components/nfc/asn1.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ASN1_01', () {
    var data = Uint8List.fromList([0x04, 0x05, 0x12, 0x34, 0x56, 0x78, 0x90]);
    var parser = ASN1(data);
    expect(parser.root.tag, equals(4));
    expect(parser.root.length, equals(5));
    expect(parser.root.bytes, equals([0x12, 0x34, 0x56, 0x78, 0x90]));
  });

  test('ASN1_02', () {
    var data = Uint8List.fromList(
        [0xdf, 0x82, 0x02, 0x05, 0x12, 0x34, 0x56, 0x78, 0x90]);
    var parser = ASN1(data);
    expect(parser.root.tag, equals(258));
    expect(parser.root.length, equals(5));
    expect(parser.root.bytes, equals([0x12, 0x34, 0x56, 0x78, 0x90]));
  });

  test('ASN1_03', () {
    var data = Uint8List.fromList(
        [0x30, 0x80, 0x04, 0x03, 0x56, 0x78, 0x90, 0x00, 0x00]);
    var parser = ASN1(data);
    expect(parser.root.tag, equals(16));
    expect(parser.root.length, equals(5));
    expect(parser.root.bytes, equals([0x04, 0x03, 0x56, 0x78, 0x90]));
  });
}
