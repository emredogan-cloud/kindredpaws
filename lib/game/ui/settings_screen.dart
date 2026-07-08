/// Settings — quiet, honest controls (UX bible §2.9): sound, haptics, and
/// notification toggles that actually gate their systems; the privacy section
/// with the real right-to-be-forgotten flow (§8.3 — double-confirmed, erases
/// local + backend + analytics identifiers, never guilt-trips the goodbye);
/// and About with licenses. Every control is labelled and ≥48 dp (a11y §4).
library;

import 'package:flutter/material.dart';

import '../../core/kindred_terms.dart';
import '../../core/legal_links.dart';
import '../../core/service_locator.dart';
import '../../services/feel_service.dart';
import '../../services/link_opener.dart';
import '../../services/prefs_service.dart';
import '../controller/game_controller.dart';
import '../model/bond.dart';
import '../model/items.dart';
import '../model/life_stage.dart';
import '../model/species.dart';
import 'widgets/cozy.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.controller, super.key});

  final GameController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PrefsService get _prefs => ServiceLocator.instance.get<PrefsService>();
  FeelService get _feel => ServiceLocator.instance.get<FeelService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('settings-screen'),
      backgroundColor: const Color(0xFFFFF6EC),
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _sectionLabel('Sound & touch'),
          SwitchListTile(
            key: const Key('settings-sound'),
            secondary: const Icon(Icons.music_note_rounded),
            title: const Text('Sounds'),
            subtitle: const Text('Gentle chimes and splashes'),
            value: _prefs.soundEnabled,
            onChanged: (v) async {
              await _prefs.setSoundEnabled(v);
              if (v) await _feel.play(SfxCue.softPop); // a hello back
              setState(() {});
            },
          ),
          SwitchListTile(
            key: const Key('settings-haptics'),
            secondary: const Icon(Icons.vibration_rounded),
            title: const Text('Gentle vibrations'),
            subtitle: const Text('A soft tap with each care moment'),
            value: _prefs.hapticsEnabled,
            onChanged: (v) async {
              await _prefs.setHapticsEnabled(v);
              if (v) await _feel.haptic(HapticKind.tap);
              setState(() {});
            },
          ),
          _sectionLabel('Notifications'),
          SwitchListTile(
            key: const Key('settings-notifications'),
            secondary: const Icon(Icons.notifications_none_rounded),
            title: const Text('Warm reminders'),
            subtitle: const Text(
              'A friendly hello now and then — never more than a couple a day',
            ),
            value: _prefs.notificationsEnabled,
            onChanged: (v) async {
              await _prefs.setNotificationsEnabled(v);
              if (!v) {
                // Off means off — clear anything already scheduled.
                await widget.controller.notifications.cancelAll();
              }
              setState(() {});
            },
          ),
          _sectionLabel('Seasons'),
          SwitchListTile(
            key: const Key('settings-southern'),
            secondary: const Icon(Icons.public_rounded),
            title: const Text('Southern-hemisphere seasons'),
            subtitle: const Text(
              'Flip the year for friends below the equator '
              '(summer in December)',
            ),
            value: _prefs.southernHemisphere,
            onChanged: (v) async {
              await _prefs.setSouthernHemisphere(v);
              setState(() {});
            },
          ),
          _sectionLabel('Privacy'),
          ListTile(
            key: const Key('settings-privacy-policy'),
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text('What we collect (very little), and why'),
            onTap: () => _openLink(kPrivacyPolicyUrl),
          ),
          ListTile(
            key: const Key('settings-terms'),
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Use'),
            onTap: () => _openLink(kTermsOfUseUrl),
          ),
          ListTile(
            key: const Key('settings-support'),
            leading: const Icon(Icons.support_agent_rounded),
            title: const Text('Support'),
            subtitle: const Text('Get help or report a problem'),
            onTap: () => _openLink(kSupportUrl),
          ),
          ListTile(
            key: const Key('settings-delete'),
            leading: const Icon(Icons.delete_outline_rounded),
            title: const Text('Delete my data'),
            subtitle: const Text(
              'Erases your pet and everything remembered — everywhere',
            ),
            onTap: _confirmDelete,
          ),
          _sectionLabel('About'),
          // Donation copy stays out until the giving loop is operational and
          // every claim is literally true (KP-006, FOUNDER_ACTIONS_TODO F-6).
          const ListTile(
            leading: Icon(Icons.favorite_border_rounded),
            title: Text(KindredTerms.gameTitle),
            subtitle: Text('Made with love, for you and your companion.'),
          ),
          ListTile(
            key: const Key('settings-licenses'),
            leading: const Icon(Icons.article_outlined),
            title: const Text('Open-source licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: KindredTerms.gameTitle,
            ),
          ),
        ],
      ),
    );
  }

  /// Opens a legal/support page in the external browser (KP-004); a failure
  /// surfaces gently instead of dead-ending the tap.
  Future<void> _openLink(String url) async {
    final ok = await ServiceLocator.instance.get<LinkOpener>().open(url);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the page — it lives at $url')),
      );
    }
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: Color(0xFF7A6A58),
      ),
    ),
  );

  /// The right-to-be-forgotten flow: two clear, calm confirmations — the
  /// second names the pet so the choice is fully informed. Never guilt.
  Future<void> _confirmDelete() async {
    final petName = widget.controller.pet?.name ?? 'your pet';
    final first = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text(
          'This erases your pet, memories, keepsakes, and progress from '
          'this device and our servers. It cannot be undone.',
        ),
        actions: [
          TextButton(
            key: const Key('delete-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep everything'),
          ),
          TextButton(
            key: const Key('delete-continue'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Say goodbye to $petName?'),
        content: const Text(
          'Thank you for all the care you gave. Are you sure?',
        ),
        actions: [
          TextButton(
            key: const Key('delete-cancel-2'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay together'),
          ),
          FilledButton(
            key: const Key('delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (second != true || !mounted) return;

    final ok = await widget.controller.deleteAccountAndStartOver();
    if (!mounted) return;
    if (ok) {
      // Back to the very beginning (GameRoot shows Rescue Day again).
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong and nothing was deleted — please try again.',
          ),
        ),
      );
    }
  }
}

/// Profile — the story so far (UX bible §2.10): the dressed pet, the Bond
/// tier, the care streak with its Warmth freezes, Gotcha Day, and days
/// together. Number-light, pride-forward, zero pressure.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.controller, super.key});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('profile-screen'),
      backgroundColor: const Color(0xFFFFF6EC),
      appBar: AppBar(title: const Text('Our story')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final pet = controller.pet;
          if (pet == null) return const SizedBox.shrink();
          final gotcha = DateTime.fromMillisecondsSinceEpoch(pet.createdAtMs);
          final freezes = pet.careStreak.warmthBanked;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: Center(
                        child: ExcludeSemantics(
                          child: Text(
                            pet.species == Species.puppy ? '🐶' : '🐱',
                            style: const TextStyle(fontSize: 84),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      pet.name,
                      key: const Key('profile-name'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${pet.species.displayName} · ${pet.lifeStage.displayName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _fact(
                context,
                key: 'profile-bond',
                emoji: '💖',
                title: 'Bond',
                value: pet.bond.stage.displayName,
              ),
              _fact(
                context,
                key: 'profile-streak',
                emoji: '🔥',
                title: 'Care streak',
                value:
                    '${pet.careStreak.count} '
                    'day${pet.careStreak.count == 1 ? '' : 's'}'
                    '${freezes > 0 ? '  ·  ❄️ $freezes warmth saved' : ''}',
              ),
              _fact(
                context,
                key: 'profile-gotcha',
                emoji: '🏡',
                title: 'Gotcha Day',
                value:
                    '${gotcha.year}-${gotcha.month.toString().padLeft(2, '0')}'
                    '-${gotcha.day.toString().padLeft(2, '0')}',
              ),
              _fact(
                context,
                key: 'profile-days',
                emoji: '🌞',
                title: 'Days together',
                value: '${pet.activeDays}',
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 18, 4, 6),
                child: Text(
                  'Milestones we\'ve reached',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF7A6A58),
                  ),
                ),
              ),
              ..._milestones(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'more chapters to come 💛',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF7A6A58),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// The Milestone Book — only chapters already lived (derived from the save;
  /// never a checklist, never pressure). Each is a warm celebration line.
  List<Widget> _milestones() {
    final pet = controller.pet!;
    final streakTier = pet.careStreak.count >= 30
        ? 30
        : pet.careStreak.count >= 7
        ? 7
        : 3;
    final reached = <(String, String)>[
      ('🏡', 'Rescue Day — the day we met'),
      for (final stage in BondStage.values)
        if (stage.rank > 0 && pet.bond.stage.rank >= stage.rank)
          ('💖', 'Reached ${stage.displayName} together'),
      if (pet.lifeStage != LifeStage.pupKit)
        ('🌱', 'Grew into a ${pet.lifeStage.displayName}'),
      if (pet.careStreak.count >= 3)
        ('🔥', '$streakTier days of care in a row'),
      for (final toy in ItemCatalog.ofKind(ItemKind.toy))
        if (controller.inventory.affinity(toy.id) >= 15)
          ('🧸', '${toy.displayName} became a favourite'),
      if (controller.keepsakes.length >= 5)
        ('📸', '${controller.keepsakes.length} keepsakes collected'),
      if (pet.activeDays >= 7) ('🌞', 'A whole week together'),
      if (pet.activeDays >= 30) ('🌈', 'A whole month together'),
    ];
    return [
      for (final (emoji, line) in reached)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: CozyChip(
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _fact(
    BuildContext context, {
    required String key,
    required String emoji,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CozyChip(
        child: Row(
          children: [
            ExcludeSemantics(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              value,
              key: Key(key),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
