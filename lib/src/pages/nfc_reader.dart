import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

import '../../main.dart';
import '../components/nfc/datagroups/data_group.dart';
import '../components/nfc/mrtd_interface.dart';
import '../components/nfc/nfc_card.dart';
import '../components/ocr/mrz_recognizer.dart';
import 'results_page.dart';

class NFCReader extends HookWidget {
  final MRZData mrz;

  const NFCReader({super.key, required this.mrz});

  static String prettifyName(String name) {
    return switch (name) {
      'additional_document_details' => 'Additional document details',
      'additional_personal_details' => 'Additional personal details',
      'mrz' => 'ID/Passport details',
      'biometric_face' => 'Face picture',
      'com' => 'Listing',
      _ => name,
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final steps = useState<List<String>>([]);
    final stepsDescription = useState<Map<String, dynamic>>({});
    final result = useState<Map<String, DataGroup?>?>(null);

    useEffect(() {
      NfcManager.instance.startSession(onDiscovered: (card) async {
        final isoDep = IsoDep.from(card);
        if (isoDep == null) {
          return;
        }
        try {
          final cie = MRTDInterface(NFCCard(isoDep.transceive));

          stepsDescription.value = {'Authentication': -1};
          steps.value = ['Authentication'];
          await cie.authenticate(mrz.doB, mrz.doE, mrz.docNo);
          stepsDescription.value = {'Authentication': 100};

          result.value = await cie.extractData(
            throwOnError: true,
            onProgress: (name, progress) {
              stepsDescription.value = {
                ...stepsDescription.value,
                name: progress
              };
              if (!steps.value.contains(name)) {
                steps.value = [...steps.value, name];
              }
            },
          );
          NfcManager.instance.stopSession();
          if (!context.mounted) {
            return;
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ResultsPage(result: result.value!),
            ),
          );
        } on PlatformException {
          stepsDescription.value = {
            ...stepsDescription.value,
            'Error': 'The document was moved too fast. Please try again.'
          };
          steps.value = [...steps.value, 'Error'];
        } on ApduException catch (e) {
          if (e.code == '6300') {
            stepsDescription.value = {
              ...stepsDescription.value,
              'Error':
                  'Authentication failed. Please try again from the beginning.'
            };
          } else {
            stepsDescription.value = {
              ...stepsDescription.value,
              'Error': 'code: ${e.code}'
            };
            steps.value = [...steps.value, 'Error'];
          }
          steps.value = [...steps.value, 'Error'];
        }
      });
      return () => NfcManager.instance.stopSession();
    }, []);

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Read document'),
        ),
        body: Container(
          padding: const EdgeInsets.only(top: 120),
          width: size.width,
          height: size.height,
          decoration: appDecoration,
          child: steps.value.isEmpty
              ? Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Material(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 20,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Please move the phone over the document to start scanning it.\nKeep it still until the process is completed.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    padding: const EdgeInsets.all(0),
                    children: [
                      for (var step in steps.value.reversed) ...[
                        if (step == 'Error')
                          Material(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            color: Colors.red.withOpacity(0.1),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                stepsDescription.value[step],
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        if (step != 'Error')
                          Material(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                            child: ListTile(
                              title: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(prettifyName(step)),
                                  const Spacer(),
                                  if (stepsDescription.value[step] != null)
                                    SizedBox(
                                      width: 100,
                                      height: 8,
                                      // If this is not the last step and the progress is not 100% an error occurred
                                      child: LinearProgressIndicator(
                                        borderRadius: BorderRadius.circular(4),
                                        color: step != steps.value.last &&
                                                stepsDescription.value[step] !=
                                                    100
                                            ? Colors.amber
                                            : null,
                                        value: stepsDescription.value[step]! ==
                                                -1
                                            ? null
                                            : stepsDescription.value[step]! /
                                                100,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8)
                      ],
                    ],
                  ),
                ),
        ));
  }
}
