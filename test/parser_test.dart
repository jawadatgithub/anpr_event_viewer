import 'package:flutter_test/flutter_test.dart';
import 'package:insysout_anpr_event_viewer/src/parsers/anpr_payload_parser.dart';

const tinyBase64Png =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';

void main() {
  test('JSON parser reads nested base64 vehicle image', () {
    final event = AnprPayloadParser.parse('''
    {
      "eventId": "ANPR-GCC-TEST",
      "plateNumber": "DXB-A-1234",
      "camera": {"cameraName": "Main Gate"},
      "images": {"vehicleImage": "$tinyBase64Png"}
    }
    ''');

    expect(event.id, 'ANPR-GCC-TEST');
    expect(event.plateNumber, 'DXB-A-1234');
    expect(event.cameraName, 'Main Gate');
    expect(event.vehicleImage, isNotNull);
    expect(event.vehicleImage!.value, startsWith('data:image/png;base64,'));
  });

  test('XML parser reads image inside images node', () {
    final event = AnprPayloadParser.parse('''
    <anprEvent>
      <eventId>ANPR-XML-TEST</eventId>
      <plateNumber>QAT-B-2020</plateNumber>
      <images><vehicleImage>$tinyBase64Png</vehicleImage></images>
    </anprEvent>
    ''');

    expect(event.id, 'ANPR-XML-TEST');
    expect(event.vehicleImage, isNotNull);
  });

  test('CSV parser reads base64 vehicle image', () {
    final event = AnprPayloadParser.parse('''
eventId,plateNumber,vehicleImage
ANPR-CSV-TEST,KSA-C-3030,"$tinyBase64Png"
''', contentType: 'text/csv');

    expect(event.id, 'ANPR-CSV-TEST');
    expect(event.vehicleImage, isNotNull);
  });

  test('SQL parser reads base64 vehicle image', () {
    final event = AnprPayloadParser.parse('''
INSERT INTO anpr_events (eventId, plateNumber, vehicleImage)
VALUES ('ANPR-SQL-TEST', 'OMN-D-4040', '$tinyBase64Png');
''', contentType: 'application/sql');

    expect(event.id, 'ANPR-SQL-TEST');
    expect(event.vehicleImage, isNotNull);
  });
}
