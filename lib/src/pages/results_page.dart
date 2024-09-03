import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:opencv_dart/opencv_dart.dart' as cv;
import '../../main.dart';
import '../components/nfc/datagroups/data_group.dart';

class ResultsPage extends HookWidget {
  final Map<String, DataGroup?> result;

  const ResultsPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final image =
        (result['biometric_face'] as BiometricDG?)?.biometricData.imageData;
    final jpegImage = useState<Uint8List?>(null);

    useEffect(() {
      void convertToJpeg() async {
        if (image != null) {
          // Convert jp2 to jpeg
          final dir = await getApplicationDocumentsDirectory();
          final path = join(dir.path, 'tmp.jp2');
          File(path).writeAsBytesSync(image);
          final img = await cv.imreadAsync(path, flags: cv.IMREAD_UNCHANGED);
          final res = await cv.imencodeAsync('.jpg', img);

          jpegImage.value = res.$2;
        }
      }

      convertToJpeg();
      return null;
    }, [image]);

    final td = (result['mrz'] as DataGroup1).travelDocument;
    final pd = result['additional_personal_details']
        as DataGroup11?; // Personal details
    final dd = result['additional_document_details']
        as DataGroup12?; // Document details

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: appDecoration,
        ),
        title: const Text('Document information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            if (jpegImage.value != null)
              Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                      height: 200, child: Image.memory(jpegImage.value!))),
            ListView(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 4),
                  title: const Text('Name'),
                  subtitle: Text(td.name),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 4),
                  title: const Text('Surname'),
                  subtitle: Text(td.surname),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 4),
                  title: const Text('Date of birth'),
                  subtitle: Text(dateFormatter.format(td.dateOfBirth)),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 4),
                  title: const Text('Date of expiry'),
                  subtitle: Text(dateFormatter.format(td.dateOfExpiry)),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 4),
                  title: const Text('Issuing state and nationality'),
                  subtitle: Text('${td.issuingState}, ${td.nationality}'),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 4),
                  title: const Text('Document number'),
                  subtitle: Text(td.documentNumber),
                ),
                if (pd != null) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 4),
                    title: const Text('Personal number'),
                    subtitle: Text(pd.personalNumber ?? ''),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 4),
                    title: const Text('Place of birth'),
                    subtitle:
                        Text(pd.placeOfBirth?.replaceAll('<', ', ') ?? ''),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 4),
                    title: const Text('Address'),
                    subtitle: Text(pd.address?.replaceAll('<', ', ') ?? ''),
                  ),
                ],
                if (dd != null) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 4),
                    title: const Text('Issuing authority'),
                    subtitle: Text(dd.issuingAuthority ?? ''),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 4),
                    title: const Text('Date of issue'),
                    subtitle: Text(dd.dateOfIssue ?? ''),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 4),
                    title: const Text('Other persons'),
                    subtitle: Text(dd.otherPersons
                        .map((e) => e.replaceAll('<<', ' '))
                        .join(', ')),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final dateFormatter = DateFormat('yy-MM-dd');
