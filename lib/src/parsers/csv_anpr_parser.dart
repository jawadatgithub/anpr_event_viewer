import 'package:uuid/uuid.dart';

import '../models/normalized_anpr_event.dart';

class CsvAnprParser {
  static NormalizedAnprEvent parse(String payload) {
    final rows = _parseCsv(payload);
    if (rows.length < 2) {
      throw const FormatException('CSV payload must include a header row and one data row.');
    }

    final headers = rows.first.map((value) => value.trim()).toList();
    final values = rows[1];
    final fields = <String, dynamic>{};

    for (var i = 0; i < headers.length; i++) {
      final key = headers[i];
      if (key.isEmpty) continue;
      fields[key] = i < values.length ? values[i] : '';
    }

    return NormalizedAnprEvent.fromMappedFields(
      sourceFormat: 'CSV',
      fields: fields,
      rawPayload: payload,
      fallbackId: const Uuid().v4(),
    );
  }

  static List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    final row = <String>[];
    final cell = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      final next = i + 1 < input.length ? input[i + 1] : null;

      if (char == '"') {
        if (inQuotes && next == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (char == ',' && !inQuotes) {
        row.add(cell.toString());
        cell.clear();
        continue;
      }

      if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && next == '\n') i++;
        row.add(cell.toString());
        cell.clear();
        if (row.any((value) => value.trim().isNotEmpty)) {
          rows.add(List<String>.from(row));
        }
        row.clear();
        continue;
      }

      cell.write(char);
    }

    row.add(cell.toString());
    if (row.any((value) => value.trim().isNotEmpty)) {
      rows.add(row);
    }

    return rows;
  }
}
