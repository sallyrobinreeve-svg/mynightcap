import 'package:flutter/widgets.dart';

const kDefaultDialCode = '+44';
const kUkPhoneAuthCopy =
    'Phone authentication is for UK users only. If you\'re outside the UK, use email.';

class DialCode {
  const DialCode(this.dial, this.label);

  final String dial;
  final String label;
}

const kDialCodes = [
  DialCode('+44', 'UK +44'),
  DialCode('+1', 'US/CA +1'),
  DialCode('+353', 'IE +353'),
  DialCode('+61', 'AU +61'),
  DialCode('+64', 'NZ +64'),
  DialCode('+33', 'FR +33'),
  DialCode('+49', 'DE +49'),
  DialCode('+34', 'ES +34'),
  DialCode('+39', 'IT +39'),
  DialCode('+31', 'NL +31'),
  DialCode('+46', 'SE +46'),
  DialCode('+47', 'NO +47'),
  DialCode('+45', 'DK +45'),
  DialCode('+48', 'PL +48'),
  DialCode('+351', 'PT +351'),
  DialCode('+91', 'IN +91'),
  DialCode('+27', 'ZA +27'),
  DialCode('+65', 'SG +65'),
  DialCode('+852', 'HK +852'),
  DialCode('+81', 'JP +81'),
];

final _e164 = RegExp(r'^\+[1-9]\d{7,14}$');

String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

/// Normalize a national or pasted number into E.164, or null if invalid.
String? toE164(String dialCode, String nationalNumber) {
  final trimmed = nationalNumber.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('+')) {
    final e164 = '+${digitsOnly(trimmed)}';
    return _e164.hasMatch(e164) ? e164 : null;
  }

  final dialDigits = digitsOnly(dialCode);
  if (dialDigits.isEmpty) return null;

  var national = digitsOnly(trimmed);
  if (national.startsWith('0')) {
    national = national.substring(1);
  }
  if (national.startsWith(dialDigits) &&
      national.length > dialDigits.length + 6) {
    national = national.substring(dialDigits.length);
  }

  final e164 = '+$dialDigits$national';
  return _e164.hasMatch(e164) ? e164 : null;
}

bool isValidOtp(String token) => RegExp(r'^\d{6}$').hasMatch(token.trim());

/// Mask a phone number for UI copy, e.g. +447••••••789.
String maskPhone(String e164) {
  final digits = digitsOnly(e164);
  if (digits.length < 8) return e164;
  final start = digits.substring(0, 3);
  final end = digits.substring(digits.length - 3);
  return '+$start${'•' * (digits.length - 6)}$end';
}

String friendlyAuthMessage(String message) {
  final m = message.toLowerCase();
  if (m.contains('signups not allowed') ||
      m.contains('user not found') ||
      m.contains('unable to find user')) {
    return 'No account found for this number. Create an account first.';
  }
  if (m.contains('error sending') || (m.contains('sms') && m.contains('error'))) {
    return "We couldn't send a verification text. Try again in a moment.";
  }
  if (m.contains('token') && (m.contains('expired') || m.contains('invalid'))) {
    return 'That code is invalid or expired. Request a new one.';
  }
  if (m.contains('rate') ||
      m.contains('too many') ||
      m.contains('over_sms_send_rate_limit')) {
    return 'Too many attempts. Wait a minute and try again.';
  }
  if (m.contains('phone') && m.contains('invalid')) {
    return 'Enter a valid mobile number including country code.';
  }
  if (m.contains('unsupported phone provider') || m.contains('phone provider')) {
    return 'Phone sign-in is not set up yet. Use email, or try again later.';
  }
  return message;
}

bool isUkMobile(String e164) => RegExp(r'^\+447\d{9}$').hasMatch(e164.trim());

bool preferUkPhoneAuth([Locale? locale]) {
  final resolved = locale ?? WidgetsBinding.instance.platformDispatcher.locale;
  final country = (resolved.countryCode ?? '').toUpperCase();
  if (country == 'GB' || country == 'UK') return true;
  final tag = resolved.toLanguageTag().toLowerCase();
  return tag.contains('-gb') || tag.contains('_gb');
}

enum UkPhoneStatus { ok, invalid, notUk }

class UkPhoneResult {
  const UkPhoneResult._(this.status, [this.phone]);

  final UkPhoneStatus status;
  final String? phone;
}

UkPhoneResult parseUkLoginPhone(String nationalNumber) {
  final trimmed = nationalNumber.trim();
  if (trimmed.isEmpty) {
    return const UkPhoneResult._(UkPhoneStatus.invalid);
  }
  if (trimmed.startsWith('+') && !trimmed.startsWith('+44')) {
    return const UkPhoneResult._(UkPhoneStatus.notUk);
  }
  final digits = digitsOnly(trimmed);
  final withoutLeadingZero =
      digits.startsWith('0') ? digits.substring(1) : digits;
  if (digits.startsWith('1') && digits.length == 11) {
    return const UkPhoneResult._(UkPhoneStatus.notUk);
  }
  if (withoutLeadingZero.length == 10 && !withoutLeadingZero.startsWith('7')) {
    if (withoutLeadingZero.startsWith('1') ||
        withoutLeadingZero.startsWith('2')) {
      return const UkPhoneResult._(UkPhoneStatus.invalid);
    }
    return const UkPhoneResult._(UkPhoneStatus.notUk);
  }
  final phone = toE164(kDefaultDialCode, trimmed);
  if (phone == null) {
    return const UkPhoneResult._(UkPhoneStatus.invalid);
  }
  if (!phone.startsWith(kDefaultDialCode)) {
    return const UkPhoneResult._(UkPhoneStatus.notUk);
  }
  if (!isUkMobile(phone)) {
    return const UkPhoneResult._(UkPhoneStatus.invalid);
  }
  return UkPhoneResult._(UkPhoneStatus.ok, phone);
}
