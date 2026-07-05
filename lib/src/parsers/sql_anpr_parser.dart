import 'package:uuid/uuid.dart';

import '../models/normalized_anpr_event.dart';

class SqlAnprParser {
  static NormalizedAnprEvent parse(String payload) {
    final match = RegExp(
      r'insert\s+into\s+\w+\s*\((.*?)\)\s*values\s*\((.*?)\)',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(payload);

    if (match == null) {
      throw const FormatException('SQL payload must contain INSERT INTO (...) VALUES (...).');
    }

    final columns = _splitSqlList(match.group(1)!).map(_cleanIdentifier).toList();
    final values = _splitSqlList(match.group(2)!).map(_cleanValue).toList();
    final fields = <String, dynamic>{};

    for (var i = 0; i < columns.length; i++) {
      if (columns[i].isEmpty) continue;
      fields[columns[i]] = i < values.length ? values[i] : '';
    }

    return NormalizedAnprEvent.fromMappedFields(
      sourceFormat: 'SQL',
      fields: fields,
      rawPayload: payload,
      fallbackId: const Uuid().v4(),
    );
  }

  static List<String> _splitSqlList(String input) {
    final values = <String>[];
    final current = StringBuffer();
    var inString = false;
    var depth = 0;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      final next = i + 1 < input.length ? input[i + 1] : null;

      if (char == "'") {
        current.write(char);
        if (inString && next == "'") {
          current.write(next);
          i++;
        } else {
          inString = !inString;
        }
        continue;
      }

      if (!inString) {
        if (char == '(') depth++;
        if (char == ')') depth--;
        if (char == ',' && depth == 0) {
          values.add(current.toString().trim());
          current.clear();
          continue;
        }
      }

      current.write(char);
    }

    if (current.toString().trim().isNotEmpty) {
      values.add(current.toString().trim());
    }

    return values;
  }

  static String _cleanIdentifier(String value) {
    return value.trim().replaceAll('`', '').replaceAll('"', '').replaceAll('[', '').replaceAll(']', '');
  }

  static String _cleanValue(String value) {
    final trimmed = value.trim();
    if (trimmed.toLowerCase() == 'null') return '';
    if (trimmed.startsWith("'") && trimmed.endsWith("'")) {
      return trimmed.substring(1, trimmed.length - 1).replaceAll("''", "'");
    }
    return trimmed;
  }
}
