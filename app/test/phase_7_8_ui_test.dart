import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/data/drift/app_database.dart';
import 'package:app/data/repositories/session_repository.dart';
import 'package:app/features/profile/user_profile_screen.dart';
import 'package:app/features/bp/bp_monitoring_screen.dart';
import 'package:app/features/doctors/doctor_discovery_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() {
    db.close();
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Phase 7 & 8 User Interface Integration Tests', () {
    testWidgets('UserProfileScreen renders all demographic fields and calculates BMI', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const UserProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Health & Biometrics Profile'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Age (Years)'), findsOneWidget);
      expect(find.text('Height (cm)'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);

      // Enter height and weight to trigger BMI recalculation
      await tester.enterText(find.widgetWithText(TextFormField, 'Height (cm)'), '180');
      await tester.enterText(find.widgetWithText(TextFormField, 'Weight (kg)'), '75');
      await tester.pump();

      expect(find.text('23.1 kg/m²'), findsOneWidget);
      expect(find.text('Normal weight'), findsOneWidget);
    });

    testWidgets('BMI age gate: age < 18 shows unavailable category not adult classification', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const UserProfileScreen()));
      await tester.pumpAndSettle();

      // Enter height, weight, and an under-18 age
      await tester.enterText(find.widgetWithText(TextFormField, 'Height (cm)'), '165');
      await tester.enterText(find.widgetWithText(TextFormField, 'Weight (kg)'), '55');
      await tester.enterText(find.widgetWithText(TextFormField, 'Age (Years)'), '15');
      await tester.pump();

      // Numeric BMI is shown but adult categories must NOT be applied
      expect(find.text('20.2 kg/m²'), findsOneWidget);
      expect(find.textContaining('under-18'), findsOneWidget);
      // Adult categories must NOT appear
      expect(find.text('Normal weight'), findsNothing);
      expect(find.text('Overweight'), findsNothing);
    });

    testWidgets('BMI age gate: age < 5 shows not applicable message', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const UserProfileScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Height (cm)'), '110');
      await tester.enterText(find.widgetWithText(TextFormField, 'Weight (kg)'), '19');
      await tester.enterText(find.widgetWithText(TextFormField, 'Age (Years)'), '4');
      await tester.pump();

      expect(find.textContaining('under 5'), findsOneWidget);
      expect(find.text('Underweight'), findsNothing);
      expect(find.text('Normal weight'), findsNothing);
    });

    testWidgets('BMI age gate: age 18+ applies adult WHO categories correctly', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const UserProfileScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Height (cm)'), '170');
      await tester.enterText(find.widgetWithText(TextFormField, 'Weight (kg)'), '100');
      await tester.enterText(find.widgetWithText(TextFormField, 'Age (Years)'), '18');
      await tester.pump();

      // BMI = 100/(1.7*1.7) = 34.6 → Obesity
      expect(find.text('Obesity'), findsOneWidget);
      expect(find.textContaining('under-18'), findsNothing);
    });

    testWidgets('BpMonitoringScreen renders medical notice and handles estimation trigger', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const BpMonitoringScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Blood Pressure Monitoring'), findsOneWidget);
      expect(find.textContaining('Experimental research model'), findsOneWidget);
      expect(find.text('Estimate Blood Pressure Now'), findsOneWidget);
      expect(find.text('Cuff Reference Calibration'), findsOneWidget);

      // Tap estimation
      await tester.tap(find.text('Estimate Blood Pressure Now'));
      await tester.pumpAndSettle();

      expect(find.textContaining('/'), findsWidgets);
    });

    testWidgets('DoctorDiscoveryScreen renders Egyptian clinic directory and filter dropdowns', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const DoctorDiscoveryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Doctor & Clinic Discovery'), findsOneWidget);
      expect(find.text('Magdi Yacoub Heart Foundation - Outpatient Clinic'), findsOneWidget);
      expect(find.text('National Heart Institute (Imbaba)'), findsOneWidget);
      expect(find.textContaining('Zero patient health data shared'), findsNothing); // before bottomsheet
    });
  });
}
