import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../phone.dart';
import '../../theme.dart';
import 'auth_repository.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _usePhone = true;
  String _dialCode = kDefaultDialCode;
  String? _sentTo;
  int _cooldown = 0;
  Timer? _timer;
  bool _loading = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
        return;
      }
      setState(() => _cooldown -= 1);
    });
  }

  Future<void> _sendCode() async {
    final phone = toE164(_dialCode, _phone.text);
    if (phone == null) {
      setState(() => _error = 'Enter a valid mobile number.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPhoneOtp(
            phone: phone,
            shouldCreateUser: false,
          );
      setState(() {
        _sentTo = phone;
        _otp.text = '';
        _message = 'We sent a 6-digit code to ${maskPhone(phone)}.';
      });
      _startCooldown();
    } on AuthException catch (e) {
      setState(() => _error = friendlyAuthMessage(e.message));
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_usePhone) {
      if (_sentTo == null) {
        await _sendCode();
        return;
      }
      if (!isValidOtp(_otp.text)) {
        setState(() => _error = 'Enter the 6-digit code from your text message.');
        return;
      }
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        await ref.read(authRepositoryProvider).verifyPhoneOtp(
              phone: _sentTo!,
              token: _otp.text.trim(),
            );
      } on AuthException catch (e) {
        setState(() => _error = friendlyAuthMessage(e.message));
      } catch (_) {
        setState(() => _error = 'Something went wrong. Please try again.');
      } finally {
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _email.text.trim(),
            password: _password.text,
          );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'NightCapt',
                    style: TextStyle(
                      color: kAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Verify with a code we text to your phone.', style: TextStyle(color: kMuted)),
                  const SizedBox(height: 24),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: true, label: Text('Phone')),
                      ButtonSegment(value: false, label: Text('Email')),
                    ],
                    selected: {_usePhone},
                    onSelectionChanged: (value) => setState(() => _usePhone = value.first),
                  ),
                  const SizedBox(height: 24),
                  if (_usePhone) ...[
                    Row(
                      children: [
                        SizedBox(
                          width: 128,
                          child: DropdownButtonFormField<String>(
                            initialValue: _dialCode,
                            items: [
                              for (final country in kDialCodes)
                                DropdownMenuItem(
                                  value: country.dial,
                                  child: Text(country.label, overflow: TextOverflow.ellipsis),
                                ),
                            ],
                            onChanged: _sentTo != null
                                ? null
                                : (value) => setState(() => _dialCode = value ?? kDefaultDialCode),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            key: const Key('signin_phone'),
                            controller: _phone,
                            enabled: _sentTo == null,
                            keyboardType: TextInputType.phone,
                            autofillHints: const [AutofillHints.telephoneNumber],
                            decoration: const InputDecoration(hintText: '7123 456789'),
                          ),
                        ),
                      ],
                    ),
                    if (_sentTo != null) ...[
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('signin_otp'),
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(hintText: '6-digit code'),
                      ),
                    ],
                  ] else ...[
                    TextField(
                      key: const Key('signin_email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(hintText: 'you@example.com'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('signin_password'),
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'Password'),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(_message!, style: const TextStyle(color: kAccent)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    key: const Key('signin_submit'),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_usePhone && _sentTo != null ? 'Verify code' : 'Sign in'),
                  ),
                  if (_usePhone && _sentTo != null)
                    TextButton(
                      onPressed: _loading || _cooldown > 0 ? null : _sendCode,
                      child: Text(_cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code'),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loading ? null : () => context.go('/signup'),
                    child: const Text(
                      "Don't have an account? Sign up",
                      style: TextStyle(color: kAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
