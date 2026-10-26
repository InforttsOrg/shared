import 'package:flutter_test/flutter_test.dart';
import 'package:infortts_shared/infortts_notification_service.dart';

void main() {
  group('InforttsNotificationService relevance & scoping', () {
    final mitoTradingEvent = InforttsNotificationEvent(
      id: 'mito-svc-infortts-mt5-live-trader',
      title: '⚠️ infortts-mt5-live-trader is inactive',
      body: 'Unit infortts-mt5-live-trader.service reports inactive.',
      topic: 'mito.ops',
      category: 'SYSTEM',
      priority: 'high',
      url: 'https://mitochondria.infortts.site',
      timestamp: DateTime.now(),
      data: {'unit': 'infortts-mt5-live-trader.service'},
    );

    final nodePressureEvent = InforttsNotificationEvent(
      id: 'mito-pressure',
      title: '⚠️ Node under pressure',
      body: 'load1=24.6484375 on 4 cores, MemAvailable=11663 MB, disk free 6.9 GB.',
      topic: 'mito.ops',
      category: 'SYSTEM',
      priority: 'high',
      url: 'https://mitochondria.infortts.site',
      timestamp: DateTime.now(),
      data: {'load1': 24.6},
    );

    final mitoStatusEvent = InforttsNotificationEvent(
      id: 'mito-status-20261026',
      title: '🫀 Mitochondria status',
      body: 'Accounts synced: 3/9 terminals running: 5',
      topic: 'mito.ops',
      category: 'SYSTEM',
      priority: 'normal',
      url: 'https://mitochondria.infortts.site',
      timestamp: DateTime.now(),
      data: {},
    );

    final waptiaUpdateEvent = InforttsNotificationEvent(
      id: 'waptia-update-1',
      title: '🚀 Cloudina Update Available',
      body: 'Version 1.4.2 is ready to install.',
      topic: 'waptia.store',
      category: 'UPDATES',
      priority: 'normal',
      url: 'https://waptia.infortts.site',
      timestamp: DateTime.now(),
      data: {'app': 'waptia'},
    );

    final userSpecificEvent = InforttsNotificationEvent(
      id: 'user-notif-1',
      title: 'Order Completed',
      body: 'Your download has finished.',
      topic: 'waptia.store',
      category: 'STORE',
      priority: 'normal',
      url: 'https://waptia.infortts.site',
      timestamp: DateTime.now(),
      data: {'user_id': 'usr_vip_42'},
    );

    test('Waptia rejects all Mitochondria and trading events', () {
      expect(
        InforttsNotificationService.isNotificationRelevant(
          mitoTradingEvent,
          appName: 'Waptia Store',
          isGuest: true,
        ),
        isFalse,
      );
      expect(
        InforttsNotificationService.isNotificationRelevant(
          mitoStatusEvent,
          appName: 'Waptia Store',
          userId: 'usr_vip_42',
          isGuest: false,
        ),
        isFalse,
      );
    });

    test('Waptia rejects internal infrastructure node pressure alerts', () {
      expect(
        InforttsNotificationService.isNotificationRelevant(
          nodePressureEvent,
          appName: 'Waptia Store',
          userId: 'usr_vip_42',
          isGuest: false,
        ),
        isFalse,
      );
    });

    test('Guest user cannot see user-specific private notifications', () {
      expect(
        InforttsNotificationService.isNotificationRelevant(
          userSpecificEvent,
          appName: 'Waptia Store',
          isGuest: true,
        ),
        isFalse,
      );
    });

    test('Logged in user only sees notifications matching their specific userId', () {
      // Matching user
      expect(
        InforttsNotificationService.isNotificationRelevant(
          userSpecificEvent,
          appName: 'Waptia Store',
          userId: 'usr_vip_42',
          isGuest: false,
        ),
        isTrue,
      );

      // Different user
      expect(
        InforttsNotificationService.isNotificationRelevant(
          userSpecificEvent,
          appName: 'Waptia Store',
          userId: 'usr_different_99',
          isGuest: false,
        ),
        isFalse,
      );
    });

    test('Waptia accepts public Waptia store package updates', () {
      expect(
        InforttsNotificationService.isNotificationRelevant(
          waptiaUpdateEvent,
          appName: 'Waptia Store',
          isGuest: true,
        ),
        isTrue,
      );
    });

    test('Mitochondria app still receives Mitochondria alerts', () {
      expect(
        InforttsNotificationService.isNotificationRelevant(
          mitoTradingEvent,
          appName: 'Mitochondria',
          userId: 'usr_trader_1',
          isGuest: false,
        ),
        isTrue,
      );
    });
  });
}
