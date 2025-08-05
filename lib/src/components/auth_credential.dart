import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../models/travel_document.dart';

abstract class AuthCredential {
  /// The type of authentication credential, e.g., MRZ, CAN, etc.
  /// 0x01 for MRZ, 0x02 for CAN.
  int get type;

  Uint8List get seed;
}

class CANAuthentication implements AuthCredential {
  @override
  final int type = 0x02;

  @override
  final Uint8List seed;

  CANAuthentication({required String can}) : seed = _getBACSeed(can);

  static Uint8List _getBACSeed(String can) {
    if (can.length != 6) {
      throw ArgumentError('CAN must be 6 characters long');
    }
    return Uint8List.fromList(ascii.encode(can));
  }
}

class MRZAuthentication implements AuthCredential {
  @override
  final int type = 0x01;

  @override
  final Uint8List seed;

  MRZAuthentication({
    required String birthStr,
    required String expireStr,
    required String docNoStr,
  }) : seed = _getBACSeed(birthStr, expireStr, docNoStr);

  static Uint8List _getBACSeed(
      String birthStr, String expireStr, String docNoStr) {
    if (birthStr.length != 6 ||
        expireStr.length != 6 ||
        docNoStr.length < 5 ||
        docNoStr.length > 9) {
      throw ArgumentError(
          'Invalid MRZ data: birthStr, expireStr must be 6 characters long, '
          'docNoStr must be between 5 and 9 characters long.');
    }

    final birth = birthStr.codeUnits;
    final expire = expireStr.codeUnits;
    final docNo = docNoStr.codeUnits;

    final birthSeed = [
      ...birth,
      TravelDocument.computeCheckDigit(birthStr) + 0x30
    ];
    final expireSeed = [
      ...expire,
      TravelDocument.computeCheckDigit(expireStr) + 0x30
    ];
    final docSeed = [
      ...docNo,
      TravelDocument.computeCheckDigit(docNoStr) + 0x30
    ];

    // The SHA1 Hash of the MRZ data
    return sha1
        .convert([...docSeed, ...birthSeed, ...expireSeed])
        .bytes
        .sublist(0, 16)
        .toUint8List();
  }
}

extension on List<int> {
  Uint8List toUint8List() => Uint8List.fromList(this);
}
