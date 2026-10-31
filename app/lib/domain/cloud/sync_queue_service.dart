import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/session_record.dart';
import 'cloud_auth_service.dart';
import 'cloud_firestore_service.dart';

enum SyncStatus {
  localOnly('Local Only (Guest)', 'محلي فقط (زائر)'),
  syncing('Syncing with Cloud...', 'جارِ المزامنة السحابية...'),
  synced('Synced with Cloud', 'تمت المزامنة بنجاح'),
  offlineQueued('Offline Queue', 'في قائمة الانتظار دون اتصال'),
  error('Sync Error', 'خطأ في المزامنة');

  const SyncStatus(this.labelEn, this.labelAr);
  final String labelEn;
  final String labelAr;
}

class SyncState {
  const SyncState({
    required this.status,
    required this.pendingCount,
    this.lastSyncTime,
    this.errorMessage,
  });

  final SyncStatus status;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final auth = ref.watch(cloudAuthServiceProvider);
  return SyncQueueService(
    authService: auth,
    firestoreService: CloudFirestoreService(),
  );
});

final syncStateStreamProvider = StreamProvider<SyncState>((ref) {
  final service = ref.watch(syncQueueServiceProvider);
  return service.stateStream;
});

/// Outbox Sync Queue Service decoupling local database writes from cloud network latency
class SyncQueueService {
  SyncQueueService({
    required this.authService,
    required this.firestoreService,
  }) {
    _controller = StreamController<SyncState>.broadcast();
    _updateState(
      authService.isAuthenticated
          ? SyncStatus.synced
          : SyncStatus.localOnly,
    );
  }

  final CloudAuthService authService;
  final CloudFirestoreService firestoreService;

  final List<SessionRecord> _pendingSessions = [];
  final List<Map<String, dynamic>> _pendingProfiles = [];
  late final StreamController<SyncState> _controller;

  SyncState _state = const SyncState(
    status: SyncStatus.localOnly,
    pendingCount: 0,
  );

  SyncState get currentState => _state;
  Stream<SyncState> get stateStream => _controller.stream;
  int get pendingCount => _pendingSessions.length + _pendingProfiles.length;

  void queueSession(SessionRecord session) {
    _pendingSessions.add(session);
    if (!authService.isAuthenticated) {
      _updateState(SyncStatus.localOnly);
    } else {
      _updateState(SyncStatus.offlineQueued);
    }
  }

  void queueProfile(Map<String, dynamic> profile) {
    _pendingProfiles.add(profile);
    if (!authService.isAuthenticated) {
      _updateState(SyncStatus.localOnly);
    } else {
      _updateState(SyncStatus.offlineQueued);
    }
  }

  Future<void> processQueue() async {
    if (!authService.isAuthenticated) {
      _updateState(SyncStatus.localOnly);
      return;
    }

    if (pendingCount == 0) {
      _updateState(SyncStatus.synced, lastSync: DateTime.now());
      return;
    }

    _updateState(SyncStatus.syncing);

    // Refresh Firebase ID token before uploading to pass Firestore security rules
    final freshToken = await authService.refreshIdToken();

    final userId = authService.currentUser!.uid;
    final List<SessionRecord> failedSessions = [];
    final List<Map<String, dynamic>> failedProfiles = [];

    // Sync Sessions
    for (final session in List<SessionRecord>.from(_pendingSessions)) {
      final success = await firestoreService.uploadSession(
        userId: userId,
        session: session,
        authToken: freshToken ?? authService.currentUser?.idToken,
      );
      if (!success) {
        failedSessions.add(session);
      }
    }

    // Sync Profiles
    for (final profile in List<Map<String, dynamic>>.from(_pendingProfiles)) {
      final success = await firestoreService.uploadProfile(
        userId: userId,
        profileData: profile,
        authToken: freshToken ?? authService.currentUser?.idToken,
      );
      if (!success) {
        failedProfiles.add(profile);
      }
    }

    _pendingSessions.clear();
    _pendingSessions.addAll(failedSessions);

    _pendingProfiles.clear();
    _pendingProfiles.addAll(failedProfiles);

    if (pendingCount > 0) {
      _updateState(
        SyncStatus.offlineQueued,
        error: 'Some items could not be uploaded. Will retry automatically.',
      );
    } else {
      _updateState(
        SyncStatus.synced,
        lastSync: DateTime.now(),
      );
    }
  }

  void _updateState(SyncStatus status, {DateTime? lastSync, String? error}) {
    _state = _state.copyWith(
      status: status,
      pendingCount: pendingCount,
      lastSyncTime: lastSync ?? _state.lastSyncTime,
      errorMessage: error,
    );
    _controller.add(_state);
  }

  void dispose() {
    _controller.close();
  }
}
