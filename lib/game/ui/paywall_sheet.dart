/// Paywall UX (P5-4) — the warm, honest monetization sheet. Surfaces the single
/// LOCKED Forever Friends subscription (monthly + annual) plus whatever bundle
/// sections the LAUNCH catalogue carries (none today: Heartstone bundles wait
/// for their spend sink, KP-007/KP-037; Rescue Bundles wait for the donation
/// loop to be operational, KP-006/F-6). Copy + plan order come from the
/// pricing-*framing* experiment via [PaywallController]; the funnel telemetry
/// + ethical wall live there.
///
/// Ethical wall, surfaced to the player (§18, D-047): every perk is cosmetic /
/// quality-of-life, cancelling never affects the pet — never pay-to-win,
/// never a guilt lever, and never a claim the build cannot honor.
library;

import 'package:flutter/material.dart';

import '../../core/legal_links.dart';
import '../../core/service_locator.dart';
import '../../monetization/entitlements.dart';
import '../../monetization/monetization_controller.dart';
import '../../monetization/paywall_controller.dart';
import '../../monetization/product_catalog.dart';
import '../../services/link_opener.dart';
import 'widgets/cozy.dart';

/// Opens the paywall as a modal sheet, logging `shown` on open + `dismissed` on
/// close (the funnel bookends). [surface] tags where it was opened from.
Future<void> showPaywall(
  BuildContext context,
  PaywallController controller, {
  String surface = 'home',
}) {
  controller.recordShown(surface);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PaywallSheet(controller: controller, surface: surface),
  ).whenComplete(() => controller.recordDismissed(surface));
}

class PaywallSheet extends StatefulWidget {
  const PaywallSheet({
    required this.controller,
    this.surface = 'home',
    super.key,
  });

  final PaywallController controller;
  final String surface;

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  late final PaywallCopy _copy = widget.controller.resolveCopy();
  bool _busy = false;

  /// The latest purchase/restore outcome, shown as an in-sheet live region (a
  /// SnackBar alone is occluded by the modal sheet, so a11y users + everyone get
  /// no feedback on failure/restore — P5 audit fix).
  String? _status;

  PaywallController get _c => widget.controller;
  MonetizationController get _monetization => _c.monetization;

  Future<void> _buy(Product product) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await _c.buy(product, surface: widget.surface);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.success) {
      _toast(
        product.isSubscription
            ? 'Welcome, Forever Friend 💛'
            : 'Thank you! Your goodies are on the way. 💛',
      );
    } else if (!result.cancelled) {
      _toast("That didn't go through — no charge was made. Please try again.");
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    final entitled = await _c.restore(surface: widget.surface);
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(
      entitled
          ? 'Restored — welcome back, Forever Friend 💛'
          : 'Nothing to restore on this account yet.',
    );
  }

  void _toast(String message) {
    // Show it BOTH inline (always visible above the sheet content, announced as
    // a live region) and as a SnackBar (visible once the sheet is dismissed).
    setState(() => _status = message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Rebuild the entitlement-dependent parts when a purchase/restore resolves.
    return ListenableBuilder(
      listenable: _monetization,
      builder: (context, _) {
        final entitled = _c.entitlements.foreverFriends;
        return SafeArea(
          child: Padding(
            key: const Key('paywall-sheet'),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CozyImage(
                      entitled
                          ? KpAssets.entitledGlow
                          : KpAssets.foreverFriendsHeader,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_copy.headline, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(_copy.subline, style: theme.textTheme.bodyMedium),
                  if (_status != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      container: true,
                      child: Container(
                        key: const Key('paywall-status'),
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _status!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (entitled)
                    _EntitledCard(entitlements: _c.entitlements)
                  else
                    _SubscriptionPlans(
                      monthly: _c.subscriptionMonthly,
                      annual: _c.subscriptionAnnual,
                      annualFirst: _copy.annualFirst,
                      busy: _busy,
                      onBuy: _buy,
                    ),
                  // Apple 3.1.2 point-of-sale disclosures (KP-003): the
                  // auto-renewal terms + functional Terms/Privacy links must
                  // sit adjacent to the purchase controls.
                  if (!entitled) ...[
                    const SizedBox(height: 10),
                    const _SubscriptionDisclosures(),
                  ],
                  const SizedBox(height: 12),
                  const _EthicalWallNote(),
                  // Bundle sections render only for products in the LAUNCH
                  // catalogue (KP-006/KP-007): Heartstone bundles return with
                  // their spend sink (KP-037), Rescue Bundles when donations
                  // are operational (F-6).
                  if (_c.heartstoneBundles.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _BundleSection(
                      title: 'Heartstones',
                      caption: 'Premium cosmetic currency — buys only looks. ✨',
                      products: _c.heartstoneBundles,
                      busy: _busy,
                      onBuy: _buy,
                    ),
                  ],
                  if (_c.rescueBundles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _BundleSection(
                      title: 'Rescue Bundles',
                      caption:
                          'A cosmetic treat with a transparent giving split.',
                      products: _c.rescueBundles,
                      busy: _busy,
                      onBuy: _buy,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      key: const Key('paywall-restore'),
                      onPressed: _busy ? null : _restore,
                      child: const Text('Restore purchases'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The current-state card shown when the player already subscribes — the
/// entitlement UX. No upsell; cancelling is always honored without pet harm.
class _EntitledCard extends StatelessWidget {
  const _EntitledCard({required this.entitlements});

  final Entitlements entitlements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const Key('paywall-entitled'),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You're a Forever Friend 💛",
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Thank you. Your cozy perks are active: the Forever Friends '
              'wardrobe pieces are yours to wear. Cancel anytime — it never '
              'affects your pet.',
            ),
          ],
        ),
      ),
    );
  }
}

/// The two LOCKED subscription plans, ordered by the experiment (annual-first
/// when value-forward). The annual plan shows its honest savings vs 12× monthly.
class _SubscriptionPlans extends StatelessWidget {
  const _SubscriptionPlans({
    required this.monthly,
    required this.annual,
    required this.annualFirst,
    required this.busy,
    required this.onBuy,
  });

  final Product monthly;
  final Product annual;
  final bool annualFirst;
  final bool busy;
  final Future<void> Function(Product) onBuy;

  @override
  Widget build(BuildContext context) {
    final savingsPct = ((1 - annual.priceUsd / (monthly.priceUsd * 12)) * 100)
        .round();
    final monthlyCard = _PlanCard(
      key: const Key('paywall-plan-monthly'),
      product: monthly,
      period: '/mo',
      busy: busy,
      onBuy: onBuy,
    );
    final annualCard = _PlanCard(
      key: const Key('paywall-plan-annual'),
      product: annual,
      period: '/yr',
      badge: 'Save $savingsPct%',
      busy: busy,
      onBuy: onBuy,
    );
    return Column(
      children: annualFirst
          ? [annualCard, const SizedBox(height: 8), monthlyCard]
          : [monthlyCard, const SizedBox(height: 8), annualCard],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.product,
    required this.period,
    required this.busy,
    required this.onBuy,
    this.badge,
    super.key,
  });

  final Product product;
  final String period;
  final String? badge;
  final bool busy;
  final Future<void> Function(Product) onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Text(product.displayName),
        // Fold the savings into the subtitle so it's part of the plan's spoken
        // label, not only a trailing color chip (a11y — P5 audit fix).
        subtitle: Text(
          badge == null
              ? '\$${product.priceUsd.toStringAsFixed(2)}$period'
              : '\$${product.priceUsd.toStringAsFixed(2)}$period · $badge',
        ),
        trailing: badge == null
            ? null
            : Chip(
                label: Text(badge!),
                backgroundColor: theme.colorScheme.tertiaryContainer,
                visualDensity: VisualDensity.compact,
              ),
        onTap: busy ? null : () => onBuy(product),
      ),
    );
  }
}

/// One-time cosmetic-currency bundles (Heartstones / Rescue Bundles). Rescue
/// Bundles disclose their giving slice up front — the transparency the ethical
/// wall requires (a commercial cosmetic with a split, NOT a charity IAP).
class _BundleSection extends StatelessWidget {
  const _BundleSection({
    required this.title,
    required this.caption,
    required this.products,
    required this.busy,
    required this.onBuy,
  });

  final String title;
  final String caption;
  final List<Product> products;
  final bool busy;
  final Future<void> Function(Product) onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        Text(caption, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        for (final p in products)
          Card(
            key: Key('paywall-bundle-${p.sku}'),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              title: Text(p.displayName),
              subtitle: p.isRescueBundle
                  ? Text(
                      '\$${p.donationSliceUsd.toStringAsFixed(2)} of '
                      '\$${p.priceUsd.toStringAsFixed(2)} goes to real rescues. 💛',
                    )
                  : null,
              trailing: Text('\$${p.priceUsd.toStringAsFixed(2)}'),
              onTap: busy ? null : () => onBuy(p),
            ),
          ),
      ],
    );
  }
}

/// The legally-required subscription disclosures at the point of sale
/// (Apple 3.1.2 / Play equivalent — KP-003): auto-renewal terms in plain
/// words, plus working Terms-of-Use and Privacy-Policy links.
class _SubscriptionDisclosures extends StatelessWidget {
  const _SubscriptionDisclosures();

  Future<void> _open(BuildContext context, String url) async {
    final ok = await ServiceLocator.instance.get<LinkOpener>().open(url);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the page — it lives at $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );
    return Column(
      key: const Key('paywall-disclosures'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscriptions renew automatically. Payment is charged to your '
          'App Store or Google Play account at purchase confirmation, and '
          'renewal is charged within 24 hours before the period ends unless '
          'cancelled at least 24 hours before then. Manage or cancel anytime '
          'in your store account settings.',
          style: small,
        ),
        Row(
          children: [
            TextButton(
              key: const Key('paywall-terms-link'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => _open(context, kTermsOfUseUrl),
              child: const Text('Terms of Use'),
            ),
            Text('·', style: small),
            TextButton(
              key: const Key('paywall-privacy-link'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => _open(context, kPrivacyPolicyUrl),
              child: const Text('Privacy Policy'),
            ),
          ],
        ),
      ],
    );
  }
}

/// The visible ethical-wall promise — cosmetic/QoL only, no pet harm, no
/// pay-to-win. Shown on every paywall so the player always sees it.
class _EthicalWallNote extends StatelessWidget {
  const _EthicalWallNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: const Key('paywall-ethical-note'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🛡️ '),
        Expanded(
          child: Text(
            'Cosmetic & cozy perks only — never an advantage. Cancelling never '
            'affects your pet, and your companion is loved the same either way.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
