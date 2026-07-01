import 'package:flutter_test/flutter_test.dart';
import 'package:nightcapt_flutter/main.dart';

void main() {
  testWidgets('shows configuration screen without Supabase credentials', (
    tester,
  ) async {
    await tester.pumpWidget(const NightCaptApp());

    expect(find.text('NightCapt'), findsOneWidget);
    expect(find.text('Flutter app is ready for configuration'), findsOneWidget);
    expect(find.text('Open support page'), findsOneWidget);
  });
}
