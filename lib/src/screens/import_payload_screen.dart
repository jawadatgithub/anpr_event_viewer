import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/anpr_event_repository.dart';
import '../services/anpr_file_import_service.dart';
import '../services/google_drive_import_service.dart';
import '../services/imported_payload.dart';

class ImportPayloadScreen extends ConsumerStatefulWidget {
  const ImportPayloadScreen({super.key});

  @override
  ConsumerState<ImportPayloadScreen> createState() => _ImportPayloadScreenState();
}

class _ImportPayloadScreenState extends ConsumerState<ImportPayloadScreen> {
  final controller = TextEditingController();
  final fileImportService = const AnprFileImportService();
  final googleDriveImportService = GoogleDriveImportService();

  String contentType = 'auto';
  String? error;
  String? success;
  bool busy = false;
  List<DrivePayloadFile> driveFiles = const [];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
      success = null;
    });

    try {
      await action();
    } catch (e) {
      final message = e.toString();
      setState(() => error = message);
      if (e is DailyEventLimitExceeded && mounted) {
        await _showProUpgradeMessage(message);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _showProUpgradeMessage(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily limit reached'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _closeAfterSuccessfulImport(String message) {
    if (!mounted) return;
    Navigator.of(context).pop(message);
  }

  Future<void> _parsePastedPayload() async {
    await _runBusy(() async {
      final text = controller.text.trim();
      if (text.isEmpty) throw const FormatException('Paste a payload first.');

      final event = ref.read(anprEventsProvider.notifier).addFromPayload(
            text,
            contentType: contentType == 'auto' ? null : contentType,
          );

      setState(() => success = 'Added event ${event.id} from pasted payload.');
    });
  }

  Future<void> _pickLocalFiles() async {
    await _runBusy(() async {
      final payloads = await fileImportService.pickPayloadFiles();
      if (payloads.isEmpty) {
        setState(() => success = 'No files selected.');
        return;
      }

      final result = _importPayloads(payloads);
      if (result.successCount > 0 && result.failures.isEmpty) {
        _closeAfterSuccessfulImport('Imported ${result.successCount}/${payloads.length} file(s).');
        return;
      }

      setState(() {
        success = result.successCount > 0 ? 'Imported ${result.successCount}/${payloads.length} file(s).' : null;
        error = result.errorText ?? 'No files were imported.';
      });
      if (result.hitDailyLimit && mounted) {
        await _showProUpgradeMessage(proUpgradeMessage);
      }
    });
  }

  Future<void> _loadDriveFiles() async {
    await _runBusy(() async {
      final files = await googleDriveImportService.listPayloadFiles();
      setState(() {
        driveFiles = files;
        success = files.isEmpty
            ? 'No supported ANPR payload files found in Google Drive.'
            : 'Found ${files.length} supported Google Drive file(s).';
      });
    });
  }

  Future<void> _importDriveFile(DrivePayloadFile file) async {
    await _runBusy(() async {
      final payload = await googleDriveImportService.downloadPayloadFile(file);
      final result = _importPayloads([payload]);
      if (result.successCount == 1 && result.failures.isEmpty) {
        _closeAfterSuccessfulImport('Imported ${file.name}.');
        return;
      }

      setState(() {
        success = null;
        error = result.errorText ?? 'Could not import ${file.name}.';
      });
      if (result.hitDailyLimit && mounted) {
        await _showProUpgradeMessage(proUpgradeMessage);
      }
    });
  }

  _BulkImportResult _importPayloads(List<ImportedPayload> payloads) {
    var successCount = 0;
    var hitDailyLimit = false;
    final failures = <String>[];

    for (final payload in payloads) {
      try {
        ref.read(anprEventsProvider.notifier).addFromImportedPayload(payload);
        successCount++;
      } catch (e) {
        if (e is DailyEventLimitExceeded) {
          hitDailyLimit = true;
          failures.add('${payload.name}: $proUpgradeMessage');
          break;
        }

        failures.add('${payload.name}: $e');
      }
    }

    return _BulkImportResult(
      successCount: successCount,
      failures: failures,
      hitDailyLimit: hitDailyLimit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import ANPR Payload')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildImportSourceCards(context),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: contentType,
            decoration: const InputDecoration(labelText: 'Pasted payload format'),
            items: const [
              DropdownMenuItem(value: 'auto', child: Text('Auto detect')),
              DropdownMenuItem(value: 'application/json', child: Text('JSON')),
              DropdownMenuItem(value: 'application/xml', child: Text('XML')),
              DropdownMenuItem(value: 'text/csv', child: Text('CSV')),
              DropdownMenuItem(value: 'application/sql', child: Text('SQL INSERT')),
              DropdownMenuItem(value: 'application/x-protobuf', child: Text('Protobuf base64')),
            ],
            onChanged: busy ? null : (value) => setState(() => contentType = value ?? 'auto'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            enabled: !busy,
            minLines: 12,
            maxLines: 22,
            decoration: const InputDecoration(
              hintText: 'Paste JSON, XML, CSV, SQL INSERT, or base64 protobuf payload...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (busy) const LinearProgressIndicator(),
          if (success != null) ...[
            const SizedBox(height: 8),
            Text(
              success!,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text('Parse Pasted Payload'),
            onPressed: busy ? null : _parsePastedPayload,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.data_object),
            label: const Text('Insert JSON Example With Base64 Image'),
            onPressed: busy
                ? null
                : () {
                    controller.text = _exampleJson;
                    setState(() => contentType = 'application/json');
                  },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.code),
            label: const Text('Insert XML Example'),
            onPressed: busy
                ? null
                : () {
                    controller.text = _exampleXml;
                    setState(() => contentType = 'application/xml');
                  },
          ),
          const SizedBox(height: 16),
          _buildDriveFilesList(context),
          const SizedBox(height: 8),
          Text(
            'Supported import types: .json, .xml, .csv, .sql, .pb, .protobuf, .bin. On Windows, use Files to pick from a synced Google Drive folder. Direct Google Drive OAuth is supported on Android, iOS, macOS, and Web only after OAuth client configuration.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildImportSourceCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add events from', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Files'),
              onPressed: busy ? null : _pickLocalFiles,
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.cloud_queue),
              label: const Text('Google Drive'),
              onPressed: busy ? null : _loadDriveFiles,
            ),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.content_paste),
              label: const Text('Paste'),
              onPressed: busy ? null : () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriveFilesList(BuildContext context) {
    if (driveFiles.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_queue),
                const SizedBox(width: 8),
                Text('Google Drive files', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: busy ? null : _loadDriveFiles,
                ),
              ],
            ),
            const Divider(),
            for (final file in driveFiles)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(_iconForContentType(file.contentType)),
                title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text([
                  file.contentType,
                  if (file.size != null) '${file.size} bytes',
                ].join(' • ')),
                trailing: IconButton(
                  tooltip: 'Import',
                  icon: const Icon(Icons.download),
                  onPressed: busy ? null : () => _importDriveFile(file),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForContentType(String contentType) {
  if (contentType.contains('json')) return Icons.data_object;
  if (contentType.contains('xml')) return Icons.code;
  if (contentType.contains('csv')) return Icons.table_chart;
  if (contentType.contains('sql')) return Icons.storage;
  if (contentType.contains('protobuf')) return Icons.memory;
  return Icons.description;
}

class _BulkImportResult {
  final int successCount;
  final List<String> failures;
  final bool hitDailyLimit;

  const _BulkImportResult({
    required this.successCount,
    required this.failures,
    this.hitDailyLimit = false,
  });

  String? get errorText => failures.isEmpty ? null : failures.join('\n');
}

const _tinyBase64Png =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';

const _exampleJson = '''
{
  "eventId": "manual-json-001",
  "plateNumber": "DXB-C-9090",
  "plateNumberArabic": "دبي ج ٩٠٩٠",
  "camera": {
    "cameraName": "Main Gate",
    "locationName": "Operations Center",
    "direction": "Entry"
  },
  "confidence": 97.4,
  "timestamp": "2026-05-19T13:20:00+04:00",
  "images": {
    "vehicleImage": "$_tinyBase64Png",
    "plateImage": "$_tinyBase64Png"
  }
}
''';

const _exampleXml = '''
<anprEvent>
  <eventId>manual-xml-001</eventId>
  <plateNumber>DXB C 9090</plateNumber>
  <plateNumberArabic>دبي ج ٩٠٩٠</plateNumberArabic>
  <camera>
    <cameraName>Main Gate</cameraName>
    <locationName>Operations Center</locationName>
    <direction>Entry</direction>
  </camera>
  <confidence>93.9</confidence>
  <timestamp>2026-05-19T14:05:00+04:00</timestamp>
  <images>
    <vehicleImage>$_tinyBase64Png</vehicleImage>
    <plateImage>$_tinyBase64Png</plateImage>
  </images>
</anprEvent>
''';
