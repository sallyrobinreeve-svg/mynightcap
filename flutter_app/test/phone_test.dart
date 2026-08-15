import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightcapt_flutter/phone.dart';

void main() {
  group('toE164', () {
    test('formats a UK number and strips the leading 0', () {
      expect(toE164('+44', '07123 456789'), '+447123456789');
    });

    test('formats a US number', () {
      expect(toE164('+1', '(415) 555-2671'), '+14155552671');
    });

    test('accepts a pasted international number', () {
      expect(toE164('+1', '+44 7123 456789'), '+447123456789');
    });

    test('rejects numbers that are too short', () {
      expect(toE164('+44', '07123'), isNull);
    });
  });

  group('isValidOtp', () {
    test('accepts a 6-digit code', () {
      expect(isValidOtp('123456'), isTrue);
    });

    test('rejects short codes', () {
      expect(isValidOtp('12345'), isFalse);
    });
  });

  test('maskPhone keeps prefix and last three digits', () {
    expect(maskPhone('+447123456789'), '+447••••••789');
  });

  test('friendlyAuthMessage maps missing-user errors', () {
    expect(
      friendlyAuthMessage('Signups not allowed for otp'),
      'No account found for this number. Create an account first.',
    );
  });

  test('preferUkPhoneAuth is true for GB locales', () {
    expect(preferUkPhoneAuth(const Locale('en', 'GB')), isTrue);
    expect(preferUkPhoneAuth(const Locale('en', 'US')), isFalse);
  });

  test('parseUkLoginPhone accepts UK mobiles and rejects US numbers', () {
    expect(parseUkLoginPhone('07123 456789').status, UkPhoneStatus.ok);
    expect(parseUkLoginPhone('07123 456789').phone, '+447123456789');
    expect(parseUkLoginPhone('+1 415 555 2671').status, UkPhoneStatus.notUk);
    expect(parseUkLoginPhone('020 7946 0958').status, UkPhoneStatus.invalid);
  });
}
