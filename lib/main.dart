import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/screens/anpr_events_screen.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: AnprEventViewerApp()));
}

class AnprEventViewerApp extends StatelessWidget {
  const AnprEventViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InSysOut ANPR Viewer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const AnprEventsScreen(),
    );
  }
}
