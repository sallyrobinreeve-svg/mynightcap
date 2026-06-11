import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _accepted = false;
  bool _loading = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_accepted) {
      setState(() => _error = 'Please agree to the Terms and Privacy Policy.');
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
      // If a session was created (email confirmation disabled), the router
      // redirect navigates to the feed automatically. Otherwise prompt the user
      // to confirm / sign in.
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
                  const SizedBox(height: 24),
                  TextField(
                    key: const Key('signup_name'),
                    controller: _name,
                    decoration: const InputDecoration(hintText: 'Display name'),
                  ),
                  const SizedBox(height: 12),
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
                        : const Text('Sign up'),
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
