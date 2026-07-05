import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/screens/anpr_events_screen.dart';

void main() => runApp(const ProviderScope(child: AnprEventViewerApp()));

class AnprEventViewerApp extends StatelessWidget {
  const AnprEventViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InSysOut ANPR Viewer',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1D4ED8),
        brightness: Brightness.dark,
      ),
      home: const AnprEventsScreen(),
    );
  }
}
