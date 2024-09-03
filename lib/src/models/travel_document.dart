// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'travel_document.g.dart';

enum TravelDocumentType {
  TD1,
  TD2,
  TD3,
}

@JsonSerializable()
class TravelDocument extends Equatable {
  @override
  List get props => [
        documentType,
        documentCode,
        issuingState,
        documentNumber,
        optionalData,
        dateOfBirth,
        sex,
        dateOfExpiry,
        nationality
      ];

  factory TravelDocument.fromJson(Map<String, dynamic> json) =>
      _$TravelDocumentFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$TravelDocumentToJson(this);
  final TravelDocumentType documentType;

  final String name;

  final String surname;

  /// Two characters, the first of which
  /// shall be A, C or I, shall be used to
  /// designate the particular type of
  /// document.
  final String documentCode;

  /// Three letter code.
  /// Note that sometimes some ID cards only include one letter, for example
  /// D -> Germany
  final String issuingState;

  /// Document number.
  final String documentNumber;

  /// Optional data.
  /// If not set it is an empty string.
  final List<String> optionalData;

  /// Date of birth.
  final DateTime dateOfBirth;

  /// Can M, F or ` ` is unspecified.
  final String sex;

  /// Date of expiry.
  final DateTime dateOfExpiry;

  /// Nationality
  /// Note that sometimes some ID cards only include one letter, for example
  /// D -> Germany
  final String nationality;

  /// Eventual errors in the MRZ. From the check digits.
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;

  const TravelDocument({
    required this.documentType,
    required this.name,
    required this.surname,
    required this.documentCode,
    required this.issuingState,
    required this.documentNumber,
    required this.optionalData,
    required this.dateOfBirth,
    required this.sex,
    required this.dateOfExpiry,
    required this.nationality,
    required this.errors,
  })  : assert(documentCode.length <= 2),
        assert(issuingState.length == 3),
        assert(documentNumber.length <= 9),
        assert(sex == 'F' || sex == 'M' || sex == ' '),
        assert(nationality.length == 3);

  @override
  String toString() {
    return 'TravelDocument('
        'documentCode: $documentCode, '
        'issuingState: $issuingState, '
        'documentNumber: $documentNumber, '
        'optionalData: $optionalData, '
        'dateOfBirth: $dateOfBirth, '
        'sex: $sex,'
        'dateOfExpiry: $dateOfExpiry, '
        'nationality: $nationality, '
        'errors: $errors)';
  }

  /// Parses a MRZ string.
  /// Throws  [FormatException] if the MRZ is invalid.
  static TravelDocument parse(String mrz) {
    final parsed = tryParse(mrz);
    if (parsed == null) {
      throw FormatException('Invalid MRZ', mrz);
    }
    return parsed;
  }

  /// Evaluates from the length if this is a TD1 or TD3 MRZ.
  static TravelDocument? tryParse(String mrz) {
    try {
      return switch (mrz.length) {
        90 => TravelDocument.TD1(
            '${mrz.substring(0, 30)}\n${mrz.substring(30, 60)}\n${mrz.substring(60)}'),
        72 =>
          TravelDocument.TD2('${mrz.substring(0, 36)}\n${mrz.substring(36)}'),
        88 =>
          TravelDocument.TD3('${mrz.substring(0, 44)}\n${mrz.substring(44)}'),
        const (90 + 2) => TravelDocument.TD1(mrz),
        const (72 + 1) => TravelDocument.TD2(mrz),
        const (88 + 1) => TravelDocument.TD3(mrz),
        _ => null
      };
    } on FormatException {
      return null;
    }
  }

  /// Parses a TD1 MRZ string.
  /// Usually found in European ID cards.
  factory TravelDocument.TD1(String mrz) {
    final lines = mrz.replaceAll('<', ' ').split('\n');

    final firstLine = lines[0];
    final secondLine = lines[1];
    final thirdLine = lines[2];

    if (lines.length != 3 || lines.any((e) => e.length != 30)) {
      throw FormatException('Does not match MRZ1 lines', mrz);
    }

    final fullName = thirdLine.substring(0, 30).trim().fixLetters();
    final [surname, name] = fullName.split('  ');

    final issuingState = firstLine.substring(2, 5);
    var docNumber = firstLine.substring(5, 14);
    if (issuingState == 'ITA') {
      docNumber =
          '${docNumber.substring(0, 2).fixLetters()}${docNumber.substring(2, 7).fixDigits()}${docNumber.substring(7, 9).fixLetters()}';
    }

    final dateOfBirth = secondLine.substring(0, 6).fixDigits();
    final expiryDate = secondLine.substring(8, 14).fixDigits();

    final docNumberCD = firstLine[14].fixDigits().toInt();
    final doBCD = secondLine[6].fixDigits().toInt();
    final expiryDateCD = secondLine[14].fixDigits().toInt();
    // docNumber + docNumberCD + DoB + DoBCD + expiryDate + expiryDateCD +
    final compositeCD = secondLine[29].fixDigits().toInt();

    return TravelDocument(
        documentType: TravelDocumentType.TD1,
        name: name,
        surname: surname,
        documentCode: firstLine.substring(0, 2).trim(),
        issuingState: issuingState,
        documentNumber: docNumber.trim(),
        optionalData: [
          firstLine.substring(15, 29).trim(),
          secondLine.substring(18, 28).trim(),
        ],
        dateOfBirth: dateOfBirth.parseMRZDate(),
        sex: secondLine[7],
        dateOfExpiry: expiryDate.parseMRZDate(2000),
        nationality: secondLine.substring(15, 18),
        errors: [
          if (computeCheckDigit(dateOfBirth) != doBCD) 'DATE OF BIRTH',
          if (computeCheckDigit(docNumber) != docNumberCD) 'DOCUMENT NUMBER',
          if (computeCheckDigit(expiryDate) != expiryDateCD) 'EXPIRY DATE',
          if (computeCheckDigit(
                  '$docNumber$docNumberCD$dateOfBirth$doBCD$expiryDate$expiryDateCD') !=
              compositeCD)
            'GENERAL',
        ]);
  }

  factory TravelDocument.TD2(String mrz) {
    final lines = mrz.replaceAll('<', ' ').split('\n');

    final firstLine = lines[0];
    final secondLine = lines[1];

    if (lines.length != 2 || lines.any((e) => e.length != 36)) {
      throw FormatException('Does not match MRZ2 lines', mrz);
    }

    final fullName = firstLine.substring(5, 36).trim().fixLetters();

    final [surname, name] = fullName.split('  ');

    final documentNumberCD = secondLine[9].fixDigits().toInt();
    final dateOfBirthCD = secondLine[19].fixDigits().toInt();
    final dateOfExpiryCD = secondLine[27].fixDigits().toInt();
    final compositeCD = secondLine[35].fixDigits().toInt();

    final documentNumber = secondLine.substring(0, 9);
    final dateOfBirth = secondLine.substring(13, 19);
    final dateOfExpiry = secondLine.substring(21, 27);
    final optionalData = secondLine.substring(28, 35);

    return TravelDocument(
        documentType: TravelDocumentType.TD2,
        name: name,
        surname: surname,
        documentCode: firstLine.substring(0, 2).trim(),
        issuingState: firstLine.substring(2, 5),
        documentNumber: documentNumber,
        optionalData: [optionalData.trim()],
        dateOfBirth: dateOfBirth.parseMRZDate(),
        sex: secondLine[20],
        dateOfExpiry: dateOfExpiry.parseMRZDate(2000),
        nationality: secondLine.substring(10, 13),
        errors: [
          if (computeCheckDigit(documentNumber) != documentNumberCD)
            'DOCUMENT NUMBER',
          if (computeCheckDigit(dateOfBirth) != dateOfBirthCD) 'DATE OF BIRTH',
          if (computeCheckDigit(dateOfExpiry) != dateOfExpiryCD) 'EXPIRY DATE',
          if (computeCheckDigit(
                  '$documentNumber$documentNumberCD$dateOfBirth$dateOfBirthCD$dateOfExpiry$dateOfExpiryCD$optionalData') !=
              compositeCD)
            'GENERAL',
        ]);
  }

  factory TravelDocument.TD3(String mrz) {
    final lines = mrz.replaceAll('<', ' ').split('\n');

    final firstLine = lines[0];
    final secondLine = lines[1];

    if (lines.length != 2 || lines.any((e) => e.length != 44)) {
      throw FormatException('Does not match MRZ3 lines', mrz);
    }

    final fullName = firstLine.substring(5, 44).trim().fixLetters();
    final [surname, name] = fullName.split('  ');

    final docNumCD = secondLine[9].fixDigits().toInt();
    final doBCD = secondLine[19].fixDigits().toInt();
    final expiryDateCD = secondLine[27].fixDigits().toInt();
    final optDataCD = secondLine[42].fixDigits().toInt();
    final compositeCD = secondLine[43].fixDigits().toInt();

    final documentNumber = secondLine.substring(0, 9);
    final dateOfBirth = secondLine.substring(13, 19);
    final dateOfExpiry = secondLine.substring(21, 27);
    final optionalData = secondLine.substring(28, 42);

    return TravelDocument(
        documentType: TravelDocumentType.TD3,
        documentCode: firstLine.substring(0, 2).trim(),
        issuingState: firstLine.substring(2, 5),
        name: name,
        surname: surname,
        documentNumber: documentNumber.trim(),
        nationality: secondLine.substring(10, 13),
        dateOfBirth: dateOfBirth.parseMRZDate(),
        sex: secondLine[20],
        dateOfExpiry: dateOfExpiry.parseMRZDate(2000),
        optionalData: [
          optionalData.trim()
        ],
        errors: [
          if (computeCheckDigit(documentNumber) != docNumCD) 'DOCUMENT NUMBER',
          if (computeCheckDigit(dateOfBirth) != doBCD) 'DATE OF BIRTH',
          if (computeCheckDigit(dateOfExpiry) != expiryDateCD) 'EXPIRY DATE',
          if (computeCheckDigit(optionalData) != optDataCD) 'OPTIONAL DATA',
          if (computeCheckDigit(
                  '$documentNumber$docNumCD$dateOfBirth$doBCD$dateOfExpiry$expiryDateCD$optionalData$optDataCD') !=
              compositeCD)
            'GENERAL',
        ]);
  }

  static final _weights = [7, 3, 1];

  static const int _A = 65;
  static const int _Z = 90;
  static const int _0 = 48;
  static const int _9 = 57;

  static int computeCheckDigit(String input) =>
      input.codeUnits
          .map((c) => switch (c) {
                >= _A && <= _Z => c - _A + 10,
                >= _0 && <= _9 => c - _0,
                _ => 0,
              })
          .mapIndexed((i, v) => v * _weights[i % _weights.length])
          .reduce((value, element) => value + element) %
      10;

  TravelDocument copyWith({
    TravelDocumentType? documentType,
    String? name,
    String? surname,
    String? documentCode,
    String? issuingState,
    String? documentNumber,
    List<String>? optionalData,
    DateTime? dateOfBirth,
    String? sex,
    DateTime? dateOfExpiry,
    List<String>? errors,
    String? nationality,
  }) {
    return TravelDocument(
      documentType: documentType ?? this.documentType,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      documentCode: documentCode ?? this.documentCode,
      issuingState: issuingState ?? this.issuingState,
      documentNumber: documentNumber ?? this.documentNumber,
      optionalData: optionalData ?? this.optionalData,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      dateOfExpiry: dateOfExpiry ?? this.dateOfExpiry,
      errors: errors ?? this.errors,
      nationality: nationality ?? this.nationality,
    );
  }
}

extension _DateParse on String {
  int toInt() => int.parse(this);

  /// Parses a date from a MRZ string.
  /// The date is in YYMMDD format.
  /// If the year is greater than the last two digits of the current year,
  /// it is assumed to be in the 19th century.
  DateTime parseMRZDate([int? startYear]) {
    var year = int.parse(substring(0, 2));
    if (startYear != null) {
      year += startYear;
    } else {
      final currentYear = DateTime.now().year % 100;
      if (year > currentYear) {
        year += 1900;
      } else {
        year += 2000;
      }
    }

    return DateTime(
        year, int.parse(substring(2, 4)), int.parse(substring(4, 6)));
  }
}

extension DocumentFixer on String {
  /// replaceSimilarDigitsWithLetters
  String fixLetters() => replaceAll('0', 'O')
      .replaceAll('1', 'I')
      .replaceAll('2', 'Z')
      .replaceAll('3', 'E')
      .replaceAll('4', 'A')
      .replaceAll('5', 'S')
      .replaceAll('6', 'G')
      .replaceAll('7', 'T')
      .replaceAll('8', 'B')
      .replaceAll('9', 'P');

  /// replaceSimilarLettersWithDigits
  String fixDigits() => replaceAll('O', '0')
      .replaceAll('Q', '0')
      .replaceAll('U', '0')
      .replaceAll('D', '0')
      .replaceAll('I', '1')
      .replaceAll('Z', '2')
      .replaceAll('S', '5')
      .replaceAll('B', '8');
}
