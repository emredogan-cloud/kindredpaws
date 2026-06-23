import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/wallet.dart';

void main() {
  group('Wallet', () {
    test('addKibble increases the balance', () {
      expect(const Wallet(kibble: 10).addKibble(5).kibble, 15);
    });

    test('spendKibble succeeds when affordable', () {
      final w = const Wallet(kibble: 100).spendKibble(30);
      expect(w, isNotNull);
      expect(w!.kibble, 70);
    });

    test('spendKibble returns null when the balance is insufficient', () {
      expect(const Wallet(kibble: 50).spendKibble(100), isNull);
    });

    test('spendKibble at exactly the balance succeeds to zero', () {
      expect(const Wallet(kibble: 100).spendKibble(100)!.kibble, 0);
    });

    test('copyWith updates only the named field', () {
      const w = Wallet(kibble: 1, heartstones: 2, compassionCoins: 3);
      final w2 = w.copyWith(heartstones: 9);
      expect(w2.kibble, 1);
      expect(w2.heartstones, 9);
      expect(w2.compassionCoins, 3);
    });

    test('toMap/fromMap round-trips losslessly', () {
      const w = Wallet(kibble: 12, heartstones: 3, compassionCoins: 7);
      expect(Wallet.fromMap(w.toMap()), w);
    });

    test('value equality', () {
      expect(const Wallet(kibble: 5), const Wallet(kibble: 5));
      expect(const Wallet(kibble: 5), isNot(const Wallet(kibble: 6)));
    });
  });
}
