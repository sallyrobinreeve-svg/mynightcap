import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../phone.dart';
import '../../supabase_providers.dart';
import '../../theme.dart';
import 'auth_repository.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _usePhone = preferUkPhoneAuth();
  bool _forcedToEmail = false;
  String? _sentTo;
  int _cooldown = 0;
  Timer? _timer;
  bool _accepted = false;
  bool _loading = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
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
    if (!_accepted) {
      setState(() => _error = 'Please agree to the Terms and Privacy Policy.');
      return;
    }
    final parsed = parseUkLoginPhone(_phone.text);
    if (parsed.status == UkPhoneStatus.notUk) {
      setState(() {
        _error = 'Phone login is for UK numbers only. Use email instead.';
        _usePhone = false;
        _forcedToEmail = true;
      });
      return;
    }
    if (parsed.status != UkPhoneStatus.ok || parsed.phone == null) {
      setState(() => _error = 'Enter a valid UK mobile number, or use email.');
      return;
    }
    final phone = parsed.phone!;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPhoneOtp(
            phone: phone,
            shouldCreateUser: true,
            data: {
              'full_name': _name.text.trim(),
              'terms_accepted_at': DateTime.now().toUtc().toIso8601String(),
            },
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
    if (!_accepted) {
      setState(() => _error = 'Please agree to the Terms and Privacy Policy.');
      return;
    }
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
      _message = null;
    });
    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _email.text.trim(),
            password: _password.text,
            displayName: _name.text.trim(),
          );
      final hasSession = ref.read(supabaseProvider).auth.currentSession != null;
      if (mounted && !hasSession) {
        setState(() => _message = 'Account created! Check your email, then sign in.');
      }
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
      appBar: AppBar(),
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
                    'Create account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Phone authentication is for UK users only. If you\'re outside the UK, use email.',
                    style: TextStyle(color: kMuted),
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: true, label: Text('UK phone')),
                      ButtonSegment(value: false, label: Text('Email')),
                    ],
                    selected: {_usePhone},
                    onSelectionChanged: (value) => setState(() => _usePhone = value.first),
                  ),
                  if (_forcedToEmail && !_usePhone) ...[
                    const SizedBox(height: 12),
                    const Text('Phone login is for UK numbers only. Continue with email.'),
                  ],
                  const SizedBox(height: 24),
                  TextField(
                    key: const Key('signup_name'),
                    controller: _name,
                    decoration: const InputDecoration(hintText: 'Display name'),
                  ),
                  const SizedBox(height: 12),
                  if (_usePhone) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          child: const Text('+44'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            key: const Key('signup_phone'),
                            controller: _phone,
                            enabled: _sentTo == null,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(hintText: '7123 456789'),
                          ),
                        ),
                      ],
                    ),
                    if (_sentTo != null) ...[
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('signup_otp'),
                        controller: _otp,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(hintText: '6-digit code'),
                      ),
                    ],
                  ] else ...[
                    TextField(
                      key: const Key('signup_email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'you@example.com'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('signup_password'),
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'Password (min 6 chars)'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    key: const Key('signup_terms'),
                    value: _accepted,
                    onChanged: (v) => setState(() => _accepted = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: kAccent,
                    title: const Text(
                      'I agree to the Terms of Use and Privacy Policy.',
                      style: TextStyle(color: kMuted, fontSize: 13),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                  if (_message != null) ...[
                    const SizedBox(height: 8),
                    Text(_message!, style: const TextStyle(color: kAccent)),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    key: const Key('signup_submit'),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_usePhone && _sentTo != null ? 'Verify code' : 'Sign up'),
                  ),
                  if (_usePhone && _sentTo != null)
                    TextButton(
                      onPressed: _loading || _cooldown > 0 ? null : _sendCode,
                      child: Text(_cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code'),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loading ? null : () => context.go('/signin'),
                    child: const Text(
                      'Already have an account? Sign in',
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
