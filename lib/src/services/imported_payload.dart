import 'dart:convert';
import 'dart:typed_data';

class ImportedPayload {
  final String name;
  final Uint8List bytes;
  final String? contentType;
  final String? source;

  const ImportedPayload({
    required this.name,
    required this.bytes,
    this.contentType,
    this.source,
  });

  bool get isProbablyBinary {
    final lower = name.toLowerCase();
    final ct = contentType?.toLowerCase() ?? '';
    return ct.contains('protobuf') ||
        ct.contains('octet-stream') ||
        lower.endsWith('.pb') ||
        lower.endsWith('.proto.bin') ||
        lower.endsWith('.protobuf') ||
        lower.endsWith('.bin');
  }

  dynamic get parserInput {
    if (isProbablyBinary) return bytes;
    return utf8.decode(bytes, allowMalformed: true);
  }

  String get resolvedContentType {
    final explicit = contentType?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return guessContentTypeFromName(name);
  }
}

String guessContentTypeFromName(String fileName) {
  final lower = fileName.toLowerCase();
  if (lower.endsWith('.json')) return 'application/json';
  if (lower.endsWith('.xml')) return 'application/xml';
  if (lower.endsWith('.csv')) return 'text/csv';
  if (lower.endsWith('.sql')) return 'application/sql';
  if (lower.endsWith('.pb') ||
      lower.endsWith('.protobuf') ||
      lower.endsWith('.proto.bin') ||
      lower.endsWith('.bin')) {
    return 'application/x-protobuf';
  }
  return 'auto';
}
