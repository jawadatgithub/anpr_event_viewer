import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/text_direction_utils.dart';
import '../models/normalized_anpr_event.dart';
import '../widgets/anpr_image_widget.dart';
import '../widgets/event_field_row.dart';

class EventDetailScreen extends StatelessWidget {
  final NormalizedAnprEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final timestamp = event.timestamp == null
        ? null
        : DateFormat('yyyy-MM-dd HH:mm:ss').format(event.timestamp!.toLocal());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: SmartText(event.displayPlate),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Event'),
              Tab(text: 'Raw'),
              Tab(text: 'Fields'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AnprImageWidget(image: event.vehicleImage ?? event.plateImage, height: 240),
                const SizedBox(height: 12),
                if (event.plateImage != null) AnprImageWidget(image: event.plateImage, height: 96, fit: BoxFit.contain),
                const SizedBox(height: 20),
                EventFieldRow(label: 'Plate', value: event.plateNumber),
                EventFieldRow(label: 'Arabic Plate', value: event.plateNumberArabic),
                EventFieldRow(label: 'Country', value: event.country),
                EventFieldRow(label: 'Emirate/Region', value: event.emirate),
                EventFieldRow(label: 'Vehicle Type', value: event.vehicleType),
                EventFieldRow(label: 'Color', value: event.vehicleColor),
                EventFieldRow(label: 'Make', value: event.make),
                EventFieldRow(label: 'Model', value: event.model),
                EventFieldRow(label: 'Camera ID', value: event.cameraId),
                EventFieldRow(label: 'Camera', value: event.cameraName),
                EventFieldRow(label: 'Location', value: event.locationName),
                EventFieldRow(label: 'Lane', value: event.lane),
                EventFieldRow(label: 'Direction', value: event.direction),
                EventFieldRow(label: 'Confidence', value: event.confidence?.toStringAsFixed(2)),
                EventFieldRow(label: 'Timestamp', value: timestamp),
                EventFieldRow(label: 'Source', value: event.sourceFormat),
              ],
            ),
            _CodeView(text: event.rawPayload),
            _CodeView(text: const JsonEncoder.withIndent('  ').convert(event.rawFields)),
          ],
        ),
      ),
    );
  }
}

class _CodeView extends StatelessWidget {
  final String text;

  const _CodeView({required this.text});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }
}
