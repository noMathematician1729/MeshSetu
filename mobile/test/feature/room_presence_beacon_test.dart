import 'dart:async';

import 'package:meshsetu_mobile/feature/rooms/room_presence_beacon.dart';
import 'package:test/test.dart';

void main() {
  test('announces immediately so a joiner is visible without waiting', () {
    var announcements = 0;
    final beacon = RoomPresenceBeacon(
      announce: () async => announcements++,
      peerCounts: const Stream<int>.empty(),
      interval: const Duration(hours: 1),
    );
    addTearDown(beacon.dispose);

    beacon.start();

    expect(announcements, 1);
  });

  test('re-announces when the mesh gains a peer', () async {
    var announcements = 0;
    final peers = StreamController<int>();
    addTearDown(peers.close);
    final beacon = RoomPresenceBeacon(
      announce: () async => announcements++,
      peerCounts: peers.stream,
      interval: const Duration(hours: 1),
    );
    addTearDown(beacon.dispose);
    beacon.start();
    expect(announcements, 1);

    // A peer arriving is the first moment a presence packet can actually be
    // delivered, so the announcement must be repeated then.
    peers.add(1);
    await Future<void>.delayed(Duration.zero);

    expect(announcements, 2);
  });

  test(
    'does not re-announce while a peer count is steady or falling',
    () async {
      var announcements = 0;
      final peers = StreamController<int>();
      addTearDown(peers.close);
      final beacon = RoomPresenceBeacon(
        announce: () async => announcements++,
        peerCounts: peers.stream,
        interval: const Duration(hours: 1),
      );
      addTearDown(beacon.dispose);
      beacon.start();

      peers.add(2);
      await Future<void>.delayed(Duration.zero);
      final afterGain = announcements;
      peers.add(2);
      peers.add(1);
      peers.add(0);
      await Future<void>.delayed(Duration.zero);

      expect(announcements, afterGain);
    },
  );

  test('keeps announcing on the interval while a room stays open', () async {
    var announcements = 0;
    final beacon = RoomPresenceBeacon(
      announce: () async => announcements++,
      peerCounts: const Stream<int>.empty(),
      interval: const Duration(milliseconds: 20),
    );
    addTearDown(beacon.dispose);

    beacon.start();
    await Future<void>.delayed(const Duration(milliseconds: 70));

    expect(announcements, greaterThanOrEqualTo(3));
  });

  test('a failing announce never escapes and later ticks still run', () async {
    var attempts = 0;
    final beacon = RoomPresenceBeacon(
      announce: () async {
        attempts++;
        throw StateError('outbox unavailable');
      },
      peerCounts: const Stream<int>.empty(),
      interval: const Duration(milliseconds: 20),
    );
    addTearDown(beacon.dispose);

    beacon.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(attempts, greaterThanOrEqualTo(2));
  });

  test('dispose stops the heartbeat', () async {
    var announcements = 0;
    final beacon = RoomPresenceBeacon(
      announce: () async => announcements++,
      peerCounts: const Stream<int>.empty(),
      interval: const Duration(milliseconds: 10),
    );

    beacon.start();
    await beacon.dispose();
    final afterDispose = announcements;
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(announcements, afterDispose);
  });
}
