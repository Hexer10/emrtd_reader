import 'dart:typed_data';

/// Wrapper for an APDU command.
class ApduCommand {
  final int cla;
  final int ins;
  final int p1;
  final int p2;
  final int? lc;
  final List<int>? data;
  final int? le;

  const ApduCommand(
      {required this.cla,
      required this.ins,
      required this.p1,
      required this.p2,
      this.lc,
      this.data,
      this.le})
      : assert(data == null && lc == null || data != null && lc != null,
            'If data exists lc must match it\'s length');

  /// Get the actual bytes for this command.
  /// Note: not tested for lc longer than 1 byte.
  Uint8List get bytes {
    assert(data == null || (data!.length == lc));
    final byteList = [cla, ins, p1, p2];
    if (lc != null) {
      if (lc! < 0x100) {
        byteList.add(lc!);
      } else {
        byteList.add(0x00);
        byteList.add((lc! >> 8) & 0xFF);
        byteList.add(lc! & 0xFF);
      }
    }
    if (data != null) {
      byteList.addAll(data!);
    }
    if (le != null) {
      if (le! < 0x100) {
        byteList.add(le!);
      } else if (le! < 0x10000) {
        byteList.add(0x00);
        byteList.add((le! >> 8) & 0xFF);
        byteList.add(le! & 0xFF);
      }
    }
    return Uint8List.fromList(byteList);
  }

  /// Construct a [ApduCommand] from raw bytes.
  static ApduCommand decode(List<int> byteList) {
    if (byteList.length < 4) {
      throw ArgumentError(
          "APDU command must have at least 4 bytes for CLA, INS, P1, and P2");
    }

    // Extract mandatory fields
    final cla = byteList[0];
    final ins = byteList[1];
    final p1 = byteList[2];
    final p2 = byteList[3];

    var index = 4;

    // Extract Lc
    int? lc;
    List<int>? data;
    if (index < byteList.length) {
      lc = byteList[index];
      if (lc == 0x00) {
        // Possible extended Lc
        if (index + 2 < byteList.length &&
            (byteList[index + 1] != 0x00 || byteList[index + 2] != 0x00)) {
          lc = (byteList[index + 1] << 8) | byteList[index + 2];
          index += 3;
        } else {
          lc = 0;
          index++;
        }
      } else {
        index++;
      }
    }

    // Extract command data
    if (lc != null && lc > 0) {
      if (index + lc <= byteList.length) {
        data = byteList.sublist(index, index + lc);
        index += lc;
      } else {
        index--; // Reset index to include Lc in the data
        lc = null;
      }
    }

    // Extract Le
    int? le;
    if (index < byteList.length) {
      int remainingBytes = byteList.length - index;
      if (remainingBytes == 1) {
        le = byteList[index];
        index += 1;
      } else if (remainingBytes == 2) {
        le = (byteList[index] << 8) | byteList[index + 1];
        index += 2;
      } else if (remainingBytes == 3 && byteList[index] == 0x00) {
        le = (byteList[index + 1] << 8) | byteList[index + 2];
        index += 3;
      }
    }

    return ApduCommand(
        cla: cla, ins: ins, p1: p1, p2: p2, lc: lc, data: data, le: le);
  }

  /// Get a description of this command by parsing the [ins] byte.
  @override
  String toString() {
    final descr = '(cla=${cla.toRadixString(16).padLeft(2, '0')}, '
        'ins=${ins.toRadixString(16).padLeft(2, '0')}, '
        'p1=${p1.toRadixString(16).padLeft(2, '0')}, '
        'p2=${p2.toRadixString(16).padLeft(2, '0')}, '
        'lc=$lc, data=${data?.toHexString()}, le=$le)';

    final command = switch (ins) {
      0x64 => 'GET CHALLENGE',
      0xA4 => 'SELECT',
      0x82 => 'AUTHENTICATE',
      0xB0 => 'READ BINARY',
      0xB2 => 'READ RECORD',
      0xCA => 'GET DATA',
      0xD0 => 'WRITE BINARY',
      0xD2 => 'WRITE RECORD',
      _ => 'UNKNOWN',
    };
    return '$command $descr';
  }
}

extension on List<int> {
  String toHexString() {
    return map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(' ')
        .toUpperCase();
  }
}
