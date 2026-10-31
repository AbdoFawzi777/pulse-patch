import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app/domain/doctors/doctor_discovery_service.dart';

void main() {
  group('DoctorDiscoveryService Offline, Provenance & Privacy Tests', () {
    const service = DoctorDiscoveryService();

    setUp(() {
      DoctorDiscoveryService.clearPlacesCache();
    });

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

    test('classifies preloaded authoritative institutions as verifiedMedical', () {
      for (final clinic in DoctorDiscoveryService.curatedClinics) {
        expect(clinic.sourceType, equals(HealthcareSourceType.verifiedMedical));
      }
    });

    test('Google Places (New) results are marked with livePlaces provenance', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('places:searchNearby'));
        expect(request.headers['X-Goog-Api-Key'], equals('test-maps-key'));

        return http.Response(
          json.encode({
            'places': [
              {
                'id': 'places_live_123',
                'displayName': {'text': 'Nile Specialized Cardiac Hospital'},
                'formattedAddress': 'Corniche El Maadi, Cairo',
                'location': {'latitude': 29.965, 'longitude': 31.250},
                'rating': 4.9,
                'nationalPhoneNumber': '+20 2 25000000',
              }
            ]
          }),
          200,
        );
      });

      final placesService = DoctorDiscoveryService(
        placesApiKey: 'test-maps-key',
        httpClient: mockClient,
      );

      final results = await placesService.findClinics(
        userLat: 30.0511,
        userLon: 31.2394,
      );

      expect(results.length, equals(1));
      expect(results.first.name, equals('Nile Specialized Cardiac Hospital'));
      expect(results.first.sourceType, equals(HealthcareSourceType.livePlaces));
      expect(DoctorDiscoveryService.cachedPlacesCount, equals(1));
    });

    test('enforces Google Maps 30-day retention limit by purging expired entries', () {
      // Simulate cached entries with different timestamps
      final freshEntry = CachedPlacesEntry(
        fetchedAt: DateTime.now().subtract(const Duration(days: 5)),
        places: const [],
      );
      final expiredEntry = CachedPlacesEntry(
        fetchedAt: DateTime.now().subtract(const Duration(days: 35)),
        places: const [],
      );

      expect(freshEntry.isExpired, isFalse);
      expect(expiredEntry.isExpired, isTrue);

      final freshCoord = CachedPlaceCoordinate(
        placeId: 'place_123',
        latitude: 30.05,
        longitude: 31.23,
        cachedAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      final expiredCoord = CachedPlaceCoordinate(
        placeId: 'place_old',
        latitude: 30.05,
        longitude: 31.23,
        cachedAt: DateTime.now().subtract(const Duration(days: 31)),
      );
      expect(freshCoord.isExpired, isFalse);
      expect(expiredCoord.isExpired, isTrue);
    });

    test('OpenStreetMap Overpass results are parsed and marked with openStreetMap provenance', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('interpreter'));
        return http.Response(
          json.encode({
            'elements': [
              {
                'type': 'node',
                'id': 366500797,
                'lat': 30.064775,
                'lon': 31.2098013,
                'tags': {
                  'name': 'National Heart Institute',
                  'name:en': 'National Heart Institute',
                  'amenity': 'hospital',
                  'addr:street': 'Kit Kat, Imbaba'
                }
              }
            ]
          }),
          200,
        );
      });

      final osmService = DoctorDiscoveryService(
        httpClient: mockClient,
      );

      final results = await osmService.findClinics(
        userLat: 30.0511,
        userLon: 31.2394,
        city: 'Cairo',
      );

      expect(results.any((c) => c.sourceType == HealthcareSourceType.openStreetMap), isTrue);
      final osmClinic = results.firstWhere((c) => c.sourceType == HealthcareSourceType.openStreetMap);
      expect(osmClinic.name, equals('National Heart Institute'));
      expect(osmClinic.category, equals('Hospital'));
    });
  });
}
