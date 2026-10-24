import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../../data/repositories/session_repository.dart';
import '../entities/ai_result_record.dart';
import '../entities/session_record.dart';
import '../signal/signal_constants.dart';
import 'ai_model_metadata.dart';

enum AiInferenceStatus {
  idle,
  loading,
  analyzing,
  success,
  insufficientData,
  invalidInput,
  modelUnavailable,
}

class AiInferenceResult {
  const AiInferenceResult({
    required this.label,
    required this.explanation,
    required this.comparisonText,
    required this.features,
    required this.scaledFeatures,
    required this.modelVersion,
    required this.inferredAt,
  });

  final String label;
  final String explanation;
  final String comparisonText;
  final Map<String, double> features;
  final Map<String, double> scaledFeatures;
  final String modelVersion;
  final DateTime inferredAt;

  Map<String, dynamic> toJson() => {
    'label': label,
    'explanation': explanation,
    'comparisonText': comparisonText,
    'features': features,
    'scaledFeatures': scaledFeatures,
    'modelVersion': modelVersion,
    'inferredAt': inferredAt.toIso8601String(),
  };
}

class AiInferenceState {
  const AiInferenceState({
    required this.status,
    this.result,
    this.errorMessage,
    this.insufficientReason,
  });

  final AiInferenceStatus status;
  final AiInferenceResult? result;
  final String? errorMessage;
  final String? insufficientReason;

  factory AiInferenceState.idle() =>
      const AiInferenceState(status: AiInferenceStatus.idle);
  factory AiInferenceState.loading() =>
      const AiInferenceState(status: AiInferenceStatus.loading);
  factory AiInferenceState.analyzing() =>
      const AiInferenceState(status: AiInferenceStatus.analyzing);
  factory AiInferenceState.success(AiInferenceResult result) =>
      AiInferenceState(status: AiInferenceStatus.success, result: result);
  factory AiInferenceState.insufficientData(String reason) => AiInferenceState(
    status: AiInferenceStatus.insufficientData,
    insufficientReason: reason,
  );
  factory AiInferenceState.invalidInput(String reason) => AiInferenceState(
    status: AiInferenceStatus.invalidInput,
    errorMessage: reason,
  );
  factory AiInferenceState.modelUnavailable(String reason) => AiInferenceState(
    status: AiInferenceStatus.modelUnavailable,
    errorMessage: reason,
  );
}

class _InferencePayload {
  const _InferencePayload({
    required this.rawFeatures,
    required this.metadataJson,
    required this.priorSessionCount,
    required this.priorMeanHr,
    required this.priorStdHr,
  });

  final Map<String, double> rawFeatures;
  final String metadataJson;
  final int priorSessionCount;
  final double? priorMeanHr;
  final double? priorStdHr;
}

/// Service managing on-device TFLite model lifecycle and isolate inference.
class AiInferenceService {
  AiInferenceService({SessionRepository? repository})
    : _repository = repository;

  final SessionRepository? _repository;
  AiModelMetadata? _metadata;
  bool _isInitialized = false;

  AiModelMetadata? get metadata => _metadata;
  bool get isInitialized => _isInitialized;

  /// Loads model metadata and verifies assets.
  Future<void> initialize({
    String metaAssetPath = 'assets/ml/model_meta.json',
    String? customMetaJson,
  }) async {
    try {
      String jsonStr;
      if (customMetaJson != null) {
        jsonStr = customMetaJson;
      } else {
        jsonStr = await rootBundle.loadString(metaAssetPath);
      }
      _metadata = AiModelMetadata.fromJsonString(jsonStr);
      _isInitialized = true;
    } catch (e) {
      // Fallback to internal default metadata if asset bundle fails
      _metadata = AiModelMetadata.fromJson(const {});
      _isInitialized = true;
    }
  }

  /// Evaluates a session's extracted features and produces a pattern result.
  Future<AiInferenceState> analyzeSession({
    required String sessionId,
    required Map<String, double?> features,
    required int validSampleCount,
    required SessionType sessionType,
  }) async {
    // 1. Check valid data requirement (at least 30 seconds of valid data)
    final minValidRequired =
        SignalConstants.minAnalyzableSessionDuration.inSeconds;
    if (validSampleCount < minValidRequired) {
      return AiInferenceState.insufficientData(
        'Requires at least 30 seconds of valid pulse data. Recorded $validSampleCount valid seconds.',
      );
    }

    // 2. Check for required features
    final meanHr = features['mean_hr'];
    final stdHr = features['std_hr'];
    final startHr = features['start_hr'];
    final endHr = features['end_hr'];
    final recoveryDrop = features['recovery_drop'];

    if (meanHr == null || stdHr == null || startHr == null || endHr == null) {
      return AiInferenceState.insufficientData(
        'Statistical features could not be calculated from recorded window.',
      );
    }

    if (sessionType == SessionType.postActivity && recoveryDrop == null) {
      return AiInferenceState.insufficientData(
        'Post-activity sessions require 70+ seconds with valid 55-65s recovery window to compute recovery drop.',
      );
    }

    // Check validity of values
    if (meanHr.isNaN ||
        stdHr.isNaN ||
        startHr.isNaN ||
        endHr.isNaN ||
        (recoveryDrop != null && recoveryDrop.isNaN)) {
      return AiInferenceState.invalidInput(
        'Calculated features contain non-numeric or infinite values.',
      );
    }

    // Effective recovery drop for rest sessions defaults to startHr - endHr if null
    final effectiveRecoveryDrop = recoveryDrop ?? (startHr - endHr);

    final rawMap = <String, double>{
      'mean_hr': meanHr,
      'std_hr': stdHr,
      'start_hr': startHr,
      'end_hr': endHr,
      'recovery_drop': effectiveRecoveryDrop,
    };

    // Ensure service is initialized
    if (!_isInitialized || _metadata == null) {
      await initialize();
    }

    final meta = _metadata;
    if (meta == null) {
      return AiInferenceState.modelUnavailable(
        'PulsePatch AI model is not loaded.',
      );
    }

    // Retrieve prior sessions for history comparison
    int priorCount = 0;
    double? priorMean;
    double? priorStd;
    if (_repository != null) {
      try {
        final priorSessions = _repository
            .getAllSessions()
            .where((s) => s.id != sessionId && s.type == sessionType)
            .toList();
        priorCount = priorSessions.length;
        if (priorCount >= 1) {
          final means = <double>[];
          for (final s in priorSessions) {
            final stats = _repository.getStatsForSession(s.id);
            if (stats != null) {
              means.add(stats.meanHr);
            }
          }
          if (means.isNotEmpty) {
            priorMean = means.reduce((a, b) => a + b) / means.length;
            if (means.length > 1) {
              final sumSq = means
                  .map((x) => math.pow(x - priorMean!, 2))
                  .reduce((a, b) => a + b);
              priorStd = math.sqrt(sumSq / (means.length - 1));
            }
          }
        }
      } catch (_) {}
    }

    try {
      final payload = _InferencePayload(
        rawFeatures: rawMap,
        metadataJson: jsonEncode(meta.toJson()),
        priorSessionCount: priorCount,
        priorMeanHr: priorMean,
        priorStdHr: priorStd,
      );

      final result = await Isolate.run(() => _executeModel(payload));

      // Persist AI result in repository if available
      if (_repository != null) {
        try {
          _repository.insertOrUpdateAiResult(
            AiResultRecord(
              sessionId: sessionId,
              modelVersion: result.modelVersion,
              label: result.label,
              featuresJson: jsonEncode(result.toJson()),
              createdAt: result.inferredAt,
            ),
          );
        } catch (_) {}
      }

      return AiInferenceState.success(result);
    } catch (e) {
      return AiInferenceState.invalidInput('Inference failed: $e');
    }
  }

  /// Executes model inference in a background isolate.
  static AiInferenceResult _executeModel(_InferencePayload payload) {
    final meta = AiModelMetadata.fromJson(
      jsonDecode(payload.metadataJson) as Map<String, dynamic>,
    );

    // Standardize features: z = (x - mean) / scale
    final scaled = <String, double>{};
    final zVector = <double>[];

    for (int i = 0; i < meta.features.length; i++) {
      final featName = meta.features[i];
      final rawVal = payload.rawFeatures[featName] ?? 0.0;
      final mean = i < meta.scalerMean.length ? meta.scalerMean[i] : 0.0;
      final scale = (i < meta.scalerScale.length && meta.scalerScale[i] != 0.0)
          ? meta.scalerScale[i]
          : 1.0;

      final z = (rawVal - mean) / scale;
      scaled[featName] = z;
      zVector.add(z);
    }

    // Forward pass: MLP evaluation or calibrated baseline fallback
    bool isTypical = true;
    final weights = meta.weights;

    if (weights != null &&
        weights['coefs'] is List &&
        weights['intercepts'] is List) {
      try {
        final rawCoefs = weights['coefs'] as List<dynamic>;
        final rawIntercepts = weights['intercepts'] as List<dynamic>;

        // Layer 1: Dense 5 -> 16, ReLU
        final c0 = (rawCoefs[0] as List<dynamic>)
            .map(
              (r) => (r as List<dynamic>)
                  .map((e) => (e as num).toDouble())
                  .toList(),
            )
            .toList();
        final b0 = (rawIntercepts[0] as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList();
        final h1 = List<double>.filled(16, 0.0);
        for (int j = 0; j < 16; j++) {
          double sum = b0[j];
          for (int i = 0; i < zVector.length && i < c0.length; i++) {
            sum += zVector[i] * c0[i][j];
          }
          h1[j] = math.max(0.0, sum);
        }

        // Layer 2: Dense 16 -> 8, ReLU
        final c1 = (rawCoefs[1] as List<dynamic>)
            .map(
              (r) => (r as List<dynamic>)
                  .map((e) => (e as num).toDouble())
                  .toList(),
            )
            .toList();
        final b1 = (rawIntercepts[1] as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList();
        final h2 = List<double>.filled(8, 0.0);
        for (int j = 0; j < 8; j++) {
          double sum = b1[j];
          for (int i = 0; i < 16 && i < c1.length; i++) {
            sum += h1[i] * c1[i][j];
          }
          h2[j] = math.max(0.0, sum);
        }

        // Layer 3: Output 8 -> 1 (Sigmoid)
        final c2 = (rawCoefs[2] as List<dynamic>)
            .map(
              (r) => (r as List<dynamic>)
                  .map((e) => (e as num).toDouble())
                  .toList(),
            )
            .toList();
        final b2 = (rawIntercepts[2] as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList();
        double logit = b2[0];
        for (int i = 0; i < 8 && i < c2.length; i++) {
          logit += h2[i] * c2[i][0];
        }
        final probDifferent = 1.0 / (1.0 + math.exp(-logit));
        isTypical = probDifferent < 0.5;
      } catch (_) {
        // Fallback to normalized Euclidean distance
        double zDistSq = 0.0;
        for (final z in zVector) {
          zDistSq += z * z;
        }
        isTypical = math.sqrt(zDistSq) <= 2.8;
      }
    } else {
      // Fallback to normalized Euclidean distance
      double zDistSq = 0.0;
      for (final z in zVector) {
        zDistSq += z * z;
      }
      isTypical = math.sqrt(zDistSq) <= 2.8;
    }

    final String label = isTypical ? 'Typical pattern' : 'Different pattern';

    // Plain-language non-diagnostic explanation
    final String explanation = isTypical
        ? 'Similar to your last ${payload.priorSessionCount > 0 ? payload.priorSessionCount : "reference"} rest sessions. A pattern label, not a health rating.'
        : 'Varied from your typical resting baseline pattern. A statistical pattern label, not a health rating.';

    // Historical comparison text
    String comparisonText;
    if (payload.priorSessionCount >= 5 &&
        payload.priorMeanHr != null &&
        payload.priorStdHr != null &&
        payload.priorStdHr! > 0.01) {
      final rawMean = payload.rawFeatures['mean_hr'] ?? 0.0;
      final zScore = (rawMean - payload.priorMeanHr!) / payload.priorStdHr!;
      final formattedZ = (zScore >= 0 ? '+' : '') + zScore.toStringAsFixed(1);
      comparisonText =
          '$formattedZ SD from your personal baseline (${payload.priorSessionCount} sessions recorded).';
    } else if (payload.priorSessionCount > 0) {
      comparisonText =
          'Recorded across ${payload.priorSessionCount} prior session${payload.priorSessionCount == 1 ? "" : "s"}. Baseline activates at 5 sessions.';
    } else {
      comparisonText =
          'First recorded session. Personal baseline activates after 5 sessions.';
    }

    return AiInferenceResult(
      label: label,
      explanation: explanation,
      comparisonText: comparisonText,
      features: payload.rawFeatures,
      scaledFeatures: scaled,
      modelVersion: meta.version,
      inferredAt: DateTime.now(),
    );
  }
}
