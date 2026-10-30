import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/doctors/doctor_discovery_service.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';

class DoctorDiscoveryScreen extends StatefulWidget {
  const DoctorDiscoveryScreen({super.key});

  @override
  State<DoctorDiscoveryScreen> createState() => _DoctorDiscoveryScreenState();
}

class _DoctorDiscoveryScreenState extends State<DoctorDiscoveryScreen> {
  final _service = const DoctorDiscoveryService();

  String _selectedCity = 'All';
  String _selectedSpecialty = 'All';
  List<DoctorClinic> _clinics = [];
  bool _isLoading = true;

  final List<String> _cities = ['All', 'Cairo', 'Giza', 'Alexandria', 'Mansoura'];
  final List<String> _specialties = ['All', 'Cardiology', 'Internal Medicine'];

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    setState(() => _isLoading = true);
    final results = await _service.findClinics(
      userLat: 30.0511,
      userLon: 31.2394,
      city: _selectedCity,
      specialty: _selectedSpecialty,
    );
    if (mounted) {
      setState(() {
        _clinics = results;
        _isLoading = false;
      });
    }
  }

  void _showClinicDetails(DoctorClinic clinic) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBgNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clinic.name,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  const Icon(Icons.local_hospital_outlined, color: AppColors.accentCyan, size: 18.0),
                  const SizedBox(width: 8.0),
                  Text(
                    clinic.specialty,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.0,
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 18.0),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      clinic.address,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.0,
                        color: AppColors.textSubtitle,
                      ),
                    ),
                  ),
                ],
              ),
              if (clinic.phone != null) ...[
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, color: AppColors.accentBlue, size: 18.0),
                    const SizedBox(width: 8.0),
                    Text(
                      clinic.phone!,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.bgBase,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: AppColors.textMuted, size: 18.0),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Offline Curated Healthcare Directory. Zero patient health data shared.',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 11.0, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return DesignCanvasScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  CircleIconButton(
                    type: CircleIconType.back,
                    semanticLabel: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      isRtl ? 'دليل الأطباء والمستشفيات' : 'Doctor & Clinic Discovery',
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
            ),

            // City and Specialty Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  // City Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCity,
                      isExpanded: true,
                      dropdownColor: AppColors.cardBgNavy,
                      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit', fontSize: 13.0),
                      decoration: const InputDecoration(
                        labelText: 'City',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                      ),
                      items: _cities
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCity = val);
                          _loadClinics();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  // Specialty Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSpecialty,
                      isExpanded: true,
                      dropdownColor: AppColors.cardBgNavy,
                      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit', fontSize: 13.0),
                      decoration: const InputDecoration(
                        labelText: 'Specialty',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                      ),
                      items: _specialties
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSpecialty = val);
                          _loadClinics();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Clinic List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _clinics.isEmpty
                      ? Center(
                          child: Text(
                            isRtl ? 'لم يتم العثور على مراكز مطابقة' : 'No clinics found matching criteria',
                            style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          itemCount: _clinics.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12.0),
                          itemBuilder: (context, index) {
                            final clinic = _clinics[index];
                            return GestureDetector(
                              onTap: () => _showClinicDetails(clinic),
                              child: MetricCard(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48.0,
                                      height: 48.0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.accentBlue.withValues(alpha: 0.15),
                                      ),
                                      child: const Icon(Icons.local_hospital, color: AppColors.accentBlue, size: 24.0),
                                    ),
                                    const SizedBox(width: 14.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            clinic.name,
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 15.0,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            '${clinic.specialty} • ${clinic.city}',
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 12.0,
                                              color: AppColors.accentCyan,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            clinic.address,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 12.0,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (clinic.distanceKm != null)
                                      Text(
                                        '${clinic.distanceKm} km',
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSubtitle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
