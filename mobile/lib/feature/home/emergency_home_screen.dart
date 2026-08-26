import 'package:flutter/material.dart';

import '../../core/ble/sos_advertisement.dart';
import '../../ui/components/mesh_components.dart';
import '../../ui/theme/mesh_tokens.dart';

/// Home tab hero. Signal-lattice hero surface with the SOS button as the
/// unambiguous focal point, compact secondary controls, and a slim Rooms
/// teaser (Rooms itself is a full tab as of Task 3 — this card just shortcuts
/// create/join without duplicating the whole Rooms screen here).
///
/// Constructor signature is unchanged from the pre-revamp screen:
/// [EventModeScreen] constructs this positionally with named args, and
/// `test/feature/emergency_home_ui_test.dart` + `test/widget_test.dart`
/// assert against it.
class EmergencyHomeScreen extends StatelessWidget {
  const EmergencyHomeScreen({
    super.key,
    required this.eventModeActive,
    required this.sending,
    required this.emergencyType,
    required this.description,
    required this.holdSeconds,
    required this.onSos,
    required this.onProfile,
    required this.onEmergencyType,
    required this.onVoice,
    required this.onDescribe,
    required this.onCreateRoom,
    required this.onJoinRoom,
    this.authorityResponseType,
    this.authorityResponseMessage,
    this.authorityRejectionMessage,
    this.onToggleEventMode,
  });

  final bool eventModeActive;
  final bool sending;
  final SosEmergencyType emergencyType;
  final String description;
  final int holdSeconds;
  final VoidCallback onSos;
  final VoidCallback onProfile;
  final VoidCallback onEmergencyType;
  final VoidCallback onVoice;
  final VoidCallback onDescribe;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;
  final String? authorityResponseType;
  final String? authorityResponseMessage;
  final String? authorityRejectionMessage;
  final VoidCallback? onToggleEventMode;

  @override
  Widget build(BuildContext context) {
    final palette = MeshPalette.of(context);
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                MeshHeroSurface(
                  live: sending,
                  padding: const EdgeInsets.fromLTRB(
                    MeshSpace.screen,
                    MeshSpace.sm,
                    MeshSpace.screen,
                    MeshSpace.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const MeshMicroLabel('MeshSetu'),
                          const Spacer(),
                          if (onToggleEventMode != null)
                            IconButton(
                              tooltip: eventModeActive
                                  ? 'Stop event mode'
                                  : 'Start event mode',
                              onPressed: onToggleEventMode,
                              icon: Icon(
                                eventModeActive
                                    ? Icons.bluetooth_disabled
                                    : Icons.bluetooth_searching,
                              ),
                            ),
                          IconButton(
                            tooltip: 'Open profile',
                            onPressed: onProfile,
                            icon: const Icon(Icons.account_circle_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: MeshSpace.sm),
                      Text(
                        'Emergency Aid',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: MeshSpace.xs),
                      Text(
                        'One tap away from help',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: MeshSpace.xl),
                      Center(
                        child: MeshSosButton(
                          enabled: !sending,
                          holdDuration: Duration(seconds: holdSeconds),
                          onActivated: onSos,
                        ),
                      ),
                      const SizedBox(height: MeshSpace.md),
                      Text(
                        sending
                            ? 'Preparing your encrypted emergency packet…'
                            : 'Press and hold for $holdSeconds seconds to activate emergency protocol',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    MeshSpace.screen,
                    MeshSpace.lg,
                    MeshSpace.screen,
                    MeshSpace.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (authorityResponseMessage?.trim().isNotEmpty ??
                          false) ...[
                        const MeshSectionTitle(
                          'Control room response',
                          subtitle: 'Verified response received',
                        ),
                        const SizedBox(height: MeshSpace.sm),
                        MeshCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                color: palette.ember,
                              ),
                              const SizedBox(width: MeshSpace.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authorityResponseType ?? 'Update',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: MeshSpace.xs),
                                    Text(authorityResponseMessage!.trim()),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: MeshSpace.lg),
                      ] else if (authorityRejectionMessage?.trim().isNotEmpty ??
                          false) ...[
                        const MeshSectionTitle(
                          'Control room response',
                          subtitle: 'Could not be verified',
                        ),
                        const SizedBox(height: MeshSpace.sm),
                        MeshCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: MeshSpace.md),
                              Expanded(
                                child: Text(authorityRejectionMessage!.trim()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: MeshSpace.lg),
                      ],
                      MeshActionTile(
                        compact: true,
                        icon: _iconFor(emergencyType),
                        title: 'Emergency type',
                        subtitle: emergencyType.label,
                        selected: emergencyType != SosEmergencyType.general,
                        onTap: onEmergencyType,
                      ),
                      const SizedBox(height: MeshSpace.sm),
                      MeshActionTile(
                        compact: true,
                        icon: Icons.mic_none_rounded,
                        title: 'Voice input',
                        subtitle: description.isEmpty
                            ? 'Speak details'
                            : 'Details ready',
                        selected: description.isNotEmpty,
                        onTap: onVoice,
                      ),
                      const SizedBox(height: MeshSpace.sm),
                      MeshActionTile(
                        compact: true,
                        icon: Icons.edit_note_rounded,
                        title: 'Describe SOS',
                        subtitle: description.isEmpty
                            ? 'Add context'
                            : description,
                        selected: description.isNotEmpty,
                        onTap: onDescribe,
                      ),
                      const SizedBox(height: MeshSpace.xl),
                      const MeshSectionTitle(
                        'Rooms',
                        subtitle: 'Coordinate securely with people nearby',
                      ),
                      MeshCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: onCreateRoom,
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Create'),
                              ),
                            ),
                            const SizedBox(width: MeshSpace.sm),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onJoinRoom,
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Join'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: palette.canvas,
    );
  }

  static IconData _iconFor(SosEmergencyType type) => switch (type) {
    SosEmergencyType.general => Icons.sos_outlined,
    SosEmergencyType.fire => Icons.local_fire_department_outlined,
    SosEmergencyType.crime => Icons.gavel_outlined,
    SosEmergencyType.kidnap => Icons.person_search_outlined,
    SosEmergencyType.medical => Icons.medical_services_outlined,
    SosEmergencyType.naturalDisaster => Icons.tsunami_outlined,
  };
}
