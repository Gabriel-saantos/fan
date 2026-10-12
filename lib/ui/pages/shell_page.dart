import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../widgets/fan_widgets.dart';
import 'explore_page.dart';
import 'home_page.dart';
import 'library_page.dart';
import 'profile_page.dart';
import 'publish_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});
  @override
  State<ShellPage> createState() => _ShellPageState();
}
class _ShellPageState extends State<ShellPage> {
  int page = 0, exploreRequest = 0;
  String category = 'Todos';
  static const items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'Início'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Explorar'),
    (Icons.bookmark_outline_rounded, Icons.bookmark_rounded, 'Biblioteca'),
    (Icons.edit_note_outlined, Icons.edit_note_rounded, 'Estúdio'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
  ];
  void explore([String value = 'Todos']) => setState(() { category = value; exploreRequest++; page = 1; });
  @override
  Widget build(BuildContext context) {
    final store = FanScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final views = [HomePage(onExplore: explore, onCreate: () => setState(() => page = 3)),
      ExplorePage(initialCategory: category, requestId: exploreRequest), LibraryPage(onExplore: explore),
      const PublishPage(), const ProfilePage()];
    final content = Column(children: [
      if (store.demoMode) Container(width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: FanColors.purple.withValues(alpha: .08),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.offline_bolt_outlined, size: 16, color: FanColors.orchid), SizedBox(width: 8),
          Flexible(child: Text('Modo local · suas histórias ficam neste dispositivo',
            style: TextStyle(color: FanColors.orchid, fontSize: 12))),
        ])),
      if (store.cloudError != null || store.localError != null) MaterialBanner(
        content: Text(store.cloudError ?? store.localError!, style: const TextStyle(fontSize: 12)),
        leading: const Icon(Icons.info_outline_rounded),
        actions: [TextButton(onPressed: () => setState(() {
          store.cloudError = null; store.localError = null;
        }), child: const Text('Entendi'))]),
      Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1240),
        child: IndexedStack(index: page, children: views)))),
    ]);
    return Scaffold(body: SafeArea(child: Row(children: [
      if (wide) Container(width: 230, decoration: const BoxDecoration(color: FanColors.surface,
        border: Border(right: BorderSide(color: FanColors.line))),
        child: Padding(padding: const EdgeInsets.all(20), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 14), const FanLogo(), const SizedBox(height: 8),
          const Text('Histórias que conectam.', style: TextStyle(color: FanColors.muted, fontSize: 12)),
          const SizedBox(height: 42),
          ...List.generate(items.length, (i) => Padding(padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(selected: page == i, selectedTileColor: FanColors.purple.withValues(alpha: .12),
              selectedColor: FanColors.orchid, textColor: FanColors.muted, iconColor: FanColors.muted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: Icon(page == i ? items[i].$2 : items[i].$1),
              title: Text(items[i].$3, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () => setState(() => page = i)))),
          const Spacer(),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
            color: FanColors.surface2, borderRadius: BorderRadius.circular(16)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.auto_awesome_rounded, color: FanColors.orchid), SizedBox(height: 12),
              Text('Um capítulo por vez.', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 6), Text('Descubra o prazer de fazer parte de uma história.',
                style: TextStyle(color: FanColors.muted, fontSize: 12, height: 1.6)),
            ])), const SizedBox(height: 20),
        ]))),
      Expanded(child: content),
    ])), bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: page,
      onDestinationSelected: (i) => setState(() => page = i),
      destinations: items.map((i) => NavigationDestination(icon: Icon(i.$1), selectedIcon: Icon(i.$2), label: i.$3)).toList()));
  }
}
