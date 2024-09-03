import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

/// Add ASN.1 tag to data
Uint8List asn1Tag(List<int> data, int tag) {
  return Uint8List.fromList(
      [...intToBytes(tag), ...lenToBytes(data.length), ...data]);
}

@visibleForTesting
List<int> intToBytes(int value) {
  return switch (value) {
    <= 0xff => [value],
    <= 0xffff => [value >> 8, value & 0xff],
    <= 0xffffff => [value >> 16, value >> 8 & 0xff, value & 0xff],
    <= 0xffffffff => [
        value >> 24,
        value >> 16 & 0xff,
        value >> 8 & 0xff,
        value & 0xff
      ],
    _ => throw ArgumentError('Tag too large', 'value'),
  };
}

@visibleForTesting
List<int> lenToBytes(int value) {
  return switch (value) {
    < 0x80 => [value],
    <= 0xff => [0x81, value],
    <= 0xffff => [0x82, value >> 8, value & 0xff],
    <= 0xffffff => [0x83, value >> 16, value >> 8 & 0xff, value & 0xff],
    <= 0xffffffff => [
        0x84,
        value >> 24,
        value >> 16 & 0xff,
        value >> 8 & 0xff,
        value & 0xff
      ],
    _ => throw ArgumentError('Length too large', 'value'),
  };
}
