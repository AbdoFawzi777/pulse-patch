import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../domain/profile/user_profile.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _sbpController;
  late TextEditingController _dbpController;

  String _gender = 'male';
  bool _isLoading = true;
  double _calculatedBmi = 0.0;
  String _bmiCategory = 'Normal weight';
  String _bmiCategoryAr = 'وزن طبيعي';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _sbpController = TextEditingController();
    _dbpController = TextEditingController();

    _loadExistingProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _sbpController.dispose();
    _dbpController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    final repo = ref.read(userProfileRepositoryProvider);
    final profile = await repo.getProfile();
    if (profile != null && mounted) {
      _nameController.text = profile.fullName;
      _ageController.text = profile.age.toString();
      _heightController.text = profile.heightCm.toString();
      _weightController.text = profile.weightKg.toString();
      if (profile.baselineSbp != null) _sbpController.text = profile.baselineSbp!.toString();
      if (profile.baselineDbp != null) _dbpController.text = profile.baselineDbp!.toString();
      _gender = profile.gender;
      _recalculateBmi();
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _recalculateBmi() {
    final height = double.tryParse(_heightController.text.trim()) ?? 0.0;
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final age = int.tryParse(_ageController.text.trim()) ?? 0;

    if (height > 0 && weight > 0) {
      final hMeters = height / 100.0;
      final bmi = weight / (hMeters * hMeters);

      // Determine BMI category based on age.
      // Adult WHO thresholds (BMI 18.5/25/30) are only valid for age ≥ 18.
      // Pediatric BMI-for-age (WHO LMS method) is NOT implemented; show
      // informational message instead of an incorrect adult classification.
      String category;
      String categoryAr;
      if (age > 0 && age < 5) {
        category = 'BMI classification not applicable (under 5)';
        categoryAr = 'تصنيف BMI غير متاح (دون 5 سنوات)';
      } else if (age >= 5 && age < 18) {
        category = 'BMI classification unavailable for under-18';
        categoryAr = 'تصنيف BMI غير متاح لمن هم دون 18 عامًا';
      } else {
        // Adult (age ≥ 18 or age not entered yet — default to adult display)
        final b = double.parse(bmi.toStringAsFixed(1));
        if (b < 18.5) {
          category = 'Underweight';
          categoryAr = 'نقص في الوزن';
        } else if (b < 25.0) {
          category = 'Normal weight';
          categoryAr = 'وزن طبيعي';
        } else if (b < 30.0) {
          category = 'Overweight';
          categoryAr = 'زيادة في الوزن';
        } else {
          category = 'Obesity';
          categoryAr = 'سمنة';
        }
      }

      setState(() {
        _calculatedBmi = double.parse(bmi.toStringAsFixed(1));
        _bmiCategory = category;
        _bmiCategoryAr = categoryAr;
      });
    } else {
      setState(() {
        _calculatedBmi = 0.0;
        _bmiCategory = '--';
        _bmiCategoryAr = '--';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(userProfileRepositoryProvider);
    final now = DateTime.now();

    final profile = UserProfile(
      id: 'user_primary',
      fullName: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      gender: _gender,
      heightCm: double.parse(_heightController.text.trim()),
      weightKg: double.parse(_weightController.text.trim()),
      baselineSbp: double.tryParse(_sbpController.text.trim()),
      baselineDbp: double.tryParse(_dbpController.text.trim()),
      createdAt: now,
      updatedAt: now,
    );

    await repo.saveProfile(profile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Health Profile Saved Successfully'),
          backgroundColor: AppColors.cardBgGradientStart,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return DesignCanvasScaffold(
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          CircleIconButton(
                            type: CircleIconType.back,
                            semanticLabel: 'Back',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Text(
                              isRtl ? 'الملف الصحي والبدني' : 'Health & Biometrics Profile',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 22.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),

                      // BMI Live Preview Card
                      MetricCard(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 56.0,
                              height: 56.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accentCyan.withValues(alpha: 0.15),
                              ),
                              child: const Icon(Icons.speed, color: AppColors.accentCyan, size: 28.0),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isRtl ? 'مؤشر كتلة الجسم (BMI)' : 'Calculated BMI (WHO)',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13.0,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    _calculatedBmi > 0 ? '$_calculatedBmi kg/m²' : '-- kg/m²',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 24.0,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    isRtl ? _bmiCategoryAr : _bmiCategory,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.accentCyan,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // Full Name Field
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit'),
                        decoration: InputDecoration(
                          labelText: isRtl ? 'الاسم الكامل' : 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                      ),
                      const SizedBox(height: 16.0),

                      // Age and Gender Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit'),
                              decoration: InputDecoration(
                                labelText: isRtl ? 'العمر (سنة)' : 'Age (Years)',
                                prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.textMuted),
                              ),
                              onChanged: (_) => _recalculateBmi(),
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                if (n == null || n < 1 || n > 120) return 'Invalid age';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender,
                              isExpanded: true,
                              dropdownColor: AppColors.cardBgNavy,
                              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit'),
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                              ),
                              items: const [
                                DropdownMenuItem(value: 'male', child: Text('Male')),
                                DropdownMenuItem(value: 'female', child: Text('Female')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _gender = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),

                      // Height and Weight Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit'),
                              decoration: InputDecoration(
                                labelText: isRtl ? 'الطول (سم)' : 'Height (cm)',
                                prefixIcon: const Icon(Icons.height, color: AppColors.textMuted),
                              ),
                              onChanged: (_) => _recalculateBmi(),
                              validator: (v) {
                                final h = double.tryParse(v ?? '');
                                if (h == null || h < 40 || h > 250) return 'Invalid height';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit'),
                              decoration: InputDecoration(
                                labelText: isRtl ? 'الوزن (كجم)' : 'Weight (kg)',
                                prefixIcon: const Icon(Icons.line_weight, color: AppColors.textMuted),
                              ),
                              onChanged: (_) => _recalculateBmi(),
                              validator: (v) {
                                final w = double.tryParse(v ?? '');
                                if (w == null || w < 2 || w > 300) return 'Invalid weight';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),

                      // Optional Baseline Cuff Blood Pressure
                      Text(
                        isRtl ? 'قراءات ضغط الدم المرجعية (اختياري - لمعايرة النموذج)' : 'Reference Cuff Blood Pressure (Optional for AI Calibration)',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sbpController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit'),
                              decoration: const InputDecoration(
                                labelText: 'Baseline SBP (mmHg)',
                                prefixIcon: Icon(Icons.favorite_border, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: TextFormField(
                              controller: _dbpController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit'),
                              decoration: const InputDecoration(
                                labelText: 'Baseline DBP (mmHg)',
                                prefixIcon: Icon(Icons.favorite_border, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28.0),

                      // Save Pill Button
                      PillButton(
                        label: isRtl ? 'حفظ البيانات' : 'Save Health Profile',
                        onPressed: _saveProfile,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
