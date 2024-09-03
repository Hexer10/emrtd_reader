import 'dart:typed_data';

class ApduResponse {
  final Uint8List response;
  final Uint8List sw;

  ApduResponse(Uint8List fullResponse)
      : response = fullResponse.sublist(0, fullResponse.length - 2),
        sw = fullResponse.sublist(fullResponse.length - 2, fullResponse.length);

  ApduResponse.fromResponseAndSw(this.response, this.sw);

  ApduResponse copyWith({Uint8List? response, Uint8List? sw}) {
    return ApduResponse.fromResponseAndSw(
      response ?? this.response,
      sw ?? this.sw,
    );
  }
}
