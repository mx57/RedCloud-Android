import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redcloud_android/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('Benchmark: SharedPreferences.getInstance() vs cached AppPreferences.instance', () async {
    const iterations = 50000;

    // Warm up and initialize
    final initialPrefs = await SharedPreferences.getInstance();
    await AppPreferences.init(initialPrefs);

    // 1. Measure baseline: repeated await SharedPreferences.getInstance()
    final stopwatchBaseline = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      final prefs = await SharedPreferences.getInstance();
      prefs.getBool('saved_dark_mode');
    }
    stopwatchBaseline.stop();
    final baselineMs = stopwatchBaseline.elapsedMicroseconds / 1000.0;

    // 2. Measure optimized: cached AppPreferences.instance
    final stopwatchOptimized = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      final prefs = AppPreferences.instance;
      prefs.getBool('saved_dark_mode');
    }
    stopwatchOptimized.stop();
    final optimizedMs = stopwatchOptimized.elapsedMicroseconds / 1000.0;

    final speedup = baselineMs > 0 ? (baselineMs / optimizedMs) : 0;

    print('\n=================================================================');
    print('=== SharedPreferences Access Benchmark ($iterations iterations) ===');
    print('Baseline (await SharedPreferences.getInstance()): ${baselineMs.toStringAsFixed(2)} ms');
    print('Optimized (AppPreferences.instance):            ${optimizedMs.toStringAsFixed(2)} ms');
    print('Speedup:                                         ${speedup.toStringAsFixed(2)}x faster');
    print('=================================================================\n');

    expect(AppPreferences.isInitialized, isTrue);
  });
}
