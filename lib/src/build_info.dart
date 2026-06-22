/// Lightweight build/identity constants for the walking skeleton.
///
/// This file intentionally contains **no game logic**. It exists only so the
/// unit-test layer has a deterministic, pure-Dart target to validate, and so
/// the environment-check screen can display a stable health string. Phase 0
/// will remove or replace it.
library;

/// Product name shown in the UI and asserted by tests.
const String kAppName = 'KindredPaws';

/// Identifies this build as the pre-Phase-0 environment-validation skeleton.
const String kBuildChannel = 'walking-skeleton';

/// Human-readable health label rendered on the environment-check screen and
/// asserted by the unit-test layer.
String healthLabel() => '$kAppName environment OK';
