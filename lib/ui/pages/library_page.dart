import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../models/fan_models.dart';
import '../widgets/fan_widgets.dart';
import 'auth_page.dart';
import 'details_page.dart';
import 'reader_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, this.onExplore, this.initialTab = 0});
  final VoidCallback? onExplore;
  final int initialTab;
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}
class _LibraryPageState extends State<LibraryPage> {
  late int tab;
  @override
  void initState() { super.initState(); tab = widget.initialTab; }
  @override
  Widget build(BuildContext context) {
    final store = FanScope.of(context);
    final List<FanStory> list = switch (tab) {
      0 => store.readingStories, 1 => store.savedStories, 2 => store.completedStories,
      _ => store.stories.where((s) => store.libraryOf(s.id).liked).toList(),
    };
    return ListView(padding: fanPagePadding(context), children: [
      const FanPageHeader(eyebrow: 'Seu espaço', title: 'Sua estante de universos.',
        subtitle: 'Guarde favoritos e volte para a conversa de onde parou.'),
      Wrap(spacing: 8, runSpacing: 8, children: List.generate(4, (i) =>
        FanTag(['Lendo', 'Salvos', 'Concluídos', 'Curtidos'][i], selected: tab == i,
          onTap: () => setState(() => tab = i)))),
      const SizedBox(height: 26),
      if (!store.signedIn) FanEmptyState(icon: Icons.bookmark_add_outlined,
        title: 'Uma estante só sua.', message: store.demoMode
          ? 'Crie um perfil local para guardar favoritos e progresso neste dispositivo.'
          : 'Entre na sua conta para sincronizar suas leituras.', actionLabel: store.demoMode ? 'Criar perfil local' : 'Entrar',
        onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage())))
      else if (list.isEmpty) FanEmptyState(icon: Icons.auto_stories_outlined,
        title: ['Sua próxima leitura está esperando.', 'Guarde histórias que você ama.',
          'Cada final é um novo começo.', 'Seus favoritos aparecerão aqui.'][tab],
        message: 'Explore o catálogo e descubra uma história para chamar de sua.',
        actionLabel: widget.onExplore == null ? null : 'Explorar histórias', onAction: widget.onExplore)
      else ...list.map((story) {
        final state = store.libraryOf(story.id);
        return Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(children: [
          FanStoryRow(story: story, subtitle: state.completed ? 'Leitura concluída · ${story.episodeCount} episódios'
            : '${state.episodeIndex} de ${story.episodeCount} episódios concluídos',
            trailing: Icon(tab == 0 ? Icons.play_circle_outline_rounded : Icons.chevron_right_rounded,
              color: FanColors.orchid),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => tab == 0
              ? ReaderPage(story: story) : DetailsPage(story: story)))),
          if (tab == 0) Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
              value: story.episodeCount == 0 ? 0 : (state.episodeIndex / story.episodeCount).clamp(0, 1).toDouble(),
              minHeight: 3, backgroundColor: FanColors.line, color: FanColors.purple))),
        ]));
      }),
    ]);
  }
}
