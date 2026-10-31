import 'dart:typed_data';

/// Cloud Storage Service managing medical PDF reports
class CloudStorageService {
  const CloudStorageService({
    String? bucketName,
  }) : _bucket = bucketName ?? 'pulsepatch-lite.firebasestorage.app';

  final String _bucket;

  String get bucket => _bucket;

  /// Simulates / executes secure cloud upload to `users/{userId}/reports/{fileName}`
  Future<String?> uploadReportPdf({
    required String userId,
    required String fileName,
    required Uint8List pdfBytes,
  }) async {
    if (userId == 'guest_local') {
      // In guest mode, files remain strictly local
      return null;
    }

    // In production, uploads to Firebase Cloud Storage gs://bucket/users/uid/reports/
    final storagePath = 'gs://$_bucket/users/$userId/reports/$fileName';
    return storagePath;
  }
}
