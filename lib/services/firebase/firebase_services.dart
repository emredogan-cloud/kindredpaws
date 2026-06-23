/// Production Firebase adapters (P3-0) — the REAL implementations of the
/// observability + backend + remote-config seams, gated behind
/// `KP_FIREBASE_PROVISIONED`. They are wired only by [registerFirebaseServices]
/// after [initFirebase] succeeds, so the default (CI/test) build keeps the
/// in-memory/mock implementations and never touches the network or native
/// plugins. Activation = `flutterfire configure` + the flag (founder step —
/// see REQUIRED_ENVIRONMENTS.md; cannot be run in the autonomous sandbox).
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../core/service_locator.dart';
import '../analytics_service.dart';
import '../backend_service.dart';
import '../crash_reporter.dart';
import '../logger.dart' show LogRecord;
import '../performance_monitor.dart';
import '../remote_config_service.dart';

/// Initialises the native Firebase app from the platform's gitignored config
/// (`google-services.json` / `GoogleService-Info.plist`, supplied per-build by
/// the founder — NOT committed to this public repo). Argless so we never import
/// committed credentials. Only called when provisioned; never throws to the
/// caller — falls back to mocks on any error (e.g. a build-only placeholder
/// config, or no native config present).
Future<bool> initFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (_) {
    return false; // misconfigured/no platform → caller keeps the mock stack
  }
}

/// Registers the production Firebase adapters over the mock defaults. Call after
/// [initFirebase] returns true.
///
/// Firebase native auto-collection is disabled in `AndroidManifest.xml` so the
/// SDKs stay fully dormant until we're provisioned (otherwise they'd start at
/// process launch, before this gate). Now that we are, re-enable collection.
void registerFirebaseServices(ServiceLocator sl) {
  sl.registerSingleton<BackendService>(FirestoreBackendService());
  sl.registerSingleton<AnalyticsService>(FirebaseAnalyticsAdapter());
  sl.registerSingleton<CrashReporter>(FirebaseCrashReporterAdapter());
  sl.registerSingleton<PerformanceMonitor>(FirebasePerformanceAdapter());
  sl.registerSingleton<RemoteConfigService>(FirebaseRemoteConfigAdapter());
  // Fire-and-forget; enabling collection must never block or throw into boot.
  unawaited(FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true));
  unawaited(FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true));
  unawaited(FirebasePerformance.instance.setPerformanceCollectionEnabled(true));
}

/// Authoritative cloud save (Firestore).
class FirestoreBackendService implements BackendService {
  FirestoreBackendService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  bool get isAuthoritative => true;

  @override
  Future<Map<String, dynamic>?> readDocument(String c, String k) async {
    final snap = await _db.collection(c).doc(k).get();
    return snap.data();
  }

  @override
  Future<void> writeDocument(String c, String k, Map<String, dynamic> v) =>
      _db.collection(c).doc(k).set(v);

  @override
  Future<void> append(String s, Map<String, dynamic> e) =>
      _db.collection(s).add(e).then((_) {});
}

/// Analytics → Firebase Analytics. Privacy-by-design: only num/String/bool
/// params cross (bool→0/1); nulls + PII-shaped values are dropped.
class FirebaseAnalyticsAdapter implements AnalyticsService {
  FirebaseAnalyticsAdapter({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  void log(AnalyticsEvent event, [Map<String, Object?> params = const {}]) {
    final clean = <String, Object>{};
    for (final e in params.entries) {
      if (LogRecord.blockedKeys.contains(e.key)) continue; // never ship PII
      final v = e.value;
      if (v is num) {
        clean[e.key] = v;
      } else if (v is String) {
        clean[e.key] = v;
      } else if (v is bool) {
        clean[e.key] = v ? 1 : 0;
      }
    }
    // Fire-and-forget; analytics must never block or throw into the game.
    _analytics.logEvent(
      name: event.name,
      parameters: clean.isEmpty ? null : clean,
    );
  }
}

/// Crash + non-fatal error reporting → Crashlytics. Never throws.
class FirebaseCrashReporterAdapter implements CrashReporter {
  FirebaseCrashReporterAdapter({FirebaseCrashlytics? crashlytics})
    : _c = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _c;

  @override
  void recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? context,
    Map<String, Object?> keys = const {},
  }) {
    for (final e in keys.entries) {
      final v = e.value;
      if (v != null) _c.setCustomKey(e.key, v);
    }
    _c.recordError(error, stack, reason: context, fatal: fatal);
  }

  @override
  void addBreadcrumb(String message) => _c.log(message);

  @override
  void setCustomKey(String key, Object? value) {
    if (value != null) _c.setCustomKey(key, value);
  }
}

/// Performance traces → Firebase Performance. Records each completed trace's
/// duration + metrics as a (started/stopped) Firebase trace.
class FirebasePerformanceAdapter implements PerformanceMonitor {
  FirebasePerformanceAdapter({FirebasePerformance? performance})
    : _p = performance ?? FirebasePerformance.instance;

  final FirebasePerformance _p;

  @override
  PerfTrace startTrace(String name) => PerfTrace(name)..start();

  @override
  void completeTrace(PerfTrace trace) {
    final t = _p.newTrace(trace.name);
    t.start();
    if (trace.durationMs != null) t.setMetric('ms', trace.durationMs!);
    trace.metrics.forEach(t.setMetric);
    t.stop();
  }

  @override
  void recordMetric(String name, int value) {
    final t = _p.newTrace(name);
    t.start();
    t.setMetric('value', value);
    t.stop();
  }
}

/// Remote Config → Firebase Remote Config, seeded with the canonical launch
/// defaults so the app behaves correctly before the first fetch.
class FirebaseRemoteConfigAdapter implements RemoteConfigService {
  FirebaseRemoteConfigAdapter({FirebaseRemoteConfig? rc})
    : _rc = rc ?? FirebaseRemoteConfig.instance,
      _fallback = const DefaultRemoteConfig();

  final FirebaseRemoteConfig _rc;
  final DefaultRemoteConfig _fallback;

  /// Seeds in-app defaults + fetches/activates. Best-effort.
  Future<void> initialise() async {
    try {
      await _rc.setDefaults(DefaultRemoteConfig.defaults);
      await _rc.fetchAndActivate();
    } catch (_) {
      // Keep the in-app defaults; live values arrive on the next fetch.
    }
  }

  bool _has(String key) => _rc.getAll().containsKey(key);

  @override
  double getDouble(String key) =>
      _has(key) ? _rc.getDouble(key) : _fallback.getDouble(key);

  @override
  int getInt(String key) => _has(key) ? _rc.getInt(key) : _fallback.getInt(key);

  @override
  bool getBool(String key) =>
      _has(key) ? _rc.getBool(key) : _fallback.getBool(key);
}
