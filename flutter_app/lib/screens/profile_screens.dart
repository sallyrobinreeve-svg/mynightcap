import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config.dart';
import '../models/friend_models.dart';
import '../screens/auth_screens.dart';
import '../services/moderation_service.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/night_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserProfile?> _future = profileService.currentProfile();
  bool saving = false;
  String? message;

  void _reload() => setState(() => _future = profileService.currentProfile());

  Future<void> signOut() async => supabase.auth.signOut();

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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = supabase.auth.currentSession?.accessToken;
    if (token == null) {
      setState(
        () => message = 'You need to sign in again before deleting your account.',
      );
      return;
    }

    setState(() {
      saving = true;
      message = null;
    });
    try {
      final response = await http.post(
        Uri.parse('${appConfig.siteUrl}/api/account/delete'),
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
      child: FutureBuilder<UserProfile?>(
        future: _future,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          return ListView(
            children: [
              NightCard(
                child: Column(
                  children: [
                    UserAvatar(
                      name: profile?.name ?? 'NightCapt',
                      avatarUrl: profile?.avatarUrl,
                      radius: 46,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile?.name ?? user?.email ?? 'NightCapt user',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (profile?.username != null)
                      Text(
                        '@${profile!.username}',
                        style: const TextStyle(color: NightColors.muted),
                      ),
                    if (profile?.bio != null && profile!.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          profile.bio!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: NightColors.muted),
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
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ProfileEditScreen(
                                  profile: profile,
                                  onSaved: _reload,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit profile'),
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
                    const Text('Safety', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Report or block users from posts and comments. Blocked users are hidden from your feed.',
                      style: TextStyle(color: NightColors.muted),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BlockedUsersScreen(),
                        ),
                      ),
                      child: const Text('Manage blocked users'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              NightCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({required this.profile, required this.onSaved, super.key});

  final UserProfile? profile;
  final VoidCallback onSaved;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final displayName = TextEditingController(text: widget.profile?.displayName ?? '');
  late final username = TextEditingController(text: widget.profile?.username ?? '');
  late final bio = TextEditingController(text: widget.profile?.bio ?? '');
  bool saving = false;
  String? message;

  Future<void> save() async {
    setState(() {
      saving = true;
      message = null;
    });
    try {
      final userId = supabase.auth.currentUser!.id;
      if (username.text.trim().isNotEmpty) {
        final available = await profileService.isUsernameAvailable(
          username.text,
          exceptUserId: userId,
        );
        if (!available) {
          setState(() {
            message = 'That username is already taken.';
            saving = false;
          });
          return;
        }
      }
      await profileService.updateProfile(
        displayName: displayName.text,
        username: username.text,
        bio: bio.text,
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => message = 'Could not save profile.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
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
      final upload = await uploadPickedFile(image, 'avatar');
      await profileService.updateProfile(avatarUrl: upload.url);
      widget.onSaved();
    } catch (_) {
      setState(() => message = 'Could not update profile photo.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      title: 'Edit profile',
      child: NightCard(
        child: Column(
          children: [
            UserAvatar(
              name: displayName.text.isNotEmpty ? displayName.text : 'N',
              avatarUrl: widget.profile?.avatarUrl,
              radius: 40,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: saving ? null : changeAvatar,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(saving ? 'Saving...' : 'Change photo'),
            ),
            const SizedBox(height: 16),
            NightTextField(controller: displayName, label: 'Display name'),
            const SizedBox(height: 12),
            NightTextField(controller: username, label: 'Username'),
            const SizedBox(height: 12),
            NightTextField(controller: bio, label: 'Bio', maxLines: 3),
            if (message != null) StatusText(message!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving ? null : save,
                child: Text(saving ? 'Saving...' : 'Save profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  late Future<List<UserProfile>> _future = _load();

  Future<List<UserProfile>> _load() async {
    final ids = await moderationService.blockedUserIds();
    if (ids.isEmpty) return [];
    final rows = await supabase
        .from('profiles')
        .select('id, display_name, username, avatar_url, bio')
        .inFilter('id', ids.toList());
    return [
      for (final row in rows as List)
        UserProfile.fromRow(row as Map<String, dynamic>),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      title: 'Blocked users',
      child: FutureBuilder<List<UserProfile>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.block,
              title: 'No blocked users',
              body: 'Users you block will appear here so you can unblock them.',
            );
          }
          return ListView(
            children: [
              for (final user in users)
                NightCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      UserAvatar(name: user.name, avatarUrl: user.avatarUrl),
                      const SizedBox(width: 12),
                      Expanded(child: Text(user.name)),
                      TextButton(
                        onPressed: () async {
                          await moderationService.unblock(user.id);
                          setState(() => _future = _load());
                        },
                        child: const Text('Unblock'),
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

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoScreen(
      title: 'Privacy Policy',
      children: const [
        InfoSection(
          title: 'Data we collect',
          body:
              'Account email, profile details, photos, videos, and journal entries you choose to save.',
        ),
        InfoSection(
          title: 'How we use it',
          body:
              'To run NightCapt, show your feed to friends you approve, and keep the community safe.',
        ),
        InfoSection(
          title: 'Your choices',
          body:
              'Control visibility per entry, block users, delete your account from Profile, or contact support.',
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
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: NightColors.muted)),
        ],
      ),
    );
  }
}
