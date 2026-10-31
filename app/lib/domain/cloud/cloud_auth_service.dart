import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents a PulsePatch User Account
class UserAccount {
  UserAccount({
    required this.uid,
    this.email,
    this.displayName,
    this.isAnonymous = false,
    this.idToken,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;
  final String? idToken;
  final DateTime createdAt;

  bool get isGuest => uid == 'guest_local';

  static final UserAccount guest = UserAccount(
    uid: 'guest_local',
    displayName: 'Local Guest',
    isAnonymous: true,
    createdAt: DateTime.fromMicrosecondsSinceEpoch(0),
  );

  static Future<UserAccount> fromFirebaseUser(User firebaseUser) async {
    String? token;
    try {
      token = await firebaseUser.getIdToken();
    } catch (_) {}
    return UserAccount(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName:
          firebaseUser.displayName ?? firebaseUser.email?.split('@').first,
      isAnonymous: firebaseUser.isAnonymous,
      idToken: token,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'isAnonymous': isAnonymous,
    'createdAt': createdAt.toIso8601String(),
  };

  UserAccount copyWithToken(String? token) {
    return UserAccount(
      uid: uid,
      email: email,
      displayName: displayName,
      isAnonymous: isAnonymous,
      idToken: token,
      createdAt: createdAt,
    );
  }
}

final cloudAuthServiceProvider = Provider<CloudAuthService>((ref) {
  return CloudAuthService();
});

/// Cloud Authentication Service managing Guest and Firebase accounts.
/// Accepts an optional [firebaseAuth] for dependency injection in tests.
class CloudAuthService {
  CloudAuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    // Listen to Firebase Auth state changes
    _authSubscription = _firebaseAuth.authStateChanges().listen(
      _onFirebaseAuthStateChanged,
      onError: (_) => _emitGuest(),
    );
  }

  final FirebaseAuth _firebaseAuth;
  StreamSubscription<User?>? _authSubscription;
  UserAccount? _currentUser = UserAccount.guest;
  final _controller = StreamController<UserAccount?>.broadcast();

  UserAccount? get currentUser => _currentUser;
  bool get isAuthenticated =>
      _currentUser != null && !_currentUser!.isGuest;
  Stream<UserAccount?> get authStateChanges => _controller.stream;

  void _onFirebaseAuthStateChanged(User? user) async {
    if (user == null) {
      _emitGuest();
    } else {
      _currentUser = await UserAccount.fromFirebaseUser(user);
      _controller.add(_currentUser);
    }
  }

  void _emitGuest() {
    _currentUser = UserAccount.guest;
    _controller.add(_currentUser);
  }

  Future<UserAccount> signInAnonymously() async {
    try {
      final cred = await _firebaseAuth.signInAnonymously();
      final account = await UserAccount.fromFirebaseUser(cred.user!);
      _currentUser = account;
      _controller.add(_currentUser);
      return account;
    } catch (e) {
      // Fallback: offline anonymous with local UID
      final uid = 'anon_${DateTime.now().millisecondsSinceEpoch}';
      final account = UserAccount(
        uid: uid,
        displayName: 'Anonymous User',
        isAnonymous: true,
      );
      _currentUser = account;
      _controller.add(_currentUser);
      return account;
    }
  }

  Future<UserAccount> signInWithEmail(String email, String password) async {
    try {
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final account = await UserAccount.fromFirebaseUser(cred.user!);
      _currentUser = account;
      _controller.add(_currentUser);
      return account;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserAccount> createAccount(String email, String password) async {
    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final account = await UserAccount.fromFirebaseUser(cred.user!);
      _currentUser = account;
      _controller.add(_currentUser);
      return account;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    _emitGuest();
  }

  /// Refreshes the ID token for use in Firestore REST calls.
  Future<String?> refreshIdToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final token = await user.getIdToken(true);
        _currentUser = _currentUser?.copyWithToken(token);
        return token;
      }
    } catch (_) {}
    return null;
  }

  void dispose() {
    _authSubscription?.cancel();
    _controller.close();
  }
}
