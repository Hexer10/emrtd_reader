/// This files contains function related to 3DS encryption used by the ICAO 9303 MRTD standard.

import 'dart:typed_data';
import 'package:pointycastle/pointycastle.dart';

/// Encrypts `data` using `masterKey` as the key and TripleDES with CBC and no padding as the algorithm.
///
/// - [masterKey] must be of length 8, 16, or 24 bytes.
/// - [data] will be padded to a multiple of 8 bytes if necessary and [withPadding] is true.
Uint8List desEnc(Uint8List masterKey, Uint8List data,
    [bool withPadding = false]) {
  if (withPadding) {
    data = data.withPadding();
  }
  assert(data.length % 8 == 0, 'Data length must be a multiple of 8');

  // Prepare a 24-byte key for TripleDES
  late final Uint8List key24;
  if (masterKey.length == 8) {
    // If key is 8 bytes, repeat it to create a 24-byte key
    key24 = Uint8List(24);
    key24.setRange(0, 8, masterKey);
    key24.setRange(8, 16, masterKey);
    key24.setRange(16, 24, masterKey);
  } else if (masterKey.length == 16) {
    // If key is 16 bytes, repeat the first 8 bytes to create a 24-byte key
    key24 = Uint8List(24);
    key24.setRange(0, 16, masterKey);
    key24.setRange(16, 24, masterKey);
  } else {
    // If key is already 24 bytes, use it directly
    key24 = masterKey.sublist(0, 24);
  }

  final key = KeyParameter(key24);
  final iv =
      Uint8List(8); // Initialization vector (IV) for CBC mode, set to zeros
  final params = ParametersWithIV<KeyParameter>(key, iv);

  // Initialize the cipher for encryption with TripleDES in CBC mode
  final cipher = BlockCipher('DESede/CBC');
  cipher.init(true, params);

  // Process each 8-byte block of data
  final cipherText = Uint8List(data.length);
  for (var i = 0; i < data.length; i += 8) {
    final block = data.sublist(i, i + 8);
    final cipherBlock = cipher.process(block);
    cipherText.setRange(i, i + 8, cipherBlock);
  }

  return cipherText;
}

/// Computes a Message Authentication Code (MAC) using TripleDES.
///
/// This function performs encryption and decryption using parts of the provided key to generate a MAC.
///
/// - [key] A key used for generating the MAC, must be at least 8 bytes long.
/// - [data] The data to generate a MAC for, it will be padded to a multiple of 8 bytes if necessary and [withPadding] is true.
///
/// Returns the MAC.
Uint8List macEnc(Uint8List key, Uint8List data, [bool withPadding = false]) {
  assert(key.length >= 8, 'Key length must be at least 8 bytes');
  if (withPadding) {
    data = data.withPadding();
  }
  assert(data.length % 8 == 0, 'Data length must be a multiple of 8');

  final k1 = key.sublist(0, 8);

  // Extract the next 8 bytes for the decryption key, if available
  final k2Start = key.length >= 16 ? 8 : 0;
  final k2 = key.sublist(k2Start, k2Start + 8);

  // Extract the last 8 bytes for the final encryption key, if available
  final k3Start = key.length >= 24 ? 16 : 0;
  final k3 = key.sublist(k3Start, k3Start + 8);

  // Perform TripleDES encryption and decryption to generate the MAC
  final mid1 = desEnc(k1, data); // First encryption
  final mid2 =
      desDec(k2, mid1.sublist(mid1.length - 8)); // Decrypt the last block
  final mid3 = desEnc(k3, mid2.sublist(0, 8)); // Final encryption

  return mid3; // Return the final MAC value
}

/// Decrypts `data` using `masterKey` as the key and TripleDES with CBC and no padding as the algorithm.
///
/// - [masterKey] The key used for decryption, must be either 8, 16, or 24 bytes long.
/// - [data] The ciphertext data to decrypt, must be a multiple of 8 bytes in length.
///
/// Returns the decrypted data.
Uint8List desDec(Uint8List masterKey, Uint8List data) {
  assert(data.length % 8 == 0, 'Data length must be a multiple of 8');

  late final Uint8List key24;
  if (masterKey.length == 8) {
    key24 = Uint8List(24);
    key24.setRange(0, 8, masterKey);
    key24.setRange(8, 16, masterKey);
    key24.setRange(16, 24, masterKey);
  } else if (masterKey.length == 16) {
    key24 = Uint8List(24);
    key24.setRange(0, 16, masterKey);
    key24.setRange(16, 24, masterKey);
  } else {
    key24 = masterKey.sublist(0, 24);
  }

  final key = KeyParameter(key24);
  final iv = Uint8List(8);
  final params = ParametersWithIV<KeyParameter>(key, iv);

  // Initialize the cipher for decryption with TripleDES in CBC mode
  final cipher = BlockCipher('DESede/CBC');
  cipher.init(false, params);

  // Process each 8-byte block of data
  final cipherText = Uint8List(data.length);
  for (var i = 0; i < data.length; i += 8) {
    final block = data.sublist(i, i + 8);
    final cipherBlock = cipher.process(block);
    cipherText.setRange(i, i + 8, cipherBlock);
  }

  return cipherText;
}

extension IsoPad on List<int> {
  static int blockSize = 8;

  /// Returns the padding bytes only (without the actual data)
  List<int> get padding {
    return [
      0x80,
      for (var i = 0; i < blockSize - ((length + 1) % blockSize); i++) 0x00
    ];
  }

  /// ISO padding requires adding a 0x80 byte after the data and then enough 0x00
  /// to reach the a multiple of the block size
  Uint8List withPadding() {
    return Uint8List.fromList([
      ...this,
      0x80,
      for (var i = 0; i < blockSize - ((length + 1) % blockSize); i++) 0x00
    ]);
  }
}

extension IsoPad2 on Uint8List {
  /// Returns the data without the ISO padding
  Uint8List removePadding() {
    if (isEmpty) {
      return this;
    }
    final idx = lastIndexOf(0x80);
    return idx == -1 ? this : sublist(0, idx);
  }
}
