import 'dart:typed_data';

import '../../../models/travel_document.dart';
import '../asn1.dart';
part 'data_group_1.dart';
part 'data_group_2.dart';
part 'data_group_11.dart';
part 'data_group_12.dart';
part 'data_group_com.dart';

sealed class DataGroup {
  String get name;

  const DataGroup();

  /// Attempts to decode a DataGroup.
  static DataGroup? decode(ASNObject data) {
    return switch (data.tag) {
      0x61 => DataGroup1.decode(data),
      0x75 => BiometricDG.decode(data, 'face'),
      // 0x63 => BiometricDG.decode(data, 'fingerprint'),
      0x6B => DataGroup11.decode(data),
      0x6C => DataGroup12.decode(data),
      0x60 => DataGroupCom.decode(data),
      _ => null,
    };
  }
}

/// Converts a tag to the corresponding file shortid.
int? tagToDG(int tag) {
  return switch (tag) {
    0x61 => 1,
    0x75 => 2,
    0x63 => 3,
    0x6B => 11,
    0x6C => 12,
    0x6E => 14,
    0x60 => 0x1E,
    _ => null,
  };
}

/// Converts a tag or file shortid to a descriptive name.
String tagToName(int tag) {
  return switch (tag) {
    1 || 0x61 => 'mrz',
    2 || 0x75 => 'biometric_face',
    3 || 0x63 => 'biometric_fingerprint',
    11 || 0x6B => 'additional_personal_details',
    12 || 0x6C => 'additional_document_details',
    14 || 0x6E => 'security_options',
    30 || 0x1E => 'com',
    _ => tag.toRadixString(16).toUpperCase(),
  };
}

/// Returns true if the given tag can be parsed by the library.
bool isTagSupported(int? tag) {
  return switch (tag) {
    0x61 || 0x75 || 0x6B || 0x6C || 0x60 => true,
    _ => false,
  };
}
