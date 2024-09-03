part of 'data_group.dart';

///  Machine Readable Zone Information
class DataGroup1 extends DataGroup {
  @override
  String get name => 'mrz';

  final TravelDocument travelDocument;

  const DataGroup1(this.travelDocument);

  DataGroup1.decode(ASNObject data)
      : assert(data.tag == 0x61),
        travelDocument = TravelDocument.parse(data[0x5F1F]!.strValue);

  @override
  String toString() {
    return 'DataGroup1(travelDocument: $travelDocument)';
  }
}
