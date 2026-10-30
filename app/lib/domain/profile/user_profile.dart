class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    this.baselineSbp,
    this.baselineDbp,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fullName;
  final int age;
  final String gender; // 'male' or 'female'
  final double heightCm;
  final double weightKg;
  final double? baselineSbp;
  final double? baselineDbp;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Body Mass Index (BMI) = weight (kg) / (height (m))^2
  double get bmi {
    if (heightCm <= 0) return 0.0;
    final heightMeters = heightCm / 100.0;
    final val = weightKg / (heightMeters * heightMeters);
    return double.parse(val.toStringAsFixed(1));
  }

  /// Clinical WHO Adult BMI Category
  String get bmiCategory {
    final b = bmi;
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal weight';
    if (b < 30.0) return 'Overweight';
    return 'Obesity';
  }

  /// Arabic translation of BMI category
  String get bmiCategoryArabic {
    final b = bmi;
    if (b < 18.5) return 'نقص في الوزن';
    if (b < 25.0) return 'وزن طبيعي';
    if (b < 30.0) return 'زيادة في الوزن';
    return 'سمنة';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'full_name': fullName,
    'age': age,
    'gender': gender,
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'baseline_sbp': baselineSbp,
    'baseline_dbp': baselineDbp,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      age: map['age'] as int,
      gender: map['gender'] as String,
      heightCm: (map['height_cm'] as num).toDouble(),
      weightKg: (map['weight_kg'] as num).toDouble(),
      baselineSbp: map['baseline_sbp'] != null ? (map['baseline_sbp'] as num).toDouble() : null,
      baselineDbp: map['baseline_dbp'] != null ? (map['baseline_dbp'] as num).toDouble() : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
