// Crashlytics: uygulamayı kapatmayan Flutter çerçeve hataları ve yakalanmamış
// Dart hataları ölümcül olmayan kayıt olarak gider (çökme sayılmaz).
import 'package:ezan_saati/data/services/error_reporter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kayıt çağrılarının "fatal" değerlerini toplar
class _FakeCrashlytics implements FirebaseCrashlytics {
  final List<bool> fatalFlags = [];

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool? printDetails,
    bool fatal = false,
  }) async => fatalFlags.add(fatal);

  @override
  Future<void> recordFlutterError(
    FlutterErrorDetails flutterErrorDetails, {
    bool fatal = false,
  }) async => fatalFlags.add(fatal);

  @override
  Future<void> recordFlutterFatalError(
    FlutterErrorDetails flutterErrorDetails,
  ) async => fatalFlags.add(true);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('Flutter ve yakalanmamış Dart hataları ölümcül değil', () {
    final flutterHandler = FlutterError.onError;
    final platformHandler = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = flutterHandler;
      PlatformDispatcher.instance.onError = platformHandler;
    });
    final crashlytics = _FakeCrashlytics();
    installCrashlyticsHandlers(crashlytics);

    FlutterError.onError!(FlutterErrorDetails(exception: Exception('çerçeve')));
    final handled = PlatformDispatcher.instance.onError!(
      Exception('dart'),
      StackTrace.current,
    );

    expect(handled, isTrue);
    expect(crashlytics.fatalFlags, [false, false]);
  });
}
