part of 'data_group.dart';

/// Additional Personal Detail(s)
class DataGroup11 extends DataGroup {
  @override
  String get name => 'additional_personal_details';

  /// Formatted as SURNAME<<NAME
  /// Multiple names are separated by < characters
  final String? fullName;
  final int? otherNamesCount;
  final String? otherNames;

  final String? personalNumber;

  /// Formatted as YYYYMMDD
  final String? dateOfBirth;

  /// Formatted as CITY<PROVINCE
  final String? placeOfBirth;

  /// Formatted as ADDRESS<CITY<PROVINCE
  final String? address;
  final String? telephone;
  final String? profession;
  final String? title;
  final String? personalSummary;

  /// Compressed image
  final String? proofOfCitizenship;
  final String? otherValidTDNumbers;
  final String? custodyInformation;

  const DataGroup11({
    required this.fullName,
    required this.otherNamesCount,
    required this.otherNames,
    required this.personalNumber,
    required this.dateOfBirth,
    required this.placeOfBirth,
    required this.address,
    required this.telephone,
    required this.profession,
    required this.title,
    required this.personalSummary,
    required this.proofOfCitizenship,
    required this.otherValidTDNumbers,
    required this.custodyInformation,
  });

  DataGroup11.decode(ASNObject data)
      : assert(data.tag == 0x6B),
        fullName = data[0x5F0E]?.strValue,
        otherNamesCount = data[0xA0]?[0x02]?.intValue,
        otherNames = data[0xA0]?[0x5F0F]?.strValue,
        personalNumber = data[0x5F10]?.strValue,
        dateOfBirth = data[0x5F2B]?.strValue,
        placeOfBirth = data[0x5F11]?.strValue,
        address = data[0x5F42]?.strValue,
        telephone = data[0x5F12]?.strValue,
        profession = data[0x5F13]?.strValue,
        title = data[0x5F14]?.strValue,
        personalSummary = data[0x5F15]?.strValue,
        proofOfCitizenship = data[0x5F16]?.strValue,
        otherValidTDNumbers = data[0x5F17]?.strValue,
        custodyInformation = data[0x5F18]?.strValue;

  @override
  String toString() {
    final buf = StringBuffer('DataGroup11(');
    if (fullName != null) {
      buf.write('fullName: $fullName, ');
    }
    if (otherNamesCount != null) {
      buf.write('otherNamesCount: $otherNamesCount, ');
    }
    if (otherNames != null) {
      buf.write('otherNames: $otherNames, ');
    }
    if (personalNumber != null) {
      buf.write('personalNumber: $personalNumber, ');
    }
    if (dateOfBirth != null) {
      buf.write('dateOfBirth: $dateOfBirth, ');
    }
    if (placeOfBirth != null) {
      buf.write('placeOfBirth: $placeOfBirth, ');
    }
    if (address != null) {
      buf.write('address: $address, ');
    }
    if (telephone != null) {
      buf.write('telephone: $telephone, ');
    }
    if (profession != null) {
      buf.write('profession: $profession, ');
    }
    if (title != null) {
      buf.write('title: $title, ');
    }
    if (personalSummary != null) {
      buf.write('personalSummary: $personalSummary, ');
    }
    if (proofOfCitizenship != null) {
      buf.write('proofOfCitizenship: $proofOfCitizenship, ');
    }
    if (otherValidTDNumbers != null) {
      buf.write('otherValidTDNumbers: $otherValidTDNumbers, ');
    }
    if (custodyInformation != null) {
      buf.write('custodyInformation: $custodyInformation, ');
    }
    buf.write(')');
    return buf.toString();
  }
}
