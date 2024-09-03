// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TravelDocument _$TravelDocumentFromJson(Map<String, dynamic> json) =>
    TravelDocument(
      documentType:
          $enumDecode(_$TravelDocumentTypeEnumMap, json['documentType']),
      name: json['name'] as String,
      surname: json['surname'] as String,
      documentCode: json['documentCode'] as String,
      issuingState: json['issuingState'] as String,
      documentNumber: json['documentNumber'] as String,
      optionalData: (json['optionalData'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      sex: json['sex'] as String,
      dateOfExpiry: DateTime.parse(json['dateOfExpiry'] as String),
      nationality: json['nationality'] as String,
      errors:
          (json['errors'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$TravelDocumentToJson(TravelDocument instance) =>
    <String, dynamic>{
      'documentType': _$TravelDocumentTypeEnumMap[instance.documentType]!,
      'name': instance.name,
      'surname': instance.surname,
      'documentCode': instance.documentCode,
      'issuingState': instance.issuingState,
      'documentNumber': instance.documentNumber,
      'optionalData': instance.optionalData,
      'dateOfBirth': instance.dateOfBirth.toIso8601String(),
      'sex': instance.sex,
      'dateOfExpiry': instance.dateOfExpiry.toIso8601String(),
      'nationality': instance.nationality,
      'errors': instance.errors,
    };

const _$TravelDocumentTypeEnumMap = {
  TravelDocumentType.TD1: 'TD1',
  TravelDocumentType.TD2: 'TD2',
  TravelDocumentType.TD3: 'TD3',
};
