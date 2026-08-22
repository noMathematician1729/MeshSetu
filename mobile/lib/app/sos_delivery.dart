import 'package:flutter/foundation.dart';

/// The user-visible lifecycle of a locally authored SOS.
///
/// [saved] and [queued] are local guarantees. [broadcasting] means the
/// foreground mesh has verified that the compact BLE alert is on air.
/// [confirmed] is the first state that represents another mesh peer taking
/// custody of the durable SOS packet. No state claims that emergency services
/// or a human has received the alert.
enum SosDeliveryPhase { saved, queued, broadcasting, confirmed, failed }

enum SosDeliveryEventKind {
  queued,
  broadcastStarted,
  broadcastFailed,
  relayConfirmed,
  expired,
  failed,
}

final class SosDeliveryEvent {
  const SosDeliveryEvent({
    required this.kind,
    required this.objectId,
    this.eventId,
    this.peerId,
    this.detail,
  });

  final SosDeliveryEventKind kind;
  final int objectId;
  final String? eventId;
  final String? peerId;
  final String? detail;
}

/// Immutable projection used by the SOS screen and easy to assert in tests.
final class SosDeliveryStatus {
  const SosDeliveryStatus({
    required this.eventId,
    required this.objectId,
    required this.phase,
    required this.locationStatus,
    this.detail = 'SOS saved securely on this device.',
    this.peerId,
    this.broadcastFailed = false,
  });

  final String eventId;
  final int objectId;
  final SosDeliveryPhase phase;
  final String locationStatus;
  final String detail;
  final String? peerId;
  final bool broadcastFailed;

  SosDeliveryStatus copyWith({
    SosDeliveryPhase? phase,
    String? detail,
    String? peerId,
    bool? broadcastFailed,
  }) => SosDeliveryStatus(
    eventId: eventId,
    objectId: objectId,
    phase: phase ?? this.phase,
    locationStatus: locationStatus,
    detail: detail ?? this.detail,
    peerId: peerId ?? this.peerId,
    broadcastFailed: broadcastFailed ?? this.broadcastFailed,
  );

  bool get isRemoteConfirmed => phase == SosDeliveryPhase.confirmed;
  bool get isTerminalFailure => phase == SosDeliveryPhase.failed;
}

/// Mutable lifecycle owned by the screen that initiated the SOS.
///
/// The foreground task and the UI-isolate bridge never hold a widget reference;
/// they emit [SosDeliveryEvent] values and the owning screen applies matching
/// events by object ID. This keeps the correlation explicit across isolates.
final class SosDeliveryTracker extends ValueNotifier<SosDeliveryStatus> {
  SosDeliveryTracker(super.value);

  void apply(SosDeliveryEvent event) {
    if (event.objectId != value.objectId) return;
    final next = switch (event.kind) {
      SosDeliveryEventKind.queued => value.copyWith(
        phase: SosDeliveryPhase.queued,
        detail: event.detail ?? 'SOS queued for the emergency mesh.',
      ),
      SosDeliveryEventKind.broadcastStarted => value.copyWith(
        phase: SosDeliveryPhase.broadcasting,
        detail: event.detail ?? 'Compact SOS is broadcasting nearby.',
      ),
      SosDeliveryEventKind.broadcastFailed => value.copyWith(
        phase: value.phase == SosDeliveryPhase.confirmed
            ? value.phase
            : SosDeliveryPhase.queued,
        broadcastFailed: true,
        detail:
            event.detail ??
            'Compact broadcast unavailable; the encrypted packet remains queued for GATT relay.',
      ),
      SosDeliveryEventKind.relayConfirmed => value.copyWith(
        phase: SosDeliveryPhase.confirmed,
        peerId: event.peerId,
        detail:
            event.detail ?? 'A nearby mesh peer confirmed custody of the SOS.',
      ),
      SosDeliveryEventKind.expired => value.copyWith(
        phase: SosDeliveryPhase.failed,
        detail:
            event.detail ?? 'SOS expired before a mesh peer acknowledged it.',
      ),
      SosDeliveryEventKind.failed => value.copyWith(
        phase: SosDeliveryPhase.failed,
        detail: event.detail ?? 'SOS could not enter the foreground mesh.',
      ),
    };
    if (next != value) value = next;
  }
}
