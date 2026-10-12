import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../data/fan_store.dart';
import '../../models/fan_models.dart';
import '../widgets/fan_widgets.dart';

/// Text reader with typography controls and persisted per-chapter progress.
class ChapterReaderPage extends StatefulWidget {
  const ChapterReaderPage({super.key, required this.story, this.startIndex});
  final FanStory story;
  final int? startIndex;

  @override
  State<ChapterReaderPage> createState() => _ChapterReaderPageState();
}

class _ChapterReaderPageState extends State<ChapterReaderPage> {
  final ScrollController _scroll = ScrollController();
  late FanStore _store;
  List<FanChapter>? _chapters;
  String? _error;
  late int _index;
  bool _loaded = false;
  bool _restoringScroll = false;
  double _progress = 0;
  double _fontSize = 17;
  String _theme = 'dark';
  Timer? _debounce;
  bool _switching = false;
  String? _saveError;
  Future<void> _writes = Future.value();

  FanChapter? get _current => _chapters == null || _chapters!.isEmpty
      ? null : _chapters![_index];
  Color get _paper => switch (_theme) {
    'sepia' => const Color(0xFFF2E8D6),
    'light' => const Color(0xFFFAF9F6),
    _ => FanColors.background,
  };
  Color get _ink => _theme == 'dark' ? FanColors.ink : const Color(0xFF29202B);
  Color get _secondary => _theme == 'dark' ? FanColors.muted : const Color(0xFF746B76);

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex ?? 0;
    _scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _store = FanScope.of(context);
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final chapters = await _store.loadChapters(widget.story.id);
      if (!mounted) return;
      final saved = _store.libraryOf(widget.story.id);
      final target = widget.startIndex ?? (saved.completed ? 0 : saved.chapterIndex);
      setState(() {
        _error = null;
        _chapters = chapters;
        _index = chapters.isEmpty ? 0 : target.clamp(0, chapters.length - 1).toInt();
        _progress = !saved.completed && saved.chapterIndex == _index ? saved.chapterProgress : 0;
      });
      _restoringScroll = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent * _progress);
        }
        _restoringScroll = false;
        _onScroll();
      });
    } catch (error) {
      if (mounted) setState(() => _error = fanError(error));
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients || _restoringScroll || _current == null) return;
    final max = _scroll.position.maxScrollExtent;
    final percent = max <= 0 ? 1.0 : (_scroll.offset / max).clamp(0.0, 1.0).toDouble();
    if ((_progress - percent).abs() > 0.005 && mounted) {
      setState(() => _progress = percent);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 900), _saveScroll);
  }

  Future<void> _saveScroll() {
    if (!_loaded || !_store.signedIn || _current == null || _switching) return Future.value();
    final index = _index, progress = _progress;
    _writes = _writes.then((_) => _store.saveChapterReading(widget.story.id,
      chapterIndex: index, chapterProgress: progress)).then((_) {
        if (mounted && _saveError != null) setState(() => _saveError = null);
      }).catchError((Object _) {
        if (mounted) setState(() => _saveError = 'Não foi possível salvar a posição. Tente novamente.');
      });
    return _writes;
  }

  Future<void> _nextChapter() async {
    if (_switching || _current == null) return;
    _debounce?.cancel();
    setState(() => _switching = true);
    final last = _index + 1 >= _chapters!.length;
    try {
      await _writes;
      if (_store.signedIn) {
        await _store.saveChapterReading(widget.story.id,
          chapterIndex: last ? _index : _index + 1, chapterProgress: last ? 1 : 0,
          completedEpisodes: _index + 1, completed: last);
      }
      if (!mounted) return;
      if (last) {
        await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
          title: const Text('Leitura concluída 💜'),
          content: const Text('Você terminou todos os capítulos publicados!'),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Voltar à história'))],
        ));
        if (mounted) Navigator.pop(context);
      } else {
        setState(() { _index++; _progress = 0; _switching = false; });
        _restoringScroll = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_scroll.hasClients) _scroll.jumpTo(0);
          _restoringScroll = false;
          _onScroll();
        });
      }
    } catch (error) {
      if (mounted) { setState(() => _switching = false); fanMessage(context, fanError(error)); }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _saveScroll();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapter = _current;
    final accent = _theme == 'dark' ? FanColors.orchid : const Color(0xFF8244AB);
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _ink,
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.story.title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _ink, fontSize: 14, fontWeight: FontWeight.w800)),
          Text(chapter == null ? 'Carregando...' : 'Capítulo ${_index + 1} de ${_chapters!.length}',
            style: TextStyle(color: _secondary, fontSize: 10)),
        ]),
        actions: [
          IconButton(tooltip: 'Diminuir fonte', icon: const Icon(Icons.text_decrease_rounded),
            onPressed: () => setState(() => _fontSize = (_fontSize - 1).clamp(14, 25).toDouble())),
          IconButton(tooltip: 'Aumentar fonte', icon: const Icon(Icons.text_increase_rounded),
            onPressed: () => setState(() => _fontSize = (_fontSize + 1).clamp(14, 25).toDouble())),
          PopupMenuButton<String>(
            tooltip: 'Tema da leitura',
            icon: const Icon(Icons.palette_outlined),
            onSelected: (theme) => setState(() => _theme = theme),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'dark', child: Text('Escuro')),
              PopupMenuItem(value: 'sepia', child: Text('Sépia')),
              PopupMenuItem(value: 'light', child: Text('Claro')),
            ],
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(value: _progress, minHeight: 3,
            color: accent, backgroundColor: accent.withValues(alpha: 0.15))),
      ),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: chapter == null
            ? Center(child: _error != null
                ? Padding(padding: const EdgeInsets.all(24), child: FanEmptyState(
                    icon: Icons.wifi_off_rounded, title: 'Não foi possível abrir este capítulo.',
                    message: _error!, actionLabel: 'Tentar novamente', onAction: _load))
                : _chapters != null && _chapters!.isEmpty
                    ? const Text('Nenhum capítulo disponível ainda.')
                    : const CircularProgressIndicator())
            : Column(children: [
                Expanded(child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(25, 30, 25, 35),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('CAPÍTULO ${_index + 1}', style: TextStyle(
                      fontSize: 10, letterSpacing: 2, color: accent,
                      fontWeight: FontWeight.w800)),
                    const SizedBox(height: 13),
                    Text(chapter.title, style: TextStyle(
                      fontSize: 28, color: _ink, fontWeight: FontWeight.w900, height: 1.25)),
                    const SizedBox(height: 10),
                    Container(width: 46, height: 3, margin: const EdgeInsets.only(right: 250),
                      decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 33),
                    ...chapter.paragraphs.map((paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: SelectableText(paragraph, textAlign: TextAlign.start,
                        style: TextStyle(fontSize: _fontSize, height: 1.87,
                          color: _ink, letterSpacing: 0.1)),
                    )),
                    const SizedBox(height: 22),
                    Center(child: Icon(Icons.auto_awesome_rounded,
                      color: accent.withValues(alpha: 0.7), size: 25)),
                  ]),
                )),
                if (_saveError != null) TextButton(onPressed: _saveScroll,
                  child: Text(_saveError!, textAlign: TextAlign.center)),
                Container(
                  decoration: BoxDecoration(color: _paper,
                    border: Border(top: BorderSide(color: accent.withValues(alpha: 0.15)))),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: SafeArea(top: false, child: SizedBox(
                    width: double.infinity, height: 48,
                    child: FilledButton.icon(
                      onPressed: _switching ? null : _nextChapter,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(_index + 1 == _chapters!.length
                        ? 'Concluir história' : 'Próximo capítulo'),
                      style: FilledButton.styleFrom(backgroundColor: FanColors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  )),
                ),
              ]),
      )),
    );
  }
}
