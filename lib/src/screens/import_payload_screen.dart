import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/anpr_event_repository.dart';
import '../services/anpr_file_import_service.dart';
import '../services/imported_payload.dart';

class ImportPayloadScreen extends ConsumerStatefulWidget {
  const ImportPayloadScreen({super.key});

  @override
  ConsumerState<ImportPayloadScreen> createState() => _ImportPayloadScreenState();
}

class _ImportPayloadScreenState extends ConsumerState<ImportPayloadScreen> {
  final TextEditingController payloadController = TextEditingController();
  final AnprFileImportService fileImportService = AnprFileImportService();

  String contentType = 'auto';
  bool busy = false;
  String? error;
  String? success;

  @override
  void dispose() {
    payloadController.dispose();
    super.dispose();
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (busy) return;

    setState(() {
      busy = true;
      error = null;
      success = null;
    });

    try {
      await action();
    } catch (e) {
      final message = _cleanError(e);
      if (!mounted) return;
      setState(() => error = message);
      if (e is DailyEventLimitExceeded) {
        await _showProUpgradeMessage(message);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _cleanError(Object e) {
    final text = e.toString();
    return text.startsWith('Exception: ') ? text.substring('Exception: '.length) : text;
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

  Future<void> _parsePastedPayload() async {
    await _runBusy(() async {
      final payload = payloadController.text.trim();
      if (payload.isEmpty) {
        throw Exception('Paste an ANPR payload first.');
      }

      ref.read(anprEventsProvider.notifier).addFromPayload(
            payload,
            contentType: _contentTypeForParser,
          );

      if (!mounted) return;
      setState(() => success = 'Payload imported successfully.');
    });
  }

  String? get _contentTypeForParser {
    switch (contentType) {
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'csv':
        return 'text/csv';
      case 'sql':
        return 'text/sql';
      case 'protobuf':
        return 'application/protobuf';
      case 'auto':
      default:
        return null;
    }
  }

  _BulkImportResult _importPayloads(List<ImportedPayload> payloads) {
    var successCount = 0;
    final failures = <String>[];

    for (final payload in payloads) {
      try {
        ref.read(anprEventsProvider.notifier).addFromImportedPayload(payload);
        successCount++;
      } catch (e) {
        failures.add(_cleanError(e));
      }
    }

    return _BulkImportResult(successCount: successCount, failures: failures);
  }

  void _insertJsonExample() {
    setState(() {
      contentType = 'json';
      payloadController.text = _jsonExample;
      error = null;
      success = 'JSON example inserted.';
    });
  }

  void _insertXmlExample() {
    setState(() {
      contentType = 'xml';
      payloadController.text = _xmlExample;
      error = null;
      success = 'XML example inserted.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/branding/insysout_app_icon.png',
              width: 34,
              height: 34,
              errorBuilder: (_, __, ___) => const Icon(Icons.document_scanner_outlined),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Import ANPR Payload')),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add events from',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ImportActionButton(
                        icon: Icons.folder_outlined,
                        label: 'Files',
                        onPressed: busy ? null : _pickLocalFiles,
                      ),
                      _ImportActionButton(
                        icon: Icons.paste_outlined,
                        label: 'Paste',
                        onPressed: busy
                            ? null
                            : () {
                                FocusScope.of(context).requestFocus(FocusNode());
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Google Drive files are supported through the standard Files picker on iOS and through synced folders on desktop.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pasted payload format',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: contentType,
              decoration: const InputDecoration(),
              items: const [
                DropdownMenuItem(value: 'auto', child: Text('Auto detect')),
                DropdownMenuItem(value: 'json', child: Text('JSON')),
                DropdownMenuItem(value: 'xml', child: Text('XML')),
                DropdownMenuItem(value: 'csv', child: Text('CSV')),
                DropdownMenuItem(value: 'sql', child: Text('SQL')),
                DropdownMenuItem(value: 'protobuf', child: Text('Protobuf')),
              ],
              onChanged: busy ? null : (value) => setState(() => contentType = value ?? 'auto'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: payloadController,
              minLines: 14,
              maxLines: 22,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.35),
              decoration: const InputDecoration(
                hintText: 'Paste JSON, XML, CSV, SQL, or Protobuf/base64 payload here...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: busy ? null : _parsePastedPayload,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(busy ? 'Please wait...' : 'Parse Pasted Payload'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: busy ? null : _insertJsonExample,
              icon: const Icon(Icons.data_object),
              label: const Text('Insert JSON Example With Base64 Image'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: busy ? null : _insertXmlExample,
              icon: const Icon(Icons.code),
              label: const Text('Insert XML Example'),
            ),
            if (success != null) ...[
              const SizedBox(height: 14),
              _StatusBox(message: success!, isError: false),
            ],
            if (error != null) ...[
              const SizedBox(height: 14),
              _StatusBox(message: error!, isError: true),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Supported import types: .json, .xml, .csv, .sql, .pb, .protobuf, .bin.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _ImportActionButton extends StatelessWidget {
  const _ImportActionButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isError ? colors.errorContainer : colors.tertiaryContainer.withValues(alpha: .45),
        border: Border.all(color: isError ? colors.error : colors.tertiary.withValues(alpha: .7)),
      ),
      child: Text(
        message,
        style: TextStyle(color: isError ? colors.onErrorContainer : colors.onSurface),
      ),
    );
  }
}

class _BulkImportResult {
  final int successCount;
  final List<String> failures;

  const _BulkImportResult({required this.successCount, required this.failures});

  bool get hitDailyLimit => failures.any((failure) => failure.contains(proUpgradeMessage));

  String? get errorText => failures.isEmpty ? null : failures.join('\n');
}

const String _jsonExample = '''{
  "eventId": "EVT-2026-05-19-0001",
  "plateNumber": "DXB-C-1037",
  "plateNumberArabic": "الشارقة ج ١٠٣٧",
  "country": "United Arab Emirates",
  "emirate": "Sharjah",
  "cameraId": "CAM-02",
  "camera": "North Barrier",
  "location": "Sharjah Smart Gate 2",
  "lane": "2",
  "direction": "Entry",
  "confidence": 87.4,
  "timestamp": "2026-05-19T08:07:00Z",
  "vehicle": {
    "type": "Sedan",
    "color": "White",
    "make": "Toyota",
    "model": "Camry"
  },
  "images": {
    "vehicleImage": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/lY0Y2QAAAABJRU5ErkJggg=="
  }
}''';

const String _xmlExample = '''<anprEvent>
  <eventId>EVT-2026-05-19-0002</eventId>
  <plateNumber>KSA-M-1111</plateNumber>
  <country>Saudi Arabia</country>
  <camera>Riyadh Smart Gate 3</camera>
  <location>Riyadh Smart Gate 3</location>
  <direction>Exit</direction>
  <confidence>94.8</confidence>
  <timestamp>2026-05-19T08:14:00Z</timestamp>
  <vehicle>
    <type>Sedan</type>
    <color>Black</color>
    <make>Mercedes</make>
  </vehicle>
</anprEvent>''';
