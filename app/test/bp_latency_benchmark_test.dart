import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/ai/bp_inference_service.dart';

void main() {
  test('Micro-benchmark BP Inference Latency Distribution', () {
    final service = BpInferenceService.defaultModel();

    // 1. Warm-up runs (100 iterations)
    for (int i = 0; i < 100; i++) {
      service.estimate(
        age: 50,
        gender: 1,
        bmi: 25.0,
        hrBpm: 70,
        crestTimeMs: 150,
        decayTimeMs: 700,
        pw50Ms: 240,
        areaRatio: 0.28,
        reflectionIndex: 0.75,
        stiffnessIndex: 10.0,
      );
    }

    // 2. Timed benchmark runs (10,000 iterations)
    const iterations = 10000;
    final latenciesMicros = <int>[];
    final totalSw = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      service.estimate(
        age: 50,
        gender: 1,
        bmi: 25.0,
        hrBpm: 70,
        crestTimeMs: 150,
        decayTimeMs: 700,
        pw50Ms: 240,
        areaRatio: 0.28,
        reflectionIndex: 0.75,
        stiffnessIndex: 10.0,
      );
      sw.stop();
      latenciesMicros.add(sw.elapsedMicroseconds);
    }
    totalSw.stop();

    latenciesMicros.sort();
    final p50 = latenciesMicros[(iterations * 0.50).toInt()];
    final p95 = latenciesMicros[(iterations * 0.95).toInt()];
    final p99 = latenciesMicros[(iterations * 0.99).toInt()];
    final avgMicros = totalSw.elapsedMicroseconds / iterations;

    // ignore: avoid_print
    print('=== LATENCY BENCHMARK RESULTS (Pure Dart on Host) ===');
    // ignore: avoid_print
    print('Iterations: $iterations');
    // ignore: avoid_print
    print('Mean Latency: ${(avgMicros / 1000.0).toStringAsFixed(4)} ms (${avgMicros.toStringAsFixed(2)} µs)');
    // ignore: avoid_print
    print('P50 Latency:  ${(p50 / 1000.0).toStringAsFixed(4)} ms ($p50 µs)');
    // ignore: avoid_print
    print('P95 Latency:  ${(p95 / 1000.0).toStringAsFixed(4)} ms ($p95 µs)');
    // ignore: avoid_print
    print('P99 Latency:  ${(p99 / 1000.0).toStringAsFixed(4)} ms ($p99 µs)');

    expect(avgMicros, lessThan(150.0), reason: 'Average latency must be under 0.15 ms (150 µs)');
  });
}
