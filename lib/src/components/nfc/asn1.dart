//ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:collection/collection.dart';

typedef Int2 = (int, int);

class ASN1 {
  List<int> data;
  late ASNObject root;

  ASN1(this.data) {
    root = parse().$1;
  }

  int getClass(int offset) {
    // Select only the first 2 bits
    return (data[offset] & 0xC0) >> 6; //0b11000000
  }

  int getType(int offset) {
    // Select only the 3rd bit
    return (data[offset] & 32) >> 5; // 0b00100000
  }

  Int2 getTag(int offset) {
    final rawData = [data[offset]];
    // Check if the last 5 bits are all 1
    if ((rawData[0] & 0x0F) == 0x0F) {
      rawData.add(data[offset + 1]);
    }

    return (rawData.toInt(), offset + rawData.length);
  }

  Int2 parseLength(int offset) {
    if (data[offset] == 0x80) {
      int count = 0;
      while (data[offset + count] != 0x00 && data[offset + count + 1] != 0x00) {
        count += 1;
      }
      return (count, offset + 1);
    }

    if (data[offset] < 0x80) {
      return (data[offset], offset + 1);
    }

    int lenBytes = data[offset] - 0x80;
    int length = 0;

    for (int i = 0; i < lenBytes; i++) {
      length = length << 8;
      length = length | data[offset + i + 1];
    }

    return (length, offset + lenBytes + 1);
  }

  (Uint8List, int) getBytes(int offset, int num) {
    return (
      Uint8List.fromList(data.sublist(offset, offset + num)),
      offset + num
    );
  }

  (ASNObject, int) parse([int offset = 0]) {
    int type = getType(offset);

    final (tag, tagOffset) = getTag(offset);
    final (length, lenOffset) = parseLength(tagOffset);
    final (bytes, lastOffset) = getBytes(lenOffset, length);

    final children = <ASNObject>[];
    if (type != 0) {
      var childrenBytes = 0;
      while (childrenBytes < length) {
        final (childData, newChildrenOffset) = parse(lenOffset + childrenBytes);
        childrenBytes = newChildrenOffset - lenOffset;
        children.add(childData);
      }
    }

    return (
      ASNObject(
          tag: tag,
          type: type,
          objClass: getClass(offset),
          length: length,
          bytes: bytes,
          children: children),
      lastOffset
    );
  }

  void prettyPrint([ASNObject? obj, int indent = 0]) {
    obj ??= root;

    final buf = StringBuffer();
    if (indent > 0) {
      buf.write('${'|  ' * (indent - 1)}|--');
    }
    buf.write(obj.describe());

    // ignore: avoid_print
    print(buf.toString());

    for (var child in obj.children) {
      prettyPrint(child, indent + 1);
    }
  }
}

extension on int {
  String get hex => '0x${toRadixString(16).padLeft(2, '0')}';
}

enum AsnType {
  Primitive(0),
  Constructed(1),
  Invalid(-1);

  const AsnType(this.value);

  final int value;

  static AsnType fromValue(int value) {
    return values.firstWhere((element) => element.value == value,
        orElse: () => Invalid);
  }
}

enum AsnClass {
  Universal(0),
  Application(1),
  ContextSpecific(2),
  Private(3),
  Invalid(-1);

  const AsnClass(this.value);

  final int value;

  static AsnClass fromValue(int value) {
    return values.firstWhere((element) => element.value == value,
        orElse: () => Invalid);
  }
}

class ASNObject {
  final int tag;
  final int type;
  final int objClass;
  final int length;
  final Uint8List bytes;
  final List<ASNObject> children;

  AsnType get asnType => AsnType.fromValue(type);

  AsnClass get asnClass => AsnClass.fromValue(objClass);

  const ASNObject({
    required this.tag,
    required this.type,
    required this.objClass,
    required this.length,
    required this.bytes,
    required this.children,
  });

  bool verify(List<int> data) {
    return data.equals(bytes);
  }

  ASNObject? getChild<T>(int tag, [int? orTag]) {
    return children.firstWhereOrNull(
        (element) => element.tag == tag || element.tag == orTag);
  }

  int get intValue => bytes.toInt();

  String get strValue => bytes.str;

  /// Alias for [getChild]
  ASNObject? operator [](int tag) => getChild(tag);

  String describe() {
    if (asnClass != AsnClass.Universal) {
      return _simpleDescription();
    }

    final (type, value) = decodeValue();
    if (asnType == AsnType.Constructed) {
      return '[${tag.hex}]: $type - ${children.length} children';
    }
    if (value == null) {
      return '[${tag.hex}]: $type - $length bytes';
    }

    return '[${tag.hex}]: $type: $value';
  }

  String _simpleDescription() {
    final buf = StringBuffer();
    buf.write('[${tag.hex}]: ${asnType.name}, ${asnClass.name}, $length bytes');
    if (children.isNotEmpty) {
      buf.write(' - ${children.length} children');
    } else {
      buf.write(' - int: ${bytes.toInt()}, str: ${bytes.str}');
    }
    return buf.toString();
  }

  (String, Object?) decodeValue() {
    if (asnClass != AsnClass.Universal) {
      return ('Specific', null);
    }
    return switch (tag) {
      0x01 => ('BOOL', bytes[0] == 0x01),
      0x02 => ('INTEGER', bytes.toInt()),
      0x03 => ('BIT STRING', utf8.decode(bytes, allowMalformed: true)),
      0x04 => ('OCTET STRING', null),
      0x05 => ('NULL', null),
      0x06 => ('OBJECT IDENTIFIER', null),
      0x0C => ('UTF8 STRING', utf8.decode(bytes, allowMalformed: true)),
      0x13 => ('PRINTABLE STRING', utf8.decode(bytes, allowMalformed: true)),
      0x14 => ('TELETEX STRING', utf8.decode(bytes, allowMalformed: true)),
      0x17 => ('UTC time', utf8.decode(bytes, allowMalformed: true)),
      0x30 => ('SEQUENCE', null),
      0x31 => ('SET', null),
      _ => ('UNKNOWN', null),
    };
  }
}

extension on List<int> {
  int toInt() {
    return switch (length) {
      1 => this[0],
      2 => this[0] << 8 | this[1],
      3 => this[0] << 16 | this[1] << 8 | this[2],
      4 => this[0] << 24 | this[1] << 16 | this[2] << 8 | this[3],
      5 =>
        this[0] << 32 | this[1] << 24 | this[2] << 16 | this[3] << 8 | this[4],
      6 => this[0] << 40 |
          this[1] << 32 |
          this[2] << 24 |
          this[3] << 16 |
          this[4] << 8 |
          this[5],
      7 => this[0] << 48 |
          this[1] << 40 |
          this[2] << 32 |
          this[3] << 24 |
          this[4] << 16 |
          this[5] << 8 |
          this[6],
      8 => this[0] << 56 |
          this[1] << 48 |
          this[2] << 40 |
          this[3] << 32 |
          this[4] << 24 |
          this[5] << 16 |
          this[6] << 8 |
          this[7],
      _ => -1,
    };
  }

  String get str {
    return utf8.decode(this, allowMalformed: true);
  }
}

extension TagCheck on ASNObject {
  void checkTag(int expectedTag, [int? orTag]) {
    if (tag != expectedTag && (tag != orTag || orTag == null)) {
      throw Exception(
          'Expected tag $expectedTag${orTag != null ? 'or $orTag,' : ''} got $tag ');
    }
  }
}
