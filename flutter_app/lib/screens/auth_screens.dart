import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../theme.dart';
import '../widgets/night_widgets.dart';
import 'home_shell.dart';

const appScheme = 'com.mynightcap.app://auth/callback';

SupabaseClient get supabase => Supabase.instance.client;

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return supabase.auth.currentSession == null
        ? const WelcomeScreen()
        : const HomeShell();
  }
}

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  bool retrying = false;
  String? message;

  Future<void> retryConnection() async {
    setState(() {
      retrying = true;
      message = null;
    });
    try {
      final nextConfig = await loadAppConfig();
      if (!nextConfig.isConfigured) {
        setState(
          () => message =
              'Still unable to connect. Check your internet connection and try again.',
        );
        return;
      }
      appConfig = nextConfig;
      await Supabase.initialize(
        url: appConfig.supabaseUrl,
        publishableKey: appConfig.supabaseAnonKey,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const AuthGate()),
      );
    } catch (_) {
      setState(
        () => message =
            'Could not reach NightCapt servers. Please try again in a moment.',
      );
    } finally {
      if (mounted) setState(() => retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      child: NightCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandHeader(),
            const SizedBox(height: 24),
            const Text(
              'Unable to connect',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'NightCapt could not connect to its servers. Check your internet connection, then try again.',
              style: TextStyle(color: NightColors.muted),
            ),
            if (message != null) StatusText(message!),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: retrying ? null : retryConnection,
                child: Text(retrying ? 'Connecting...' : 'Try again'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed('/support'),
                child: const Text('Contact support'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool showSignUp = false;

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      child: NightCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandHeader(),
            const SizedBox(height: 12),
            Text(
              showSignUp ? 'Create account' : 'Sign in',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            showSignUp ? const SignUpForm() : const SignInForm(),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => setState(() => showSignUp = !showSignUp),
                child: Text(
                  showSignUp
                      ? 'Already have an account? Sign in'
                      : 'Need an account? Sign up',
                ),
              ),
            ),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/terms'),
                    child: const Text('Terms'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/privacy'),
                    child: const Text('Privacy'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/support'),
                    child: const Text('Support'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final email = TextEditingController();
  final password = TextEditingController();
  String? message;
  bool loading = false;

  Future<void> runAction(Future<void> Function() action) async {
    setState(() {
      loading = true;
      message = null;
    });
    try {
      await action();
    } on AuthException catch (error) {
      setState(() => message = error.message);
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
        NightTextField(
          controller: email,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        NightTextField(
          controller: password,
          label: 'Password',
          obscureText: true,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: loading
                ? null
                : () async {
                    if (email.text.trim().isEmpty) {
                      setState(() => message = 'Enter your email address first.');
                      return;
                    }
                    await runAction(() async {
                      await supabase.auth.resetPasswordForEmail(
                        email.text.trim(),
                        redirectTo: appScheme,
                      );
                      setState(
                        () => message =
                            'Check your email for a password reset link.',
                      );
                    });
                  },
            child: const Text('Forgot password?'),
          ),
        ),
        if (message != null) StatusText(message!),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: loading
                    ? null
                    : () => runAction(
                        () => supabase.auth.signInWithPassword(
                          email: email.text.trim(),
                          password: password.text,
                        ),
                      ),
                child: Text(loading ? 'Signing in...' : 'Sign in'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: loading
                  ? null
                  : () => runAction(() async {
                      await supabase.auth.signInWithOtp(
                        email: email.text.trim(),
                        emailRedirectTo: '${appConfig.siteUrl}/auth/callback',
                      );
                      setState(
                        () => message = 'Check your email for the magic link.',
                      );
                    }),
              child: const Text('Magic link'),
            ),
          ],
        ),
      ],
    );
  }
}

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final displayName = TextEditingController();
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool acceptedTerms = false;
  bool loading = false;
  String? message;

  Future<void> signUp() async {
    if (!acceptedTerms) {
      setState(() => message = 'You must accept the Terms and Privacy Policy.');
      return;
    }
    setState(() {
      loading = true;
      message = null;
    });
    final acceptedAt = DateTime.now().toUtc().toIso8601String();
    try {
      final response = await supabase.auth.signUp(
        email: email.text.trim(),
        password: password.text,
        emailRedirectTo: '${appConfig.siteUrl}/auth/callback',
        data: {
          'full_name': displayName.text.trim(),
          'terms_accepted_at': acceptedAt,
        },
      );
      final userId = response.user?.id;
      if (userId != null) {
        final updates = <String, dynamic>{'terms_accepted_at': acceptedAt};
        if (username.text.trim().isNotEmpty) {
          updates['username'] = username.text.trim().toLowerCase();
        }
        await supabase.from('profiles').update(updates).eq('id', userId);
      }
      setState(() => message = 'Check your email to confirm your account.');
    } on AuthException catch (error) {
      setState(() => message = error.message);
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
        NightTextField(controller: displayName, label: 'Display name'),
        const SizedBox(height: 12),
        NightTextField(
          controller: username,
          label: 'Username (optional)',
        ),
        const SizedBox(height: 12),
        NightTextField(
          controller: email,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        NightTextField(
          controller: password,
          label: 'Password',
          obscureText: true,
        ),
        CheckboxListTile(
          value: acceptedTerms,
          onChanged: (value) => setState(() => acceptedTerms = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'I accept the Terms, Privacy Policy, and zero-tolerance safety policy.',
          ),
        ),
        if (message != null) StatusText(message!),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: loading ? null : signUp,
            child: Text(loading ? 'Creating account...' : 'Sign up'),
          ),
        ),
      ],
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final password = TextEditingController();
  final confirm = TextEditingController();
  String? message;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      title: 'Reset password',
      child: NightCard(
        child: Column(
          children: [
            NightTextField(
              controller: password,
              label: 'New password',
              obscureText: true,
            ),
            const SizedBox(height: 12),
            NightTextField(
              controller: confirm,
              label: 'Confirm password',
              obscureText: true,
            ),
            if (message != null) StatusText(message!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (password.text.length < 6) {
                          setState(
                            () => message =
                                'Password must be at least 6 characters.',
                          );
                          return;
                        }
                        if (password.text != confirm.text) {
                          setState(() => message = 'Passwords do not match.');
                          return;
                        }
                        setState(() {
                          loading = true;
                          message = null;
                        });
                        try {
                          await supabase.auth.updateUser(
                            UserAttributes(password: password.text),
                          );
                          setState(() => message = 'Password updated.');
                        } on AuthException catch (error) {
                          setState(() => message = error.message);
                        } catch (_) {
                          setState(() => message = 'Could not update password.');
                        } finally {
                          if (mounted) setState(() => loading = false);
                        }
                      },
                child: Text(loading ? 'Updating...' : 'Update password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
