import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Benchmark fastResults best latency loop processing', () {
    final List<MapEntry<String, int>> fastResults = List.generate(
      1000,
      (i) => MapEntry('104.16.1.$i', (i % 300) + 100),
    );

    int bestLatencyOriginal = 9999;
    String bestIPOriginal = "";

    final stopwatchOriginal = Stopwatch()..start();
    for (int run = 0; run < 10000; run++) {
      bestLatencyOriginal = 9999;
      bestIPOriginal = "";
      for (var result in fastResults) {
        if (result.value < bestLatencyOriginal && result.value < 1500) {
          bestLatencyOriginal = result.value;
          bestIPOriginal = result.key;
        }
      }
    }
    stopwatchOriginal.stop();

    int bestLatencyOptimized = 9999;
    String bestIPOptimized = "";

    final stopwatchOptimized = Stopwatch()..start();
    for (int run = 0; run < 10000; run++) {
      bestLatencyOptimized = 9999;
      bestIPOptimized = "";
      for (final result in fastResults) {
        final latency = result.value;
        if (latency < bestLatencyOptimized && latency < 1500) {
          bestLatencyOptimized = latency;
          bestIPOptimized = result.key;
        }
      }
    }
    stopwatchOptimized.stop();

    expect(bestIPOptimized, equals(bestIPOriginal));
    expect(bestLatencyOptimized, equals(bestLatencyOriginal));

    print('Original Loop Time: ${stopwatchOriginal.elapsedMicroseconds} us');
    print('Optimized Loop Time: ${stopwatchOptimized.elapsedMicroseconds} us');
  });
}
