import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:insysout_anpr_event_viewer/main.dart';

void main() {
  testWidgets('ANPR app launches', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AnprEventViewerApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('InSysOut ANPR Viewer'), findsOneWidget);
  });
}
