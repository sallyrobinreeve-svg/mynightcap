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

/// Strip international prefixes and a trunk 0.
String nationalSignificantNumber(String value, String dialCode) {
  var digits = digitsOnly(value);
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  }
  final dialDigits = digitsOnly(dialCode);
  if (dialDigits.isNotEmpty &&
      digits.startsWith(dialDigits) &&
      digits.length > dialDigits.length + 6) {
    digits = digits.substring(dialDigits.length);
  }
  if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  return digits;
}

/// Normalize a national or pasted number into E.164, or null if invalid.
String? toE164(String dialCode, String nationalNumber) {
  final trimmed = nationalNumber.trim();
  if (trimmed.isEmpty) return null;

  final dialDigits = digitsOnly(dialCode);
  if (dialDigits.isEmpty && !trimmed.startsWith('+')) return null;

  if (trimmed.startsWith('+') &&
      dialDigits.isNotEmpty &&
      !digitsOnly(trimmed).startsWith(dialDigits)) {
    final e164 = '+${digitsOnly(trimmed)}';
    return _e164.hasMatch(e164) ? e164 : null;
  }

  final national = nationalSignificantNumber(
    trimmed,
    dialDigits.isEmpty ? dialCode : '+$dialDigits',
  );
  if (dialDigits.isEmpty || national.isEmpty) return null;
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

int? retryAfterSeconds(String message) {
  final match = RegExp(r'(\d+)\s*seconds?', caseSensitive: false).firstMatch(message);
  if (match == null) return null;
  final seconds = int.tryParse(match.group(1)!);
  if (seconds == null || seconds <= 0 || seconds > 3600) return null;
  return seconds;
}

bool isTransientAuthError(String message) {
  final m = message.toLowerCase();
  return m.contains('failed to fetch') ||
      m.contains('network') ||
      m.contains('timeout') ||
      m.contains('timed out') ||
      m.contains('load failed') ||
      m.contains('socket');
}

String friendlyAuthMessage(String message) {
  final m = message.toLowerCase();
  final wait = retryAfterSeconds(message);
  if (m.contains('signups not allowed') ||
      m.contains('user not found') ||
      m.contains('unable to find user')) {
    return 'No account found for this number. Create an account first.';
  }
  if (m.contains('error sending') ||
      m.contains('sms_send_failed') ||
      (m.contains('sms') && m.contains('error'))) {
    return "We couldn't send a verification text. Wait a moment, then tap resend. If it keeps failing, use email.";
  }
  if (m.contains('otp_expired') ||
      (m.contains('token') && (m.contains('expired') || m.contains('invalid')))) {
    return 'That code is invalid or expired. Request a new one and enter the latest text.';
  }
  if (m.contains('rate') ||
      m.contains('too many') ||
      m.contains('security purposes') ||
      m.contains('over_sms_send_rate_limit') ||
      m.contains('over_request_rate_limit')) {
    return wait == null
        ? 'Too many attempts. Wait a minute and try again.'
        : 'Too many attempts. Wait $wait seconds, then try again.';
  }
  if (m.contains('phone') && m.contains('invalid')) {
    return 'Enter a valid UK mobile, like 07123 456789.';
  }
  if (m.contains('unsupported phone provider') ||
      m.contains('phone provider') ||
      m.contains('phone_provider_disabled') ||
      m.contains('sms provider')) {
    return 'Phone sign-in is not set up yet. Use email, or try again later.';
  }
  if (isTransientAuthError(message)) {
    return "We couldn't reach the verification service. Check your connection and try again.";
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

  final digits = digitsOnly(trimmed);
  final international = trimmed.startsWith('+') || digits.startsWith('00');
  if (international && !digits.startsWith('44') && !digits.startsWith('0044')) {
    return const UkPhoneResult._(UkPhoneStatus.notUk);
  }
  if (!international && digits.startsWith('1') && digits.length == 11) {
    return const UkPhoneResult._(UkPhoneStatus.notUk);
  }

  final national = nationalSignificantNumber(trimmed, kDefaultDialCode);
  if (!international && national.length == 10 && !national.startsWith('7')) {
    if (national.startsWith('1') || national.startsWith('2')) {
      return const UkPhoneResult._(UkPhoneStatus.invalid);
    }
    return const UkPhoneResult._(UkPhoneStatus.notUk);
  }
  if (national.length == 10 &&
      (national.startsWith('1') || national.startsWith('2'))) {
    return const UkPhoneResult._(UkPhoneStatus.invalid);
  }

  final phone = '+44$national';
  if (!isUkMobile(phone)) {
    return const UkPhoneResult._(UkPhoneStatus.invalid);
  }
  return UkPhoneResult._(UkPhoneStatus.ok, phone);
}
