import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../models/fan_models.dart';
import '../widgets/fan_widgets.dart';
import 'auth_page.dart';
import 'reader_page.dart';

class DetailsPage extends StatefulWidget {
  const DetailsPage({super.key, required this.story});
  final FanStory story;
  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  late Future<List<FanEpisode>> episodeFuture;
  @override
  void initState() {
    super.initState();
    // Access scope after didChangeDependencies.
  }
  bool loaded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded) {
      episodeFuture = FanScope.of(context).loadEpisodes(widget.story.id);
      loaded = true;
    }
  }

  Future<void> saveOrLike({bool isLike = false}) async {
    if (!await requireFanLogin(context)) return;
    if (!mounted) return;
    final store = FanScope.of(context);
    final state = store.libraryOf(widget.story.id);
    try {
      await store.updateLibrary(widget.story.id,
        liked: isLike ? !state.liked : null,
        saved: isLike ? null : !state.saved);
    } catch (e) { if (mounted) fanMessage(context, '$e'); }
  }

  Future<void> followAuthor() async {
    if (!await requireFanLogin(context)) return;
    if (!mounted) return;
    try { await FanScope.of(context).toggleFollow(widget.story.authorId); }
    catch (e) { if (mounted) fanMessage(context, '$e'); }
  }

  Future<void> reportStory() async {
    if (!await requireFanLogin(context)) return;
    if (!mounted) return;
    final reason = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Denunciar história'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final r in ['Conteúdo impróprio', 'Assédio ou discurso de ódio', 'Plágio', 'Outro motivo'])
          ListTile(title: Text(r, style: const TextStyle(fontSize: 12)),
            onTap: () => Navigator.pop(context, r)),
      ]),
    ));
    if (reason == null || !mounted) return;
    try {
      await FanScope.of(context).reportStory(widget.story.id, reason);
      if (mounted) fanMessage(context, 'Denúncia registrada para revisão.');
    } catch (e) { if (mounted) fanMessage(context, '$e'); }
  }

  @override
  Widget build(BuildContext context) {
    final store = FanScope.of(context);
    final story = widget.story;
    final lib = store.libraryOf(story.id);
    return Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: ListView(children: [
        Stack(children: [
          SizedBox(height: 270, width: double.infinity, child:
            story.coverUrl.isNotEmpty
              ? Image.network(story.coverUrl, fit: BoxFit.cover,
                  errorBuilder: (context, error, trace) => Image.asset(story.coverAsset, fit: BoxFit.cover))
              : Image.asset(story.coverAsset, fit: BoxFit.cover)),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [FanColors.background.withOpacity(.12), FanColors.background],
          )))),
          Positioned(top: 14, left: 12, child: CircleAvatar(backgroundColor: FanColors.surface.withOpacity(.87),
            child: IconButton(onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: FanColors.ink)))),
          Positioned(top: 14, right: 12, child: Row(children: [
            CircleAvatar(backgroundColor: FanColors.surface.withOpacity(.87),
              child: IconButton(onPressed: () => saveOrLike(isLike: true),
                icon: Icon(lib.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: FanColors.pink))),
            const SizedBox(width: 7),
            PopupMenuButton<String>(color: FanColors.surface2,
              icon: const Icon(Icons.more_vert), onSelected: (v) {
                if (v == 'report') reportStory();
              }, itemBuilder: (_) => const [PopupMenuItem(value: 'report', child: Text('Denunciar história'))]),
          ])),
        ]),
        Padding(padding: const EdgeInsets.fromLTRB(22, 4, 22, 25), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            FanTag(story.category, selected: true),
            const SizedBox(height: 15),
            Text(story.title, style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900, letterSpacing: -1)),
            const SizedBox(height: 18),
            Row(children: [
              CircleAvatar(radius: 18, backgroundColor: FanColors.surface2,
                child: Text(story.authorName.isEmpty ? 'F' : story.authorName[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: FanColors.orchid))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(story.authorName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                const Text('Criador de universos', style: TextStyle(color: FanColors.muted, fontSize: 10)),
              ])),
              if (story.authorId != store.uid)
                FanTag(store.follows(story.authorId) ? 'Seguindo ✓' : '+ Seguir', onTap: followAuthor),
            ]),
            const SizedBox(height: 20),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FanTag('${story.episodeCount} episódios', icon: Icons.chat_bubble_outline_rounded),
              FanTag(story.contentRating, icon: Icons.shield_outlined),
              if (story.isDemo) const FanTag('Amostra', icon: Icons.auto_awesome_rounded),
            ]),
            const SizedBox(height: 20),
            Text(story.description, style: const TextStyle(color: FanColors.muted, height: 1.8, fontSize: 12)),
            const SizedBox(height: 25),
            FanButton(label: lib.episodeIndex > 0 ? 'Continuar leitura' : 'Iniciar leitura',
              icon: Icons.play_arrow_rounded, onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ReaderPage(story: story,
                  startIndex: lib.episodeIndex >= story.episodeCount ? 0 : lib.episodeIndex)))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: saveOrLike, icon: Icon(lib.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
              label: Text(lib.saved ? 'Salvo na biblioteca' : 'Salvar na biblioteca'),
              style: OutlinedButton.styleFrom(foregroundColor: FanColors.orchid,
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: FanColors.line)))),
            const SizedBox(height: 24),
            const FanSectionHeading(title: 'Episódios'),
            FutureBuilder<List<FanEpisode>>(future: episodeFuture, builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return Text('Falha ao carregar episódios: ${snapshot.error}',
                style: const TextStyle(fontSize: 11, color: FanColors.pink));
              final chapters = snapshot.data ?? [];
              if (chapters.isEmpty) return const Text('Esta história ainda não tem episódios.',
                style: TextStyle(color: FanColors.muted, fontSize: 12));
              return Column(children: List.generate(chapters.length, (index) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: FanColors.surface2,
                  child: Text('${index + 1}', style: const TextStyle(color: FanColors.orchid, fontWeight: FontWeight.w900))),
                title: Text(chapters[index].title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                subtitle: Text('${chapters[index].lines.length} mensagens',
                  style: const TextStyle(color: FanColors.muted, fontSize: 10)),
                trailing: const Icon(Icons.chevron_right_rounded, color: FanColors.orchid),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(
                  story: story, startIndex: index))),
              )));
            }),
          ],
        )),
      ]),
    ))));
  }
}
