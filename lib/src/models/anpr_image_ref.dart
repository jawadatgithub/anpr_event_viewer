enum AnprImageType { base64, url, filePath, unknown }

class AnprImageRef {
  final AnprImageType type;
  final String value;
  final String? mimeType;

  const AnprImageRef({
    required this.type,
    required this.value,
    this.mimeType,
  });

  static AnprImageRef? fromDynamic(dynamic input) {
    if (input == null) return null;

    final raw = input.toString();
    final v = raw.trim();
    if (v.isEmpty || v.toLowerCase() == 'null') return null;

    final lower = v.toLowerCase();

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return AnprImageRef(type: AnprImageType.url, value: v);
    }

    if (lower.startsWith('data:image/') && lower.contains('base64,')) {
      final semicolon = v.indexOf(';');
      final mime = semicolon > 5 ? v.substring(5, semicolon) : null;
      return AnprImageRef(
        type: AnprImageType.base64,
        value: v,
        mimeType: mime,
      );
    }

    final compact = v.replaceAll(RegExp(r'\s+'), '');
    final looksLikeBase64 = compact.length > 100 &&
        compact.length % 4 == 0 &&
        RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(compact);

    if (looksLikeBase64) {
      return AnprImageRef(type: AnprImageType.base64, value: compact);
    }

    if (v.startsWith('/') ||
        v.contains('\\') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      return AnprImageRef(type: AnprImageType.filePath, value: v);
    }

    return AnprImageRef(type: AnprImageType.unknown, value: v);
  }
}
