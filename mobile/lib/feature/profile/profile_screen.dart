import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/localization/mesh_localizations.dart';
import '../../ui/theme/mesh_tokens.dart';
import '../onboarding/onboarding_profile.dart';
import '../onboarding/onboarding_screen.dart';
import '../stt/stt_engine.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingProfileProvider);
    return profile.when(
      loading: () => const MeshPage(
        title: 'Profile',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => MeshPage(
        title: 'Profile',
        child: MeshEmptyState(
          icon: Icons.error_outline,
          title: 'Profile unavailable',
          message: '$error',
          action: FilledButton(
            onPressed: () => ref.invalidate(onboardingProfileProvider),
            child: const Text('Try again'),
          ),
        ),
      ),
      data: (value) => value == null
          ? MeshPage(
              title: 'Profile',
              child: MeshEmptyState(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Create your emergency profile',
                message:
                    'Your profile helps responders and people in your rooms support you.',
                action: FilledButton(
                  onPressed: () => _edit(context, ref, null),
                  child: const Text('Create profile'),
                ),
              ),
            )
          : _ProfileContent(profile: value),
    );
  }

  static Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    OnboardingProfile? profile,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(initialProfile: profile),
      ),
    );
    ref.invalidate(onboardingProfileProvider);
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile});

  final OnboardingProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MeshPalette.of(context);
    return MeshPage(
      title: 'Profile',
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MeshCard(
            tint: palette.primary.withValues(alpha: 0.08),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  child: const Icon(Icons.person_outline),
                ),
                const SizedBox(width: MeshSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        profile.phone,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        context.meshL10n.languageName(
                          SttLanguage.fromDisplayName(profile.language)?.code ??
                              'en',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit profile',
                  onPressed: () => ProfileScreen._edit(context, ref, profile),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: MeshSpace.sm),
          MeshCard(
            child: MeshDataRow(
              label: 'Reporter ID',
              value: profile.reporterUid.toUpperCase(),
              icon: Icons.badge_outlined,
            ),
          ),
          const SizedBox(height: MeshSpace.sm),
          MeshActionTile(
            compact: true,
            icon: Icons.language_outlined,
            title: 'Preferred language',
            subtitle: context.meshL10n.languageName(
              SttLanguage.fromDisplayName(profile.language)?.code ?? 'en',
            ),
            onTap: () => _changeLanguage(context, ref),
          ),
          const SizedBox(height: MeshSpace.lg),
          const MeshSectionTitle('Medical information'),
          MeshCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InformationRow(
                  icon: Icons.bloodtype_outlined,
                  title: 'Blood type',
                  value: _available(profile.medicalProfile.bloodGroup),
                  critical: profile.medicalProfile.bloodGroup.isNotEmpty,
                ),
                const Divider(height: MeshSpace.sm),
                _InformationRow(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Allergies',
                  value: _available(profile.medicalProfile.allergies),
                  critical: profile.medicalProfile.allergies.isNotEmpty,
                ),
                const Divider(height: MeshSpace.sm),
                _InformationRow(
                  icon: Icons.medical_information_outlined,
                  title: 'Medical conditions',
                  value: _available(profile.medicalProfile.conditions),
                ),
              ],
            ),
          ),
          const SizedBox(height: MeshSpace.lg),
          MeshSectionTitle(
            'Trusted contacts',
            subtitle:
                '${profile.emergencyContacts.length} contact${profile.emergencyContacts.length == 1 ? '' : 's'} saved',
          ),
          for (final contact in profile.emergencyContacts) ...[
            MeshCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    foregroundColor: palette.text,
                    child: Text(
                      contact.name.isEmpty
                          ? '?'
                          : contact.name.characters.first.toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: MeshSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          contact.phone,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  MeshStatusPill(label: 'Priority ${contact.priority}'),
                ],
              ),
            ),
            const SizedBox(height: MeshSpace.sm),
          ],
          const SizedBox(height: MeshSpace.md),
          MeshFullWidthButton(
            label: 'Edit emergency profile',
            icon: Icons.edit_outlined,
            onPressed: () => ProfileScreen._edit(context, ref, profile),
          ),
        ],
      ),
    );
  }

  static String _available(String value) =>
      value.trim().isEmpty ? 'Not provided' : value.trim();

  Future<void> _changeLanguage(BuildContext context, WidgetRef ref) async {
    final current =
        SttLanguage.fromDisplayName(profile.language) ?? SttLanguage.english;
    final selected = await showModalBottomSheet<SttLanguage>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: .7,
        minChildSize: .35,
        maxChildSize: .92,
        expand: false,
        builder: (sheetContext, scrollController) => SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(MeshSpace.md),
                child: Text(
                  sheetContext.meshL10n.text('Preferred language'),
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    for (final language in SttLanguage.values)
                      ListTile(
                        title: Text(
                          sheetContext.meshL10n.languageName(language.code),
                        ),
                        trailing: language == current
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () => Navigator.of(sheetContext).pop(language),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || selected == current) return;

    await ref
        .read(onboardingRepositoryProvider)
        .save(profile.withLanguage(selected.displayName));
    ref.invalidate(onboardingProfileProvider);
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.title,
    required this.value,
    this.critical = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MeshSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: critical ? palette.ember : palette.text),
          const SizedBox(width: MeshSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.meshL10n.text(title),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
