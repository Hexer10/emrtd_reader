part of 'data_group.dart';

/// Encoded Identification Features — Face/Fingerprint(s)
// TODO: support multiple images
class BiometricDG extends DataGroup {
  @override
  final String name;

  final int numberOfImages;
  final BiometricHeader biometricHeader;
  final BiometricData biometricData;

  const BiometricDG(this.numberOfImages, this.biometricHeader,
      this.biometricData, String name)
      : name = 'biometric_$name';

  BiometricDG.decode(ASNObject data, String name)
      : assert(data.tag == 0x75 || data.tag == 0x63),
        name = 'biometric_$name',
        numberOfImages = data[0x7F61]![0x02]!.intValue,
        biometricHeader = BiometricHeader.decode(data[0x7F61]![0x7F60]![0xA1]!),
        biometricData = BiometricData.decode(
            data[0x7F61]![0x7F60]!.getChild(0xF72E, 0x5F2E)!);

  @override
  String toString() {
    final buf = StringBuffer('DataGroup2(\n');
    buf.writeln('\tnumberOfImages: $numberOfImages, ');
    buf.writeln('\tbiometricHeader: $biometricHeader, ');
    buf.writeln('\tbiometricData: $biometricData');
    buf.write(')');
    return buf.toString();
  }
}

class BiometricHeader {
  final int? icaoHeaderVersion;
  final int? biometricType;
  final int? biometricSubtype;
  final String? creationDate;
  final String? validityPeriod;
  final int? biometricReferenceDataCreator;
  final int formatOwner;
  final int formatType;

  const BiometricHeader(
      {required this.biometricType,
      required this.biometricSubtype,
      required this.creationDate,
      required this.validityPeriod,
      required this.biometricReferenceDataCreator,
      required this.formatOwner,
      required this.formatType,
      required this.icaoHeaderVersion});

  static BiometricHeader decode(ASNObject data) {
    assert(data.tag == 0xA1);
    return BiometricHeader(
      icaoHeaderVersion: data.getChild(0x80)?.intValue,
      biometricType: data.getChild(0x81)?.intValue,
      biometricSubtype: data.getChild(0x82)?.intValue,
      creationDate: data.getChild(0x83)?.strValue,
      validityPeriod: data.getChild(0x85)?.strValue,
      biometricReferenceDataCreator: data.getChild(0x86)?.intValue,
      formatOwner: data.getChild(0x87)!.intValue,
      formatType: data.getChild(0x88)!.intValue,
    );
  }

  @override
  String toString() {
    final buf = StringBuffer('BiometricHeader(');
    if (icaoHeaderVersion != null) {
      buf.write('icaoHeaderVersion: $icaoHeaderVersion, ');
    }
    if (biometricType != null) {
      buf.write('biometricType: $biometricType, ');
    }
    if (biometricSubtype != null) {
      buf.write('biometricSubtype: $biometricSubtype, ');
    }
    if (creationDate != null) {
      buf.write('creationDate: $creationDate, ');
    }
    if (validityPeriod != null) {
      buf.write('validityPeriod: $validityPeriod, ');
    }
    if (biometricReferenceDataCreator != null) {
      buf.write(
          'biometricReferenceDataCreator: $biometricReferenceDataCreator, ');
    }
    buf.write('formatOwner: $formatOwner, ');
    buf.write('formatType: $formatType');
    buf.write(')');
    return buf.toString();
  }
}

class BiometricData {
  // Version of the biometric data format.
  final int? version;

  // Length of the biometric record.
  final int? lengthOfRecord;

  // Number of biometric images present.
  final int? numberOfImages;

  // Overall length of the record data.
  final int? recordDataLength;

  // Number of facial feature points.
  final int? featurePoints;

  // Gender of the biometric subject.
  final int? gender;

  // Eye color of the subject.
  final int? eyeColor;

  // Hair color of the subject.
  final int? hairColor;

  // Feature characteristics mask.
  final int? featureMask;

  // Detected facial expression.
  final int? expression;

  // Pose angle of the subject.
  final int? poseAngle;

  // Uncertainty of the pose angle.
  final int? poseAngleUncertainty;

  // Type of face image.
  final int? imageType;

  // Image data type.
  final int? imageDataType;

  // Width of the face image.
  final int? imageWidth;

  // Height of the face image.
  final int? imageHeight;

  // Image color space.
  final int? imageColorSpace;

  // Image source type.
  final int? sourceType;

  // Device type used for acquisition.
  final int? deviceType;

  // Quality of the face image.
  final int? quality;

  // Face image data.
  final Uint8List? imageData;

  BiometricData({
    this.version,
    this.lengthOfRecord,
    this.numberOfImages,
    this.recordDataLength,
    this.featurePoints,
    this.gender,
    this.eyeColor,
    this.hairColor,
    this.featureMask,
    this.expression,
    this.poseAngle,
    this.poseAngleUncertainty,
    this.imageType,
    this.imageDataType,
    this.imageWidth,
    this.imageHeight,
    this.imageColorSpace,
    this.sourceType,
    this.deviceType,
    this.quality,
    this.imageData,
  });

  static BiometricData decode(ASNObject object) {
    assert(object.tag == 0xF72E || object.tag == 0x5F2E);
    final data = SequentialByteData(object.bytes.buffer.asByteData(4));

    final version = data.uint32;
    final lengthOfRecord = data.uint32;
    final numberOfImages = data.uint16;
    final recordDataLength = data.uint32;
    final featurePoints = data.uint16;
    final gender = data.uint8;
    final eyeColor = data.uint8;
    final hairColor = data.uint8;
    final featureMask = data.uint24;
    final expression = data.uint16;
    final poseAngle = data.uint24;
    final poseAngleUncertainty = data.uint24;
    // skip feature block
    data.skip(featurePoints * 8);
    final imageType = data.uint8;
    final imageDataType = data.uint8;
    final imageWidth = data.uint16;
    final imageHeight = data.uint16;
    final imageColorSpace = data.uint8;
    final sourceType = data.uint8;
    final deviceType = data.uint16;
    final quality = data.uint16;
    final imageData = object.bytes.sublist(data._offset + 4);

    // TODO: Validate image data

    return BiometricData(
      version: version,
      lengthOfRecord: lengthOfRecord,
      numberOfImages: numberOfImages,
      recordDataLength: recordDataLength,
      featurePoints: featurePoints,
      gender: gender,
      eyeColor: eyeColor,
      hairColor: hairColor,
      featureMask: featureMask,
      expression: expression,
      poseAngle: poseAngle,
      poseAngleUncertainty: poseAngleUncertainty,
      imageType: imageType,
      imageDataType: imageDataType,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      imageColorSpace: imageColorSpace,
      sourceType: sourceType,
      deviceType: deviceType,
      quality: quality,
      imageData: imageData,
    );
  }

  @override
  String toString() {
    final buf = StringBuffer('BiometricData(');
    if (version != null) buf.write('version: $version, ');
    if (lengthOfRecord != null) buf.write('lengthOfRecord: $lengthOfRecord, ');
    if (numberOfImages != null) buf.write('numberOfImages: $numberOfImages, ');
    if (recordDataLength != null) {
      buf.write('recordDataLength: $recordDataLength, ');
    }
    if (featurePoints != null) buf.write('featurePoints: $featurePoints, ');
    if (gender != null) buf.write('gender: $gender, ');
    if (eyeColor != null) buf.write('eyeColor: $eyeColor, ');
    if (hairColor != null) buf.write('hairColor: $hairColor, ');
    if (featureMask != null) buf.write('featureMask: $featureMask, ');
    if (expression != null) buf.write('expression: $expression, ');
    if (poseAngle != null) buf.write('poseAngle: $poseAngle, ');
    if (poseAngleUncertainty != null) {
      buf.write('poseAngleUncertainty: $poseAngleUncertainty, ');
    }
    if (imageType != null) buf.write('imageType: $imageType, ');
    if (imageDataType != null) buf.write('imageDataType: $imageDataType, ');
    if (imageWidth != null) buf.write('imageWidth: $imageWidth, ');
    if (imageHeight != null) buf.write('imageHeight: $imageHeight, ');
    if (imageColorSpace != null) {
      buf.write('imageColorSpace: $imageColorSpace, ');
    }
    if (sourceType != null) buf.write('sourceType: $sourceType, ');
    if (deviceType != null) buf.write('deviceType: $deviceType, ');
    if (quality != null) buf.write('quality: $quality, ');
    if (imageData != null) buf.write('imageData: [${imageData!.length} bytes]');
    buf.write(')');
    return buf.toString();
  }
}

class SequentialByteData {
  final ByteData data;

  var _offset = 0;

  SequentialByteData(this.data);

  int get uint8 => data.getUint8(_offset++);

  int get uint16 {
    final value = data.getUint16(_offset);
    _offset += 2;
    return value;
  }

  int get uint24 {
    final value = data.getUint32(_offset);
    _offset += 3;
    return value & 0xFFFFFF;
  }

  int get uint32 {
    final value = data.getUint32(_offset);
    _offset += 4;
    return value;
  }

  int get uint64 {
    final value = data.getUint64(_offset);
    _offset += 8;
    return value;
  }

  void skip(int bytes) {
    _offset += bytes;
  }
}
