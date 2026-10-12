import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../models/fan_models.dart';
import '../widgets/fan_widgets.dart';
import 'auth_page.dart';
import 'details_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final store = FanScope.of(context);
    final List<FanStory> list = switch (tab) {
      0 => store.savedStories,
      1 => store.readingStories,
      _ => store.stories.where((s) => store.libraryOf(s.id).liked).toList(),
    };
    return ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 20), children: [
      const Text('Minha Biblioteca', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -1)),
      const SizedBox(height: 7),
      const Text('Seus universos, sempre por perto.', style: TextStyle(color: FanColors.muted, fontSize: 11.5)),
      const SizedBox(height: 24),
      Row(children: List.generate(3, (i) => Padding(padding: const EdgeInsets.only(right: 8),
        child: FanTag(['Salvos', 'Lendo', 'Curtidos'][i], selected: i == tab,
          onTap: () => setState(() => tab = i))))),
      const SizedBox(height: 22),
      if (!store.signedIn) ...[
        const _LibraryEmpty(icon: Icons.bookmark_add_outlined,
          title: 'Sua estante está esperando.',
          subtitle: 'Entre para salvar histórias e continuar de onde parou.'),
        const SizedBox(height: 14),
        FanButton(label: 'Entrar no FAN', onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AuthPage()))),
      ] else if (list.isEmpty)
        const _LibraryEmpty(icon: Icons.menu_book_rounded,
          title: 'Nenhuma história por aqui ainda.',
          subtitle: 'Explore e marque seus universos favoritos para vê-los nesta página.')
      else
        ...list.map((story) => FanStoryRow(story: story,
          subtitle: '${story.category} · ${store.libraryOf(story.id).episodeIndex}/${story.episodeCount} episódios lidos',
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => DetailsPage(story: story))))),
    ]);
  }
}

class _LibraryEmpty extends StatelessWidget {
  const _LibraryEmpty({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 24),
    decoration: BoxDecoration(color: FanColors.surface, borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      Icon(icon, size: 43, color: FanColors.orchid), const SizedBox(height: 19),
      Text(title, textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      const SizedBox(height: 10),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(
        fontSize: 11.5, color: FanColors.muted, height: 1.6)),
    ]),
  );
}
