part of 'data_group.dart';

///  Machine Readable Zone Information
class DataGroupCom extends DataGroup {
  @override
  String get name => 'com';

  final String unicodeVersion;
  final String ldsVersion;
  final List<int> tags;

  const DataGroupCom(this.unicodeVersion, this.ldsVersion, this.tags);

  DataGroupCom.decode(ASNObject data)
      : assert(data.tag == 0x60),
        unicodeVersion = data[0x5F36]!.strValue,
        ldsVersion = data[0x5F01]!.strValue,
        tags = data[0x5C]!.bytes;

  @override
  String toString() {
    return 'DataGroupCom(unicodeVersion: $unicodeVersion, ldsVersion: $ldsVersion, tags: ${tags.map((e) => e.toRadixString(16).padLeft(2, '0')).toList()})';
  }
}
