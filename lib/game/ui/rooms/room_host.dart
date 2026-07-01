/// The room shell — hosts every room of the pet's home in a swipeable
/// [PageView] with a cozy bottom room dock. One shared app bar (pet name,
/// Kibble, keepsakes, Memory Book, Forever Friends) and one shared drawer sit
/// over all rooms, so navigation is immediate: no loading screens, no route
/// pushes between rooms, and the single [GameController] keeps the simulation
/// consistent everywhere (changing rooms never resets pet state).
library;

import 'package:flutter/material.dart';

import '../../../core/service_locator.dart';
import '../../../monetization/paywall_controller.dart';
import '../../../render/pet_renderer.dart';
import '../../controller/game_controller.dart';
import '../../rooms/room_id.dart';
import '../keepsake_screen.dart';
import '../memory_book_screen.dart';
import '../paywall_sheet.dart';
import '../widgets/cozy.dart';
import 'room_registry.dart';

/// Vertical space rooms must leave free at the bottom so content never sits
/// under the floating room dock.
const double kRoomDockClearance = 92;

class RoomHost extends StatefulWidget {
  const RoomHost({
    required this.controller,
    this.renderer,
    this.initialRoom = RoomId.home,
    super.key,
  });

  final GameController controller;

  /// The rig renderer; defaults to the one wired in `bootstrap()`.
  final PetRenderer? renderer;

  final RoomId initialRoom;

  @override
  State<RoomHost> createState() => _RoomHostState();
}

class _RoomHostState extends State<RoomHost> {
  late final List<RoomDefinition> _rooms;
  late final PageController _pages;
  late int _current;

  @override
  void initState() {
    super.initState();
    _rooms = enabledRooms();
    _current = _indexOf(widget.initialRoom);
    _pages = PageController(initialPage: _current);
  }

  int _indexOf(RoomId id) {
    final i = _rooms.indexWhere((r) => r.id == id);
    return i < 0 ? _rooms.indexWhere((r) => r.id == RoomId.home) : i;
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index == _current) return;
    _pages.animateToPage(
      index,
      // Immediate, springy room hop (UX bible: 200–350ms ease-out).
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final pet = widget.controller.pet;
        if (pet == null) return const SizedBox.shrink();
        final rig =
            widget.renderer ?? ServiceLocator.instance.get<PetRenderer>();

        return Scaffold(
          key: const Key('companion-home'),
          extendBodyBehindAppBar: true,
          drawer: _CozyDrawer(controller: widget.controller),
          appBar: AppBar(
            title: Text(pet.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Semantics(
                    label: 'Kibble: ${pet.wallet.kibble}',
                    child: Row(
                      key: const Key('kibble-count'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CozyImage(
                          KpAssets.iconKibble,
                          width: 26,
                          height: 26,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${pet.wallet.kibble}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                key: const Key('keepsakes-button'),
                icon: const Icon(Icons.photo_album),
                tooltip: 'Keepsakes',
                onPressed: () => _open(
                  context,
                  KeepsakeScreen(controller: widget.controller),
                ),
              ),
              IconButton(
                key: const Key('memory-book-button'),
                icon: const Icon(Icons.menu_book),
                tooltip: 'The Memory Book',
                onPressed: () => _open(
                  context,
                  MemoryBookScreen(controller: widget.controller),
                ),
              ),
              IconButton(
                key: const Key('paywall-button'),
                icon: const Icon(Icons.favorite_border),
                tooltip: 'Forever Friends',
                onPressed: () => showPaywall(
                  context,
                  ServiceLocator.instance.get<PaywallController>(),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Rooms. Each page paints its own full-bleed scene, so the swipe
              // carries the scene with the room (no cross-fade seams).
              PageView.builder(
                key: const Key('room-pages'),
                controller: _pages,
                itemCount: _rooms.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (context, i) =>
                    _rooms[i].build(widget.controller, rig),
              ),
              // Soft top scrim so the app-bar title + icons stay legible over
              // any scene (esp. the dark night room).
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xCCFFF6EC), Color(0x00FFF6EC)],
                      ),
                    ),
                  ),
                ),
              ),
              if (_rooms.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: _RoomDock(
                      rooms: _rooms,
                      current: _current,
                      onSelect: _goTo,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _open(BuildContext context, Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));
}

/// The floating room dock: one warm rounded chip per open room. The current
/// room glows; tapping hops there immediately. Scrolls when the home grows
/// wider than the screen, and always keeps the current room in view.
class _RoomDock extends StatefulWidget {
  const _RoomDock({
    required this.rooms,
    required this.current,
    required this.onSelect,
  });

  final List<RoomDefinition> rooms;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  State<_RoomDock> createState() => _RoomDockState();
}

class _RoomDockState extends State<_RoomDock> {
  static const double _chipExtent = 64;
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(_RoomDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current && _scroll.hasClients) {
      // Keep the selected room centered-ish in the dock.
      final target =
          (widget.current * _chipExtent) -
          (_scroll.position.viewportDimension - _chipExtent) / 2;
      _scroll.animateTo(
        target.clamp(0.0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('room-dock'),
      height: 78,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE9A178).withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        itemCount: widget.rooms.length,
        itemBuilder: (context, i) {
          final room = widget.rooms[i];
          final selected = i == widget.current;
          return SizedBox(
            width: _chipExtent,
            child: Semantics(
              button: true,
              selected: selected,
              label: '${room.id.displayName} — ${room.id.tagline}',
              child: InkWell(
                key: Key('room-dock-${room.id.id}'),
                borderRadius: BorderRadius.circular(20),
                onTap: () => widget.onSelect(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: selected
                            ? scheme.primary.withValues(alpha: 0.9)
                            : scheme.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        room.icon,
                        size: 24,
                        color: selected
                            ? scheme.onPrimary
                            : const Color(0xFF4A3F38),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      room.id.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: const Color(0xFF4A3F38),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The side navigation (UX bible): wardrobe · keepsakes · memory book · shop ·
/// settings · profile. Existing screens route; not-yet-built screens give a
/// warm "coming soon" (honest — those screens are a future deliverable).
class _CozyDrawer extends StatelessWidget {
  const _CozyDrawer({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFFF6EC),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'KindredPaws',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            _item(
              context,
              KpAssets.iconWardrobe,
              'Wardrobe',
              'drawer-wardrobe',
              () => _soon(context, 'Wardrobe'),
            ),
            _item(
              context,
              KpAssets.iconKeepsakes,
              'Keepsakes',
              'drawer-keepsakes',
              () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => KeepsakeScreen(controller: controller),
                  ),
                );
              },
            ),
            _item(
              context,
              KpAssets.iconMemory,
              'Memory Book',
              'drawer-memory',
              () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MemoryBookScreen(controller: controller),
                  ),
                );
              },
            ),
            _item(context, KpAssets.iconShop, 'Shop', 'drawer-shop', () {
              Navigator.of(context).pop();
              showPaywall(
                context,
                ServiceLocator.instance.get<PaywallController>(),
                surface: 'shop',
              );
            }),
            _item(
              context,
              KpAssets.iconSettings,
              'Settings',
              'drawer-settings',
              () => _soon(context, 'Settings'),
            ),
            _item(
              context,
              KpAssets.iconBond,
              'Profile',
              'drawer-profile',
              () => _soon(context, 'Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    String icon,
    String label,
    String key,
    VoidCallback onTap,
  ) {
    return ListTile(
      key: Key(key),
      leading: CozyImage(icon, width: 34, height: 34),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  void _soon(BuildContext context, String what) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$what is on its way — coming soon 🐾')),
      );
  }
}
