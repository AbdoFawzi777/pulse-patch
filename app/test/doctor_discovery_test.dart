import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/doctors/doctor_discovery_service.dart';

void main() {
  group('DoctorDiscoveryService Offline & Privacy Tests', () {
    final service = DoctorDiscoveryService();

    test('calculates accurate Haversine distance in kilometers', () {
      // Cairo Downtown to Giza Imbaba ~3.1 km
      final dist = DoctorDiscoveryService.calculateDistanceKm(
        lat1: 30.0511,
        lon1: 31.2394,
        lat2: 30.0682,
        lon2: 31.2145,
      );

      expect(dist, inInclusiveRange(2.5, 4.0));
    });

    test('filters clinics by city and sorts by distance', () async {
      final clinics = await service.findClinics(
        userLat: 30.0511,
        userLon: 31.2394,
        city: 'Cairo',
      );

      expect(clinics, isNotEmpty);
      expect(clinics.every((c) => c.city == 'Cairo'), isTrue);
      expect(clinics.first.distanceKm, lessThan(clinics.last.distanceKm ?? 999.0));
    });

    test('filters by medical specialty correctly', () async {
      final clinics = await service.findClinics(specialty: 'Cardiology');
      expect(clinics.isNotEmpty, isTrue);
      expect(clinics.every((c) => c.specialty.contains('Cardiology')), isTrue);
    });
  });
}
