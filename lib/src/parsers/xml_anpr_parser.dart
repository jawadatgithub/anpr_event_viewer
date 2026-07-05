import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import '../models/normalized_anpr_event.dart';

class XmlAnprParser {
  static NormalizedAnprEvent parse(String payload) {
    final doc = XmlDocument.parse(payload);
    final map = <String, dynamic>{};

    void walk(XmlElement element, [String prefix = '']) {
      final localName = element.name.local;
      final key = prefix.isEmpty ? localName : '$prefix.$localName';
      final children = element.children.whereType<XmlElement>().toList();

      if (children.isEmpty) {
        final text = element.innerText.trim();
        map[localName] = text;
        map[key] = text;
        return;
      }

      for (final child in children) {
        walk(child, key);
      }
    }

    walk(doc.rootElement);

    return NormalizedAnprEvent.fromMappedFields(
      sourceFormat: 'XML',
      fields: map,
      rawPayload: payload,
      fallbackId: const Uuid().v4(),
    );
  }
}
