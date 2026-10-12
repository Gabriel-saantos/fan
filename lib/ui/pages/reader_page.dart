import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../models/fan_models.dart';
import '../widgets/fan_widgets.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.story, this.startIndex = 0});
  final FanStory story;
  final int startIndex;
  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  List<FanEpisode>? episodes;
  String? failure;
  late int index;
  int visible = 1;
  final Map<String, String> answers = {};
  final ScrollController scroll = ScrollController();
  bool _requested = false;

  @override
  void initState() { super.initState(); index = widget.startIndex; }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested) { _requested = true; _load(); }
  }

  Future<void> _load() async {
    try {
      final result = await FanScope.of(context).loadEpisodes(widget.story.id);
      if (mounted) setState(() { episodes = result; index = result.isEmpty ? 0 : index.clamp(0, result.length - 1).toInt(); });
    } catch (e) { if (mounted) setState(() => failure = '$e'); }
  }

  @override
  void dispose() { scroll.dispose(); super.dispose(); }

  FanEpisode? get current => episodes == null || episodes!.isEmpty ? null : episodes![index];
  void bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 360), curve: Curves.easeOut);
  });

  Future<void> advance() async {
    final ep = current;
    if (ep == null || visible >= ep.lines.length) return;
    final last = ep.lines[visible - 1];
    if (last.options.isNotEmpty && !answers.containsKey(last.choiceId ?? last.id)) {
      fanMessage(context, 'Escolha uma resposta para continuar.'); return;
    }
    setState(() => visible += 1);
    bottom();
    if (visible >= ep.lines.length) await _recordProgress();
  }

  Future<void> _recordProgress() async {
    final store = FanScope.of(context);
    if (!store.signedIn) return;
    try { await store.updateLibrary(widget.story.id, episodeIndex: index + 1); }
    catch (_) { /* Keep reading even when offline. */ }
  }

  Future<void> next() async {
    await _recordProgress();
    if (!mounted) return;
    if (index + 1 >= (episodes?.length ?? 0)) {
      showDialog<void>(context: context, builder: (_) => AlertDialog(
        title: const Text('Você chegou ao fim ✨'),
        content: const Text('Mais uma história para guardar no coração. Explore outros universos!'),
        actions: [TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); },
          child: const Text('Concluir'))],
      ));
    } else {
      setState(() { index++; visible = 1; answers.clear(); });
      if (scroll.hasClients) scroll.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapter = current;
    final finished = chapter != null && visible >= chapter.lines.length;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.story.title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          Text(chapter == null ? 'Carregando...' : 'Episódio ${index + 1} de ${episodes!.length} · ${chapter.title}',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5, color: FanColors.muted)),
        ]),
        actions: [
          IconButton(tooltip: sound ? 'Desativar som' : 'Som indisponível nesta versão',
            onPressed: () => fanMessage(context, 'Leitura silenciosa: áudio pode ser habilitado em uma atualização.'),
            icon: const Icon(Icons.volume_off_outlined, color: FanColors.muted)),
          PopupMenuButton<String>(onSelected: (v) {
            if (v == 'restart') setState(() { visible = 1; answers.clear(); });
          }, itemBuilder: (_) => const [PopupMenuItem(value: 'restart', child: Text('Reiniciar episódio'))]),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(3), child: LinearProgressIndicator(
          value: chapter == null || chapter.lines.isEmpty ? 0 : visible / chapter.lines.length,
          minHeight: 3, backgroundColor: FanColors.surface2, color: FanColors.orchid)),
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 730), child:
        chapter == null
          ? Center(child: failure == null ? const CircularProgressIndicator() : Text('Erro: $failure'))
          : Column(children: [
              Expanded(child: Container(
                decoration: const BoxDecoration(image: DecorationImage(
                  image: AssetImage('assets/backgrounds/stars.webp'), fit: BoxFit.cover, opacity: .20)),
                child: ListView.builder(
                  controller: scroll, padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  itemCount: visible.clamp(0, chapter.lines.length),
                  itemBuilder: (context, i) {
                    final line = chapter.lines[i];
                    if (line.requires != null && !answers.values.contains(line.requires)) {
                      return const SizedBox.shrink();
                    }
                    final outgoing = line.speaker == 'Você';
                    return Column(crossAxisAlignment: outgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Padding(padding: EdgeInsets.only(left: outgoing ? 55 : 0, right: outgoing ? 0 : 55),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (!outgoing) CircleAvatar(radius: 12, backgroundColor: FanColors.surface2,
                              child: Text(line.speaker.isEmpty ? '?' : line.speaker[0],
                                style: const TextStyle(color: FanColors.orchid, fontSize: 10))),
                            const SizedBox(width: 7),
                            Text(line.speaker, style: const TextStyle(fontSize: 10.5,
                              color: FanColors.muted, fontWeight: FontWeight.w700)),
                          ])),
                        const SizedBox(height: 6),
                        Align(alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 14, left: outgoing ? 48 : 8, right: outgoing ? 8 : 48),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                            decoration: BoxDecoration(
                              color: outgoing ? FanColors.purple : FanColors.surface2,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(17), topRight: const Radius.circular(17),
                                bottomLeft: Radius.circular(outgoing ? 17 : 5),
                                bottomRight: Radius.circular(outgoing ? 5 : 17)),
                              border: Border.all(color: outgoing ? FanColors.purple : FanColors.line)),
                            child: Text(line.text, style: const TextStyle(fontSize: 12.5, height: 1.6)),
                          )),
                        if (line.options.isNotEmpty) ...[
                          if (answers.containsKey(line.choiceId ?? line.id))
                            Align(alignment: Alignment.centerRight, child: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: FanTag('Você: ${answers[line.choiceId ?? line.id]!}', selected: true)))
                          else if (i == visible - 1)
                            ...line.options.map((choice) => Padding(
                              padding: const EdgeInsets.only(bottom: 9, left: 38),
                              child: SizedBox(width: double.infinity, child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: FanColors.pink, side: const BorderSide(color: FanColors.purple),
                                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15)),
                                onPressed: () {
                                  setState(() => answers[line.choiceId ?? line.id] = choice);
                                  bottom();
                                },
                                child: Text(choice, style: const TextStyle(fontSize: 11)),
                              )),
                            )),
                        ],
                      ],
                    );
                  },
                ),
              )),
              Container(padding: const EdgeInsets.fromLTRB(16, 11, 16, 15),
                decoration: const BoxDecoration(color: FanColors.surface,
                  border: Border(top: BorderSide(color: FanColors.line))),
                child: SafeArea(top: false, child: Column(children: [
                  if (!finished) ...[
                    const Text('Toque para revelar a próxima mensagem',
                      style: TextStyle(fontSize: 10, color: FanColors.muted)),
                    const SizedBox(height: 9),
                  ],
                  FanButton(label: finished ? (index + 1 < episodes!.length
                    ? 'Próximo episódio' : 'Concluir história') : 'Continuar conversa',
                    icon: finished ? Icons.auto_awesome : Icons.keyboard_arrow_down_rounded,
                    onPressed: finished ? next : advance),
                ])),
              ),
            ]),
      )),
    );
  }
}
