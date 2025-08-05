import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/equality.dart';
import 'package:crypto/crypto.dart';
import 'package:emrtd_reader/src/components/nfc/apdu/apdu_command.dart';
import 'package:emrtd_reader/src/components/nfc/asn1.dart';
import 'package:emrtd_reader/src/components/nfc/datagroups/data_group.dart';
import 'package:emrtd_reader/src/components/nfc/mrtd_interface.dart';
import 'package:emrtd_reader/src/components/nfc/nfc_card.dart';
import 'package:emrtd_reader/src/components/nfc/3des.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:pointycastle/digests/sha1.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:emrtd_reader/src/components/nfc/diffie_hellman.dart' as dh;
import 'package:emrtd_reader/src/components/nfc/asn1_utils.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('MRTD Scanner')),
        body: const AppBody(),
      ),
    );
  }
}

class AppBody extends HookWidget {
  const AppBody({super.key});

  void _restartSession() {
    NfcManager.instance.stopSession();
    NfcManager.instance.startSession(
      pollingOptions: NfcPollingOption.values.toSet(),
      onDiscovered: (card) async {
        final isoDep = IsoDepAndroid.from(card);
        if (isoDep == null) {
          return;
        }

        final cie = MRTDInterface(
            NFCCard(({required Uint8List data}) => isoDep.transceive(data)));
//
        await cie.authenticate(can: '123456');

        await cie.initialSelect();
        final x = await cie.extractData();
        print(x);

        NfcManager.instance.stopSession();
        return;//
        // Try to read EF.CardAccess

        // Select EF.CardAccess
        // await cie.send(ApduCommand(cla: 0x00, ins: 0xA4, p1: 0x02, p2: 0x0C, lc: 0x02, data: Uint8List.fromList([0x2F, 0x01])));
        await cie.send(ApduCommand(
            cla: 0x00,
            ins: 0xA4,
            p1: 0x02,
            p2: 0x0C,
            lc: 0x02,
            data: Uint8List.fromList([0x01, 0x1C])));

        final r = await cie.send(
            ApduCommand(cla: 0x00, ins: 0xB0, p1: 0x00, p2: 0x00, le: 0x06));
        final len = _parseLength(r);
        final data2 = await cie.send(
            ApduCommand(cla: 0x00, ins: 0xB0, p1: 0x00, p2: 0x00, le: len));
        var asn = ASN1(data2)..prettyPrint();
        final sub = asn.root[0x30]!;
        final prot = sub[0x06]!;
        final b64 = base64Encode(prot.bytes);
        print('Card Access Protocol: $b64');
        final dg14 = DataGroup14.decode(asn.root);
        print(dg14);

        final sec = dg14.securityInfos[0];

        // Fix MSE:Set AT command structure - properly ASN.1 encode the data
        final protocolOid = asn1Tag(sec.protocol.bytes, 0x80);
        final pswType = asn1Tag([0x02], 0x83); // 0x02 = CAN

        final mseData = Uint8List.fromList([...protocolOid, ...pswType]);

        // MSE:Set AT
        await cie.send(ApduCommand(
            cla: 0x00,
            ins: 0x22,
            p1: 0xC1,
            p2: 0xA4,
            lc: mseData.length,
            data: mseData));

        // Now get encrypted nonce
        const can = '123456';

        // First General Authenticate - request encrypted nonce
        print('First GA - data: 7C 00');
        var resp = await cie.send(const ApduCommand(
            cla: 0x10,
            ins: 0x86,
            p1: 0x00,
            p2: 0x00,
            lc: 0x02,
            data: [0x7C, 0x00],
            le: 0x00));
        print(
            'First GA response: ${resp.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
        asn = ASN1(resp)..prettyPrint();

        // Extract encrypted nonce from response
        final encryptedNonce = asn.root[0x80]!.bytes;

        // nonce key is SHA1(can || 00000003)
        final canBytes = Uint8List.fromList(utf8.encode(can));
        final nonceKey = sha1
            .convert([...canBytes, 0x00, 0x00, 0x00, 0x03])
            .bytes
            .take(16)
            .toList();

        final nonce = desDec(Uint8List.fromList(nonceKey), encryptedNonce);
        print('Nonce: ${nonce.toHexString()}');

        final algo1 = dh.DiffieHellman(dh.standardDHParam2Group,
            dh.standardDHParam2Prime, dh.standardDHParam2Order);
        final key1 = algo1.generateKey();

        // Second General Authenticate - send ephemeral public key
        final keyPayload = asn1Tag(key1.publicKey.toList(), 0x81);
        final gaData2 = asn1Tag(keyPayload, 0x7C);

        print('Second GA - key1.publicKey length: ${key1.publicKey.length}');
        print(
            'Second GA - keyPayload: ${keyPayload.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
        print(
            'Second GA - gaData2: ${gaData2.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

        print(
            'Second GA command: 10 86 00 00 ${gaData2.length.toRadixString(16).padLeft(2, '0')} ${gaData2.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')} 00');
        resp = await cie.send(ApduCommand(
          cla: 0x10,
          ins: 0x86,
          p1: 0x00,
          p2: 0x00,
          lc: gaData2.length,
          data: gaData2,
          le: 0x00,
        ));

        print(
            'Second GA response: ${resp.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

        // Extract other party's public key from response
        final respAsn1 = ASN1(resp);
        respAsn1.prettyPrint();
        final otherPubKey1 = respAsn1.root[0x82]!.bytes;

        // Calculate shared secret and do mapping
        final secret1 = algo1.computeKey(key1.privateKey, otherPubKey1);
        // TODO: Implement mapping with nonce
        // algo1.doMapping(secret1, nonce);
        final algo2 = algo1.map(secret1, nonce);

        final key2 = algo2.generateKey();

        // Third General Authenticate - send second ephemeral public key
        final keyPayload2 = asn1Tag(key2.publicKey.toList(), 0x83);
        final gaData3 = asn1Tag(keyPayload2, 0x7C);

        resp = await cie.send(ApduCommand(
          cla: 0x10,
          ins: 0x86,
          p1: 0x00,
          p2: 0x00,
          lc: gaData3.length,
          data: gaData3,
          le: 0x00,
        ));

        // Extract other party's second public key
        final respAsn2 = ASN1(resp);
        final otherPubKey2 = respAsn2.root[0x84]!.bytes;

        // Calculate final shared secret
        final secret2 = algo2.computeKey(key2.privateKey, otherPubKey2);

        // Derive session keys
        final kSessMac = sha1
            .convert([...secret2, 0x00, 0x00, 0x00, 0x02])
            .bytes
            .take(16)
            .toList()
            .toUint8List();
        final kSessEnc = sha1
            .convert([...secret2, 0x00, 0x00, 0x00, 0x01])
            .bytes
            .take(16)
            .toList()
            .toUint8List();

        // Create authentication data and token
        final oidTag = sec.protocol.bytes;
        final authData = asn1Tag(
            [...asn1Tag(oidTag, 0x06), ...asn1Tag(otherPubKey2.toList(), 0x84)],
            0x7F49);
        // TODO: Implement MAC calculation
        final authToken = macEnc(kSessMac, authData, true);

        // Fourth General Authenticate - send authentication token (final command, class 0x00)
        final authTokenPayload = asn1Tag(authToken, 0x85);
        final gaData4 = asn1Tag(authTokenPayload, 0x7C);

        resp = await cie.send(ApduCommand(
          cla: 0x00, // Final command, not chained
          ins: 0x86,
          p1: 0x00,
          p2: 0x00,
          lc: gaData4.length,
          data: gaData4,
          le: 0x00,
        ));
/*

*/
        final otherAuthData = asn1Tag(
            [...asn1Tag(oidTag, 0x06), ...asn1Tag(otherPubKey2.toList(), 0x84)],
            0x7F49);
        final otherAuthToken = ASN1(resp).root[0x86]!.bytes;
        final otherAuthTokenCalc = macEnc(kSessMac, otherAuthData, true);

        // Verify that MAC match
        if (ListEquality().equals(otherAuthTokenCalc, otherAuthToken)) {
          print('MAC mismatch');
        } else {
          print('MAC match');
        }

        NfcManager.instance.stopSession();
      },
    );
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

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      WakelockPlus.enable();
    }, []);
    return Center(
        child: Row(
      children: [
        const Text('Hold travel document near NFC scanner'),
        ElevatedButton(
          onPressed: _restartSession,
          child: const Text('Restart'),
        ),
      ],
    ));
  }
}

extension on List<int> {
  Uint8List toUint8List() => Uint8List.fromList(this);
}
