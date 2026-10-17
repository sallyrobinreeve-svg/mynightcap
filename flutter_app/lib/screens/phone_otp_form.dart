import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../phone.dart';
import '../theme.dart';
import '../widgets/night_widgets.dart';

class PhoneOtpForm extends StatefulWidget {
  const PhoneOtpForm({
    super.key,
    required this.shouldCreateUser,
    this.userMetadata,
    this.validateBeforeSend,
    this.onVerified,
    this.onRequireEmail,
    this.submitLabel = 'Send verification code',
  });

  final bool shouldCreateUser;
  final Map<String, dynamic> Function()? userMetadata;
  final String? Function()? validateBeforeSend;
  final Future<void> Function()? onVerified;
  final VoidCallback? onRequireEmail;
  final String submitLabel;

  @override
  State<PhoneOtpForm> createState() => _PhoneOtpFormState();
}

class _PhoneOtpFormState extends State<PhoneOtpForm> {
  final number = TextEditingController();
  final otp = TextEditingController();
  final otpFocus = FocusNode();
  String? sentTo;
  String? message;
  bool loading = false;
  bool codeVisible = false;
  int cooldown = 0;
  Timer? _timer;
  String? _attemptedOtp;
  bool _verifyLock = false;

  @override
  void initState() {
    super.initState();
    otp.addListener(_onOtpChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    otp.removeListener(_onOtpChanged);
    number.dispose();
    otp.dispose();
    otpFocus.dispose();
    super.dispose();
  }

  void _onOtpChanged() {
    final phone = sentTo;
    final code = otp.text.trim();
    if (phone == null || !isValidOtp(code) || _verifyLock || loading) return;
    final key = '$phone:$code';
    if (_attemptedOtp == key) return;
    _attemptedOtp = key;
    verifyCode();
  }

  bool _samePhone(String? a, String? b) {
    if (a == null || b == null) return false;
    return digitsOnly(a) == digitsOnly(b);
  }

  void _startCooldown([int seconds = 60]) {
    _timer?.cancel();
    setState(() => cooldown = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (cooldown <= 1) {
        timer.cancel();
        setState(() => cooldown = 0);
        return;
      }
      setState(() => cooldown -= 1);
    });
  }

  Future<void> sendCode() async {
    final blocked = widget.validateBeforeSend?.call();
    if (blocked != null) {
      setState(() => message = blocked);
      return;
    }

    final parsed = parseUkLoginPhone(number.text);
    if (parsed.status == UkPhoneStatus.notUk) {
      setState(
        () =>
            message = 'Phone login is for UK numbers only. Use email instead.',
      );
      widget.onRequireEmail?.call();
      return;
    }
    if (parsed.status != UkPhoneStatus.ok || parsed.phone == null) {
      setState(() => message = 'Enter a valid UK mobile number, or use email.');
      return;
    }
    final phone = parsed.phone!;
    final resend = sentTo != null;
    if (resend) otp.text = '';

    setState(() {
      loading = true;
      message = 'Sending the code. Enter it as soon as the text arrives.';
      codeVisible = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) otpFocus.requestFocus();
    });
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final pending = Supabase.instance.client.auth.signInWithOtp(
          phone: phone,
          shouldCreateUser: widget.shouldCreateUser,
          data: widget.userMetadata?.call(),
          channel: OtpChannel.sms,
        );
        unawaited(pending.then<void>((_) {}, onError: (_) {}));
        await pending.timeout(const Duration(seconds: 20));
        if (!mounted) return;
        _attemptedOtp = null;
        setState(() {
          sentTo = phone;
          message =
              'Code sent to ${maskPhone(phone)}. Enter it here when the text arrives.';
          loading = false;
        });
        _startCooldown();
        if (isValidOtp(otp.text)) unawaited(verifyCode());
        return;
      } on TimeoutException {
        if (!mounted) return;
        setState(() {
          sentTo = phone;
          message =
              'The text is taking a moment. Enter the code if it arrives, or tap resend.';
          loading = false;
        });
        _startCooldown(30);
        if (isValidOtp(otp.text)) unawaited(verifyCode());
        return;
      } on AuthException catch (error) {
        lastError = error;
        if (attempt == 0 && isImmediateNetworkError(error.message)) continue;
        break;
      } catch (error) {
        lastError = error;
        final text = error.toString();
        if (attempt == 0 && isImmediateNetworkError(text)) continue;
        break;
      }
    }

    if (!mounted) return;
    final raw = lastError is AuthException
        ? (lastError as AuthException).message
        : 'Network error';
    final wait = retryAfterSeconds(raw);
    setState(() {
      message = friendlyAuthMessage(raw);
      loading = false;
      if (!resend) {
        codeVisible = false;
        sentTo = null;
      }
    });
    if (wait != null) _startCooldown(wait);
  }

  Future<void> verifyCode() async {
    if (sentTo == null) {
      await sendCode();
      return;
    }
    if (!isValidOtp(otp.text)) {
      setState(
        () => message = 'Enter the 6-digit code from your text message.',
      );
      return;
    }

    if (_verifyLock) return;
    _verifyLock = true;
    setState(() {
      loading = true;
      message = null;
    });
    try {
      User? user;
      try {
        final response = await Supabase.instance.client.auth.verifyOTP(
          phone: sentTo,
          token: otp.text.trim(),
          type: OtpType.sms,
        );
        user = response.user;
      } on AuthException catch (error) {
        user = Supabase.instance.client.auth.currentUser;
        if (!_samePhone(user?.phone, sentTo)) {
          if (mounted) setState(() => message = friendlyAuthMessage(error.message));
          return;
        }
      }

      user ??= Supabase.instance.client.auth.currentUser;
      if (user == null || !_samePhone(user.phone, sentTo)) {
        if (mounted) {
          setState(
            () => message =
                "The code was accepted but sign-in didn't finish. Request a new code and try again.",
          );
        }
        return;
      }

      try {
        await widget.onVerified?.call();
      } catch (_) {
        // The code already signed the user in.
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              "We couldn't reach the verification service. Check your connection and try again.",
        );
      }
    } finally {
      _verifyLock = false;
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NightColors.accent, width: 1.4),
                boxShadow: neonGlow(NightColors.accent.withValues(alpha: 0.45)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 16),
                  SizedBox(width: 6),
                  Text('+44'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NightTextField(
                controller: number,
                label: 'UK mobile number',
                keyboardType: TextInputType.phone,
                enabled: !codeVisible && !loading,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
            ),
          ],
        ),
        if (codeVisible) ...[
          const SizedBox(height: 12),
          NightTextField(
            controller: otp,
            focusNode: otpFocus,
            label: 'Verification code',
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
        ],
        if (message != null) StatusText(message!),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: NeonButton(
            onPressed: loading ? null : verifyCode,
            label: loading
                ? (sentTo == null ? 'Sending code...' : 'Verifying...')
                : (sentTo == null && !codeVisible
                      ? widget.submitLabel
                      : 'Verify code'),
          ),
        ),
        if (widget.onRequireEmail != null)
          TextButton(
            onPressed: loading ? null : widget.onRequireEmail,
            child: const Text(
              'Outside the UK? Use email instead',
              style: TextStyle(
                color: NightColors.orange,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        if (codeVisible)
          Row(
            children: [
              TextButton(
                onPressed: loading || cooldown > 0 ? null : sendCode,
                child: Text(
                  cooldown > 0 ? 'Resend code in ${cooldown}s' : 'Resend code',
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: loading
                    ? null
                    : () => setState(() {
                        sentTo = null;
                        codeVisible = false;
                        otp.text = '';
                        message = null;
                        cooldown = 0;
                        _timer?.cancel();
                      }),
                child: const Text('Change number'),
              ),
            ],
          ),
      ],
    );
  }
}
