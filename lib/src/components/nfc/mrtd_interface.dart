import 'dart:math' as mrtd_interface;

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../auth_credential.dart';
import 'apdu/exceptions.dart';
import 'crypto/3des.dart';
import 'apdu/apdu_command.dart';
import 'apdu/apdu_response.dart';
import 'asn/asn1.dart';
import 'asn/asn1_utils.dart';
import 'datagroups/data_group.dart';
import 'crypto/diffie_hellman.dart' as dh;
import 'nfc_card.dart';

typedef ProgressFunction = void Function(int current, int total);

/// Interface for interacting with the ID cards, passports, or any document
/// that adheres to the ICAO 9303 standard.
class MRTDInterface {
  final NFCCardInterface _card;

  Uint8List? _kSessMac;
  Uint8List? _kSessEnc;

  final _rnd = mrtd_interface.Random();
  var _seq = <int>[];

  MRTDInterface(this._card);

  Future<Uint8List> send(ApduCommand command) async {
    final auth = _kSessEnc != null && _kSessMac != null;
    if (auth) {
      return await _sendSM(command);
    }
    final resp = (await _card.sendRaw(command.bytes));
    final swCode =
        resp.sw.map((e) => e.toRadixString(16)).join().padRight(4, '0');
    if (swCode != '9000') {
      throw ApduException(swCode);
    }
    return resp.response;
  }

  /// Get security information from the card (EF.CardAccess).
  Future<DataGroup14?> _getCardSecurity() async {
    try {
      // Select EF.CardAccess
      await send(ApduCommand(
          cla: 0x00,
          ins: 0xA4,
          p1: 0x02,
          p2: 0x0C,
          lc: 0x02,
          data: Uint8List.fromList([0x01, 0x1C])));

      // Read EF.CardAccess file header to get length
      final r = await send(const ApduCommand(
          cla: 0x00, ins: 0xB0, p1: 0x00, p2: 0x00, le: 0x06));
      final len = _parseLength(r);

      // Read the full EF.CardAccess file
      final data = await send(
          ApduCommand(cla: 0x00, ins: 0xB0, p1: 0x00, p2: 0x00, le: len));

      final asn = ASN1(data);
      return DataGroup14.decode(asn.root);
    } catch (e) {
      // If any error occurs (e.g., file not found), PACE is not supported.
      return null;
    }
  }

  /// Authenticates with the card.
  ///
  /// Provide either [MRZAuthentication] or [CANAuthentication] as the [auth] parameter.
  /// PACE authentication is preferred if the card supports it.
  /// BAC is use as a fallback if PACE fails or is not supported AND [MRZAuthentication] was provided.
  ///
  /// If this is called while already authenticated, it will return immediately.
  Future<void> authenticate(AuthCredential auth) async {
    if (_kSessEnc != null && _kSessMac != null) {
      // Already authenticated
      return;
    }
    // Try PACE first
    final cardSecurity = await _getCardSecurity();
    if (cardSecurity != null && cardSecurity.securityInfos.isNotEmpty) {
      try {
        await _authenticatePACE(auth, cardSecurity.securityInfos[0]);

        // Select to prepare for reading data groups - BAC does already do that while authenticating.
        await _initialSelect();
        return;
      } on ApduException catch (e) {
        if (e.code == '6300') {
          throw AuthException();
        }
        // PACE failed, will try to fall back to BAC if possible
        if (auth is! MRZAuthentication) {
          // If no MRZ data, rethrow the error as we can't fallback to BAC
          rethrow;
        }
      }
    }

    // Fallback or default to BAC
    if (auth is MRZAuthentication) {
      try {
        return _authenticateBAC(auth);
      } on ApduException catch (e) {
        if (e.code == '6300') {
          throw AuthException();
        }
        rethrow;
      }
    }

    // If we are here, authentication was not possible
    throw AuthException("No valid authentication method provided.");
  }

  /// Authenticates using Password Authenticated Connection Establishment (PACE).
  Future<void> _authenticatePACE(AuthCredential auth, SecurityInfo sec) async {
    // MSE:Set AT command for PACE
    final protocolOid = asn1Tag(sec.protocol.bytes, 0x80);
    final pswTypeTag =
        asn1Tag([auth.type], 0x83); // 0x02 = CAN, 0x01 = MRZ Seed
    final mseData = Uint8List.fromList([...protocolOid, ...pswTypeTag]);

    await send(ApduCommand(
        cla: 0x00,
        ins: 0x22,
        p1: 0xC1,
        p2: 0xA4,
        lc: mseData.length,
        data: mseData));

    // GA 1: Get Nonce from card
    var resp = await send(const ApduCommand(
        cla: 0x10,
        ins: 0x86,
        p1: 0x00,
        p2: 0x00,
        lc: 0x02,
        data: [0x7C, 0x00],
        le: 0x00));
    var asn = ASN1(resp);
    final encryptedNonce = asn.root[0x80]!.bytes;

    // Derive key to decrypt nonce
    final nonceKey = sha1
        .convert([...auth.seed, 0x00, 0x00, 0x00, 0x03])
        .bytes
        .take(16)
        .toList();

    final nonce = desDec(Uint8List.fromList(nonceKey), encryptedNonce);

    // --- DH Key Exchange Step 1 ---
    final algo1 = dh.DiffieHellman(dh.standardDHParam2Group,
        dh.standardDHParam2Prime, dh.standardDHParam2Order);
    final key1 = algo1.generateKey();

    // GA 2: Send our ephemeral public key
    final keyPayload1 = asn1Tag(key1.publicKey, 0x81);
    final gaData2 = asn1Tag(keyPayload1, 0x7C);

    resp = await send(ApduCommand(
        cla: 0x10,
        ins: 0x86,
        p1: 0x00,
        p2: 0x00,
        lc: gaData2.length,
        data: gaData2,
        le: 0x00));
    final respAsn1 = ASN1(resp);
    final otherPubKey1 = respAsn1.root[0x82]!.bytes;

    // --- DH Key Exchange Step 2 (Mapping) ---
    final secret1 = algo1.computeKey(key1.privateKey, otherPubKey1);
    final algo2 = algo1.map(secret1, nonce);
    final key2 = algo2.generateKey();

    // GA 3: Send our second ephemeral public key
    final keyPayload2 = asn1Tag(key2.publicKey.toList(), 0x83);
    final gaData3 = asn1Tag(keyPayload2, 0x7C);
    resp = await send(ApduCommand(
        cla: 0x10,
        ins: 0x86,
        p1: 0x00,
        p2: 0x00,
        lc: gaData3.length,
        data: gaData3,
        le: 0x00));
    final respAsn2 = ASN1(resp);
    final otherPubKey2 = respAsn2.root[0x84]!.bytes;

    // Calculate final shared secret
    final secret2 = algo2.computeKey(key2.privateKey, otherPubKey2);

    // Derive session keys
    final kSessEnc = sha1
        .convert([...secret2, 0x00, 0x00, 0x00, 0x01])
        .bytes
        .take(16)
        .toList()
        .toUint8List();
    final kSessMac = sha1
        .convert([...secret2, 0x00, 0x00, 0x00, 0x02])
        .bytes
        .take(16)
        .toList()
        .toUint8List();

    // --- Authentication Token ---
    final protocolTag = sec.protocol.tag;
    final oidTag = sec.protocol.bytes;
    // The token we send is created using the card's public key (otherPubKey2)
    // to prove to the card that we have derived the session keys correctly.
    final authDataToSend = asn1Tag(
        [...asn1Tag(oidTag, protocolTag), ...asn1Tag(otherPubKey2, 0x84)], 0x7F49);

    final authToken = macEnc(kSessMac, authDataToSend, true);

    // GA 4: Send authentication token
    final authTokenPayload = asn1Tag(authToken, 0x85);
    final gaData4 = asn1Tag(authTokenPayload, 0x7C);
    resp = await send(ApduCommand(
        cla: 0x00,
        ins: 0x86,
        p1: 0x00,
        p2: 0x00,
        lc: gaData4.length,
        data: gaData4,
        le: 0x00));

    // Verify card's authentication token
    final receivedAuthTokenASN = ASN1(resp);
    final receivedAuthToken = receivedAuthTokenASN.root[0x86]!.bytes;

    // The card's authentication token is computed over our public key (key2.publicKey),
    // so we must use it here to calculate the expected token.
    final otherAuthData = asn1Tag(
        [...asn1Tag(oidTag, 0x06), ...asn1Tag(key2.publicKey, 0x84)], 0x7F49);

    final calculatedCardAuthToken = macEnc(kSessMac, otherAuthData, true);

    if (!const ListEquality()
        .equals(receivedAuthToken, calculatedCardAuthToken)) {
      throw AuthException(
          "PACE authentication failed: MAC mismatch on card's token.");
    }

    _kSessEnc = kSessEnc;
    _kSessMac = kSessMac;
    _seq = Uint8List(8);
  }

  /// Unlocks the card using the data contained in the MRZ (BAC).
  /// [birthStr] is the birth date in YYMMDD format
  /// [expireStr] is the expiration date in YYMMDD format
  /// [docNoStr] is the id (number) of the card.
  Future<void> _authenticateBAC(MRZAuthentication auth) async {
    await _initialSelect();
    final rndMrtd = await _getRandom();

    final kSeed = auth.seed.sublist(0, 16);

    final encKey = sha1
        .convert([...kSeed, 0x00, 0x00, 0x00, 0x01])
        .bytes
        .sublist(0, 16)
        .toUint8List();

    final macKey = sha1
        .convert([...kSeed, 0x00, 0x00, 0x00, 0x02])
        .bytes
        .sublist(0, 16)
        .toUint8List();

    final rndIs1 = _getRandomBytes(8);
    final kIs = _getRandomBytes(16);

    final eIs1 = desEnc(
        encKey, [...rndIs1, ...rndMrtd.response, ...kIs].toUint8List(), false);
    final eIsMac = macEnc(macKey, eIs1, true);

    final command = ApduCommand(
        cla: 0x00,
        ins: 0x82,
        p1: 0x00,
        p2: 0x00,
        lc: 0x28,
        data: [...eIs1, ...eIsMac],
        le: 0x28);

    final respMutualAuth = (await _card.send(command)).response;

    final kIsMac = macEnc(macKey, respMutualAuth.sublist(0, 32), true);
    final kIsMac2 = respMutualAuth.sublist(respMutualAuth.length - 8);
    if (!kIsMac.every((element) => kIsMac2.contains(element))) {
      throw AuthException();
    }

    final decResp = desDec(encKey, respMutualAuth.sublist(0, 32));
    final kMrtd = decResp.sublist(decResp.length - 16);
    final kSessSeed = stringXor(kIs, kMrtd);

    _kSessEnc = sha1
        .convert([...kSessSeed, 0x00, 0x00, 0x00, 0x01])
        .bytes
        .toUint8List()
        .sublist(0, 16);
    _kSessMac = sha1
        .convert([...kSessSeed, 0x00, 0x00, 0x00, 0x02])
        .bytes
        .toUint8List()
        .sublist(0, 16);

    _seq = [...decResp.sublist(4, 8), ...decResp.sublist(12, 16)];
  }

  Future<List<int>> readDg(int numDg, {ProgressFunction? progress}) async {
    final somma = (numDg + 0x80);

    final readLenCmd =
        ApduCommand(cla: 0x0C, ins: 0xB0, p1: somma, p2: 0x00, le: 0x04);

    // If not authenticated, send the command without the secure message
    final auth = _kSessEnc != null && _kSessMac != null;
    final chunkLen = auth
        ? await _sendSM(readLenCmd)
        : (await _card.sendRaw(readLenCmd.bytes)).response;
    final maxLen = _parseLength(chunkLen);

    progress?.call(0, maxLen);

    final data = <int>[];

    assert(maxLen <= 0xFFFF);
    while (data.length < maxLen) {
      final readLen = mrtd_interface.min(0xe0, maxLen - data.length);
      final command = ApduCommand(
          cla: 0x0C,
          ins: 0xB0,
          p1: (data.length >> 8) & 0xFF,
          p2: data.length & 0xFF,
          le: readLen);

      final chunk = auth
          ? await _sendSM(command)
          : (await _card.sendRaw(command.bytes)).response;

      data.addAll(chunk);

      progress?.call(data.length, maxLen);
    }

    return data;
  }

  /// Reads the COM DataGroup of the card to extract the available files and the reads all the supported ones.
  /// Returns a [Map] where the keys are the file (descriptive) name and the value is the parsed [DataGroup],
  /// if key is null the DataGroup is not supported by the library or an error as occurred while reading.
  ///
  /// If [throwOnError] is true when a error is thrown while reading a file the key won't be set to null
  /// and the error won't be handled.
  ///
  /// [onProgress] is called when a new read file read, [progress] is the % of the file that has been read.
  Future<Map<String, DataGroup?>> extractData(
      {void Function(String name, int progress)? onProgress,
      bool throwOnError = false}) async {
    final mainDGData = await readDg(30, progress: (int current, int total) {
      onProgress?.call('com', current * 100 ~/ total);
    });

    final mainDG = DataGroupCom.decode(ASN1(mainDGData).root);
    final results = <String, DataGroup?>{};

    for (var byte in mainDG.tags.reversed) {
      final dg = tagToDG(byte);
      if (!isTagSupported(byte) || dg == null) {
        results[tagToName(byte)] = null;
        continue;
      }

      try {
        final data = await readDg(dg, progress: (int current, int total) {
          onProgress?.call(tagToName(byte), current * 100 ~/ total);
        });
        final dgObj = DataGroup.decode(ASN1(data).root);
        results[dgObj?.name ?? tagToName(byte)] = dgObj;
      } catch (e) {
        if (throwOnError) {
          rethrow;
        }
        results[tagToName(byte)] = null;
      }
    }

    return results;
  }

  /// Sends an "initial selection" APDU to the card preparing it for the BAC authentication or reading.
  Future<ApduResponse> _initialSelect() {
    const command = ApduCommand(
        cla: 0x00,
        ins: 0xA4,
        p1: 0x04,
        p2: 0x0C,
        lc: 0x07,
        data: [0xA0, 0x00, 0x00, 0x02, 0x47, 0x10, 0x01]);
    return _card.send(command);
  }

  /// Increment the message sequence number
  void _incrementSeq([int? index]) {
    index ??= _seq.length - 1;
    if (_seq[index] == 0xff) {
      _seq[index] = 0;
      _incrementSeq(index - 1);
    } else {
      _seq[index]++;
    }
  }

  /// Sends an APDU to the CIE requesting a random number
  Future<ApduResponse> _getRandom() {
    const command =
        ApduCommand(cla: 0x00, ins: 0x84, p1: 0x00, p2: 0x00, le: 0x08);
    return _card.send(command);
  }

  Uint8List _secureMessage(List<int> apdu) {
    assert(_kSessEnc != null && _kSessMac != null, 'Session keys not set');
    assert(apdu.length >= 4);

    final [cla, ins, p1, p2, ...other] = apdu;

    int? le;
    int? lc;
    List<int>? data;
    if (other.length == 1) {
      le = other.first;
    } else {
      lc = other[0];
      data = other.skip(1).take(lc).toList();

      // Still one byte left to read
      if (other.length - data.length == 2) {
        // Account for le and lc
        le = other.last;
      }
      assert((data.length == other.length - 1 && (le == null)) ||
          (data.length == other.length - 2));
    }

    assert(data == null || (data.length == lc));
    assert(cla == 0x0C);

    Uint8List? encryptedData;

    // Check if there is data to encrypt
    if (lc != null) {
      encryptedData = desEnc(_kSessEnc!, Uint8List.fromList(data!), true);
    }

    _incrementSeq();
    final header = [..._seq, ...apdu.sublist(0, 4)];

    final even = ins % 2 == 0;
    final formattedData = encryptedData != null
        ? asn1Tag([if (even) 0x01, ...encryptedData], even ? 0x87 : 0x85)
        : null;

    final macData = [
      ...header,
      ...header.padding,
      if (formattedData != null) ...formattedData,
      if (le != null) ...[0x97, 0x01, le]
    ];
    final smMac = macEnc(_kSessMac!, Uint8List.fromList(macData), true);

    final finalData = [
      if (encryptedData != null) ...[
        encryptedData.length,
        ...encryptedData,
      ],
      if (le != null) ...[0x97, 0x01, le],
      0x8E,
      0x08,
      ...smMac
    ];
    return [cla, ins, p1, p2, finalData.length, ...finalData, 0x00]
        .toUint8List();
  }

  Uint8List _respSecureMessage(
      Uint8List keyEnc, Uint8List keySig, Uint8List resp) {
    _incrementSeq();

    final asn = ASN1(resp);
    final encData = asn.root.bytes.sublist(1);

    if (encData.length > 1) {
      return desDec(keyEnc, encData).removePadding();
    }

    return Uint8List(0);
  }

  int _parseLength(Uint8List data) {
    assert(data.isNotEmpty);
    var dataLen = data.length;

    var readPos = 2;

    var byteLen = data[1];
    if (byteLen > 128) {
      var lenlen = byteLen - 128;
      byteLen = 0;
      for (var i = 0; i < lenlen; i++) {
        assert(readPos != dataLen, 'parseLength: incomplete length');

        byteLen = (byteLen << 8) | data[readPos];
        readPos += 1;
      }
    }

    return readPos + byteLen;
  }

  Uint8List _getRandomBytes(int length) {
    return Uint8List.fromList(List.generate(length, (_) => _rnd.nextInt(256)));
  }

  /// Send a Secure Message to the card and automatically decodes the message.
  Future<Uint8List> _sendSM(ApduCommand command) async {
    final sm = _secureMessage(command.bytes);
    final response = await _card.sendRaw(sm);
    return _respSecureMessage(_kSessEnc!, _kSessMac!, response.response);
  }
}

extension on NFCCardInterface {
  Future<ApduResponse> send(ApduCommand command) async {
    return sendRaw(command.bytes);
  }

  Future<ApduResponse> sendRaw(Uint8List bytes) async {
    final reply = await transceive(data: bytes);
    final resp = ApduResponse(reply);
    final swCode =
        resp.sw.map((e) => e.toRadixString(16)).join().padRight(4, '0');
    if (swCode != '9000') {
      throw ApduException(swCode);
    }
    return resp;
  }
}

/// Performs a XOR between each elements of [a] and [b]. They must be of the same length.
/// Used in [MRTDInterface._authenticateBAC] to compute the kSeed.
@visibleForTesting
Uint8List stringXor(Uint8List a, Uint8List b) {
  if (a.length != b.length) {
    throw StateError('lengths must be equal');
  }
  final result = Uint8List(a.length);
  for (var i = 0; i < a.length; i++) {
    result[i] = a[i] ^ b[i];
  }
  return result;
}

extension on List<int> {
  Uint8List toUint8List() => Uint8List.fromList(this);
}
