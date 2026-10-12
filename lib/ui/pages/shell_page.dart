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
  int page = 0;
  static const items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'Início'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Explorar'),
    (Icons.add_circle_outline_rounded, Icons.add_circle_rounded, 'Criar'),
    (Icons.bookmark_border_rounded, Icons.bookmark_rounded, 'Biblioteca'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final store = FanScope.of(context);
    final views = [
      HomePage(onExplore: () => setState(() => page = 1)),
      const ExplorePage(), const PublishPage(), const LibraryPage(), const ProfilePage(),
    ];
    return Scaffold(
      body: SafeArea(child: Column(children: [
        if (store.demoMode)
          Material(color: const Color(0xFF342147), child: InkWell(
            onTap: () => fanMessage(context,
              'Modo demonstração: execute flutterfire configure para ativar a nuvem.'),
            child: const SizedBox(height: 27, child: Center(child: Text(
              'PRÉVIA LOCAL · dados não sincronizados',
              style: TextStyle(color: FanColors.pink, fontSize: 9.5, letterSpacing: .8,
                fontWeight: FontWeight.w700),
            ))),
          )),
        Expanded(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: IndexedStack(index: page, children: views),
        ))),
      ])),
      bottomNavigationBar: SafeArea(top: false, child: Container(
        padding: const EdgeInsets.fromLTRB(5, 9, 5, 6),
        decoration: const BoxDecoration(color: FanColors.surface,
          border: Border(top: BorderSide(color: FanColors.line))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = page == index;
            return Expanded(child: InkWell(
              onTap: () => setState(() => page = index),
              borderRadius: BorderRadius.circular(15),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Column(
                mainAxisSize: MainAxisSize.min, children: [
                  Icon(selected ? item.$2 : item.$1,
                    color: selected ? FanColors.orchid : FanColors.muted, size: 22),
                  const SizedBox(height: 5),
                  Text(item.$3, style: TextStyle(fontSize: 9, fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected ? FanColors.orchid : FanColors.muted)),
                ],
              )),
            ));
          }),
        ),
      )),
    );
  }
}
