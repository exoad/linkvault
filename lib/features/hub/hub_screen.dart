import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../animations/app_page_route.dart';
import '../../hub/hub_module.dart';
import '../../hub/hub_registry.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/hub_app_tile.dart';
import '../../widgets/hub_coming_soon_tile.dart';
import '../../widgets/hub_hero_header.dart';
import '../../widgets/linkvault_ambient_background.dart';
import '../settings/settings_screen.dart';

/// Your Hub — modular launcher for registered [HubModule] apps.
class HubScreen extends StatelessWidget {
  const HubScreen({super.key, required this.themeController});

  final ThemeController themeController;

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.push<void>(
      context,
      AppPageRoute(
        child: SettingsScreen(themeController: themeController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final launcher = HubRegistry.launcher;
    final teasers = HubRegistry.comingSoon;
    final tileHeight = hubAppTileHeight(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final topPad = MediaQuery.paddingOf(context).top + kToolbarHeight + 8;

    return LinkvaultAmbientScaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: PhosphorIcon(PhosphorIcons.gear),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: CustomScrollView(
        clipBehavior: Clip.none,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, topPad, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const HubHeroHeader(
                  subtitle: 'Apps on this device · pick one to open',
                ),
                const SizedBox(height: 24),
                Text(
                  'Apps',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: tileHeight,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final module = launcher[index];
                  return StreamBuilder<String>(
                    stream: module.watchStatLabel(context),
                    builder: (context, snapshot) {
                      return HubAppTile(
                        app: module.definition,
                        statLabel: snapshot.data ?? '…',
                        onTap: () => module.open(context),
                      );
                    },
                  );
                },
                childCount: launcher.length,
              ),
            ),
          ),
          if (teasers.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index < teasers.length - 1 ? 10 : 0,
                    ),
                    child: HubComingSoonTile(module: teasers[index]),
                  ),
                  childCount: teasers.length,
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: 24 + bottomInset),
          ),
        ],
      ),
    );
  }
}
