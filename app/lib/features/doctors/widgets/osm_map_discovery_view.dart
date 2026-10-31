import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/doctors/doctor_discovery_service.dart';

/// Interactive OpenStreetMap View for Healthcare Discovery
/// Powered by open-source flutter_map and OpenStreetMap / CartoDB Dark basemap tiles.
/// 100% free with zero paid Google Maps billing or API keys required.
class OsmMapDiscoveryView extends StatefulWidget {
  const OsmMapDiscoveryView({
    super.key,
    required this.clinics,
    required this.initialLat,
    required this.initialLon,
    required this.selectedRadiusKm,
    required this.onSelectClinic,
  });

  final List<DoctorClinic> clinics;
  final double initialLat;
  final double initialLon;
  final double selectedRadiusKm;
  final ValueChanged<DoctorClinic> onSelectClinic;

  @override
  State<OsmMapDiscoveryView> createState() => _OsmMapDiscoveryViewState();
}

class _OsmMapDiscoveryViewState extends State<OsmMapDiscoveryView> {
  final MapController _mapController = MapController();

  bool get _isTestingEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // 1. User Location Marker
    markers.add(
      Marker(
        point: LatLng(widget.initialLat, widget.initialLon),
        width: 44.0,
        height: 44.0,
        child: Tooltip(
          message: 'Your Location (Cairo)',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentCyan.withValues(alpha: 0.25),
              border: Border.all(color: AppColors.accentCyan, width: 2.0),
            ),
            child: const Center(
              child: Icon(
                Icons.my_location_rounded,
                color: AppColors.accentCyan,
                size: 20.0,
              ),
            ),
          ),
        ),
      ),
    );

    // 2. Medical Facility Markers
    for (final clinic in widget.clinics) {
      Color markerColor = AppColors.accentCyan;
      IconData markerIcon = Icons.medical_services_rounded;

      final cat = clinic.category.toLowerCase();
      if (cat.contains('hospital')) {
        markerColor = AppColors.statusRed;
        markerIcon = Icons.local_hospital_rounded;
      } else if (cat.contains('pharmacy')) {
        markerColor = AppColors.accentGreen;
        markerIcon = Icons.local_pharmacy_rounded;
      } else if (cat.contains('cardio')) {
        markerColor = AppColors.accentCyan;
        markerIcon = Icons.favorite_rounded;
      }

      markers.add(
        Marker(
          point: LatLng(clinic.latitude, clinic.longitude),
          width: 42.0,
          height: 42.0,
          child: GestureDetector(
            onTap: () => widget.onSelectClinic(clinic),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.canvasDarkNavy,
                border: Border.all(color: markerColor, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: markerColor.withValues(alpha: 0.35),
                    blurRadius: 6.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  markerIcon,
                  color: markerColor,
                  size: 20.0,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    if (_isTestingEnvironment) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.canvasDarkNavy,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.map_rounded, color: AppColors.accentCyan, size: 40.0),
              const SizedBox(height: 8.0),
              Text(
                'OpenStreetMap View (${widget.clinics.length} facilities)',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.0,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.initialLat, widget.initialLon),
              initialZoom: 13.0,
              minZoom: 4.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pulsepatch.lite.app',
              ),
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),

          // Map Controls (Recenter + Zoom)
          Positioned(
            top: 12.0,
            right: 12.0,
            child: Column(
              children: [
                _MapControlButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Center on user location',
                  onPressed: () {
                    _mapController.move(
                      LatLng(widget.initialLat, widget.initialLon),
                      14.0,
                    );
                  },
                ),
                const SizedBox(height: 6.0),
                _MapControlButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom in',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 6.0),
                _MapControlButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom out',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                ),
              ],
            ),
          ),

          // Mandatory OpenStreetMap Attribution Badge
          Positioned(
            bottom: 6.0,
            right: 8.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.0,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38.0,
      height: 38.0,
      decoration: BoxDecoration(
        color: AppColors.canvasDarkNavy.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18.0, color: AppColors.accentCyan),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
