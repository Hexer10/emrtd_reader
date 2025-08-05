part of 'data_group.dart';

//// Security Options
class DataGroup14 extends DataGroup {
  @override
  String get name => 'security_options';

  final List<SecurityInfo> securityInfos;

  const DataGroup14(this.securityInfos);

  static DataGroup14 decode(ASNObject data) {
    final securityInfos = data.children
        .map((e) => SecurityInfo(
            protocol: e.children[0],
            requiredData: e.children[1],
            optionalData: e.children[2]))
        .toList();
    return DataGroup14(securityInfos);
  }

  @override
  String toString() {
    return 'DataGroup14(securityInfos: ${securityInfos.map((e) => e.toString()).join(', ')})';
  }
}

class SecurityInfo {
  final ASNObject protocol;
  final ASNObject requiredData;
  final ASNObject optionalData;

  const SecurityInfo({
    required this.protocol,
    required this.requiredData,
    required this.optionalData,
  });

  @override
  String toString() {
    return 'SecurityInfo(protocol: ${protocol.bytes.toHexString()}, requiredData: ${requiredData.intValue}, optionalData: ${optionalData.intValue})';
  }
}
