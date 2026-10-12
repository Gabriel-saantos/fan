import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../data/fan_store.dart';
import '../../models/fan_models.dart';
import '../../models/reader_session.dart';
import '../widgets/fan_widgets.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({
    super.key,
    required this.story,
    this.startIndex,
    this.previewEpisodes,
  });
  final FanStory story;
  final int? startIndex;
  final List<FanEpisode>? previewEpisodes;
  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late FanStore store;
  List<FanEpisode> episodes = [];
  ReaderSession? session;
  int index = 0;
  bool requested = false, loading = true, auto = false, finishing = false;
  String? error, saveError;
  bool typing = false;
  String typingSpeaker = '';
  @override
  void initState() {
    super.initState();
    auto = widget.previewEpisodes == null;
  }

  final scroll = ScrollController();
  Timer? timer;
  Future<void> writes = Future.value();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!requested) {
      requested = true;
      store = FanScope.of(context);
      load();
    }
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result =
          widget.previewEpisodes ?? await store.loadEpisodes(widget.story.id);
      if (!mounted) return;
      final progress = store.libraryOf(widget.story.id);
      var target = widget.startIndex ?? 0;
      if (widget.startIndex == null && !progress.completed) {
        final savedIndex = result.indexWhere(
          (e) => e.id == progress.currentEpisodeId,
        );
        target = savedIndex >= 0 ? savedIndex : progress.episodeIndex;
      }
      index = result.isEmpty ? 0 : target.clamp(0, result.length - 1).toInt();
      episodes = result;
      session = result.isEmpty
          ? null
          : ReaderSession(
              result[index],
              revealFirst: widget.previewEpisodes != null,
              visibleCount:
                  widget.startIndex == null &&
                      !progress.completed &&
                      progress.currentEpisodeId == result[index].id
                  ? progress.visibleCount
                  : 0,
              answers:
                  widget.startIndex == null &&
                      !progress.completed &&
                      progress.currentEpisodeId == result[index].id
                  ? progress.answers
                  : const {},
            );
      setState(() => loading = false);
      queueSave();
      bottom();
      if (auto) scheduleNext();
    } catch (e) {
      if (mounted) {
        setState(() {
          error = fanError(e);
          loading = false;
        });
      }
    }
  }

  Future<void> queueSave() {
    final s = session;
    if (s == null || !store.signedIn || widget.previewEpisodes != null) {
      return Future.value();
    }
    final episodeId = s.episode.id, visible = s.cursor;
    final answers = Map<String, String>.of(s.answers);
    final completedEpisodes = s.finished ? index + 1 : null;
    final complete = s.finished && index == episodes.length - 1;
    writes = writes
        .then(
          (_) => store.saveReading(
            widget.story.id,
            episodeId,
            visible,
            answers,
            completedEpisodes: completedEpisodes,
            completed: complete,
          ),
        )
        .then((_) {
          if (mounted && saveError != null) setState(() => saveError = null);
        })
        .catchError((Object _) {
          if (mounted) {
            setState(
              () => saveError =
                  'Seu progresso ainda não foi salvo. Toque para tentar novamente.',
            );
          }
        });
    return writes;
  }

  void bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || !scroll.hasClients) return;
    if (store.reduceMotion || MediaQuery.disableAnimationsOf(context)) {
      scroll.jumpTo(scroll.position.maxScrollExtent);
    } else {
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    }
  });
  void advance() {
    if (typing) {
      reveal();
    } else {
      beginTyping();
    }
  }

  void beginTyping() {
    final s = session;
    if (!mounted ||
        s == null ||
        typing ||
        s.pendingChoice != null ||
        s.finished) {
      return;
    }
    timer?.cancel();
    final line = s.episode.lines[s.cursor];
    setState(() {
      typing = true;
      typingSpeaker = line.speaker;
    });
    bottom();
    final delay = store.reduceMotion
        ? 300
        : (500 + line.text.length * 17).clamp(650, 1950).toInt();
    timer = Timer(Duration(milliseconds: delay), reveal);
  }

  void reveal() {
    timer?.cancel();
    if (!mounted || session == null) return;
    setState(() {
      typing = false;
      session!.advance();
    });
    queueSave();
    bottom();
    if (session!.finished) {
      timer?.cancel();
    } else if (auto) {
      scheduleNext();
    }
  }

  void scheduleNext() {
    timer?.cancel();
    if (auto && session?.pendingChoice == null && session?.finished == false) {
      timer = Timer(const Duration(milliseconds: 620), beginTyping);
    }
  }

  void choose(String value) {
    session!.choose(value);
    setState(() {});
    queueSave();
    bottom();
    if (session!.finished) {
      timer?.cancel();
    } else if (auto) {
      scheduleNext();
    }
  }

  void stopAuto() {
    timer?.cancel();
    if (mounted) {
      setState(() {
        auto = false;
        typing = false;
      });
    }
  }

  void toggleAuto() {
    if (auto) {
      stopAuto();
      return;
    }
    setState(() => auto = true);
    scheduleNext();
  }

  Future<void> next() async {
    if (finishing || session?.finished != true) return;
    setState(() => finishing = true);
    final continueAuto = auto;
    stopAuto();
    await queueSave();
    if (!mounted) return;
    if (index + 1 == episodes.length) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.auto_awesome_rounded,
            color: FanColors.orchid,
            size: 36,
          ),
          title: const Text('Um universo inteiro vivido.'),
          content: Text(
            'Você concluiu ${widget.story.title}. Que tal descobrir a próxima história?',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Voltar à história'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } else {
      setState(() {
        index++;
        session = ReaderSession(
          episodes[index],
          revealFirst: widget.previewEpisodes != null,
        );
        finishing = false;
        auto = continueAuto;
      });
      if (scroll.hasClients) scroll.jumpTo(0);
      queueSave();
      if (auto) scheduleNext();
    }
  }

  Future<void> selectEpisode() async {
    stopAuto();
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Episódios',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ...List.generate(
                episodes.length,
                (i) => ListTile(
                  selected: i == index,
                  leading: Text(
                    '${i + 1}',
                    style: const TextStyle(color: FanColors.orchid),
                  ),
                  title: Text(episodes[i].title),
                  trailing: i == index
                      ? const Icon(Icons.equalizer_rounded)
                      : null,
                  onTap: () => Navigator.pop(context, i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await queueSave();
    if (!mounted) return;
    setState(() {
      index = selected;
      session = ReaderSession(episodes[index]);
    });
    queueSave();
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  Future<void> restart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar episódio?'),
        content: const Text('As escolhas deste episódio serão reiniciadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    stopAuto();
    setState(() => session = ReaderSession(episodes[index]));
    queueSave();
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void settings() => showModalBottomSheet<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Uma leitura do seu jeito',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              Text('Tamanho do texto · ${store.readerFontSize.round()}'),
              Slider(
                value: store.readerFontSize,
                min: 14,
                max: 22,
                divisions: 4,
                onChanged: (v) {
                  update(() => store.readerFontSize = v);
                  setState(() {});
                },
                onChangeEnd: (v) => store.setReadingPreferences(fontSize: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reduzir animações'),
                subtitle: const Text(
                  'Movimentos mais suaves durante a leitura.',
                ),
                value: store.reduceMotion,
                onChanged: (v) {
                  store.setReadingPreferences(reducedMotion: v);
                  update(() {});
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  void dispose() {
    timer?.cancel();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = session;
    final lines = s?.revealed ?? [];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.previewEpisodes != null
                  ? 'Prévia · ${widget.story.title}'
                  : widget.story.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              s == null
                  ? 'Seu próximo capítulo'
                  : '${index + 1}/${episodes.length} · ${s.episode.title}',
              style: const TextStyle(fontSize: 12, color: FanColors.muted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ajustar leitura',
            onPressed: settings,
            icon: const Icon(Icons.text_fields_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'episodes' ? selectEpisode() : restart(),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'episodes',
                child: Text('Escolher episódio'),
              ),
              PopupMenuItem(
                value: 'restart',
                child: Text('Reiniciar episódio'),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: s?.progress ?? 0,
            minHeight: 3,
            color: FanColors.purple,
            backgroundColor: FanColors.line,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: FanEmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'A conversa não carregou.',
                    message: error!,
                    actionLabel: 'Tentar novamente',
                    onAction: load,
                  ),
                )
              : s == null
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: FanEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Esta conversa ainda está sendo escrita.',
                    message: 'Volte mais tarde para encontrar novos episódios.',
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: scroll,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                        children: [
                          Center(
                            child: FanTag(
                              'Episódio ${index + 1} · ${s.episode.title}',
                            ),
                          ),
                          const SizedBox(height: 28),
                          ...lines.map(
                            (line) => _ChatBubble(
                              line: line,
                              fontSize: store.readerFontSize,
                              answer: s.answers[line.answerKey],
                            ),
                          ),
                          if (typing)
                            TypingBubble(
                              speaker: typingSpeaker,
                              animate:
                                  !store.reduceMotion &&
                                  !MediaQuery.disableAnimationsOf(context),
                            ),
                          if (s.pendingChoice != null) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Como você responde?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: FanColors.orchid,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...s.pendingChoice!.options.map(
                              (value) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: OutlinedButton(
                                  onPressed: () => choose(value),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      value,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (s.finished)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Fim do episódio',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: FanColors.muted),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (saveError != null)
                      TextButton.icon(
                        onPressed: queueSave,
                        icon: const Icon(Icons.sync_problem_rounded),
                        label: Text(saveError!, textAlign: TextAlign.center),
                      ),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: FanColors.surface,
                        border: Border(top: BorderSide(color: FanColors.line)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            Expanded(
                              child: FanButton(
                                label: s.finished
                                    ? (index == episodes.length - 1
                                          ? 'Concluir história'
                                          : 'Próximo episódio')
                                    : s.pendingChoice != null
                                    ? 'Escolha uma resposta acima'
                                    : typing
                                    ? 'Mostrar mensagem agora'
                                    : 'Próxima mensagem',
                                loading: finishing,
                                icon: s.finished
                                    ? Icons.arrow_forward_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                onPressed: s.pendingChoice != null
                                    ? null
                                    : s.finished
                                    ? next
                                    : advance,
                              ),
                            ),
                            if (!s.finished) ...[
                              const SizedBox(width: 10),
                              IconButton.filledTonal(
                                tooltip: auto
                                    ? 'Pausar leitura automática'
                                    : 'Leitura automática',
                                onPressed: toggleAuto,
                                icon: Icon(
                                  auto
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.line, required this.fontSize, this.answer});
  final ChatLine line;
  final double fontSize;
  final String? answer;
  @override
  Widget build(BuildContext context) {
    final outgoing = line.speaker == 'Você',
        narrator = line.speaker == 'Narrador';
    if (narrator) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Text(
          line.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize - 1,
            height: 1.8,
            fontStyle: FontStyle.italic,
            color: FanColors.muted,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: outgoing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            line.speaker,
            style: const TextStyle(
              fontSize: 12,
              color: FanColors.orchid,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Align(
          alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            margin: EdgeInsets.only(
              bottom: 22,
              left: outgoing ? 36 : 0,
              right: outgoing ? 0 : 36,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              color: outgoing ? const Color(0xFF493866) : FanColors.surface2,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(outgoing ? 18 : 4),
                bottomRight: Radius.circular(outgoing ? 4 : 18),
              ),
            ),
            child: SelectableText(
              line.text,
              style: TextStyle(fontSize: fontSize, height: 1.65),
            ),
          ),
        ),
        if (answer != null)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FanColors.purple.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                answer!,
                style: TextStyle(fontSize: fontSize, color: FanColors.orchid),
              ),
            ),
          ),
      ],
    );
  }
}

class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key, required this.speaker, this.animate = true});
  final bool animate;
  final String speaker;

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.speaker} está digitando...',
            style: const TextStyle(color: FanColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: FanColors.surface2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final phase = ((_controller.value - i * 0.2) % 1.0);
                  final active = phase < 0.33;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Transform.translate(
                      offset: Offset(0, active ? -2.5 : 0),
                      child: CircleAvatar(
                        radius: 3.4,
                        backgroundColor: FanColors.orchid.withValues(
                          alpha: active ? 1 : 0.35,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
