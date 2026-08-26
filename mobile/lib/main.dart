import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/mesh_shell.dart';
import 'app/notification_router.dart';
import 'app/providers.dart';
import 'app/routes.dart';
import 'app/sos_alert_notifications.dart';
import 'app/sos_incident_navigator.dart';
import 'core/ble/mesh_gatt.dart';
import 'core/ble/permission_gate.dart';
import 'feature/onboarding/onboarding_screen.dart';
import 'feature/stt/stt_engine.dart';
import 'ui/localization/mesh_localizations.dart';
import 'ui/theme/mesh_theme.dart';
import 'ui/theme/theme_controller.dart';

/// Port of `in.meshsetu.app.MainActivity` (Kotlin `app/` module) — the
/// runnable shell. The foreground task owns BLE discovery, relay transport,
/// metrics, and the small diagnostic bridge displayed by the event screen.
/// `ProviderScope` binds the Dev B repositories (Bible §4.2) that live in
/// this UI isolate — `core/data`, `feature/join`, `feature/rooms`,
/// `feature/sos`, `feature/voice`, `feature/gateway`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MeshGatt.validateCompanyId();
  FlutterForegroundTask.initCommunicationPort();
  unawaited(NotificationRouter.configure(FlutterLocalNotificationsPlugin()));
  unawaited(
    SosAlertNotifications.ensureInitialized(
      onTapPayload: SosIncidentNavigator.openPayload,
    ),
  );
  runApp(const ProviderScope(child: MeshSetuApp()));
}

class MeshSetuApp extends ConsumerWidget {
  const MeshSetuApp({
    super.key,
    this.enforcePermissions = true,
    this.enforceOnboarding = true,
  });

  /// Test-only escape hatches. Production construction requires both the
  /// persisted emergency profile and runtime BLE permissions.
  final bool enforcePermissions;
  final bool enforceOnboarding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationRouter.flushPending();
      SosIncidentNavigator.openPending();
    });
    final eventMode = enforcePermissions
        ? const PermissionGate(child: MeshShell())
        : const MeshShell();
    final highContrast = ref.watch(highContrastProvider);
    final darkMode = ref.watch(darkModeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final profile = ref.watch(onboardingProfileProvider).valueOrNull;
    final language = SttLanguage.fromDisplayName(profile?.language ?? '');
    return MaterialApp(
      title: 'MeshSetu',
      locale: Locale(language?.code ?? 'en'),
      supportedLocales: MeshLocalizations.supportedLocales,
      localizationsDelegates: const [
        MeshLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: MeshTheme.light(highContrast: highContrast),
      darkTheme: MeshTheme.dark(highContrast: highContrast),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(fontScale)),
        child: child ?? const SizedBox.shrink(),
      ),
      navigatorKey: navigatorKey,
      home: enforceOnboarding ? OnboardingGate(child: eventMode) : eventMode,
      onGenerateRoute: MeshRoutes.onGenerateRoute,
    );
  }
}
