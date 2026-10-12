import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../models/fan_models.dart';
import '../widgets/fan_widgets.dart';
import 'details_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({
    super.key,
    this.initialCategory = 'Todos',
    this.requestId = 0,
  });
  final String initialCategory;
  final int requestId;
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final search = TextEditingController();
  late String category;
  String sort = 'Recomendadas';
  String rating = 'Todas';
  String format = 'Todos';
  @override
  void initState() {
    super.initState();
    category = widget.initialCategory;
  }

  @override
  void didUpdateWidget(ExplorePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestId != widget.requestId) {
      category = widget.initialCategory;
      search.clear();
      rating = 'Todas';
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  String normalize(String value) {
    var text = value.toLowerCase().trim();
    const accents = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ç': 'c',
    };
    accents.forEach((a, b) => text = text.replaceAll(a, b));
    return text;
  }

  void reset() => setState(() {
    search.clear();
    category = 'Todos';
    rating = 'Todas';
    sort = 'Recomendadas';
    format = 'Todos';
  });
  @override
  Widget build(BuildContext context) {
    final list = FanScope.of(context).stories
        .where(
          (s) =>
              (category == 'Todos' || s.category == category) &&
              (format == 'Todos' ||
                  (format == 'Chats' && s.format == StoryFormat.chat) ||
                  (format == 'Capítulos' && s.format == StoryFormat.chapter)) &&
              (rating == 'Todas' || s.contentRating == rating) &&
              normalize(
                '${s.title} ${s.authorName} ${s.description} ${s.category}',
              ).contains(normalize(search.text)),
        )
        .toList();
    if (sort == 'Título A–Z') {
      list.sort((a, b) => normalize(a.title).compareTo(normalize(b.title)));
    }
    if (sort == 'Mais partes') {
      list.sort((a, b) => b.episodeCount.compareTo(a.episodeCount));
    }
    return ListView(
      padding: fanPagePadding(context),
      children: [
        const FanPageHeader(
          eyebrow: 'Descobrir',
          title: 'Encontre seu próximo universo.',
          subtitle:
              'Do romance ao mistério, há uma conversa esperando por você.',
        ),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Busque por título, autor ou assunto',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpar busca',
                    onPressed: () => setState(search.clear),
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Todos', 'Chats', 'Capítulos']
              .map(
                (f) => FanTag(
                  f,
                  selected: format == f,
                  icon: f == 'Capítulos'
                      ? Icons.menu_book_rounded
                      : Icons.forum_outlined,
                  onTap: () => setState(() => format = f),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Todos', ...storyCategories]
              .map(
                (c) => FanTag(
                  c,
                  selected: category == c,
                  onTap: () => setState(() => category = c),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${list.length} ${list.length == 1 ? 'história' : 'histórias'}',
              style: const TextStyle(color: FanColors.muted),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: sort,
                decoration: const InputDecoration(
                  labelText: 'Ordenar',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: ['Recomendadas', 'Título A–Z', 'Mais partes']
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => sort = v ?? sort),
              ),
            ),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: rating,
                decoration: const InputDecoration(
                  labelText: 'Classificação',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: ['Todas', ...contentRatings]
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 12)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => rating = v ?? rating),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (list.isEmpty)
          FanEmptyState(
            icon: Icons.search_off_rounded,
            title: 'Ainda não encontramos essa história.',
            message: 'Tente outro título, autor ou categoria.',
            actionLabel: 'Limpar filtros',
            onAction: reset,
          )
        else
          LayoutBuilder(
            builder: (context, box) {
              final cols = box.maxWidth > 850
                  ? 4
                  : box.maxWidth > 540
                  ? 3
                  : 2;
              final width = (box.maxWidth - (cols - 1) * 18) / cols;
              return Wrap(
                spacing: 18,
                runSpacing: 28,
                children: list
                    .map(
                      (s) => SizedBox(
                        width: width,
                        child: FanStoryCard(
                          story: s,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailsPage(story: s),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }
}
