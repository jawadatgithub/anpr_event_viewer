import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/normalized_anpr_event.dart';
import '../parsers/anpr_payload_parser.dart';
import '../services/imported_payload.dart';

const int freeDailyEventLimit = 10;

const String proUpgradeMessage =
    'Buy the pro version, which include unlimited events per day and custom schema definition.\n'
    'for features request: contact hello@insysout.com';

final anprRepositoryProvider = Provider((ref) => AnprEventRepository());

final anprEventsProvider = StateNotifierProvider<AnprEventsNotifier, List<NormalizedAnprEvent>>(
  (ref) => AnprEventsNotifier(ref.read(anprRepositoryProvider)),
);

class DailyEventLimitExceeded implements Exception {
  const DailyEventLimitExceeded();

  @override
  String toString() => proUpgradeMessage;
}

class AnprEventRepository {
  Future<List<NormalizedAnprEvent>> loadSamples() async {
    final json = await rootBundle.loadString('assets/samples/sample_event.json');
    final xml = await rootBundle.loadString('assets/samples/sample_event.xml');

    return [
      AnprPayloadParser.parse(json, contentType: 'application/json'),
      AnprPayloadParser.parse(xml, contentType: 'application/xml'),
    ];
  }
}

class AnprEventsNotifier extends StateNotifier<List<NormalizedAnprEvent>> {
  final AnprEventRepository repository;

  AnprEventsNotifier(this.repository) : super(const []) {
    loadSamples();
  }

  Future<void> loadSamples() async {
    state = await repository.loadSamples();
  }

  NormalizedAnprEvent addFromPayload(String payload, {String? contentType}) {
    final event = AnprPayloadParser.parse(payload, contentType: contentType);
    _ensureDailyLimit([event]);
    state = [event, ...state];
    return event;
  }

  NormalizedAnprEvent addFromImportedPayload(ImportedPayload payload) {
    final event = AnprPayloadParser.parse(
      payload.parserInput,
      contentType: payload.resolvedContentType == 'auto' ? null : payload.resolvedContentType,
    );
    _ensureDailyLimit([event]);
    state = [event, ...state];
    return event;
  }

  List<NormalizedAnprEvent> addFromImportedPayloads(List<ImportedPayload> payloads) {
    final parsedEvents = <NormalizedAnprEvent>[];
    for (final payload in payloads) {
      parsedEvents.add(
        AnprPayloadParser.parse(
          payload.parserInput,
          contentType: payload.resolvedContentType == 'auto' ? null : payload.resolvedContentType,
        ),
      );
    }

    if (parsedEvents.isNotEmpty) {
      _ensureDailyLimit(parsedEvents);
      state = [...parsedEvents.reversed, ...state];
    }
    return parsedEvents;
  }

  void clear() => state = const [];

  int countForDay(DateTime day) {
    final key = _dayKey(day);
    return state.where((event) => _dayKey(_eventDay(event)) == key).length;
  }

  int remainingForDay(DateTime day) {
    final remaining = freeDailyEventLimit - countForDay(day);
    return remaining < 0 ? 0 : remaining;
  }

  void _ensureDailyLimit(List<NormalizedAnprEvent> incomingEvents) {
    final counts = <String, int>{};

    for (final event in state) {
      final key = _dayKey(_eventDay(event));
      counts[key] = (counts[key] ?? 0) + 1;
    }

    for (final event in incomingEvents) {
      final key = _dayKey(_eventDay(event));
      final current = counts[key] ?? 0;
      if (current >= freeDailyEventLimit) {
        throw const DailyEventLimitExceeded();
      }
      counts[key] = current + 1;
    }
  }

  DateTime _eventDay(NormalizedAnprEvent event) {
    final dt = (event.timestamp ?? DateTime.now()).toLocal();
    return DateTime(dt.year, dt.month, dt.day);
  }

  String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}
