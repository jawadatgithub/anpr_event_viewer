import 'dart:convert';
import 'dart:typed_data';

class ImportedPayload {
  final String name;
  final String parserInput;
  final String resolvedContentType;
  final int byteLength;
  final bool isBinary;

  const ImportedPayload({
    required this.name,
    required this.parserInput,
    required this.resolvedContentType,
    this.byteLength = 0,
    this.isBinary = false,
  });

  factory ImportedPayload.fromBytes({
    required String name,
    required Uint8List bytes,
  }) {
    final contentType = contentTypeForFileName(name);
    final binary = isBinaryContentType(contentType);

    return ImportedPayload(
      name: name,
      parserInput: binary ? base64Encode(bytes) : utf8.decode(bytes, allowMalformed: true),
      resolvedContentType: contentType,
      byteLength: bytes.length,
      isBinary: binary,
    );
  }

  static String contentTypeForFileName(String name) {
    final lower = name.toLowerCase();

    if (lower.endsWith('.json')) return 'application/json';
    if (lower.endsWith('.xml')) return 'application/xml';
    if (lower.endsWith('.csv')) return 'text/csv';
    if (lower.endsWith('.sql')) return 'text/sql';

    if (lower.endsWith('.protobuf')) return 'application/protobuf';
    if (lower.endsWith('.proto')) return 'application/protobuf';
    if (lower.endsWith('.pb')) return 'application/protobuf';
    if (lower.endsWith('.bin')) return 'application/protobuf';

    return 'auto';
  }

  static bool isBinaryContentType(String contentType) {
    final lower = contentType.toLowerCase();
    return lower.contains('protobuf') || lower.contains('octet-stream');
  }
}
