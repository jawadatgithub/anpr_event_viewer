import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'imported_payload.dart';

class AnprFileImportService {
  Future<List<ImportedPayload>> pickPayloadFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return const [];
    }

    final payloads = <ImportedPayload>[];

    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        continue;
      }

      payloads.add(
        ImportedPayload.fromBytes(
          name: file.name,
          bytes: Uint8List.fromList(bytes),
        ),
      );
    }

    return payloads;
  }
}
