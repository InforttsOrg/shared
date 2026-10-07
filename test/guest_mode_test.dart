import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infortts_shared/infortts_shared.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Infortts Guest Mode & Session Auth Tests', () {
    test('AuthSession accurately differentiates between authenticated user and guest', () {
      final guest = AuthSession(
        userId: 'usr_guest',
        email: '',
        profile: {
          'display_name': 'GUEST',
          'username': 'guest',
        },
      );

      expect(guest.isGuest, isTrue);
      expect(guest.authenticated, isFalse);
      expect(guest.displayName, equals('GUEST'));

      final authenticatedUser = AuthSession(
        userId: 'usr_12345',
        email: 'operator@infortts.site',
        token: 'session_jwt_xyz',
        profile: {
          'display_name': 'Lead Operator',
          'role': 'superadmin',
        },
      );

      expect(authenticatedUser.isGuest, isFalse);
      expect(authenticatedUser.authenticated, isTrue);
      expect(authenticatedUser.isSuperadmin, isTrue);
      expect(authenticatedUser.displayName, equals('Lead Operator'));
    });

    test('InforttsAuthManager enterGuestMode produces active guest session', () async {
      final manager = InforttsAuthManager.instance;
      final guestSession = manager.enterGuestMode(persist: true);

      expect(manager.isGuest, isTrue);
      expect(manager.isAuthenticated, isFalse);
      expect(manager.currentSession?.userId, equals('usr_guest'));
      expect(guestSession.userId, equals('usr_guest'));

      // Wait brief microtask for async prefs write
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('infortts_auth_userId'), equals('usr_guest'));
    });

    test('InforttsAuthManager signOut clears session and storage', () async {
      final manager = InforttsAuthManager.instance;
      manager.enterGuestMode(persist: true);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await manager.signOut(requireAuth: true);

      expect(manager.currentSession, isNull);
      expect(manager.isAuthenticated, isFalse);
      expect(manager.isGuest, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('infortts_auth_userId'), isNull);
    });
  });
}
