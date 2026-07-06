import 'dart:convert';

import '../models/normalized_anpr_event.dart';
import 'csv_anpr_parser.dart';
import 'json_anpr_parser.dart';
import 'manual_protobuf_anpr_parser.dart';
import 'payload_format.dart';
import 'sql_anpr_parser.dart';
import 'xml_anpr_parser.dart';

import 'rasd_protobuf_decoder.dart';
class AnprPayloadParser {
  static NormalizedAnprEvent parse(dynamic input, {String? contentType}) {
    final rasdContentType = (contentType ?? '').toLowerCase();
    if (rasdContentType.contains('protobuf') ||
        rasdContentType.contains('x-protobuf') ||
        rasdContentType.contains('octet-stream') ||
        RasdProtobufDecoder.looksLikeRasdPayload(input)) {
      final rasdMap = RasdProtobufDecoder.decodeToJsonMap(input);
      return parse(jsonEncode(rasdMap), contentType: 'application/json');
    }


    final format = detectPayloadFormat(input, contentType: contentType);

    switch (format) {
      case PayloadFormat.json:
        return JsonAnprParser.parse(input.toString());
      case PayloadFormat.xml:
        return XmlAnprParser.parse(input.toString());
      case PayloadFormat.csv:
        return CsvAnprParser.parse(input.toString());
      case PayloadFormat.sql:
        return SqlAnprParser.parse(input.toString());
      case PayloadFormat.protobuf:
        if (input is List<int>) return ManualProtobufAnprParser.parse(input);
        return ManualProtobufAnprParser.parse(base64Decode(input.toString().trim()));
      case PayloadFormat.unknown:
        throw const FormatException('Unknown ANPR payload format');
    }
  }
}
