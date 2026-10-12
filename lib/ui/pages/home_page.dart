import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../models/fan_models.dart';
import '../widgets/fan_widgets.dart';
import 'details_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final store = FanScope.of(context);
    final stories = store.stories;
    final featured = stories.isEmpty ? null : stories.first;
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 22, 20, 13), child:
        Row(children: [
          const FanLogo(size: 35), const Spacer(),
          IconButton(onPressed: onExplore, icon: const Icon(Icons.search_rounded, size: 24)),
          const SizedBox(width: 5),
          InkWell(onTap: () => fanMessage(context, 'Novidades aparecerão aqui em breve.'),
            child: const Icon(Icons.notifications_none_rounded, size: 23)),
        ]),
      )),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 3, 20, 19), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SEU PRÓXIMO UNIVERSO', style: TextStyle(color: FanColors.orchid.withOpacity(.85),
            fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 2)),
          const SizedBox(height: 6),
          const Text('Toda grande emoção\ncomeça com uma mensagem.',
            style: TextStyle(fontWeight: FontWeight.w900, height: 1.21,
              letterSpacing: -.9, fontSize: 23)),
        ],
      ))),
      if (featured != null) SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: LayoutBuilder(builder: (context, constraints) => Stack(children: [
          FanCover(story: featured, width: constraints.maxWidth, height: 270, featured: true,
            onTap: () => _showStory(context, featured)),
          Positioned(right: 16, bottom: 20,
            child: DecoratedBox(decoration: BoxDecoration(
              gradient: FanColors.gradient, borderRadius: BorderRadius.circular(16)),
              child: IconButton(onPressed: () => _showStory(context, featured),
                icon: const Icon(Icons.play_arrow_rounded, color: FanColors.background, size: 27)))),
        ])),
      )),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 25, 20, 4), child:
        const FanSectionHeading(title: 'Explore por sentimento'))),
      SliverToBoxAdapter(child: SizedBox(height: 96, child: ListView(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20),
        children: const [
          _CategoryBox('Romance', Icons.favorite_rounded, Color(0xFFF59BCC)),
          _CategoryBox('Fantasia', Icons.auto_awesome, Color(0xFFCBA5FF)),
          _CategoryBox('Mistério', Icons.nights_stay_rounded, Color(0xFFBBB5FF)),
          _CategoryBox('Drama', Icons.theater_comedy_rounded, Color(0xFFFCBF94)),
        ],
      ))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: FanSectionHeading(title: 'Histórias para você', trailing: 'Ver todas', onTap: onExplore))),
      SliverToBoxAdapter(child: SizedBox(height: 221, child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20), scrollDirection: Axis.horizontal,
        itemCount: stories.length, separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => FanCover(story: stories[index],
          width: 151, height: 216, onTap: () => _showStory(context, stories[index])),
      ))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 25, 20, 0), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FanSectionHeading(title: 'Novos mundos para descobrir'),
          ...stories.skip(1).take(3).map((story) => FanStoryRow(
            story: story, onTap: () => _showStory(context, story))),
          const SizedBox(height: 30),
        ],
      ))),
    ]);
  }

  void _showStory(BuildContext context, FanStory story) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(story: story)));
  }
}

class _CategoryBox extends StatelessWidget {
  const _CategoryBox(this.name, this.icon, this.color);
  final String name;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 10), width: 88,
    decoration: BoxDecoration(color: FanColors.surface, borderRadius: BorderRadius.circular(17),
      border: Border.all(color: FanColors.line)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 27), const SizedBox(height: 10),
      Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
    ]),
  );
}
