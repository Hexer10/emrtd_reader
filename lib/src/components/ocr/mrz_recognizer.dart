import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../models/travel_document.dart';

typedef MRZData = ({String doB, String doE, String docNo});

/// Processes the image stream from the camera and extracts MRZ data.
/// Use [MrzRecognizer.processImage] to process an image and listen to [MrzRecognizer.mrzData] to get the extracted data.
class MrzRecognizer {
  MrzRecognizer();

  final _textRecognizer = TextRecognizer();

  /// Releases the resources.
  Future<void> dispose() async {
    await _textRecognizer.close();
  }

  // Used for TD1 documents since the data is split in two lines
  String? _tempNumber;
  String? _tempDoB;
  String? _tempDoE;

  bool get processing => _processing;
  var _processing = false;

  /// Process a camera image, if [processing] is true when this is called null is always returned.
  Future<MRZData?> processImage(InputImage image) async {
    if (_processing) return null;
    _processing = true;
    final processed = await _textRecognizer.processImage(image);
    final text = processed.text.replaceAll(RegExp(r' +'), '');
    _checkTD1Dates2(text);
    for (final line in text.split('\n')) {
      final data = _processLine(line);
      if (data != null) {
        _processing = false;
        return data;
      }
    }
    _processing = false;
    return null;
  }

  MRZData? _processLine(String text) {
    return _checkTD3(text) ?? _checkTD1(text);
  }

  MRZData? _checkTD1No(String line) {
    if (line.length < 15) return null;

    final number = line.substring(5, 14);
    // Check that the number starts with a letter to avoid false positives
    // Please report if there are any IDs that start with a number
    if (number.codeUnits[0] case < 65 || > 90) return null;

    final numberCD = int.tryParse(line[14]);
    if (numberCD == null ||
        TravelDocument.computeCheckDigit(number) != numberCD) return null;

    _tempNumber = number;
    if (_tempDoB != null && _tempDoE != null) {
      final data = (doB: _tempDoB!, doE: _tempDoE!, docNo: _tempNumber!);
      _tempDoB = null;
      _tempDoE = null;
      _tempNumber = null;
      return data;
    }
    return null;
  }

  MRZData? _checkTD1Dates2(String block) {
    // Find all the sequences of 6 digits + 1 digit
    final matches = RegExp(r'\d{6}\d').allMatches(block);
    if (matches.isEmpty) return null;
    final dates = matches
        .map((m) => m.group(0)!)
        .where((e) =>
            e.substring(0, 6).isDate &&
            TravelDocument.computeCheckDigit(e.substring(0, 6)) ==
                int.tryParse(e[6]))
        .toList();
    if (dates.length < 2) return null;

    _tempDoB = dates[0].substring(0, 6);
    _tempDoE = dates[1].substring(0, 6);

    if (_tempNumber != null) {
      final data = (doB: _tempDoB!, doE: _tempDoE!, docNo: _tempNumber!);
      _tempNumber = null;
      return data;
    }
    return null;
  }

  MRZData? _checkTD1Dates(String line) {
    if (line.length < 15) return null;

    final dateOfBirth = line.substring(0, 6);
    final dateOfBirthCD = int.tryParse(line[6]);
    if (!dateOfBirth.isDate ||
        TravelDocument.computeCheckDigit(dateOfBirth) != dateOfBirthCD) {
      return null;
    } else {
      _tempDoB = dateOfBirth;
    }

    final dateOfExpiry = line.substring(8, 14);
    final dateOfExpiryCD = int.tryParse(line[14]);
    if (!dateOfExpiry.isDate ||
        TravelDocument.computeCheckDigit(dateOfExpiry) != dateOfExpiryCD) {
      return null;
    }
    _tempDoE = dateOfExpiry;

    if (_tempNumber != null) {
      final data = (doB: _tempDoB!, doE: _tempDoE!, docNo: _tempNumber!);
      _tempDoB = null;
      _tempDoE = null;
      _tempNumber = null;
      return data;
    }
    return null;
  }

  MRZData? _checkTD1(String line) {
    return _checkTD1No(line);
  }

  final docNoExp = RegExp(r'^[A-Z0-9<]{9}$');

  MRZData? _checkTD3(String line) {
    if (line.length < 28) return null;

    final number = line.substring(0, 9);
    final numberCD = int.tryParse(line[9]);
    if (TravelDocument.computeCheckDigit(number) != numberCD) return null;

    final dateOfBirth = line.substring(13, 19);
    final dateOfBirthCD = int.tryParse(line[19]);
    if (!dateOfBirth.isDate ||
        TravelDocument.computeCheckDigit(dateOfBirth) != dateOfBirthCD) {
      return null;
    }

    final dateOfExpiry = line.substring(21, 27);
    final dateOfExpiryCD = int.tryParse(line[27]);
    if (!dateOfBirth.isDate ||
        TravelDocument.computeCheckDigit(dateOfExpiry) != dateOfExpiryCD) {
      return null;
    }

    return (doB: dateOfBirth, doE: dateOfExpiry, docNo: number);
  }
}

extension on String {
  bool get isDate {
    if (length != 6) return false;
    final year = int.tryParse(substring(0, 2));
    final month = int.tryParse(substring(2, 4));
    final day = int.tryParse(substring(4, 6));
    if (year == null || month == null || day == null) return false;
    if (year < 0 || month < 1 || month > 12 || day < 1 || day > 31) {
      return false;
    }
    return true;
  }
}
