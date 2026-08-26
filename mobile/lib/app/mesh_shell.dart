import 'package:flutter/material.dart';

import '../feature/activity/activity_screen.dart';
import '../feature/profile/profile_screen.dart';
import '../feature/rooms/rooms_screen.dart';
import '../ui/localization/mesh_localizations.dart';
import '../ui/theme/mesh_tokens.dart';
import 'event_mode_screen.dart';

/// Bottom-nav shell (Task 3 of the UI revamp): four tabs, each carrying its
/// own [Navigator] so a push inside one tab (e.g. Rooms -> Room Lobby ->
/// Room Chat) does not disturb the others, and switching tabs preserves
/// each tab's stack instead of resetting it.
///
/// Deep links from notifications (`notification_router.dart`,
/// `sos_incident_navigator.dart`) intentionally do NOT go through these
/// per-tab navigators — they push against the *root* navigator
/// (`MaterialApp.navigatorKey`), which sits above this whole shell. That
/// keeps `/rooms` and `/incident` reachable regardless of which tab is
/// active, and is why [MeshShell] itself does not read or touch
/// `navigatorKey` — see `routes.dart` for that contract.
class MeshShell extends StatefulWidget {
  const MeshShell({super.key});

  @override
  State<MeshShell> createState() => _MeshShellState();
}

enum _MeshTab { home, rooms, activity, you }

class _MeshShellState extends State<MeshShell> {
  _MeshTab _current = _MeshTab.home;

  final _navigatorKeys = {
    for (final tab in _MeshTab.values) tab: GlobalKey<NavigatorState>(),
  };

  static const _tabs =
      <_MeshTab, ({String label, IconData icon, IconData activeIcon})>{
        _MeshTab.home: (
          label: 'Home',
          icon: Icons.shield_outlined,
          activeIcon: Icons.shield,
        ),
        _MeshTab.rooms: (
          label: 'Rooms',
          icon: Icons.forum_outlined,
          activeIcon: Icons.forum,
        ),
        _MeshTab.activity: (
          label: 'Activity',
          icon: Icons.pending_actions_outlined,
          activeIcon: Icons.pending_actions,
        ),
        _MeshTab.you: (
          label: 'You',
          icon: Icons.person_outline,
          activeIcon: Icons.person,
        ),
      };

  Widget _rootFor(_MeshTab tab) => switch (tab) {
    _MeshTab.home => const EventModeScreen(),
    _MeshTab.rooms => const RoomsScreen(),
    _MeshTab.activity => const ActivityScreen(),
    _MeshTab.you => const ProfileScreen(),
  };

  void _selectTab(_MeshTab tab) {
    if (tab == _current) {
      // Re-tapping the active tab pops that tab's stack back to its root,
      // matching the standard iOS/Android tab-bar convention.
      _navigatorKeys[tab]!.currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _current = tab);
  }

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final navigator = _navigatorKeys[_current]!.currentState;
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _current.index,
          children: [
            for (final tab in _MeshTab.values)
              Offstage(
                offstage: _current != tab,
                child: Navigator(
                  key: _navigatorKeys[tab],
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    settings: settings,
                    builder: (_) => _rootFor(tab),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _current.index,
          onDestinationSelected: (index) => _selectTab(_MeshTab.values[index]),
          backgroundColor: palette.surface,
          indicatorColor: palette.primary.withValues(alpha: 0.14),
          destinations: [
            for (final entry in _tabs.entries)
              NavigationDestination(
                icon: Icon(entry.value.icon),
                selectedIcon: Icon(
                  entry.value.activeIcon,
                  color: palette.primary,
                ),
                label: context.meshL10n.text(entry.value.label),
              ),
          ],
        ),
      ),
    );
  }
}
