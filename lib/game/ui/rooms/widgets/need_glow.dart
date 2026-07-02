/// A number-light need indicator (§5.5): a soft rounded glow bar + icon, no
/// percentages, no red alarm — low just means a gentler, dimmer glow.
library;

import 'package:flutter/material.dart';

class NeedGlow extends StatelessWidget {
  const NeedGlow({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });

  final String label;

  /// The meter value, 0–100.
  final double value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = (value / 100).clamp(0.0, 1.0);
    final color = Color.lerp(
      const Color(0xFFE9C46A), // gentle honey when low — never alarm red
      const Color(0xFF8AB17D), // soft leaf-green when full
      t,
    )!;
    return Semantics(
      label: '$label: ${value.round()} of 100',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF7A6A58)),
          const SizedBox(width: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 52,
              height: 8,
              child: Stack(
                children: [
                  Container(color: color.withValues(alpha: 0.22)),
                  FractionallySizedBox(
                    widthFactor: t,
                    child: Container(color: color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
