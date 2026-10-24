import 'dart:convert';

/// Metadata specification for the PulsePatch AI Insights model.
class AiModelMetadata {
  const AiModelMetadata({
    required this.modelName,
    required this.engine,
    required this.version,
    required this.trainingDate,
    required this.features,
    required this.scalerMean,
    required this.scalerScale,
    required this.labels,
    required this.architecture,
    this.weights,
    required this.nonDiagnosticDisclaimer,
    required this.trainingCohort,
  });

  final String modelName;
  final String engine;
  final String version;
  final String trainingDate;
  final List<String> features;
  final List<double> scalerMean;
  final List<double> scalerScale;
  final List<String> labels;
  final String architecture;
  final Map<String, dynamic>? weights;
  final String nonDiagnosticDisclaimer;
  final String trainingCohort;

  factory AiModelMetadata.fromJson(Map<String, dynamic> json) {
    final scaler = json['scaler'] as Map<String, dynamic>? ?? {};
    final meanList = (scaler['mean'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toDouble())
        .toList();
    final scaleList = (scaler['scale'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toDouble())
        .toList();
    final featureList = (json['features'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final labelList = (json['labels'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return AiModelMetadata(
      modelName: json['model_name'] as String? ?? 'PulsePatch AI Insights',
      engine: json['engine'] as String? ?? 'TensorFlow Lite',
      version: json['version'] as String? ?? '1.0.0',
      trainingDate: json['training_date'] as String? ?? '2026-10-24',
      features: featureList.isNotEmpty
          ? featureList
          : ['mean_hr', 'std_hr', 'start_hr', 'end_hr', 'recovery_drop'],
      scalerMean: meanList.isNotEmpty
          ? meanList
          : [72.5, 4.2, 75.0, 71.0, -4.0],
      scalerScale: scaleList.isNotEmpty
          ? scaleList
          : [12.0, 2.5, 12.0, 11.5, 6.0],
      labels: labelList.isNotEmpty
          ? labelList
          : ['Typical pattern', 'Different pattern'],
      architecture:
          json['architecture'] as String? ?? 'MLP (5 -> 16 -> 8 -> 2)',
      weights: json['weights'] as Map<String, dynamic>?,
      nonDiagnosticDisclaimer:
          json['non_diagnostic_disclaimer'] as String? ??
          'PulsePatch Lite is an educational prototype and does not provide medical diagnosis or health evaluations.',
      trainingCohort:
          json['training_cohort'] as String? ??
          'Educational prototype resting and recovery volunteer protocol',
    );
  }

  factory AiModelMetadata.fromJsonString(String source) {
    return AiModelMetadata.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
    'model_name': modelName,
    'engine': engine,
    'version': version,
    'training_date': trainingDate,
    'features': features,
    'scaler': {'mean': scalerMean, 'scale': scalerScale},
    'labels': labels,
    'architecture': architecture,
    if (weights != null) 'weights': weights,
    'non_diagnostic_disclaimer': nonDiagnosticDisclaimer,
    'training_cohort': trainingCohort,
  };
}
