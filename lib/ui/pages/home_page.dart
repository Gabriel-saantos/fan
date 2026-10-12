import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../models/fan_models.dart';
import '../widgets/fan_widgets.dart';
import 'details_page.dart';
import 'reader_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onExplore, required this.onCreate});
  final void Function([String category]) onExplore;
  final VoidCallback onCreate;
  void open(BuildContext context, FanStory story) => Navigator.push(context,
    MaterialPageRoute(builder: (_) => DetailsPage(story: story)));
  @override
  Widget build(BuildContext context) {
    final store = FanScope.of(context), stories = FanScope.of(context).stories;
    return ListView(padding: fanPagePadding(context), children: [
      FanPageHeader(eyebrow: 'Seu próximo universo',
        title: store.signedIn ? 'Olá, ${store.displayName.split(' ').first}.' : 'Boas histórias começam aqui.',
        subtitle: 'Conversas que surpreendem. Escolhas que fazem parte da história.',
        action: IconButton(tooltip: 'Buscar histórias', onPressed: () => onExplore(),
          icon: const Icon(Icons.search_rounded))),
      if (stories.isNotEmpty) _Featured(story: stories.first, onTap: () => open(context, stories.first)),
      if (store.readingStories.isNotEmpty) ...[
        const SizedBox(height: 32), const FanSectionHeading(title: 'Continue de onde parou'),
        ...store.readingStories.take(2).map((story) => Padding(padding: const EdgeInsets.only(bottom: 12),
          child: FanStoryRow(story: story, subtitle: 'Sua próxima mensagem está esperando',
            trailing: const Icon(Icons.play_circle_filled_rounded, color: FanColors.orchid, size: 32),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(story: story)))))),
      ],
      const SizedBox(height: 32), const FanSectionHeading(title: 'O que você quer sentir hoje?'),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final entry in const <(String, IconData)>[
          ('Romance', Icons.favorite_outline_rounded), ('Fantasia', Icons.auto_awesome_rounded),
          ('Mistério', Icons.nights_stay_outlined), ('Drama', Icons.theater_comedy_outlined),
          ('Terror', Icons.visibility_outlined), ('Comédia', Icons.sentiment_satisfied_alt_rounded)])
          FanTag(entry.$1, icon: entry.$2, onTap: () => onExplore(entry.$1)),
      ]),
      const SizedBox(height: 32),
      FanSectionHeading(title: 'Descubra sua próxima leitura', trailing: 'Ver catálogo', onTap: () => onExplore()),
      LayoutBuilder(builder: (context, box) {
        final columns = box.maxWidth > 850 ? 4 : box.maxWidth > 540 ? 3 : 2;
        final width = (box.maxWidth - (columns - 1) * 18) / columns;
        return Wrap(spacing: 18, runSpacing: 24, children: stories.take(8).map((s) => SizedBox(width: width,
          child: FanStoryCard(story: s, onTap: () => open(context, s)))).toList());
      }),
      const SizedBox(height: 36),
      Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.edit_note_rounded, color: FanColors.orchid, size: 30), const SizedBox(height: 14),
        const Text('Tem uma história para contar?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8), const Text('Crie personagens, escreva conversas e dê vida ao seu próprio universo.',
          style: TextStyle(color: FanColors.muted, height: 1.6)),
        const SizedBox(height: 18), OutlinedButton.icon(onPressed: onCreate,
          icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Conhecer o estúdio')),
      ]))),
    ]);
  }
}
class _Featured extends StatelessWidget {
  const _Featured({required this.story, required this.onTap});
  final FanStory story;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    final wide = box.maxWidth > 650;
    final text = Padding(padding: EdgeInsets.all(wide ? 32 : 24), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(Icons.auto_awesome_rounded, size: 16, color: FanColors.orchid),
        SizedBox(width: 8), Text('EM DESTAQUE', style: TextStyle(fontSize: 11, letterSpacing: 2,
          color: FanColors.orchid, fontWeight: FontWeight.w700))]),
      const SizedBox(height: 20), Text(story.title, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 14), Text(story.description, maxLines: 3, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15, color: FanColors.muted, height: 1.7)),
      const SizedBox(height: 18), Text('${story.category}  ·  ${story.episodeCount} episódios  ·  ${story.contentRating}',
        style: const TextStyle(color: FanColors.orchid, fontSize: 12)),
      const SizedBox(height: 24), SizedBox(width: 220,
        child: FanButton(label: 'Conhecer história', icon: Icons.arrow_forward_rounded, onPressed: onTap)),
    ]));
    return ClipRRect(borderRadius: BorderRadius.circular(24), child: Container(
      decoration: BoxDecoration(color: FanColors.surface, border: Border.all(color: FanColors.line),
        borderRadius: BorderRadius.circular(24)),
      child: wide ? Row(children: [Expanded(flex: 3, child: text),
        Expanded(flex: 2, child: SizedBox(height: 360, child: FanArtwork(story: story)))])
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(height: 190, child: FanArtwork(story: story)), text])));
  });
}
