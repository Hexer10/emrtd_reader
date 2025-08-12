import 'package:emrtd_reader/src/components/auth_credential.dart';
import 'package:emrtd_reader/src/components/nfc/apdu/apdu_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mrz_seed', () {
    final docNr = 'L898902C';
    final dob = '690806';
    final doe = '940623';
    final auth =
        MRZAuthentication(birthStr: dob, expireStr: doe, docNoStr: docNr);
    final seed = auth.seed;
    expect(seed.length, equals(16));
    expect(
        seed.toHexString(), '23 9A B9 CB 28 2D AF 66 23 1D C5 A4 DF 6B FB AE');
  });
}
