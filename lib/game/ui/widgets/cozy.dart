/// Premium UI asset registry + memory-safe image widgets (UI integration sprint).
///
/// The GPT-generated source PNGs are large (up to ~1536 px, multi-MB decoded).
/// [CozyImage] / [CozyBackground] decode them DOWN to the displayed size via
/// `cacheWidth` (devicePixelRatio-aware), so a 32 px icon never costs a 6 MB
/// decode. Every loader degrades gracefully (a soft surface) if an asset is
/// missing, so the app never shows a broken-image glyph.
library;

import 'package:flutter/material.dart';

/// Central, typed registry of premium UI asset paths. One place to rename/swap.
abstract final class KpAssets {
  // Backgrounds (opaque, full-bleed).
  static const cozyRoomDay = 'assets/backgrounds/cozy_room_day.png';
  static const cozyRoomNight = 'assets/backgrounds/cozy_room_night.png';
  static const rainyWindow = 'assets/backgrounds/rainy_window.png';
  static const gardenDay = 'assets/backgrounds/garden_day.png';
  static const campsiteEvening = 'assets/backgrounds/campsite_evening.png';
  static const onboardingDark = 'assets/backgrounds/onboarding_rainy_dark.png';
  static const bathroomScene = 'assets/backgrounds/bathroom_clean_scene.png';

  // UI frames (transparent).
  static const speechBubble = 'assets/ui/speech_bubble.png';
  static const cardFrame = 'assets/ui/card_frame.png';
  static const panelFrame = 'assets/ui/panel_frame.png';

  // Care buttons (transparent bubble art).
  static const btnFeed = 'assets/ui/buttons/feed.png';
  static const btnClean = 'assets/ui/buttons/clean.png';
  static const btnPlay = 'assets/ui/buttons/play.png';

  // Icons (transparent).
  static const iconKibble = 'assets/icons/kibble.png';
  static const iconBond = 'assets/icons/bond_heart.png';
  static const iconWardrobe = 'assets/icons/wardrobe.png';
  static const iconKeepsakes = 'assets/icons/keepsakes.png';
  static const iconMemory = 'assets/icons/memory_book.png';
  static const iconShop = 'assets/icons/shop.png';
  static const iconSettings = 'assets/icons/settings.png';
  static const iconNotification = 'assets/icons/notification_bell.png';

  // Illustrations (transparent).
  static const onboardingBeat1 = 'assets/illustrations/onboarding_beat_1.png';
  static const onboardingBeat2 = 'assets/illustrations/onboarding_beat_2.png';
  static const onboardingBeat3 = 'assets/illustrations/onboarding_beat_3.png';
  static const adoptionChoice = 'assets/illustrations/adoption_choice.png';
  static const emptyMemory = 'assets/illustrations/empty_memory_book.png';
  static const emptyKeepsakes = 'assets/illustrations/empty_keepsakes.png';

  // Cards (transparent).
  static const keepsakeTemplate = 'assets/cards/keepsake_template.png';
  static const memoryCard = 'assets/cards/memory_card.png';
  static const shopItem = 'assets/cards/shop_item.png';

  // Premium / shop.
  static const foreverFriendsHeader =
      'assets/premium/forever_friends_header.png';
  static const entitledGlow = 'assets/premium/entitled_glow.png';
  static const rescueBundleBadge = 'assets/shop/rescue_bundle_badge.png';

  /// Every background, for precaching.
  static const backgrounds = [
    cozyRoomDay,
    cozyRoomNight,
    rainyWindow,
    onboardingDark,
  ];
}

/// A memory-safe asset image: decodes to the displayed width (× dpr) so the
/// large source PNGs don't blow up memory. Falls back to empty space on error.
class CozyImage extends StatelessWidget {
  const CozyImage(
    this.asset, {
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    super.key,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final dpr = media?.devicePixelRatio ?? 2.0;
    // Decode to the displayed width; for an infinite/unbounded width (e.g. a
    // full-bleed header) cap at the screen width so we never decode the full
    // ~1536px source for a small element.
    final targetW = (width != null && width!.isFinite)
        ? width!
        : (media?.size.width ?? 400.0);
    final cw = (targetW * dpr).round().clamp(1, 2160);
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cw,
      filterQuality: FilterQuality.medium,
      semanticLabel: semanticLabel,
      // Decorative by default: a label-less image is kept out of the a11y tree
      // (adjacent text carries the meaning), so screen readers don't announce
      // an unnamed image for every icon/illustration.
      excludeFromSemantics: semanticLabel == null,
      errorBuilder: (_, _, _) => SizedBox(width: width, height: height),
    );
  }
}

/// A full-bleed cozy scene behind [child]. Decoded to screen width; on a missing
/// asset it falls back to the theme surface so the screen is never broken/white.
class CozyBackground extends StatelessWidget {
  const CozyBackground({
    required this.asset,
    this.child,
    this.scrim,
    super.key,
  });

  final String asset;
  final Widget? child;

  /// Optional soft overlay (e.g. to lift text contrast or dim a side panel).
  final Color? scrim;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final dpr = media?.devicePixelRatio ?? 2.0;
    final w = media?.size.width ?? 400;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          asset,
          fit: BoxFit.cover,
          cacheWidth: (w * dpr).round().clamp(1, 2160),
          errorBuilder: (context, _, _) =>
              ColoredBox(color: Theme.of(context).colorScheme.surface),
        ),
        if (scrim != null) ColoredBox(color: scrim!),
        ?child,
      ],
    );
  }
}

/// A tappable cozy PNG button (feed/clean/play): bubble art + label + ripple.
class CozyImageButton extends StatelessWidget {
  const CozyImageButton({
    required this.asset,
    required this.label,
    required this.onTap,
    this.size = 84,
    this.tapKey,
    super.key,
  });

  final String asset;
  final String label;
  final VoidCallback? onTap;
  final double size;

  /// Key on the tappable region (so widget/integration tests can find it).
  final Key? tapKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: label,
          child: InkResponse(
            key: tapKey,
            onTap: onTap,
            radius: size * 0.6,
            child: CozyImage(asset, width: size, height: size),
          ),
        ),
        const SizedBox(height: 2),
        // A soft white halo keeps the label legible over the busy cozy scene
        // (esp. the dark night room) without a heavy backing.
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4A3F38),
            shadows: const [
              Shadow(color: Color(0xE6FFF6EC), blurRadius: 6),
              Shadow(color: Color(0xE6FFF6EC), blurRadius: 3),
            ],
          ),
        ),
      ],
    );
  }
}
