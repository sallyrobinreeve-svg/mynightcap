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
  String? sentTo;
  String? message;
  bool loading = false;
  int cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    number.dispose();
    otp.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => cooldown = 60);
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
      setState(() => message = 'Phone login is for UK numbers only. Use email instead.');
      widget.onRequireEmail?.call();
      return;
    }
    if (parsed.status != UkPhoneStatus.ok || parsed.phone == null) {
      setState(() => message = 'Enter a valid UK mobile number, or use email.');
      return;
    }
    final phone = parsed.phone!;

    setState(() {
      loading = true;
      message = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: widget.shouldCreateUser,
        data: widget.userMetadata?.call(),
        channel: OtpChannel.sms,
      );
      if (!mounted) return;
      setState(() {
        sentTo = phone;
        otp.text = '';
        message = 'We sent a 6-digit code to ${maskPhone(phone)}.';
      });
      _startCooldown();
    } on AuthException catch (error) {
      setState(() => message = friendlyAuthMessage(error.message));
    } catch (_) {
      setState(() => message = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
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

    setState(() {
      loading = true;
      message = null;
    });
    try {
      await Supabase.instance.client.auth.verifyOTP(
        phone: sentTo,
        token: otp.text.trim(),
        type: OtpType.sms,
      );
      await widget.onVerified?.call();
    } on AuthException catch (error) {
      setState(() => message = friendlyAuthMessage(error.message));
    } catch (_) {
      setState(() => message = 'Something went wrong. Please try again.');
    } finally {
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                color: NightColors.background.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: const Text('+44'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NightTextField(
                controller: number,
                label: 'UK mobile number',
                keyboardType: TextInputType.phone,
                enabled: sentTo == null && !loading,
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
            ),
          ],
        ),
        if (sentTo != null) ...[
          const SizedBox(height: 12),
          NightTextField(
            controller: otp,
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
          child: FilledButton(
            onPressed: loading ? null : verifyCode,
            child: Text(
              loading
                  ? (sentTo == null ? 'Sending code...' : 'Verifying...')
                  : (sentTo == null ? widget.submitLabel : 'Verify code'),
            ),
          ),
        ),
        if (widget.onRequireEmail != null)
          TextButton(
            onPressed: loading ? null : widget.onRequireEmail,
            child: const Text('Outside the UK? Use email instead'),
          ),
        if (sentTo != null)
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
