import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/doctors/doctor_discovery_service.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/design_canvas_scaffold.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/pill_button.dart';
import 'widgets/osm_map_discovery_view.dart';

class DoctorDiscoveryScreen extends StatefulWidget {
  const DoctorDiscoveryScreen({super.key});

  @override
  State<DoctorDiscoveryScreen> createState() => _DoctorDiscoveryScreenState();
}

class _DoctorDiscoveryScreenState extends State<DoctorDiscoveryScreen> {
  final _service = const DoctorDiscoveryService();

  String _selectedCity = 'All';
  String _selectedSpecialty = 'All';
  String _selectedCategory = 'All';
  double? _selectedRadiusKm = 10.0;
  bool _isMapView = false;
  List<DoctorClinic> _clinics = [];
  bool _isLoading = true;

  final double _userLat = 30.0511;
  final double _userLon = 31.2394;

  final List<String> _cities = ['All', 'Cairo', 'Giza', 'Alexandria', 'Mansoura', 'Aswan'];
  final List<String> _specialties = ['All', 'Cardiology', 'Internal Medicine', 'Emergency'];
  final List<String> _categories = ['All', 'Cardiology', 'Hospital', 'Pharmacy'];
  final List<double?> _radiusOptions = [1.0, 3.0, 5.0, 10.0, null];

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    setState(() => _isLoading = true);
    final results = await _service.findClinics(
      userLat: _userLat,
      userLon: _userLon,
      city: _selectedCity,
      specialty: _selectedSpecialty,
      category: _selectedCategory,
      maxRadiusKm: _selectedRadiusKm,
    );
    if (mounted) {
      setState(() {
        _clinics = results;
        _isLoading = false;
      });
    }
  }

  Widget _buildSourceBadge(HealthcareSourceType type, bool isRtl) {
    Color bg;
    Color fg;
    String label;

    switch (type) {
      case HealthcareSourceType.verifiedMedical:
        bg = AppColors.accentGreen.withValues(alpha: 0.15);
        fg = AppColors.accentGreen;
        label = isRtl ? 'مؤسسة طبية معتمدة' : 'Verified Medical Institution';
        break;
      case HealthcareSourceType.livePlaces:
        bg = AppColors.accentCyan.withValues(alpha: 0.15);
        fg = AppColors.accentCyan;
        label = isRtl ? 'Google Places • معتمد' : 'Google Places (New) • Live';
        break;
      case HealthcareSourceType.openStreetMap:
        bg = AppColors.accentCyan.withValues(alpha: 0.15);
        fg = AppColors.accentCyan;
        label = isRtl ? 'بيانات مجتمعية • OpenStreetMap' : 'OpenStreetMap (Community)';
        break;
      case HealthcareSourceType.curatedDirectory:
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.lightBlueAccent;
        label = isRtl ? 'دليل صحي منتقى' : 'Curated Directory';
        break;
      case HealthcareSourceType.testFixture:
        bg = AppColors.statusAmber.withValues(alpha: 0.15);
        fg = AppColors.statusAmber;
        label = isRtl ? 'بيانات اختبار' : 'Test Fixture';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type == HealthcareSourceType.livePlaces ? Icons.public : Icons.verified_user_outlined,
            size: 12.0,
            color: fg,
          ),
          const SizedBox(width: 4.0),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  void _showClinicDetails(DoctorClinic clinic) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      clinic.name,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.statusAmber, size: 14.0),
                        const SizedBox(width: 4.0),
                        Text(
                          clinic.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(
                    clinic.category.toLowerCase().contains('hospital')
                        ? Icons.local_hospital_rounded
                        : Icons.favorite_rounded,
                    color: AppColors.accentCyan,
                    size: 16.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    '${clinic.specialty} • ${clinic.distanceKm ?? 0.0} km away',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.0,
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (clinic.open24x7) ...[
                    const SizedBox(width: 8.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        isRtl ? 'طوارئ 24/7' : '24/7 Open',
                        style: const TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8.0),
              _buildSourceBadge(clinic.sourceType, isRtl),
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
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, color: AppColors.accentBlue, size: 18.0),
                    const SizedBox(width: 8.0),
                    Text(
                      clinic.phone!,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16.0),
              // Action Buttons: Get Directions & Call
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: isRtl ? 'الاتجاهات بالخريطة' : 'Get Directions',
                      style: PillButtonStyle.white,
                      height: 42.0,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isRtl
                                  ? 'جارِ فتح الملاحة إلى ${clinic.name}'
                                  : 'Opening GPS directions to ${clinic.name}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  if (clinic.phone != null)
                    Expanded(
                      child: PillButton(
                        label: isRtl ? 'اتصال بالعيادة' : 'Call Clinic',
                        style: PillButtonStyle.dark,
                        height: 42.0,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isRtl
                                    ? 'جارِ الاتصال بـ ${clinic.phone}'
                                    : 'Dialing ${clinic.phone}...',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: AppColors.bgBase,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: AppColors.textMuted, size: 16.0),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Healthcare discovery operates with zero patient health telemetry sharing.',
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
            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                children: [
                  CircleIconButton(
                    type: CircleIconType.back,
                    semanticLabel: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      isRtl ? 'دليل الأطباء والمستشفيات' : 'Doctor & Clinic Discovery',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Map / List Toggle
                  IconButton(
                    icon: Icon(
                      _isMapView ? Icons.view_list_rounded : Icons.map_rounded,
                      color: AppColors.accentCyan,
                    ),
                    tooltip: _isMapView ? 'List View' : 'Map View',
                    onPressed: () => setState(() => _isMapView = !_isMapView),
                  ),
                ],
              ),
            ),

            // Category & Radius Filter Chips Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  // Category chips
                  ..._categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(cat),
                        labelStyle: TextStyle(
                          fontSize: 12.0,
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: AppColors.cardBgNavy,
                        selectedColor: AppColors.accentCyan.withValues(alpha: 0.3),
                        checkmarkColor: AppColors.accentCyan,
                        onSelected: (val) {
                          setState(() => _selectedCategory = cat);
                          _loadClinics();
                        },
                      ),
                    );
                  }),
                  const SizedBox(width: 8.0),
                  // Radius chips
                  ..._radiusOptions.map((rad) {
                    final isSelected = _selectedRadiusKm == rad;
                    final label = rad == null ? 'All' : '${rad.toInt()} km';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(label),
                        labelStyle: TextStyle(
                          fontSize: 11.0,
                          color: isSelected ? AppColors.accentCyan : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: AppColors.canvasDarkNavy,
                        selectedColor: AppColors.accentCyan.withValues(alpha: 0.2),
                        onSelected: (val) {
                          setState(() => _selectedRadiusKm = rad);
                          _loadClinics();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10.0),

            // City and Specialty Dropdowns
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  // City Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCity,
                      isExpanded: true,
                      dropdownColor: AppColors.cardBgNavy,
                      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit', fontSize: 12.0),
                      decoration: const InputDecoration(
                        labelText: 'City',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
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
                  const SizedBox(width: 10.0),
                  // Specialty Dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSpecialty,
                      isExpanded: true,
                      dropdownColor: AppColors.cardBgNavy,
                      style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit', fontSize: 12.0),
                      decoration: const InputDecoration(
                        labelText: 'Specialty',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
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
            const SizedBox(height: 12.0),
            if (_clinics.any((c) => c.sourceType == HealthcareSourceType.livePlaces))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.public, size: 12, color: AppColors.accentCyan),
                    const SizedBox(width: 6),
                    Text(
                      isRtl ? 'النتائج مزودة بواسطة OpenStreetMap ودليل المراكز المعتمدة' : 'Results powered by OpenStreetMap & Curated Directory',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

            // Content: Map View or List View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isMapView
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                          child: OsmMapDiscoveryView(
                            clinics: _clinics,
                            initialLat: _userLat,
                            initialLon: _userLon,
                            selectedRadiusKm: _selectedRadiusKm ?? 10.0,
                            onSelectClinic: _showClinicDetails,
                          ),
                        )
                      : _clinics.isEmpty
                          ? Center(
                              child: Text(
                                isRtl ? 'لم يتم العثور على مراكز مطابقة' : 'No clinics found matching criteria',
                                style: const TextStyle(fontFamily: 'Outfit', color: AppColors.textMuted),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                              itemCount: _clinics.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10.0),
                              itemBuilder: (context, index) {
                                final clinic = _clinics[index];
                                return GestureDetector(
                                  onTap: () => _showClinicDetails(clinic),
                                  child: MetricCard(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44.0,
                                          height: 44.0,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: clinic.category.toLowerCase().contains('hospital')
                                                ? AppColors.statusRed.withValues(alpha: 0.15)
                                                : AppColors.accentCyan.withValues(alpha: 0.15),
                                          ),
                                          child: Icon(
                                            clinic.category.toLowerCase().contains('hospital')
                                                ? Icons.local_hospital_rounded
                                                : Icons.favorite_rounded,
                                            color: clinic.category.toLowerCase().contains('hospital')
                                                ? AppColors.statusRed
                                                : AppColors.accentCyan,
                                            size: 22.0,
                                          ),
                                        ),
                                        const SizedBox(width: 12.0),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                clinic.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2.0),
                                              Text(
                                                '${clinic.specialty} • ${clinic.city}',
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 12.0,
                                                  color: AppColors.accentCyan,
                                                ),
                                              ),
                                              const SizedBox(height: 2.0),
                                              Text(
                                                clinic.address,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 11.0,
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
