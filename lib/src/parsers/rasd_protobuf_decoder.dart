import 'dart:convert';
import 'dart:typed_data';

/// Decoder for the Zenith Patrol / RASD protobuf-net payload described by
/// RasdEvent.cs.
///
/// This intentionally does not replace the app's existing generic ANPR schema.
/// It only adds support for this extra binary protobuf schema, then converts it
/// into the same JSON-style field names the app already understands.
class RasdProtobufDecoder {
  static const Map<int, String> fieldNames = <int, String>{
    1: 'sourceType',
    2: 'sourceName',
    3: 'cameraName',
    4: 'eventHostname',
    5: 'hostTime',
    6: 'eventTime',
    7: 'plateNumber',
    8: 'plateCodeName',
    9: 'plateCountryName',
    10: 'plateStateName',
    11: 'plateTypeName',
    12: 'plateDebugInfo',
    13: 'plateImageBase64',
    14: 'vehicleImageBase64',
    15: 'plateCategoryName',
    16: 'plateColor',
    17: 'plateModel',
    18: 'plateRequester',
    19: 'plateCrime',
    20: 'plateRemarks',
    21: 'plateCameraGpsPosition',
    22: 'vehicleColorName',
    23: 'vehicleMakerName',
    24: 'vehicleModelName',
  };

  static const Set<int> _stringFields = <int>{
    1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
  };

  static const Set<int> _bytesFields = <int>{13, 14};

  static bool looksLikeRasdPayload(String input) {
    final trimmed = input.trimLeft();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('{') || trimmed.startsWith('[') || trimmed.startsWith('<')) {
      return false;
    }

    try {
      final bytes = _inputToBytes(input, strict: false);
      final fields = _decodeWire(bytes, softFail: true);
      final known = fields.keys.where((key) => fieldNames.containsKey(key)).length;
      return known >= 4 && (fields.containsKey(7) || fields.containsKey(14));
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> decodeToJsonMap(String input) {
    final bytes = _inputToBytes(input);
    final decoded = _decodeWire(bytes);

    final out = <String, dynamic>{};

    for (final entry in decoded.entries) {
      final fieldName = fieldNames[entry.key];
      if (fieldName == null) continue;
      out[fieldName] = entry.value;
    }

    final plate = _stringValue(out['plateNumber']);
    final plateCode = _stringValue(out['plateCodeName']);
    final country = _stringValue(out['plateCountryName']);
    final state = _stringValue(out['plateStateName']);
    final cameraName = _stringValue(out['cameraName']);
    final sourceName = _stringValue(out['sourceName']);
    final eventTime = out['eventTime'];
    final vehicleImage = _stringValue(out['vehicleImageBase64']);
    final plateImage = _stringValue(out['plateImageBase64']);

    out['schema'] = 'rasdEvent';
    out['schemaSource'] = 'RasdEvent.cs';
    out['sourceFormat'] = 'protobuf';

    if (plate != null) {
      out['plate'] = plate;
      out['plateNumber'] = plate;
    }

    if (plateCode != null && plate != null) {
      final parts = <String>[
        if (state != null) state,
        plateCode,
        plate,
      ];
      out['plateNumberFormatted'] = parts.join('-');
    }

    if (country != null) out['country'] = country;
    if (state != null) {
      out['state'] = state;
      out['emirate'] = state;
      out['region'] = state;
    }

    if (cameraName != null && cameraName.isNotEmpty) {
      out['camera'] = cameraName;
      out['location'] = cameraName;
    } else if (sourceName != null && sourceName.isNotEmpty) {
      out['camera'] = sourceName;
      out['location'] = sourceName;
    }

    if (eventTime is int) {
      out['timestamp'] = DateTime.fromMillisecondsSinceEpoch(eventTime, isUtc: true).toIso8601String();
    }

    final vehicle = <String, dynamic>{};
    final vehicleColor = _stringValue(out['vehicleColorName']) ?? _stringValue(out['plateColor']);
    final vehicleMake = _stringValue(out['vehicleMakerName']);
    final vehicleModel = _stringValue(out['vehicleModelName']) ?? _stringValue(out['plateModel']);
    if (vehicleColor != null) vehicle['color'] = vehicleColor;
    if (vehicleMake != null) vehicle['make'] = vehicleMake;
    if (vehicleModel != null) vehicle['model'] = vehicleModel;
    if (vehicle.isNotEmpty) out['vehicle'] = vehicle;

    final images = <String, dynamic>{};
    if (vehicleImage != null && vehicleImage.isNotEmpty) {
      images['vehicleImage'] = _asDataUrl(vehicleImage);
      images['vehicleImageBase64'] = vehicleImage;
    }
    if (plateImage != null && plateImage.isNotEmpty) {
      images['plateImage'] = _asDataUrl(plateImage);
      images['plateImageBase64'] = plateImage;
    }
    if (images.isNotEmpty) out['images'] = images;

    return out;
  }

  static String? _stringValue(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _asDataUrl(String base64Value) {
    final mime = _guessImageMimeFromBase64(base64Value);
    return 'data:$mime;base64,$base64Value';
  }

  static String _guessImageMimeFromBase64(String value) {
    try {
      final bytes = base64Decode(value);
      if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }
      if (bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      }
    } catch (_) {}
    return 'image/jpeg';
  }

  static Uint8List _inputToBytes(String input, {bool strict = true}) {
    final trimmed = input.trim();

    if (trimmed.startsWith('data:') && trimmed.contains(',')) {
      return Uint8List.fromList(base64Decode(trimmed.substring(trimmed.indexOf(',') + 1).trim()));
    }

    try {
      final compact = trimmed.replaceAll(RegExp(r'\s+'), '');
      if (compact.isNotEmpty && RegExp(r'^[A-Za-z0-9+/=_-]+$').hasMatch(compact)) {
        final normalized = compact.replaceAll('-', '+').replaceAll('_', '/');
        final padded = normalized.padRight(normalized.length + ((4 - normalized.length % 4) % 4), '=');
        return Uint8List.fromList(base64Decode(padded));
      }
    } catch (_) {}

    final codeUnits = input.codeUnits;
    if (codeUnits.every((unit) => unit >= 0 && unit <= 255)) {
      return Uint8List.fromList(codeUnits);
    }

    if (input.contains('\uFFFD')) {
      throw const FormatException(
        'The protobuf file was decoded as malformed UTF-8 before parsing. '
        'Use the updated AnprFileImportService so .pb/.protobuf/.bin files are passed as base64 bytes.',
      );
    }

    if (strict) {
      throw const FormatException('Unsupported protobuf input encoding.');
    }

    return Uint8List.fromList(utf8.encode(input));
  }

  static Map<int, dynamic> _decodeWire(Uint8List bytes, {bool softFail = false}) {
    final fields = <int, dynamic>{};
    var offset = 0;

    try {
      while (offset < bytes.length) {
        final keyResult = _readVarint(bytes, offset);
        final key = keyResult.value;
        offset = keyResult.nextOffset;

        final fieldNumber = key >> 3;
        final wireType = key & 0x07;

        if (fieldNumber <= 0) {
          if (softFail) return fields;
          throw FormatException('Invalid protobuf field number $fieldNumber.');
        }

        switch (wireType) {
          case 0:
            final result = _readVarint(bytes, offset);
            offset = result.nextOffset;
            fields[fieldNumber] = result.value;
            break;

          case 1:
            _ensureAvailable(bytes, offset, 8);
            fields[fieldNumber] = bytes.sublist(offset, offset + 8);
            offset += 8;
            break;

          case 2:
            final lengthResult = _readVarint(bytes, offset);
            final length = lengthResult.value;
            offset = lengthResult.nextOffset;
            _ensureAvailable(bytes, offset, length);
            final raw = bytes.sublist(offset, offset + length);
            offset += length;

            if (_bytesFields.contains(fieldNumber)) {
              fields[fieldNumber] = base64Encode(raw);
            } else if (_stringFields.contains(fieldNumber)) {
              fields[fieldNumber] = utf8.decode(raw, allowMalformed: true);
            } else {
              fields[fieldNumber] = raw;
            }
            break;

          case 5:
            _ensureAvailable(bytes, offset, 4);
            fields[fieldNumber] = bytes.sublist(offset, offset + 4);
            offset += 4;
            break;

          default:
            if (softFail) return fields;
            throw FormatException('Unsupported protobuf wire type $wireType for field $fieldNumber.');
        }
      }
    } catch (_) {
      if (softFail) return fields;
      rethrow;
    }

    return fields;
  }

  static _VarintResult _readVarint(Uint8List bytes, int offset) {
    var result = 0;
    var shift = 0;
    var current = offset;

    while (current < bytes.length) {
      final byte = bytes[current++];
      result |= (byte & 0x7F) << shift;

      if ((byte & 0x80) == 0) {
        return _VarintResult(result, current);
      }

      shift += 7;
      if (shift > 63) {
        throw const FormatException('Invalid protobuf varint.');
      }
    }

    throw const FormatException('Unexpected end of protobuf varint.');
  }

  static void _ensureAvailable(Uint8List bytes, int offset, int length) {
    if (length < 0 || offset + length > bytes.length) {
      throw const FormatException('Unexpected end of protobuf payload.');
    }
  }
}

class _VarintResult {
  final int value;
  final int nextOffset;

  const _VarintResult(this.value, this.nextOffset);
}
