import 'dart:convert';
import 'package:http/http.dart' as http;
import '../entities/session_record.dart';

/// User-scoped Cloud Firestore Service managing remote health records
class CloudFirestoreService {
  CloudFirestoreService({
    String? projectId,
    http.Client? httpClient,
  })  : _projectId = projectId ?? const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'pulsepatch-lite'),
        _client = httpClient ?? http.Client();

  final String _projectId;
  final http.Client _client;

  String get _firestoreBaseUrl =>
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  Map<String, String> _buildHeaders(String? authToken) {
    return {
      'Content-Type': 'application/json',
      if (authToken != null && authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
    };
  }

  /// Saves a session record to `users/{userId}/sessions/{sessionId}`
  Future<bool> uploadSession({
    required String userId,
    required SessionRecord session,
    String? authToken,
  }) async {
    if (userId == 'guest_local') return false; // Never upload guest data

    final path = 'users/$userId/sessions/${session.id}';
    final uri = Uri.parse('$_firestoreBaseUrl/$path');

    final fields = <String, dynamic>{
      'sessionId': {'stringValue': session.id},
      'startedAt': {'integerValue': session.startedAt.millisecondsSinceEpoch.toString()},
      if (session.endedAt != null)
        'endedAt': {'integerValue': session.endedAt!.millisecondsSinceEpoch.toString()},
      'type': {'stringValue': session.type.name},
      'qualitySummary': {'stringValue': session.qualitySummary.name},
      'appVersion': {'stringValue': session.appVersion},
      'source': {'stringValue': session.source.code},
    };

    try {
      final response = await _client.patch(
        uri,
        headers: _buildHeaders(authToken),
        body: json.encode({'fields': fields}),
      ).timeout(const Duration(seconds: 8));

      return response.statusCode == 200;
    } catch (_) {
      // Offline or network timeout
      return false;
    }
  }

  /// Fetches a session record from `users/{userId}/sessions/{sessionId}`
  Future<Map<String, dynamic>?> fetchSession({
    required String userId,
    required String sessionId,
    String? authToken,
  }) async {
    if (userId == 'guest_local') return null;

    final path = 'users/$userId/sessions/$sessionId';
    final uri = Uri.parse('$_firestoreBaseUrl/$path');

    try {
      final response = await _client.get(
        uri,
        headers: _buildHeaders(authToken),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Deletes a session record from `users/{userId}/sessions/{sessionId}`
  Future<bool> deleteSession({
    required String userId,
    required String sessionId,
    String? authToken,
  }) async {
    if (userId == 'guest_local') return false;

    final path = 'users/$userId/sessions/$sessionId';
    final uri = Uri.parse('$_firestoreBaseUrl/$path');

    try {
      final response = await _client.delete(
        uri,
        headers: _buildHeaders(authToken),
      ).timeout(const Duration(seconds: 8));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Uploads user profile to `users/{userId}/profile`
  Future<bool> uploadProfile({
    required String userId,
    required Map<String, dynamic> profileData,
    String? authToken,
  }) async {
    if (userId == 'guest_local') return false;

    final path = 'users/$userId/profile';
    final uri = Uri.parse('$_firestoreBaseUrl/$path');

    final fields = _mapToFirestoreFields(profileData);

    try {
      final response = await _client.patch(
        uri,
        headers: _buildHeaders(authToken),
        body: json.encode({'fields': fields}),
      ).timeout(const Duration(seconds: 8));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Uploads blood pressure calibration to `users/{userId}/bp_calibrations/{calibrationId}`
  Future<bool> uploadBpCalibration({
    required String userId,
    required String calibrationId,
    required Map<String, dynamic> calibrationData,
    String? authToken,
  }) async {
    if (userId == 'guest_local') return false;

    final path = 'users/$userId/bp_calibrations/$calibrationId';
    final uri = Uri.parse('$_firestoreBaseUrl/$path');

    final fields = _mapToFirestoreFields(calibrationData);

    try {
      final response = await _client.patch(
        uri,
        headers: _buildHeaders(authToken),
        body: json.encode({'fields': fields}),
      ).timeout(const Duration(seconds: 8));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Uploads health alert to `users/{userId}/health_alerts/{alertId}`
  Future<bool> uploadHealthAlert({
    required String userId,
    required String alertId,
    required Map<String, dynamic> alertData,
    String? authToken,
  }) async {
    if (userId == 'guest_local') return false;

    final path = 'users/$userId/health_alerts/$alertId';
    final uri = Uri.parse('$_firestoreBaseUrl/$path');

    final fields = _mapToFirestoreFields(alertData);

    try {
      final response = await _client.patch(
        uri,
        headers: _buildHeaders(authToken),
        body: json.encode({'fields': fields}),
      ).timeout(const Duration(seconds: 8));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _mapToFirestoreFields(Map<String, dynamic> data) {
    final fields = <String, dynamic>{};
    for (final entry in data.entries) {
      final v = entry.value;
      if (v is String) {
        fields[entry.key] = {'stringValue': v};
      } else if (v is int) {
        fields[entry.key] = {'integerValue': v.toString()};
      } else if (v is double) {
        fields[entry.key] = {'doubleValue': v};
      } else if (v is bool) {
        fields[entry.key] = {'booleanValue': v};
      }
    }
    return fields;
  }
}
