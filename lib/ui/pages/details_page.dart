import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../models/fan_models.dart';
import '../widgets/fan_widgets.dart';
import 'auth_page.dart';
import 'reader_page.dart';
import 'chapter_reader_page.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key, required this.story});
  final FanStory story;
  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  Future<List<Object>>? future;
  bool busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    future ??= loadSections();
  }

  Future<List<Object>> loadSections() async {
    final store = FanScope.of(context);
    return widget.story.format == StoryFormat.chat
        ? await store.loadEpisodes(widget.story.id)
        : await store.loadChapters(widget.story.id);
  }

  Future<void> save({bool like = false}) async {
    if (busy || !await requireFanLogin(context) || !mounted) return;
    setState(() => busy = true);
    final store = FanScope.of(context),
        state = FanScope.of(context).libraryOf(widget.story.id);
    try {
      await store.updateLibrary(
        widget.story.id,
        saved: like ? null : !state.saved,
        liked: like ? !state.liked : null,
      );
    } catch (e) {
      if (mounted) fanMessage(context, fanError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> follow() async {
    if (busy || !await requireFanLogin(context) || !mounted) return;
    setState(() => busy = true);
    try {
      await FanScope.of(context).toggleFollow(widget.story.authorId);
    } catch (e) {
      if (mounted) fanMessage(context, fanError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> report() async {
    if (!await requireFanLogin(context) || !mounted) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Denunciar história'),
        children: [
          for (final r in [
            'Conteúdo impróprio',
            'Assédio ou discurso de ódio',
            'Plágio',
            'Outro motivo',
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, r),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(r),
              ),
            ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    try {
      await FanScope.of(context).reportStory(widget.story.id, reason);
      if (mounted) fanMessage(context, 'Denúncia enviada para revisão.');
    } catch (e) {
      if (mounted) fanMessage(context, fanError(e));
    }
  }

  void read({int? index}) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => widget.story.format == StoryFormat.chat
          ? ReaderPage(story: widget.story, startIndex: index)
          : ChapterReaderPage(story: widget.story, startIndex: index),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final store = FanScope.of(context);
    final story = store.storyById(widget.story.id) ?? widget.story;
    final state = store.libraryOf(story.id);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: state.liked ? 'Remover curtida' : 'Curtir história',
            onPressed: busy ? null : () => save(like: true),
            icon: Icon(
              state.liked
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              color: FanColors.pink,
            ),
          ),
          if (store.hasCloud && !story.isDemo)
            PopupMenuButton<String>(
              onSelected: (_) => report(),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'report',
                  child: Text('Denunciar história'),
                ),
              ],
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: ListView(
            padding: fanPagePadding(context),
            children: [
              LayoutBuilder(
                builder: (context, box) {
                  final wide = box.maxWidth > 700;
                  final artwork = Center(
                    child: FanCover(
                      story: story,
                      width: wide ? 280 : 210,
                      height: wide ? 370 : 275,
                    ),
                  );
                  final summary = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FanTag(story.category, selected: true),
                          FanTag(story.contentRating),
                          FanTag(story.format.label),
                          if (story.isDemo) const FanTag('História de exemplo'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        story.title,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: FanColors.surface2,
                            child: Text(
                              story.authorName.isEmpty
                                  ? 'F'
                                  : story.authorName[0].toUpperCase(),
                              style: const TextStyle(color: FanColors.orchid),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story.authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Text(
                                  'Autor da história',
                                  style: TextStyle(
                                    color: FanColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (story.authorId != store.uid)
                            TextButton(
                              onPressed: busy ? null : follow,
                              child: Text(
                                store.follows(story.authorId)
                                    ? 'Seguindo'
                                    : 'Seguir',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        story.description,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.8,
                          color: FanColors.muted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${story.episodeCount} ${story.format.unit} · ${story.format.label}',
                        style: const TextStyle(
                          color: FanColors.orchid,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FanButton(
                        label: state.completed
                            ? 'Ler novamente'
                            : state.started
                            ? 'Continuar leitura'
                            : 'Começar a ler',
                        icon: Icons.play_arrow_rounded,
                        onPressed: story.episodeCount == 0
                            ? null
                            : () => read(),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: busy ? null : save,
                          icon: Icon(
                            state.saved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                          ),
                          label: Text(
                            state.saved
                                ? 'Salvo na biblioteca'
                                : 'Salvar na biblioteca',
                          ),
                        ),
                      ),
                    ],
                  );
                  return wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            artwork,
                            const SizedBox(width: 40),
                            Expanded(child: summary),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            artwork,
                            const SizedBox(height: 28),
                            summary,
                          ],
                        );
                },
              ),
              const SizedBox(height: 40),
              FanSectionHeading(
                title: story.format == StoryFormat.chat
                    ? 'Episódios'
                    : 'Capítulos',
              ),
              FutureBuilder<List<Object>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return FanEmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Não foi possível carregar os episódios.',
                      message: 'Confira a conexão e tente novamente.',
                      actionLabel: 'Tentar novamente',
                      onAction: () => setState(() => future = loadSections()),
                    );
                  }
                  final episodes = snapshot.data ?? [];
                  if (episodes.isEmpty) {
                    return const FanEmptyState(
                      icon: Icons.edit_note_rounded,
                      title: 'Novos capítulos estão a caminho.',
                      message: 'Esta história ainda não tem episódios.',
                    );
                  }
                  return Column(
                    children: List.generate(
                      episodes.length,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: FanColors.surface2,
                              child: i < state.episodeIndex
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: FanColors.success,
                                    )
                                  : Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        color: FanColors.orchid,
                                      ),
                                    ),
                            ),
                            title: Text(
                              episodes[i] is FanEpisode
                                  ? (episodes[i] as FanEpisode).title
                                  : (episodes[i] as FanChapter).title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              episodes[i] is FanEpisode
                                  ? '${(episodes[i] as FanEpisode).lines.length} mensagens'
                                  : '${(episodes[i] as FanChapter).paragraphs.length} parágrafos',
                              style: const TextStyle(
                                color: FanColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.play_arrow_rounded,
                              color: FanColors.orchid,
                            ),
                            onTap: () => read(index: i),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
