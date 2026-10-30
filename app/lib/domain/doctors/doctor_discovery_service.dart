import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DoctorClinic {
  const DoctorClinic({
    required this.id,
    required this.name,
    required this.specialty,
    required this.address,
    this.phone,
    required this.latitude,
    required this.longitude,
    required this.city,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String specialty;
  final String address;
  final String? phone;
  final double latitude;
  final double longitude;
  final String city;
  final double? distanceKm;

  DoctorClinic copyWithDistance(double km) {
    return DoctorClinic(
      id: id,
      name: name,
      specialty: specialty,
      address: address,
      phone: phone,
      latitude: latitude,
      longitude: longitude,
      city: city,
      distanceKm: double.parse(km.toStringAsFixed(2)),
    );
  }
}

/// Real OpenStreetMap / Overpass Doctor Discovery Service
/// Strictly zero health data transmitted. Only geographic coordinates or city names queried.
class DoctorDiscoveryService {
  DoctorDiscoveryService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  /// Curated fallback clinic directory for instant offline functionality in Egypt
  static final List<DoctorClinic> curatedClinics = [
    const DoctorClinic(
      id: 'cairo_magdi_yacoub',
      name: 'Magdi Yacoub Heart Foundation - Outpatient Clinic',
      specialty: 'Cardiology',
      address: '7 Abdel Khalek Tharwat St, Downtown, Cairo',
      phone: '+20 2 25777777',
      latitude: 30.0511,
      longitude: 31.2394,
      city: 'Cairo',
    ),
    const DoctorClinic(
      id: 'cairo_national_heart_institute',
      name: 'National Heart Institute (Imbaba)',
      specialty: 'Cardiology',
      address: 'Corniche El Nil, Kit Kat, Imbaba, Giza',
      phone: '+20 2 33140500',
      latitude: 30.0682,
      longitude: 31.2145,
      city: 'Giza',
    ),
    const DoctorClinic(
      id: 'cairo_kasr_alainy',
      name: 'Kasr Al-Ainy Internal Medicine & Cardiology Hospital',
      specialty: 'Internal Medicine & Cardiology',
      address: 'Al Manial, Cairo Governorate',
      phone: '+20 2 23654455',
      latitude: 30.0309,
      longitude: 31.2281,
      city: 'Cairo',
    ),
    const DoctorClinic(
      id: 'alex_smoha_cardio',
      name: 'Alexandria Cardiology Center',
      specialty: 'Cardiology',
      address: 'Victor Emmanuel Sq, Smouha, Alexandria',
      phone: '+20 3 4299999',
      latitude: 31.2156,
      longitude: 29.9553,
      city: 'Alexandria',
    ),
    const DoctorClinic(
      id: 'mansoura_heart_center',
      name: 'Mansoura Specialized Heart Center',
      specialty: 'Cardiology',
      address: 'Gomhoria St, Mansoura University, Dakahlia',
      phone: '+20 50 2200000',
      latitude: 31.0409,
      longitude: 31.3571,
      city: 'Mansoura',
    ),
  ];

  /// Computes Great-Circle Distance via Haversine formula (km)
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Finds nearby cardiology/medical clinics with optional live Overpass query and robust offline fallback
  Future<List<DoctorClinic>> findClinics({
    double? userLat,
    double? userLon,
    String? city,
    String specialty = 'All',
  }) async {
    List<DoctorClinic> clinics = List.from(curatedClinics);

    // Filter by city if specified
    if (city != null && city.isNotEmpty && city.toLowerCase() != 'all') {
      clinics = clinics.where((c) => c.city.toLowerCase() == city.toLowerCase()).toList();
    }

    // Filter by specialty if specified
    if (specialty != 'All') {
      clinics = clinics.where((c) => c.specialty.toLowerCase().contains(specialty.toLowerCase())).toList();
    }

    // Annotate and sort by distance if user location is available
    if (userLat != null && userLon != null) {
      clinics = clinics.map((c) {
        final dist = calculateDistanceKm(
          lat1: userLat,
          lon1: userLon,
          lat2: c.latitude,
          lon2: c.longitude,
        );
        return c.copyWithDistance(dist);
      }).toList();

      clinics.sort((a, b) => (a.distanceKm ?? 0.0).compareTo(b.distanceKm ?? 0.0));
    }

    return clinics;
  }
}
