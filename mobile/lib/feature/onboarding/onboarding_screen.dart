import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/emergency_gestures.dart';
import '../../app/providers.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';
import 'onboarding_profile.dart';
import '../stt/stt_engine.dart';

/// Startup gate for the sender identity requirement. The profile is read from
/// encrypted local storage; no enrollment network call is needed while offline.
class OnboardingGate extends ConsumerWidget {
  const OnboardingGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingProfileProvider);
    return profile.when(
      loading: () => Scaffold(
        backgroundColor: MeshPalette.of(context).canvas,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: MeshPalette.of(context).canvas,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(MeshSpace.lg),
            child: MeshEmptyState(
              icon: Icons.error_outline,
              title: 'Profile unavailable',
              message: 'Unable to load your emergency profile: $error',
              action: FilledButton(
                onPressed: () => ref.invalidate(onboardingProfileProvider),
                child: const Text('Try again'),
              ),
            ),
          ),
        ),
      ),
      data: (value) => value == null
          ? OnboardingScreen(
              onComplete: () => ref.invalidate(onboardingProfileProvider),
            )
          : child,
    );
  }
}

/// Section-by-section onboarding for the sender emergency profile.
///
/// The profile remains a single locally persisted object, but the UI only
/// presents one logical section at a time. This keeps the required identity
/// and contact details focused while leaving optional medical information for
/// the end of the flow.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    super.key,
    this.initialProfile,
    this.onComplete,
    @visibleForTesting this.requireGestureEnrollment,
  });

  final OnboardingProfile? initialProfile;
  final VoidCallback? onComplete;

  /// Overrides platform detection in widget tests; production callers leave it
  /// null so Android onboarding continues to use the real platform check.
  @visibleForTesting
  final bool? requireGestureEnrollment;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _OnboardingSection { identity, contacts, gestures, medical }

enum _LanguageModelState { checking, downloading, ready, failed }

const _matteButtonStyle = ButtonStyle(
  elevation: WidgetStatePropertyAll(0),
  shadowColor: WidgetStatePropertyAll(Colors.transparent),
  surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
);

final class _OnboardingStep {
  const _OnboardingStep({
    required this.section,
    required this.title,
    required this.icon,
  });

  final _OnboardingSection section;
  final String title;
  final IconData icon;
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _bloodGroup;
  late final TextEditingController _allergies;
  late final TextEditingController _conditions;
  late final List<_ContactEditors> _contacts;
  bool _saving = false;
  bool _checkingGestures = false;
  bool _gestureServiceEnabled = false;
  late SttLanguage _language;
  _LanguageModelState _languageModelState = _LanguageModelState.checking;
  String? _error;
  int _sectionIndex = 0;

  bool get _requiresGestureEnrollment =>
      widget.requireGestureEnrollment ??
      (widget.initialProfile == null &&
          defaultTargetPlatform == TargetPlatform.android);

  List<_OnboardingStep> get _steps => [
    const _OnboardingStep(
      section: _OnboardingSection.identity,
      title: 'Your details',
      icon: Icons.badge_outlined,
    ),
    const _OnboardingStep(
      section: _OnboardingSection.contacts,
      title: 'Emergency contacts',
      icon: Icons.people_outline,
    ),
    if (_requiresGestureEnrollment)
      const _OnboardingStep(
        section: _OnboardingSection.gestures,
        title: 'Emergency gestures',
        icon: Icons.touch_app_outlined,
      ),
    const _OnboardingStep(
      section: _OnboardingSection.medical,
      title: 'Medical details',
      icon: Icons.health_and_safety_outlined,
    ),
  ];

  _OnboardingStep get _currentStep => _steps[_sectionIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final profile = widget.initialProfile;
    _name = TextEditingController(text: profile?.name ?? '');
    _phone = TextEditingController(text: profile?.phone ?? '');
    _language =
        SttLanguage.fromDisplayName(profile?.language ?? '') ??
        SttLanguage.english;
    _bloodGroup = TextEditingController(
      text: profile?.medicalProfile.bloodGroup ?? '',
    );
    _allergies = TextEditingController(
      text: profile?.medicalProfile.allergies ?? '',
    );
    _conditions = TextEditingController(
      text: profile?.medicalProfile.conditions ?? '',
    );
    _contacts = [
      for (final contact in profile?.emergencyContacts ?? const [])
        _ContactEditors(contact),
      if ((profile?.emergencyContacts ?? const []).isEmpty) _ContactEditors(),
    ];
    unawaited(_prepareLanguageModel(_language));
    if (_requiresGestureEnrollment) unawaited(_refreshGestureEnrollment());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _requiresGestureEnrollment) {
      unawaited(_refreshGestureEnrollment());
    }
  }

  Future<void> _refreshGestureEnrollment() async {
    if (_checkingGestures) return;
    setState(() => _checkingGestures = true);
    try {
      final enabled = await EmergencyGestureSettings.isEnabled();
      if (mounted) setState(() => _gestureServiceEnabled = enabled);
    } catch (_) {
      if (mounted) setState(() => _gestureServiceEnabled = false);
    } finally {
      if (mounted) setState(() => _checkingGestures = false);
    }
  }

  Future<void> _prepareLanguageModel(SttLanguage language) async {
    if (mounted && _language == language) {
      setState(() => _languageModelState = _LanguageModelState.checking);
    }
    final manager = ref.read(sttModelManagerProvider);
    final ready = await manager.isReady(language);
    if (mounted && _language != language) return;
    if (ready) {
      if (mounted) {
        setState(() => _languageModelState = _LanguageModelState.ready);
      }
      return;
    }

    if (mounted) {
      setState(() => _languageModelState = _LanguageModelState.downloading);
    }
    try {
      await manager.download(language);
      if (mounted && _language == language) {
        setState(() => _languageModelState = _LanguageModelState.ready);
      }
    } catch (_) {
      if (mounted && _language == language) {
        setState(() => _languageModelState = _LanguageModelState.failed);
      }
    }
  }

  Future<void> _openGestureSettings() async {
    await EmergencyGestureSettings.openSettings();
    // Android will call `resumed` after Settings closes; this immediate check
    // also handles devices that return directly without a lifecycle change.
    await _refreshGestureEnrollment();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _name.dispose();
    _phone.dispose();
    _bloodGroup.dispose();
    _allergies.dispose();
    _conditions.dispose();
    for (final contact in _contacts) {
      contact.dispose();
    }
    super.dispose();
  }

  String? _validateCurrentSection() {
    switch (_currentStep.section) {
      case _OnboardingSection.identity:
        if (_name.text.trim().isEmpty) return 'Enter your name.';
        if (OnboardingProfile.canonicalE164(_phone.text) == null) {
          return 'Enter your phone number in E.164 format, e.g. +919876543210.';
        }
      case _OnboardingSection.contacts:
        if (_contacts.isEmpty) return 'Add at least one emergency contact.';
        if (_contacts.length > 10) {
          return 'A maximum of 10 emergency contacts is supported.';
        }
        for (final contact in _contacts) {
          final error = EmergencyContact(
            name: contact.name.text,
            phone: contact.phone.text,
          ).validationError;
          if (error != null) return error;
        }
      case _OnboardingSection.gestures:
        if (!_gestureServiceEnabled) {
          return 'Enable Emergency gestures in Android Accessibility settings before continuing.';
        }
      case _OnboardingSection.medical:
        break;
    }
    return null;
  }

  Future<void> _continue() async {
    final validationError = _validateCurrentSection();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    FocusScope.of(context).unfocus();
    if (_sectionIndex < _steps.length - 1) {
      setState(() {
        _sectionIndex++;
        _error = null;
      });
    } else {
      unawaited(_save());
    }
  }

  void _back() {
    if (_sectionIndex == 0 || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sectionIndex--;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_requiresGestureEnrollment && !_gestureServiceEnabled) {
      setState(() {
        _error =
            'Enable Emergency gestures in Android Accessibility settings before saving your emergency profile.';
        _sectionIndex = _steps.indexWhere(
          (step) => step.section == _OnboardingSection.gestures,
        );
      });
      return;
    }
    final profile = OnboardingProfile.create(
      profileId: widget.initialProfile?.profileId,
      name: _name.text,
      phone: _phone.text,
      language: _language.displayName,
      emergencyContacts: [
        for (var index = 0; index < _contacts.length; index++)
          EmergencyContact(
            name: _contacts[index].name.text,
            phone: _contacts[index].phone.text,
            priority: index + 1,
          ),
      ],
      medicalProfile: MedicalProfile(
        bloodGroup: _bloodGroup.text,
        allergies: _allergies.text,
        conditions: _conditions.text,
      ),
    );
    final validationError = profile.validationError;
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(onboardingRepositoryProvider).save(profile);
      ref.invalidate(onboardingProfileProvider);
      widget.onComplete?.call();
      if (mounted && widget.onComplete == null) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not save profile: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    final progress = (_sectionIndex + 1) / _steps.length;
    return MeshPage(
      title: widget.initialProfile == null
          ? 'Emergency Profile'
          : 'Edit Profile',
      maxWidth: 720,
      padding: const EdgeInsets.fromLTRB(
        MeshSpace.screen,
        MeshSpace.lg,
        MeshSpace.screen,
        MeshSpace.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _progressHeader(context, palette, progress),
          const SizedBox(height: MeshSpace.lg),
          AnimatedSwitcher(
            duration: MeshMotion.standard,
            switchInCurve: MeshMotion.easeOut,
            switchOutCurve: MeshMotion.easeOut,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: MeshMotion.easeOut,
                      ),
                    ),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_currentStep.section),
              child: _sectionContent(context, palette),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: MeshSpace.md),
            _errorMessage(context, palette),
          ],
          const SizedBox(height: MeshSpace.lg),
          _navigation(context),
        ],
      ),
    );
  }

  Widget _progressHeader(
    BuildContext context,
    MeshPalette palette,
    double progress,
  ) => MeshCard(
    matte: true,
    tint: palette.mesh.withValues(alpha: 0.08),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_currentStep.icon, color: palette.mesh),
            const SizedBox(width: MeshSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MeshMicroLabel(
                    'Step ${_sectionIndex + 1} of ${_steps.length}',
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currentStep.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            MeshStatusPill(
              label: '${(_sectionIndex + 1) * 100 ~/ _steps.length}%',
              tone: MeshStatusTone.neutral,
            ),
          ],
        ),
        const SizedBox(height: MeshSpace.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(MeshRadius.full),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: palette.hairline,
          ),
        ),
      ],
    ),
  );

  Widget _sectionContent(BuildContext context, MeshPalette palette) =>
      switch (_currentStep.section) {
        _OnboardingSection.identity => _identitySection(context),
        _OnboardingSection.contacts => _contactsSection(context),
        _OnboardingSection.gestures => _gesturesSection(context, palette),
        _OnboardingSection.medical => _medicalSection(context),
      };

  Widget _identitySection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const MeshSectionTitle('Who are we helping?'),
      const SizedBox(height: MeshSpace.sm),
      DropdownButtonFormField<SttLanguage>(
        key: const Key('preferred-language-dropdown'),
        initialValue: _language,
        decoration: const InputDecoration(
          labelText: 'Most comfortable language *',
        ),
        items: [
          for (final language in SttLanguage.values)
            DropdownMenuItem(
              value: language,
              child: Text(language.displayName),
            ),
        ],
        onChanged: (language) {
          if (language == null) return;
          setState(() {
            _language = language;
            _languageModelState = _LanguageModelState.checking;
            _error = null;
          });
          unawaited(_prepareLanguageModel(language));
        },
      ),
      const SizedBox(height: MeshSpace.sm),
      _languageModelStatus(context),
      const SizedBox(height: MeshSpace.md),
      _field(_name, 'Your name', required: true),
      const SizedBox(height: MeshSpace.md),
      _field(
        _phone,
        'Your phone number',
        required: true,
        keyboardType: TextInputType.phone,
      ),
    ],
  );

  Widget _contactsSection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const MeshSectionTitle('People in your circle'),
      for (var index = 0; index < _contacts.length; index++) ...[
        _contactFields(index),
        const SizedBox(height: MeshSpace.md),
      ],
      if (_contacts.length < 10) ...[
        const SizedBox(height: MeshSpace.sm),
        OutlinedButton.icon(
          style: _matteButtonStyle,
          onPressed: () => setState(() => _contacts.add(_ContactEditors())),
          icon: const Icon(Icons.add),
          label: const Text('Add emergency contact'),
        ),
      ],
    ],
  );

  Widget _languageModelStatus(BuildContext context) {
    return switch (_languageModelState) {
      _LanguageModelState.ready => Text(
        '${_language.displayName} ready to be sent via voice.',
      ),
      _LanguageModelState.checking => Text(
        'Checking ${_language.displayName} voice model…',
      ),
      _LanguageModelState.downloading => Text(
        'Preparing ${_language.displayName} voice model in background…',
      ),
      _LanguageModelState.failed => Text(
        '${_language.displayName} voice model could not download. It will retry when you select the language again.',
        style: TextStyle(color: MeshPalette.of(context).ember),
      ),
    };
  }

  Widget _gesturesSection(
    BuildContext context,
    MeshPalette palette,
  ) => MeshCard(
    matte: true,
    tint: _gestureServiceEnabled
        ? palette.live.withValues(alpha: 0.1)
        : palette.ember.withValues(alpha: 0.08),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enable emergency gestures',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: MeshSpace.sm),
        const Text(
          'Enable MeshSetu emergency gestures in Android Accessibility settings. '
          '↑ ↑ General · ↓ ↓ ↓ Fire · ↑ ↓ ↑ Crime · ↓ ↑ ↓ Kidnap · ↑ ↑ ↑ Medical · ↓ ↓ ↓ ↓ Natural Disaster.',
        ),
        const SizedBox(height: MeshSpace.lg),
        MeshStatusPill(
          label: _checkingGestures
              ? 'Checking permission…'
              : _gestureServiceEnabled
              ? 'Enabled'
              : 'Not enabled',
          tone: _checkingGestures
              ? MeshStatusTone.neutral
              : _gestureServiceEnabled
              ? MeshStatusTone.active
              : MeshStatusTone.critical,
        ),
        const SizedBox(height: MeshSpace.lg),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: _matteButtonStyle,
                onPressed: _checkingGestures ? null : _openGestureSettings,
                icon: const Icon(Icons.settings_accessibility),
                label: const Text(
                  'Open Accessibility settings',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: MeshSpace.sm),
            IconButton(
              tooltip: 'Check again',
              onPressed: _checkingGestures ? null : _refreshGestureEnrollment,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _medicalSection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const MeshSectionTitle('Optional medical context'),
      const SizedBox(height: MeshSpace.sm),
      _field(_bloodGroup, 'Blood group'),
      const SizedBox(height: MeshSpace.md),
      _field(_allergies, 'Allergies', maxLines: 2),
      const SizedBox(height: MeshSpace.md),
      _field(_conditions, 'Medical conditions', maxLines: 2),
    ],
  );

  Widget _errorMessage(BuildContext context, MeshPalette palette) => Text(
    _error!,
    style: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: palette.ember),
  );

  Widget _navigation(BuildContext context) {
    final isLast = _sectionIndex == _steps.length - 1;
    final busy = _saving;
    return Row(
      children: [
        if (_sectionIndex > 0) ...[
          Expanded(
            child: MeshFullWidthButton(
              matte: true,
              label: 'Back',
              icon: Icons.arrow_back,
              secondary: true,
              onPressed: busy ? null : _back,
            ),
          ),
          const SizedBox(width: MeshSpace.sm),
        ],
        Expanded(
          flex: _sectionIndex > 0 ? 2 : 1,
          child: MeshFullWidthButton(
            matte: true,
            label: isLast
                ? _saving
                      ? 'Saving profile…'
                      : 'Save emergency profile'
                : 'Continue',
            icon: isLast ? Icons.check : Icons.arrow_forward,
            busy: busy,
            onPressed: busy ? null : _continue,
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) => TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    onChanged: (_) {
      if (_error != null) setState(() => _error = null);
    },
    decoration: InputDecoration(labelText: required ? '$label *' : label),
  );

  Widget _contactFields(int index) {
    final contact = _contacts[index];
    return MeshCard(
      matte: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Contact ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (_contacts.length > 1)
                IconButton(
                  tooltip: 'Remove contact',
                  onPressed: () => setState(() {
                    final removed = _contacts.removeAt(index);
                    removed.dispose();
                  }),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
            ],
          ),
          const SizedBox(height: MeshSpace.sm),
          _field(contact.name, 'Name', required: true),
          const SizedBox(height: MeshSpace.md),
          _field(
            contact.phone,
            'Phone number',
            required: true,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }
}

final class _ContactEditors {
  _ContactEditors([EmergencyContact? contact])
    : name = TextEditingController(text: contact?.name ?? ''),
      phone = TextEditingController(text: contact?.phone ?? '');

  final TextEditingController name;
  final TextEditingController phone;

  void dispose() {
    name.dispose();
    phone.dispose();
  }
}
