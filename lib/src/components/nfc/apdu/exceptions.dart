class ApduException implements Exception {
  final String code;

  String get message => 'APDU error: $code';

  ApduException(this.code);
}

class AuthException implements Exception {
  final String message;

  AuthException(
      [this.message =
          'Authentication failed please check the input parameters.']);

  @override
  String toString() => 'AuthException: $message';
}
