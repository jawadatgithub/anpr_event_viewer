import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'imported_payload.dart';

class AnprFileImportService {
  const AnprFileImportService();

  Future<List<ImportedPayload>> pickPayloadFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const [
        'json',
        'xml',
        'csv',
        'sql',
        'pb',
        'protobuf',
        'bin',
        'txt',
      ],
    );

    if (result == null) return const [];

    return result.files
        .where((file) => file.bytes != null && file.bytes!.isNotEmpty)
        .map(
          (file) => ImportedPayload(
            name: file.name,
            bytes: Uint8List.fromList(file.bytes!),
            contentType: guessContentTypeFromName(file.name),
            source: 'file',
          ),
        )
        .toList(growable: false);
  }
}
