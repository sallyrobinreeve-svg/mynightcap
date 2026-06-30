import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const siteUrl = String.fromEnvironment(
  'SITE_URL',
  defaultValue: 'https://mynightcap.vercel.app',
);
const appScheme = 'com.mynightcap.app://auth/callback';

bool get isSupabaseConfigured =>
    supabaseUrl.startsWith('http') && supabaseAnonKey.isNotEmpty;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isSupabaseConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }
  runApp(const NightCaptApp());
}

class NightCaptApp extends StatelessWidget {
  const NightCaptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NightCapt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: NightColors.accent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: NightColors.background,
        useMaterial3: true,
      ),
      routes: {
        '/support': (_) => const SupportScreen(),
        '/terms': (_) => const TermsScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
      },
      home: isSupabaseConfigured
          ? const AuthGate()
          : const ConfigurationScreen(),
    );
  }
}

class NightColors {
  static const background = Color(0xFF1E1B24);
  static const card = Color(0xFF2B2633);
  static const accent = Color(0xFFFF6B9D);
  static const mint = Color(0xFF7AF0C2);
  static const muted = Color(0xFFB8AFC2);
  static const yellow = Color(0xFFFFDC7A);
}

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

class ConfigurationScreen extends StatelessWidget {
  const ConfigurationScreen({super.key});

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
              'Flutter app is ready for configuration',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Run with Supabase credentials to enable auth, feed, create, memories, and profile features.',
              style: TextStyle(color: NightColors.muted),
            ),
            const SizedBox(height: 16),
            CodeBlock(
              'flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co '
              '--dart-define=SUPABASE_ANON_KEY=your_anon_key',
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed('/support'),
              child: const Text('Open support page'),
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

  Future<void> signIn() async {
    await runAction(() async {
      await supabase.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
    });
  }

  Future<void> magicLink() async {
    await runAction(() async {
      await supabase.auth.signInWithOtp(
        email: email.text.trim(),
        emailRedirectTo: '$siteUrl/auth/callback',
      );
      setState(() => message = 'Check your email for the magic link.');
    });
  }

  Future<void> resetPassword() async {
    if (email.text.trim().isEmpty) {
      setState(() => message = 'Enter your email address first.');
      return;
    }
    await runAction(() async {
      await supabase.auth.resetPasswordForEmail(
        email.text.trim(),
        redirectTo: appScheme,
      );
      setState(() => message = 'Check your email for a password reset link.');
    });
  }

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
            onPressed: loading ? null : resetPassword,
            child: const Text('Forgot password?'),
          ),
        ),
        if (message != null) StatusText(message!),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: loading ? null : signIn,
                child: Text(loading ? 'Signing in...' : 'Sign in'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: loading ? null : magicLink,
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
        emailRedirectTo: '$siteUrl/auth/callback',
        data: {
          'full_name': displayName.text.trim(),
          'terms_accepted_at': acceptedAt,
        },
      );
      final userId = response.user?.id;
      if (userId != null) {
        await supabase
            .from('profiles')
            .update({'terms_accepted_at': acceptedAt})
            .eq('id', userId);
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

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const FeedScreen(),
      const CreateEntryScreen(),
      const MemoriesScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_fire_department),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            label: 'Memories',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Future<List<Map<String, dynamic>>> future = loadFeed();

  Future<List<Map<String, dynamic>>> loadFeed() async {
    final rows = await supabase
        .from('entries')
        .select(
          'id, date_of_night, rating, visibility, created_at, profiles(display_name, avatar_url), photos(url, type)',
        )
        .order('created_at', ascending: false)
        .limit(30);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      title: 'Feed',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorCard(
              message: 'Could not load feed.',
              onRetry: () => setState(() => future = loadFeed()),
            );
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const EmptyState(
              icon: Icons.nightlife,
              title: 'No nights yet',
              body:
                  'Create your first entry or follow friends to fill the feed.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() => future = loadFeed()),
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) => EntryCard(entry: entries[i]),
            ),
          );
        },
      ),
    );
  }
}

class EntryCard extends StatelessWidget {
  const EntryCard({required this.entry, super.key});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final profile = entry['profiles'] as Map<String, dynamic>?;
    final photos = List<Map<String, dynamic>>.from(entry['photos'] ?? const []);
    final cover = photos.cast<Map<String, dynamic>?>().firstWhere(
      (photo) => photo?['url'] != null,
      orElse: () => null,
    );
    final rating = entry['rating'];
    final date = DateTime.tryParse('${entry['date_of_night']}');
    return NightCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: NightColors.accent,
                child: Icon(Icons.person),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  profile?['display_name']?.toString() ?? 'NightCapt user',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${entry['visibility']}',
                style: const TextStyle(color: NightColors.muted),
              ),
            ],
          ),
          if (cover?['url'] != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                cover!['url'],
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.star,
                color: rating == null ? NightColors.muted : NightColors.yellow,
              ),
              const SizedBox(width: 6),
              Text(rating == null ? 'Not rated' : '$rating / 5'),
              const Spacer(),
              Text(
                date == null ? '' : DateFormat.yMMMd().format(date),
                style: const TextStyle(color: NightColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreateEntryScreen extends StatefulWidget {
  const CreateEntryScreen({super.key});

  @override
  State<CreateEntryScreen> createState() => _CreateEntryScreenState();
}

class _CreateEntryScreenState extends State<CreateEntryScreen> {
  DateTime date = DateTime.now();
  int? rating;
  String visibility = 'friends';
  PickedUpload? outfit;
  PickedUpload? favourite;
  bool saving = false;
  String? message;

  Future<void> pickPhoto(String type) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (file == null) return;
    setState(() => message = null);
    try {
      final upload = await uploadPickedFile(file, type);
      setState(() {
        if (type == 'outfit') {
          outfit = upload;
        } else {
          favourite = upload;
        }
      });
    } catch (_) {
      setState(() => message = 'Photo upload failed. Please try again.');
    }
  }

  Future<PickedUpload> uploadPickedFile(XFile file, String type) async {
    final userId = supabase.auth.currentUser!.id;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').lastOrNull ?? 'jpg';
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}-$type.$ext';
    await supabase.storage
        .from('photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: file.mimeType ?? 'image/jpeg'),
        );
    return PickedUpload(
      path: path,
      url: supabase.storage.from('photos').getPublicUrl(path),
    );
  }

  Future<void> saveEntry() async {
    if (rating == null) {
      setState(() => message = 'Choose a rating before posting.');
      return;
    }
    setState(() {
      saving = true;
      message = null;
    });
    try {
      final userId = supabase.auth.currentUser!.id;
      final entry = await supabase
          .from('entries')
          .insert({
            'user_id': userId,
            'date_of_night': DateFormat('yyyy-MM-dd').format(date),
            'rating': rating,
            'prompts': <String, dynamic>{},
            'visibility': visibility,
          })
          .select('id')
          .single();
      final entryId = entry['id'];
      final photoRows = [
        if (outfit != null)
          {'entry_id': entryId, 'type': 'outfit', 'url': outfit!.url},
        if (favourite != null)
          {'entry_id': entryId, 'type': 'favourite', 'url': favourite!.url},
      ];
      if (photoRows.isNotEmpty) {
        await supabase.from('photos').insert(photoRows);
      }
      setState(() {
        message = 'Entry posted.';
        rating = null;
        outfit = null;
        favourite = null;
      });
    } catch (_) {
      setState(
        () => message =
            'Could not save entry. Check your connection and permissions.',
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      title: 'Create',
      child: ListView(
        children: [
          NightCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date of night'),
                  subtitle: Text(DateFormat.yMMMMd().format(date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) setState(() => date = picked);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Rating'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(5, (i) {
                    final value = i + 1;
                    return ChoiceChip(
                      label: Text('$value'),
                      selected: rating == value,
                      onSelected: (_) => setState(() => rating = value),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: PhotoButton(
                        label: outfit == null
                            ? 'Choose outfit photo'
                            : 'Outfit added',
                        icon: Icons.checkroom,
                        onTap: () => pickPhoto('outfit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PhotoButton(
                        label: favourite == null
                            ? 'Choose favourite photo'
                            : 'Favourite added',
                        icon: Icons.favorite,
                        onTap: () => pickPhoto('favourite'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: visibility,
                  decoration: nightInputDecoration('Visibility'),
                  items: const [
                    DropdownMenuItem(value: 'private', child: Text('Private')),
                    DropdownMenuItem(value: 'friends', child: Text('Friends')),
                    DropdownMenuItem(value: 'public', child: Text('Public')),
                  ],
                  onChanged: (value) =>
                      setState(() => visibility = value ?? 'friends'),
                ),
                if (message != null) StatusText(message!),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saving ? null : saveEntry,
                    child: Text(saving ? 'Posting...' : 'Post entry'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PickedUpload {
  const PickedUpload({required this.path, required this.url});

  final String path;
  final String url;
}

class PhotoButton extends StatelessWidget {
  const PhotoButton({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  late Future<List<Map<String, dynamic>>> future = loadPhotos();

  Future<List<Map<String, dynamic>>> loadPhotos() async {
    final rows = await supabase
        .from('photos')
        .select('url, type, created_at')
        .order('created_at', ascending: false)
        .limit(60);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      title: 'Memories',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final photos = snapshot.data ?? [];
          if (photos.isEmpty) {
            return const EmptyState(
              icon: Icons.photo_library_outlined,
              title: 'No photos yet',
              body: 'Add photos to entries and they will appear here.',
            );
          }
          return GridView.builder(
            itemCount: photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(photos[i]['url'], fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> future = loadProfile();
  bool saving = false;
  String? message;

  Future<Map<String, dynamic>?> loadProfile() async {
    final userId = supabase.auth.currentUser!.id;
    return await supabase
        .from('profiles')
        .select('display_name, avatar_url, bio')
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> changeAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (image == null) return;
    setState(() {
      saving = true;
      message = null;
    });
    try {
      final userId = supabase.auth.currentUser!.id;
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').lastOrNull ?? 'jpg';
      final path =
          '$userId/avatar-${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage
          .from('photos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: image.mimeType ?? 'image/jpeg',
            ),
          );
      final url = supabase.storage.from('photos').getPublicUrl(path);
      await supabase
          .from('profiles')
          .update({'avatar_url': url})
          .eq('id', userId);
      setState(() => future = loadProfile());
    } catch (_) {
      setState(() => message = 'Could not update profile photo.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently removes your account and app data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = supabase.auth.currentSession?.accessToken;
    if (token == null) {
      setState(
        () =>
            message = 'You need to sign in again before deleting your account.',
      );
      return;
    }

    setState(() {
      saving = true;
      message = null;
    });
    try {
      final response = await http.post(
        Uri.parse('$siteUrl/api/account/delete'),
        headers: {'authorization': 'Bearer $token'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Delete failed');
      }
      await supabase.auth.signOut();
    } catch (_) {
      setState(
        () => message =
            'Could not delete account. Contact support if this continues.',
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    return NightScaffold(
      title: 'Profile',
      child: FutureBuilder<Map<String, dynamic>?>(
        future: future,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          return ListView(
            children: [
              NightCard(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: NightColors.accent,
                      backgroundImage: profile?['avatar_url'] == null
                          ? null
                          : NetworkImage(profile!['avatar_url']),
                      child: profile?['avatar_url'] == null
                          ? const Icon(Icons.person, size: 46)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile?['display_name'] ??
                          user?.email ??
                          'NightCapt user',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user?.email != null)
                      Text(
                        user!.email!,
                        style: const TextStyle(color: NightColors.muted),
                      ),
                    if (message != null) StatusText(message!),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: saving ? null : changeAvatar,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(saving ? 'Saving...' : 'Choose photo'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/support'),
                          icon: const Icon(Icons.help_outline),
                          label: const Text('Support'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              NightCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Delete your account and associated app data.',
                      style: TextStyle(color: NightColors.muted),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: signOut,
                        child: const Text('Sign out'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: saving ? null : deleteAccount,
                        child: const Text('Delete account'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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

  Future<void> updatePassword() async {
    if (password.text.length < 6) {
      setState(() => message = 'Password must be at least 6 characters.');
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
      await supabase.auth.updateUser(UserAttributes(password: password.text));
      setState(() => message = 'Password updated.');
    } on AuthException catch (error) {
      setState(() => message = error.message);
    } catch (_) {
      setState(() => message = 'Could not update password.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

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
                onPressed: loading ? null : updatePassword,
                child: Text(loading ? 'Updating...' : 'Update password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoScreen(
      title: 'NightCapt Support',
      children: const [
        InfoSection(
          title: 'Contact',
          body:
              'Email nightcapt1@outlook.com. We aim to respond within 24-48 hours.',
        ),
        InfoSection(
          title: 'Common questions',
          body:
              'Reset password from the sign-in screen. Delete account from Profile > Account. Report entries, comments, and profiles from their menus.',
        ),
        InfoSection(
          title: 'Safety',
          body:
              'NightCapt has zero tolerance for objectionable content or abusive users. Reports are reviewed within 24 hours.',
        ),
      ],
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoScreen(
      title: 'Terms of Use',
      children: const [
        InfoSection(
          title: 'Using NightCapt',
          body:
              'NightCapt is a social journal for saving and sharing night-out memories.',
        ),
        InfoSection(
          title: 'User content and safety',
          body:
              'Do not post harassment, hate, threats, illegal content, or content that violates privacy or rights. Users can report and block others.',
        ),
        InfoSection(
          title: 'Accounts',
          body:
              'You can update your profile, reset your password, and request account deletion.',
        ),
      ],
    );
  }
}

class InfoScreen extends StatelessWidget {
  const InfoScreen({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      title: title,
      child: ListView(
        children: [
          NightCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoSection extends StatelessWidget {
  const InfoSection({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: NightColors.muted)),
        ],
      ),
    );
  }
}

class NightScaffold extends StatelessWidget {
  const NightScaffold({required this.child, this.title, super.key});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              backgroundColor: NightColors.background,
              foregroundColor: Colors.white,
            ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NightColors.background,
              Color(0xFF34243A),
              NightColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NightCard extends StatelessWidget {
  const NightCard({
    required this.child,
    this.padding = const EdgeInsets.all(22),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: NightColors.card.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NightCapt',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: NightColors.accent,
          ),
        ),
        SizedBox(height: 4),
        Text('Capture the chaos', style: TextStyle(color: NightColors.muted)),
      ],
    );
  }
}

class NightTextField extends StatelessWidget {
  const NightTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: nightInputDecoration(label),
    );
  }
}

InputDecoration nightInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: NightColors.background.withValues(alpha: 0.68),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
    ),
  );
}

class StatusText extends StatelessWidget {
  const StatusText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(message, style: const TextStyle(color: NightColors.mint)),
    );
  }
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return NightCard(
      child: Column(
        children: [
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return NightCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: NightColors.accent),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: NightColors.muted),
          ),
        ],
      ),
    );
  }
}

class CodeBlock extends StatelessWidget {
  const CodeBlock(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
