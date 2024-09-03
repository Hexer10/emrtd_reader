part of 'data_group.dart';

///  Additional Document Detail(s)
class DataGroup12 extends DataGroup {
  @override
  String get name => 'additional_document_details';

  final String? issuingAuthority;
  final String? dateOfIssue;
  final String? endorsementsOrObservations;
  final String? taxOrExitRequirements;

  /// Formatted as yyyymmddhhmmss
  final String? documentPersonalizationDate;
  final String? documentPersonalizationSerialNumber;
  final Uint8List? imageOfFrontDocument;
  final Uint8List? imageOfRearDocument;
  final List<String> otherPersons;

  DataGroup12(
      {required this.issuingAuthority,
      required this.dateOfIssue,
      required this.endorsementsOrObservations,
      required this.taxOrExitRequirements,
      required this.documentPersonalizationDate,
      required this.documentPersonalizationSerialNumber,
      required this.imageOfFrontDocument,
      required this.imageOfRearDocument,
      required this.otherPersons});

  DataGroup12.decode(ASNObject data)
      : assert(data.tag == 0x6C),
        issuingAuthority = data[0x5F19]?.strValue,
        dateOfIssue = data[0x5F26]?.strValue,
        endorsementsOrObservations = data[0x5F1B]?.strValue,
        taxOrExitRequirements = data[0x5F1C]?.strValue,
        documentPersonalizationDate = data[0x5F55]?.strValue,
        documentPersonalizationSerialNumber = data[0x5F56]?.strValue,
        imageOfFrontDocument = data[0x5F1D]?.bytes,
        imageOfRearDocument = data[0x5F1E]?.bytes,
        otherPersons = data[0xA0]
                ?.children
                .where((e) => e.tag == 0x5F1A)
                .map((e) => e.strValue)
                .toList() ??
            [];

  @override
  String toString() {
    final buf = StringBuffer('DataGroup12(');
    if (issuingAuthority != null) {
      buf.write('issuingAuthority: $issuingAuthority, ');
    }
    if (dateOfIssue != null) {
      buf.write('dateOfIssue: $dateOfIssue, ');
    }
    if (endorsementsOrObservations != null) {
      buf.write('endorsementsOrObservations: $endorsementsOrObservations, ');
    }
    if (taxOrExitRequirements != null) {
      buf.write('taxOrExitRequirements: $taxOrExitRequirements, ');
    }
    if (documentPersonalizationDate != null) {
      buf.write('documentPersonalizationDate: $documentPersonalizationDate, ');
    }
    if (documentPersonalizationSerialNumber != null) {
      buf.write(
          'documentPersonalizationSerialNumber: $documentPersonalizationSerialNumber, ');
    }
    if (imageOfFrontDocument != null) {
      buf.write('imageOfFrontDocument: ${imageOfFrontDocument!.length} bytes');
    }
    if (imageOfRearDocument != null) {
      buf.write('imageOfRearDocument: ${imageOfRearDocument!.length} bytes');
    }
    buf.write('otherPersons: $otherPersons');
    buf.write(')');
    return buf.toString();
  }
}
