import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/domain/cloud/cloud_auth_service.dart';
import 'package:app/domain/cloud/cloud_firestore_service.dart';
import 'package:app/domain/cloud/sync_queue_service.dart';
import 'package:app/domain/entities/session_record.dart';

class MockHttpClient extends Mock implements http.Client {}

// ---------------------------------------------------------------------------
// Lightweight stubs for Firebase Auth objects — no Firebase SDK call ever fired
// ---------------------------------------------------------------------------
class _FakeFirebaseUser extends Fake implements User {
  _FakeFirebaseUser({
    required this.uid,
    this.email,
    String? displayName,
    this.isAnonymous = false,
  }) : _displayName = displayName;

  @override
  final String uid;
  @override
  final String? email;
  final String? _displayName;
  @override
  String? get displayName => _displayName;
  @override
  final bool isAnonymous;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      'fake_token_$uid';
}

class _FakeUserCredential extends Fake implements UserCredential {
  _FakeUserCredential(this.user);
  @override
  final User user;
}

/// Minimal [FirebaseAuth] stub that never touches the network.
/// Pre-programmed with a user to return when [signInWithEmailAndPassword] is
/// called, and remembers the current signed-in user for [currentUser].
class _StubFirebaseAuth extends Fake implements FirebaseAuth {
  _StubFirebaseAuth({_FakeFirebaseUser? initialUser}) : _current = initialUser;

  _FakeFirebaseUser? _current;
  final _stateController = StreamController<User?>.broadcast();

  @override
  Stream<User?> authStateChanges() => _stateController.stream;

  @override
  User? get currentUser => _current;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = _FakeFirebaseUser(
      uid: 'usr_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      email: email,
      displayName: email.split('@').first,
    );
    _current = user;
    _stateController.add(user);
    return _FakeUserCredential(user);
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    final user = _FakeFirebaseUser(
      uid: 'anon_${DateTime.now().millisecondsSinceEpoch}',
      isAnonymous: true,
      displayName: 'Anonymous User',
    );
    _current = user;
    _stateController.add(user);
    return _FakeUserCredential(user);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _stateController.add(null);
  }

  void dispose() => _stateController.close();
}

void main() {
  group('PulsePatch Next Generation — Firebase Cloud & Offline-First Sync Tests', () {
    late _StubFirebaseAuth stubAuth;
    late CloudAuthService authService;
    late CloudFirestoreService firestoreService;
    late SyncQueueService syncQueueService;
    late MockHttpClient mockClient;

    setUp(() {
      registerFallbackValue(Uri.parse('https://example.com'));
      mockClient = MockHttpClient();
      stubAuth = _StubFirebaseAuth();
      authService = CloudAuthService(firebaseAuth: stubAuth);
      firestoreService = CloudFirestoreService(
        projectId: 'pulsepatch-lite',
        httpClient: mockClient,
      );
      syncQueueService = SyncQueueService(
        authService: authService,
        firestoreService: firestoreService,
      );
    });

    tearDown(() {
      stubAuth.dispose();
    });

    test('Default authentication state starts in Local Guest mode (100% offline privacy)', () {
      expect(authService.currentUser?.isGuest, isTrue);
      expect(authService.isAuthenticated, isFalse);
      expect(syncQueueService.currentState.status, equals(SyncStatus.localOnly));
    });

    test('Signing in transitions auth and sync state cleanly', () async {
      final user = await authService.signInWithEmail('test.patient@hospital.org', 'securePass123');
      expect(user.email, equals('test.patient@hospital.org'));
      expect(user.uid, contains('test_patient'));
      expect(authService.isAuthenticated, isTrue);
    });

    test('Queuing session records tracks outbox count and status', () {
      final dummySession = SessionRecord(
        id: 'sess_123',
        startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        endedAt: DateTime.now(),
        type: SessionType.rest,
        qualitySummary: QualitySummary.good,
        appVersion: '2.0.0',
        source: SessionSource.pulsepatch,
      );

      // In guest mode, queuing stays local
      syncQueueService.queueSession(dummySession);
      expect(syncQueueService.pendingCount, equals(1));
      expect(syncQueueService.currentState.status, equals(SyncStatus.localOnly));
    });

    test('Signing out resets state to Guest mode with zero data leak', () async {
      await authService.signInAnonymously();
      expect(authService.isAuthenticated, isTrue);

      await authService.signOut();
      expect(authService.currentUser?.isGuest, isTrue);
      expect(authService.isAuthenticated, isFalse);
    });

    test('Guest local mode strictly blocks all remote uploads', () async {
      final dummySession = SessionRecord(
        id: 'sess_guest_01',
        startedAt: DateTime.now(),
        type: SessionType.rest,
        qualitySummary: QualitySummary.good,
        appVersion: '2.0.0',
        source: SessionSource.pulsepatch,
      );

      final sessionUploaded = await firestoreService.uploadSession(
        userId: 'guest_local',
        session: dummySession,
      );
      expect(sessionUploaded, isFalse);

      final profileUploaded = await firestoreService.uploadProfile(
        userId: 'guest_local',
        profileData: {'age': 30},
      );
      expect(profileUploaded, isFalse);

      final calibrationUploaded = await firestoreService.uploadBpCalibration(
        userId: 'guest_local',
        calibrationId: 'cal_01',
        calibrationData: {'sbp': 120, 'dbp': 80},
      );
      expect(calibrationUploaded, isFalse);

      final alertUploaded = await firestoreService.uploadHealthAlert(
        userId: 'guest_local',
        alertId: 'alert_01',
        alertData: {'type': 'tachycardia'},
      );
      expect(alertUploaded, isFalse);

      verifyNever(() => mockClient.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')));
    });

    test('User isolation: Authenticated uploads target specific user UID subcollections', () async {
      when(() => mockClient.patch(
            any(that: predicate<Uri>((uri) => uri.path.contains('/users/usr_patient_alice/sessions/sess_alice_01'))),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{"name": "doc_alice"}', 200));

      final dummySession = SessionRecord(
        id: 'sess_alice_01',
        startedAt: DateTime.now(),
        type: SessionType.rest,
        qualitySummary: QualitySummary.good,
        appVersion: '2.0.0',
        source: SessionSource.pulsepatch,
      );

      final success = await firestoreService.uploadSession(
        userId: 'usr_patient_alice',
        session: dummySession,
        authToken: 'token_alice_valid',
      );

      expect(success, isTrue);

      verify(() => mockClient.patch(
            any(that: predicate<Uri>((uri) =>
                uri.path.contains('users/usr_patient_alice/sessions/sess_alice_01') &&
                !uri.path.contains('users/usr_patient_bob'))),
            headers: any(named: 'headers', that: containsPair('Authorization', 'Bearer token_alice_valid')),
            body: any(named: 'body'),
          )).called(1);
    });

    test('Outbox queue processes records idempotently and updates sync state to synced', () async {
      await authService.signInWithEmail('dr.omar@clinic.eg', 'safePass789');

      when(() => mockClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{"name": "synced_doc"}', 200));

      final dummySession = SessionRecord(
        id: 'sess_sync_456',
        startedAt: DateTime.now(),
        type: SessionType.postActivity,
        qualitySummary: QualitySummary.good,
        appVersion: '2.0.0',
        source: SessionSource.pulsepatch,
      );

      syncQueueService.queueSession(dummySession);
      syncQueueService.queueProfile({'fullName': 'Dr Omar', 'specialty': 'Cardiology'});
      expect(syncQueueService.pendingCount, equals(2));

      await syncQueueService.processQueue();

      expect(syncQueueService.pendingCount, equals(0));
      expect(syncQueueService.currentState.status, equals(SyncStatus.synced));
      expect(syncQueueService.currentState.lastSyncTime, isNotNull);
    });
  });
}
