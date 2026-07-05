import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../core/field_flattener.dart';
import '../models/normalized_anpr_event.dart';

class JsonAnprParser {
  static NormalizedAnprEvent parse(String payload) {
    final decoded = jsonDecode(payload);

    final map = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'items': decoded};

    final fields = FieldFlattener.flattenMap(map);

    return NormalizedAnprEvent.fromMappedFields(
      sourceFormat: 'JSON',
      fields: fields,
      rawPayload: const JsonEncoder.withIndent('  ').convert(decoded),
      fallbackId: const Uuid().v4(),
    );
  }
}
