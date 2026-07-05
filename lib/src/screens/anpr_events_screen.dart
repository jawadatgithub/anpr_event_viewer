import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/text_direction_utils.dart';
import '../models/normalized_anpr_event.dart';
import '../repository/anpr_event_repository.dart';
import '../widgets/anpr_image_widget.dart';
import 'event_detail_screen.dart';
import 'import_payload_screen.dart';

class AnprEventsScreen extends ConsumerStatefulWidget {
  const AnprEventsScreen({super.key});

  @override
  ConsumerState<AnprEventsScreen> createState() => _AnprEventsScreenState();
}

class _AnprEventsScreenState extends ConsumerState<AnprEventsScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(anprEventsProvider);
    final filtered = events.where((event) {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return [
        event.plateNumber,
        event.plateNumberArabic,
        event.cameraName,
        event.locationName,
        event.direction,
        event.sourceFormat,
        event.country,
        event.emirate,
      ].whereType<String>().any((value) => value.toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          children: [
            Image.asset('assets/branding/insysout_logo.png', width: 34, height: 34),
            const SizedBox(width: 8),
            const Expanded(child: Text('InSysOut ANPR Viewer')),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reload samples',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(anprEventsProvider.notifier).loadSamples(),
          ),
          IconButton(
            tooltip: 'Import payload',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              final message = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_) => const ImportPayloadScreen()),
              );

              if (!context.mounted || message == null || message.isEmpty) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search plate, camera, location...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No ANPR events found'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, index) => _EventCard(event: filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final NormalizedAnprEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final timestamp = event.timestamp == null
        ? 'Unknown time'
        : DateFormat('yyyy-MM-dd HH:mm:ss').format(event.timestamp!.toLocal());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 128,
                child: AnprImageWidget(
                  image: event.vehicleImage ?? event.plateImage,
                  height: 82,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(event.sourceFormat),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SmartText(
                            event.displayPlate,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(event.displayLocation, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${event.direction ?? 'Unknown'} • ${event.confidence?.toStringAsFixed(1) ?? '--'}%'),
                    Text(timestamp, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
