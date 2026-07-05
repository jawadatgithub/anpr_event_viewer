enum PayloadFormat { json, xml, csv, sql, protobuf, unknown }

PayloadFormat detectPayloadFormat(dynamic input, {String? contentType}) {
  final ct = contentType?.toLowerCase() ?? '';

  if (ct.contains('protobuf') || ct.contains('x-protobuf') || ct.contains('octet-stream')) {
    return PayloadFormat.protobuf;
  }
  if (ct.contains('json')) return PayloadFormat.json;
  if (ct.contains('xml')) return PayloadFormat.xml;
  if (ct.contains('csv')) return PayloadFormat.csv;
  if (ct.contains('sql')) return PayloadFormat.sql;

  if (input is String) {
    final t = input.trimLeft();
    final lower = t.toLowerCase();

    if (t.startsWith('{') || t.startsWith('[')) return PayloadFormat.json;
    if (t.startsWith('<')) return PayloadFormat.xml;
    if (lower.contains('insert into') && lower.contains('values')) return PayloadFormat.sql;
    if (_looksLikeCsv(t)) return PayloadFormat.csv;
  }

  if (input is List<int>) return PayloadFormat.protobuf;
  return PayloadFormat.unknown;
}

bool _looksLikeCsv(String text) {
  final lines = text.split(RegExp(r'\r?\n')).where((line) => line.trim().isNotEmpty).take(3).toList();
  if (lines.length < 2) return false;
  return lines.first.contains(',') && lines[1].contains(',');
}
