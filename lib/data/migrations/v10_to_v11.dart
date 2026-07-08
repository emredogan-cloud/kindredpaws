import '../migration.dart';

/// v10 → v11: the care-Kibble faucet cap (KP-014, pre-release remediation).
/// The daily ledger gains `careKibbleToday` so the bounded care-action
/// faucet survives restarts (and a downgrade can't silently refill it — the
/// version bump makes an older app refuse the save into the KP-010 "update
/// the app" recovery instead of dropping the counter). Existing pets upgrade
/// with a zero tally — today's faucet simply starts fresh; the upgrade never
/// orphans a pet (Risk R4). Idempotent (KP-022 discipline).
class V10ToV11 extends Migration {
  const V10ToV11();

  @override
  int get fromVersion => 10;
  @override
  int get toVersion => 11;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);
    final ledger = Map<String, dynamic>.from(
      (next['bondLedger'] as Map?) ?? const {'dayEpoch': null},
    );
    ledger.putIfAbsent('earnedToday', () => 0);
    ledger.putIfAbsent('careKibbleToday', () => 0);
    next['bondLedger'] = ledger;
    return next;
  }
}
