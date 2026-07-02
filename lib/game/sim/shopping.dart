/// The Grocery Store / boutique purchase engine — a pure, deterministic
/// function over the wallet + inventory. **Kibble only** (soft currency):
/// no real-money path exists here by construction, premium cosmetics are
/// entitlement-granted (never sold for cash in a room), and nothing sold
/// grants Bond or growth (no pay-to-win).
library;

import '../model/inventory.dart';
import '../model/items.dart';
import '../model/pet_state.dart';

/// Why a purchase didn't happen (all handled warmly in the UI — never an
/// error state, never pressure to buy).
enum PurchaseBlock {
  /// Not enough Kibble — "a few more care moments and it's yours!".
  kibble,

  /// Toys/cosmetics are forever — already owned, nothing to re-buy.
  alreadyOwned,

  /// Premium cosmetics are Forever Friends keepsakes, not Kibble goods.
  notSoldHere,
}

class PurchaseOutcome {
  const PurchaseOutcome._(this.state, this.inventory, this.block);

  /// Successful purchase: the debited pet state + updated inventory.
  const PurchaseOutcome.success(PetState state, Inventory inventory)
    : this._(state, inventory, null);

  const PurchaseOutcome.blocked(PurchaseBlock block)
    : this._(null, null, block);

  final PetState? state;
  final Inventory? inventory;
  final PurchaseBlock? block;

  bool get success => block == null;
}

/// Attempts to buy [item] with Kibble. Pure — no clocks, no I/O.
PurchaseOutcome tryPurchase({
  required PetState state,
  required Inventory inventory,
  required ItemDef item,
}) {
  if (!item.purchasable) {
    return const PurchaseOutcome.blocked(PurchaseBlock.notSoldHere);
  }
  final ownedForever = switch (item.kind) {
    ItemKind.toy => inventory.ownsToy(item.id),
    ItemKind.cosmetic => inventory.ownsCosmetic(item.id),
    _ => false,
  };
  if (ownedForever) {
    return const PurchaseOutcome.blocked(PurchaseBlock.alreadyOwned);
  }
  final debited = state.wallet.spendKibble(item.kibblePrice);
  if (debited == null) {
    return const PurchaseOutcome.blocked(PurchaseBlock.kibble);
  }
  return PurchaseOutcome.success(
    state.copyWith(wallet: debited),
    inventory.add(item),
  );
}
