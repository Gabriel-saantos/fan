import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../widgets/fan_widgets.dart';
import 'details_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String term = '';
  String category = 'Todos';
  static const categories = ['Todos', 'Romance', 'Fantasia', 'Mistério', 'Drama', 'Terror', 'Comédia'];

  @override
  Widget build(BuildContext context) {
    final stories = FanScope.of(context).stories.where((s) {
      return (category == 'Todos' || category == s.category) &&
        ('${s.title} ${s.authorName} ${s.description}'.toLowerCase().contains(term.toLowerCase()));
    }).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(20, 23, 20, 26), children: [
      const Text('Explorar', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: -1)),
      const SizedBox(height: 7),
      const Text('Mundos incríveis esperam por você.', style: TextStyle(color: FanColors.muted, fontSize: 12)),
      const SizedBox(height: 23),
      TextField(onChanged: (text) => setState(() => term = text),
        decoration: const InputDecoration(hintText: 'Buscar histórias, autores, universos...',
          prefixIcon: Icon(Icons.search_rounded, color: FanColors.orchid))),
      const SizedBox(height: 16),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children:
        categories.map((c) => Padding(padding: const EdgeInsets.only(right: 7),
          child: FanTag(c, selected: category == c, onTap: () => setState(() => category = c)))).toList(),
      )),
      const SizedBox(height: 20),
      Text('${stories.length} histórias encontradas',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: FanColors.muted)),
      const SizedBox(height: 12),
      if (stories.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text('Nenhuma história com esses filtros.',
          style: TextStyle(color: FanColors.muted))))
      else LayoutBuilder(builder: (context, constraints) {
        final cols = constraints.maxWidth > 700 ? 4 : (constraints.maxWidth > 440 ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: stories.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .68),
          itemBuilder: (context, i) => LayoutBuilder(builder: (context, box) => FanCover(
            story: stories[i], width: box.maxWidth, height: box.maxHeight,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(story: stories[i]))),
          )),
        );
      }),
    ]);
  }
}
