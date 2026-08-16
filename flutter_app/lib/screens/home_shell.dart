import 'package:flutter/material.dart';

import '../widgets/night_widgets.dart';
import 'entry_editor_screen.dart';
import 'feed_friends_screens.dart';
import 'profile_screens.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = const [
      FeedScreen(),
      FriendsScreen(),
      EntryEditorScreen(),
      MemoriesScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: InstagramNavBar(
        index: index,
        onChanged: (value) => setState(() => index = value),
      ),
    );
  }
}
