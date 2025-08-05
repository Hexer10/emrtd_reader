import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// A class to represent a key pair (private and public keys).
class KeyPair {
  final Uint8List privateKey;
  final Uint8List publicKey;

  KeyPair(this.privateKey, this.publicKey);
}

class DiffieHellman {
  final Uint8List group;
  final Uint8List prime;
  final Uint8List order;

  DiffieHellman(this.group, this.prime, this.order);

  /// Generates a Diffie-Hellman key pair (private and public keys).
  KeyPair generateKey() {
/*    // Remove leading zeros from the prime
    while (prime.isNotEmpty && prime[0] == 0) {
      prime = prime.sublist(1);
    }*/

    // Generate private key
    final primeSize = prime.length;
    final privateKey = Uint8List(primeSize);
    final rnd = Random.secure();

    for (int i = primeSize - 20; i < primeSize; i++) {
      privateKey[i] = rnd.nextInt(256); // Random byte
    }
    privateKey[primeSize - 20] = 1; // Ensure the private key is non-zero

    // Compute public key: group^privateKey mod prime
    final groupBigInt = _uint8ListToBigInt(group);
    final privateKeyBigInt = _uint8ListToBigInt(privateKey);
    final primeBigInt = _uint8ListToBigInt(prime);

    final publicKeyBigInt = groupBigInt.modPow(privateKeyBigInt, primeBigInt);
    final publicKey = _bigIntToUint8List(publicKeyBigInt, primeSize);

    return KeyPair(privateKey, publicKey);
  }

  /// Computes the shared key using the other party's public key.
  Uint8List computeKey(Uint8List privateKey, Uint8List dhOtherPub) {
/*    // Remove leading zeros from the prime
    while (prime.isNotEmpty && prime[0] == 0) {
      prime = prime.sublist(1);
    }*/

    // Compute shared key: dhOtherPub^privateKey mod prime
    final dhOtherPubBigInt = _uint8ListToBigInt(dhOtherPub);
    final privateKeyBigInt = _uint8ListToBigInt(privateKey);
    final primeBigInt = _uint8ListToBigInt(prime);

    final sharedKeyBigInt =
        dhOtherPubBigInt.modPow(privateKeyBigInt, primeBigInt);
    var sharedKey = _bigIntToUint8List(sharedKeyBigInt, prime.length);

    if (sharedKey.length != prime.length) {
      Uint8List paddedKey = Uint8List(prime.length);
      int paddingSize = prime.length - sharedKey.length;
      paddedKey.setRange(paddingSize, prime.length, sharedKey);
      sharedKey = paddedKey;
    }
    return sharedKey;

  }

  DiffieHellman map(Uint8List secret, Uint8List nonce) {
    final tmp = group.toBigInt().modPow(nonce.toBigInt(), prime.toBigInt());
    final tmp2 = tmp * secret.toBigInt();
    final newGroup = tmp2.remainder(prime.toBigInt());
    return DiffieHellman(
      _bigIntToUint8List(newGroup, group.length),
      prime,
      order,
    );
  }
}

extension on Uint8List {
  BigInt toBigInt() {
    var result = BigInt.zero;
    for (int byte in this) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }
}


/// Converts a `Uint8List` to a `BigInt`.
BigInt _uint8ListToBigInt(Uint8List bytes) {
  var result = BigInt.zero;
  for (int byte in bytes) {
    result = (result << 8) | BigInt.from(byte);
  }
  return result;
}

/// Converts a `BigInt` to a `Uint8List` of the specified size.
Uint8List _bigIntToUint8List(BigInt value, int size) {
  final bytes = <int>[];
  var temp = value;
  while (temp > BigInt.zero) {
    bytes.insert(0, (temp & BigInt.from(0xFF)).toInt());
    temp = temp >> 8;
  }

  // Pad with leading zeros if necessary
  while (bytes.length < size) {
    bytes.insert(0, 0);
  }

  return Uint8List.fromList(bytes);
}

/// Diffie-Hellman standard parameters as constants.
final Uint8List standardDHParam2Prime = _hexStringToUint8List(
    "87A8E61D B4B6663C FFBBD19C 65195999 8CEEF608 660DD0F2 5D2CEED4 435E3B00 E00DF8F1 D61957D4 FAF7DF45 61B2AA30 16C3D911 34096FAA 3BF4296D 830E9A7C 209E0C64 97517ABD 5A8A9D30 6BCF67ED 91F9E672 5B4758C0 22E0B1EF 4275BF7B 6C5BFC11 D45F9088 B941F54E B1E59BB8 BC39A0BF 12307F5C 4FDB70C5 81B23F76 B63ACAE1 CAA6B790 2D525267 35488A0E F13C6D9A 51BFA4AB 3AD83477 96524D8E F6A167B5 A41825D9 67E144E5 14056425 1CCACB83 E6B486F6 B3CA3F79 71506026 C0B857F6 89962856 DED4010A BD0BE621 C3A3960A 54E710C3 75F26375 D7014103 A4B54330 C198AF12 6116D227 6E11715F 693877FA D7EF09CA DB094AE9 1E1A1597");

final Uint8List standardDHParam2Group = _hexStringToUint8List(
    "3FB32C9B 73134D0B 2E775066 60EDBD48 4CA7B18F 21EF2054 07F4793A 1A0BA125 10DBC150 77BE463F FF4FED4A AC0BB555 BE3A6C1B 0C6B47B1 BC3773BF 7E8C6F62 901228F8 C28CBB18 A55AE313 41000A65 0196F931 C77A57F2 DDF463E5 E9EC144B 777DE62A AAB8A862 8AC376D2 82D6ED38 64E67982 428EBC83 1D14348F 6F2F9193 B5045AF2 767164E1 DFC967C1 FB3F2E55 A4BD1BFF E83B9C80 D052B985 D182EA0A DB2A3B73 13D3FE14 C8484B1E 052588B9 B7D2BBD2 DF016199 ECD06E15 57CD0915 B3353BBB 64E0EC37 7FD02837 0DF92B52 C7891428 CDC67EB6 184B523D 1DB246C3 2F630784 90F00EF8 D647D148 D4795451 5E2327CF EF98C582 664B4C0F 6CC41659");

final Uint8List standardDHParam2Order = _hexStringToUint8List(
    "8CF83642 A709A097 B4479976 40129DA2 99B1A47D 1EB3750B A308B0FE 64F5FBD3");

/// Converts a hexadecimal string to a Uint8List.
Uint8List _hexStringToUint8List(String hexString) {
  hexString = hexString.replaceAll(' ', ''); // Remove spaces
  List<int> bytes = [];
  for (int i = 0; i < hexString.length; i += 2) {
    String byteString = hexString.substring(i, i + 2);
    bytes.add(int.parse(byteString, radix: 16));
  }
  return Uint8List.fromList(bytes);
}
