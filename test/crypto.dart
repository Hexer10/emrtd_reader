import 'dart:typed_data';

import 'package:emrtd_reader/src/components/nfc/3des.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MAC ENC Tests', () {
    test('test_mac_enc_key_8', () {
      final key =
          Uint8List.fromList([0x22, 0x88, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]);
      final data = Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80]);

      final result = macEnc(key, data, false);
      expect(result,
          equals(Uint8List.fromList([23, 178, 198, 248, 245, 165, 8, 101])));
    });

    test('test_mac_enc_key_9', () {
      final key = Uint8List.fromList(
          [0x22, 0x88, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x00]);
      final data = Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80]);

      final result = macEnc(key, data, false);
      expect(result,
          equals(Uint8List.fromList([23, 178, 198, 248, 245, 165, 8, 101])));
    });

    test('test_mac_enc_key_16', () {
      final key = Uint8List.fromList([
        0x22,
        0x88,
        0xAA,
        0xBB,
        0xCC,
        0xDD,
        0xEE,
        0xFF,
        0x00,
        0xAA,
        0xBB,
        0xCC,
        0xDD,
        0xEE,
        0xFF,
        0x00
      ]);
      final data = Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80]);

      final result = macEnc(key, data, false);
      expect(result,
          equals(Uint8List.fromList([247, 80, 35, 172, 217, 38, 86, 53])));
    });

    test('test_mac_enc_key_17', () {
      final key = Uint8List.fromList([
        0x22,
        0x88,
        0xAA,
        0xBB,
        0xCC,
        0xDD,
        0xEE,
        0xFF,
        0x00,
        0xAA,
        0xBB,
        0xCC,
        0xDD,
        0xEE,
        0xFF,
        0x00,
        0x11
      ]);
      final data = Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80]);

      final result = macEnc(key, data, false);
      expect(result,
          equals(Uint8List.fromList([247, 80, 35, 172, 217, 38, 86, 53])));
    });
  });

  group('DES ENC Tests', () {
    test('test_des_enc_key_8', () {
      final key =
          Uint8List.fromList([0x22, 0x88, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]);
      final data = Uint8List.fromList([
        10,
        20,
        30,
        40,
        50,
        60,
        70,
        80,
        10,
        20,
        30,
        40,
        50,
        60,
        70,
        80,
        10,
        20,
        30,
        40,
        50,
        60,
        70,
        80
      ]);

      final result = desEnc(key, data, false);
      expect(
          result,
          equals(Uint8List.fromList([
            23,
            178,
            198,
            248,
            245,
            165,
            8,
            101,
            165,
            213,
            156,
            236,
            227,
            206,
            48,
            11,
            109,
            53,
            186,
            176,
            219,
            134,
            34,
            71
          ])));
    });

    test('test_des_enc_key_16', () {
      final key = Uint8List.fromList([
        0x22,
        0x88,
        0xAA,
        0xBB,
        0xCC,
        0xDD,
        0xEE,
        0xFF,
        0x00,
        0xAA,
        0xBB,
        0xCC,
        0xDD,
        0xEE,
        0xFF,
        0x00
      ]);
      final data = Uint8List.fromList([
        10,
        20,
        30,
        40,
        50,
        60,
        70,
        80,
        10,
        20,
        30,
        40,
        50,
        60,
        70,
        80,
        10,
        20,
        30,
        40,
        50,
        60,
        70,
        80
      ]);

      final result = desEnc(key, data, false);
      expect(
          result,
          equals(Uint8List.fromList([
            247,
            80,
            35,
            172,
            217,
            38,
            86,
            53,
            206,
            1,
            123,
            91,
            36,
            118,
            195,
            248,
            142,
            69,
            45,
            123,
            74,
            67,
            63,
            61
          ])));
    });
  });

  group('DES DEC Tests', () {
    test('test_des_dec_key_8', () {
      final encData = Uint8List.fromList([
        23,
        178,
        198,
        248,
        245,
        165,
        8,
        101,
        165,
        213,
        156,
        236,
        227,
        206,
        48,
        11,
        109,
        53,
        186,
        176,
        219,
        134,
        34,
        71
      ]);
      final key =
          Uint8List.fromList([0x22, 0x88, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF]);

      final result = desDec(key, encData);
      expect(
          result,
          equals(Uint8List.fromList([
            10,
            20,
            30,
            40,
            50,
            60,
            70,
            80,
            10,
            20,
            30,
            40,
            50,
            60,
            70,
            80,
            10,
            20,
            30,
            40,
            50,
            60,
            70,
            80
          ])));
    });

    test('test_des_dec_key_16', () {
      final encData = Uint8List.fromList([
        247,
        80,
        35,
        172,
        217,
        38,
        86,
        53,
        206,
        1,
        123,
        91,
        36,
        118,
        195,
        248,
        142,
        69,
        45,
        123,
        74,
        67,
        63,
        61
      ]);
      final key = Uint8List.fromList([
        0x22,
        0x88,
        0xAA,
        0xBB,
        0xCC,
        0xDD,
        0xEE,
        0xFF,
        0x00,
        0xAA,
        0xBB,
        0xCC,
        0xDD,
        0xEE,
        0xFF,
        0x00
      ]);

      final result = desDec(key, encData);
      expect(
          result,
          equals(Uint8List.fromList([
            10,
            20,
            30,
            40,
            50,
            60,
            70,
            80,
            10,
            20,
            30,
            40,
            50,
            60,
            70,
            80,
            10,
            20,
            30,
            40,
            50,
            60,
            70,
            80
          ])));
    });
  });
}
