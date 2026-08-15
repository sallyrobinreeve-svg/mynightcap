import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightcapt_flutter/screens/phone_otp_form.dart';
import 'package:nightcapt_flutter/theme.dart';

void main() {
  testWidgets('phone verification form asks for a number and a send action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNightTheme(),
        home: const Scaffold(
          body: PhoneOtpForm(shouldCreateUser: false),
        ),
      ),
    );

    expect(find.text('UK mobile number'), findsOneWidget);
    expect(find.text('+44'), findsOneWidget);
    expect(find.text('Send verification code'), findsOneWidget);
    expect(find.text('Verification code'), findsNothing);
  });
}
