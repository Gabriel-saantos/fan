import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../data/fan_store.dart';
import '../../models/fan_models.dart';
import '../widgets/fan_widgets.dart';
import 'auth_page.dart';
import 'details_page.dart';
import 'reader_page.dart';
import 'chapter_reader_page.dart';

class PublishPage extends StatelessWidget {
  const PublishPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = FanScope.of(context);
    return ListView(
      padding: fanPagePadding(context),
      children: [
        const FanPageHeader(
          eyebrow: 'Para quem cria',
          title: 'Seu estúdio de histórias.',
          subtitle:
              'Transforme uma ideia em personagens, conversas e novos universos.',
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  color: FanColors.orchid,
                  size: 36,
                ),
                const SizedBox(height: 18),
                const Text(
                  'A próxima grande história pode ser sua.',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. Apresente seu universo\n2. Escreva as conversas e escolhas\n3. Revise a prévia e publique',
                  style: TextStyle(color: FanColors.muted, height: 2),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: 260,
                  child: FanButton(
                    label: 'Criar uma história',
                    icon: Icons.add_rounded,
                    onPressed: () async {
                      if (await requireFanLogin(context) && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateStoryPage(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        FanSectionHeading(
          title: 'Minhas histórias · ${store.myStories.length}',
        ),
        if (!store.signedIn)
          const FanEmptyState(
            icon: Icons.person_outline_rounded,
            title: 'Seu estúdio começa com um perfil.',
            message:
                'Use o botão acima para entrar e criar sua primeira história.',
          )
        else if (store.myStories.isEmpty)
          const FanEmptyState(
            icon: Icons.auto_stories_outlined,
            title: 'Uma página em branco. Infinitas possibilidades.',
            message:
                'Comece com um título e uma sinopse. Sua história ficará em rascunho até você publicar.',
          )
        else
          ...store.myStories.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: FanStoryRow(
                story: s,
                subtitle:
                    '${s.published ? 'Publicada' : 'Rascunho'} · ${s.episodeCount} ${s.format.unit}',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageStoryPage(storyId: s.id),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key, this.story});
  final FanStory? story;
  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(), description = TextEditingController();
  String category = 'Romance', rating = 'Livre', asset = coverAssets.first;
  StoryFormat format = StoryFormat.chat;
  Uint8List? image;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final s = widget.story;
    if (s != null) {
      title.text = s.title;
      description.text = s.description;
      category = s.category;
      rating = s.contentRating;
      asset = s.coverAsset;
      format = s.format;
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length >= 5 * 1024 * 1024) {
        throw StateError('Escolha uma imagem menor que 5 MB.');
      }
      if (mounted &&
          FanScope.of(context).demoMode &&
          bytes.length > 512 * 1024) {
        throw StateError('No modo local, escolha uma capa de até 512 KB.');
      }
      if (mounted) setState(() => image = bytes);
    } catch (e) {
      if (mounted) fanMessage(context, fanError(e));
    }
  }

  bool replacedAsset = false;
  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final store = FanScope.of(context);
      final url = image != null
          ? await store.uploadCover(image!)
          : replacedAsset
          ? ''
          : widget.story?.coverUrl ?? '';
      if (widget.story != null) {
        await store.editStory(
          widget.story!.copyWith(
            title: title.text.trim(),
            description: description.text.trim(),
            category: category,
            contentRating: rating,
            coverAsset: asset,
            coverUrl: url,
          ),
        );
        if (mounted) Navigator.pop(context);
      } else {
        final story = await store.createStory(
          title: title.text,
          description: description.text,
          category: category,
          contentRating: rating,
          coverAsset: asset,
          coverUrl: url,
          format: format,
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ManageStoryPage(storyId: story.id),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) fanMessage(context, fanError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = FanStory(
      id: '',
      title: '',
      description: '',
      category: category,
      authorId: '',
      authorName: '',
      coverAsset: asset,
      coverUrl: replacedAsset ? '' : widget.story?.coverUrl ?? '',
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.story == null ? 'Nova história' : 'Editar história'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: fanPagePadding(context),
            children: [
              FanPageHeader(
                title: widget.story == null
                    ? 'Apresente seu universo.'
                    : 'Cada detalhe conta.',
                subtitle:
                    'Escolha uma capa e conte o que torna sua história especial.',
              ),
              Center(
                child: SizedBox(
                  width: 170,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          height: 220,
                          width: 170,
                          child: image == null
                              ? FanArtwork(story: preview)
                              : Image.memory(image!, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: saving ? null : pick,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Escolher capa'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: coverAssets
                      .map(
                        (a) => Semantics(
                          button: true,
                          label:
                              'Selecionar capa ${coverAssets.indexOf(a) + 1}',
                          selected: asset == a && image == null,
                          child: InkWell(
                            onTap: saving
                                ? null
                                : () => setState(() {
                                    asset = a;
                                    image = null;
                                    replacedAsset = true;
                                  }),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  width: 2,
                                  color: asset == a && image == null
                                      ? FanColors.purple
                                      : FanColors.line,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  a,
                                  width: 48,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 28),
              Form(
                key: form,
                child: Column(
                  children: [
                    if (widget.story == null) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Como sua história será lida?',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: StoryFormat.values
                            .map(
                              (f) => FanTag(
                                f.label,
                                selected: format == f,
                                icon: f == StoryFormat.chat
                                    ? Icons.forum_outlined
                                    : Icons.menu_book_outlined,
                                onTap: saving
                                    ? null
                                    : () => setState(() => format = f),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    TextFormField(
                      controller: title,
                      enabled: !saving,
                      maxLength: 70,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        hintText: 'Um nome que desperta curiosidade',
                      ),
                      validator: (v) => (v?.trim().length ?? 0) < 3
                          ? 'Use pelo menos 3 caracteres.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: description,
                      enabled: !saving,
                      maxLength: 800,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Sinopse',
                        hintText: 'Qual é o ponto de partida da sua história?',
                      ),
                      validator: (v) => (v?.trim().length ?? 0) < 15
                          ? 'Conte um pouco mais: pelo menos 15 caracteres.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: storyCategories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (v) => setState(() => category = v ?? category),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: rating,
                      decoration: const InputDecoration(
                        labelText: 'Classificação indicativa',
                      ),
                      items: contentRatings
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (v) => setState(() => rating = v ?? rating),
                    ),
                    const SizedBox(height: 28),
                    FanButton(
                      label: widget.story == null
                          ? 'Salvar e começar a escrever'
                          : 'Salvar alterações',
                      icon: Icons.check_rounded,
                      loading: saving,
                      onPressed: save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ManageStoryPage extends StatefulWidget {
  const ManageStoryPage({super.key, required this.storyId});
  final String storyId;
  @override
  State<ManageStoryPage> createState() => _ManageStoryPageState();
}

class _ManageStoryPageState extends State<ManageStoryPage> {
  Future<List<Object>>? future;
  bool busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    future ??= loadSections();
  }

  Future<List<Object>> loadSections() async {
    final store = FanScope.of(context);
    final story = store.storyById(widget.storyId);
    return story?.format == StoryFormat.chapter
        ? await store.loadChapters(widget.storyId)
        : await store.loadEpisodes(widget.storyId);
  }

  void refresh() => setState(() => future = loadSections());
  Future<void> editor(FanStory story, [Object? section]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => story.format == StoryFormat.chat
            ? EpisodeEditorPage(story: story, episode: section as FanEpisode?)
            : ChapterEditorPage(story: story, chapter: section as FanChapter?),
      ),
    );
    if (mounted) refresh();
  }

  Future<void> publication(FanStory story) async {
    if (busy) return;
    final store = FanScope.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          story.published
              ? 'Retirar do catálogo?'
              : 'Tudo pronto para publicar?',
        ),
        content: Text(
          story.published
              ? 'A história ficará como rascunho e continuará no seu estúdio.'
              : store.demoMode
              ? 'A história aparecerá no catálogo deste dispositivo. Revise a leitura e a classificação antes de confirmar.'
              : 'A história ficará visível no catálogo público. Confira a leitura, os direitos de uso e a classificação indicativa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(story.published ? 'Retirar' : 'Publicar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => busy = true);
    try {
      await store.publishStory(story, publish: !story.published);
      if (mounted) {
        fanMessage(
          context,
          story.published
              ? 'História voltou para rascunho.'
              : 'História publicada.',
        );
      }
    } catch (e) {
      if (mounted) fanMessage(context, fanError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = FanScope.of(context),
        story = FanScope.of(context).storyById(widget.storyId);
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar história')),
      body: story == null || !store.signedIn
          ? const Center(
              child: Text('Esta história não está disponível neste perfil.'),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: ListView(
                  padding: fanPagePadding(context),
                  children: [
                    FanStoryRow(
                      story: story,
                      subtitle: story.published ? 'Publicada' : 'Rascunho',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailsPage(story: story),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateStoryPage(story: story),
                              ),
                            );
                            if (mounted) refresh();
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar detalhes'),
                        ),
                        OutlinedButton.icon(
                          onPressed: busy ? null : () => publication(story),
                          icon: Icon(
                            story.published
                                ? Icons.public_off_rounded
                                : Icons.public_rounded,
                          ),
                          label: Text(
                            story.published
                                ? 'Retirar do catálogo'
                                : 'Publicar história',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    FanSectionHeading(
                      title: story.format == StoryFormat.chat
                          ? 'Episódios'
                          : 'Capítulos',
                    ),
                    FutureBuilder<List<Object>>(
                      future: future,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return FanEmptyState(
                            icon: Icons.wifi_off_rounded,
                            title: 'Não foi possível carregar.',
                            message: 'Verifique a conexão e tente novamente.',
                            actionLabel: 'Tentar novamente',
                            onAction: refresh,
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.data!.isEmpty) {
                          return const FanEmptyState(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'Seu primeiro capítulo começa aqui.',
                            message:
                                'Adicione conteúdo para dar vida à história.',
                          );
                        }
                        return Column(
                          children: snapshot.data!
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Card(
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(14),
                                      leading: CircleAvatar(
                                        backgroundColor: FanColors.surface2,
                                        child: Text(
                                          '${(e is FanEpisode ? e.order : (e as FanChapter).order) + 1}',
                                        ),
                                      ),
                                      title: Text(
                                        e is FanEpisode
                                            ? e.title
                                            : (e as FanChapter).title,
                                      ),
                                      subtitle: Text(
                                        e is FanEpisode
                                            ? '${e.lines.length} mensagens'
                                            : '${(e as FanChapter).paragraphs.length} parágrafos',
                                      ),
                                      trailing: const Icon(
                                        Icons.edit_outlined,
                                        color: FanColors.orchid,
                                      ),
                                      onTap: () => editor(story, e),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    FanButton(
                      label: story.format == StoryFormat.chat
                          ? 'Adicionar episódio'
                          : 'Adicionar capítulo',
                      icon: Icons.add_rounded,
                      onPressed: story.episodeCount >= 50
                          ? null
                          : () => editor(story),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class EpisodeEditorPage extends StatefulWidget {
  const EpisodeEditorPage({super.key, required this.story, this.episode});
  final FanStory story;
  final FanEpisode? episode;
  @override
  State<EpisodeEditorPage> createState() => _EpisodeEditorPageState();
}

class _EpisodeEditorPageState extends State<EpisodeEditorPage> {
  final title = TextEditingController();
  final List<ChatLine> lines = [];
  late FanStore store;
  bool loaded = false, saving = false, saved = false;
  String draftStatus = 'Rascunho salvo neste dispositivo';
  Timer? debounce;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (loaded) return;
    loaded = true;
    store = FanScope.of(context);
    final draft = store.editorDraft(widget.story.id, widget.episode?.id);
    title.text = '${draft?['title'] ?? widget.episode?.title ?? ''}';
    if (draft != null) {
      lines.addAll(
        (draft['lines'] as List? ?? []).map(
          (l) => ChatLine.fromMap(Map<String, dynamic>.from(l as Map)),
        ),
      );
    } else {
      lines.addAll(widget.episode?.lines ?? []);
    }
    title.addListener(scheduleDraft);
  }

  void scheduleDraft() {
    debounce?.cancel();
    if (mounted) setState(() => draftStatus = 'Salvando rascunho…');
    debounce = Timer(const Duration(milliseconds: 500), persistDraft);
  }

  Future<void> persistDraft() async {
    try {
      await store.saveEditorDraft(widget.story.id, widget.episode?.id, {
        'title': title.text,
        'lines': lines.map((l) => l.toMap()).toList(),
      });
      if (mounted) {
        setState(() => draftStatus = 'Rascunho salvo neste dispositivo');
      }
    } catch (_) {
      if (mounted) {
        setState(() => draftStatus = 'Não foi possível salvar o rascunho');
      }
    }
  }

  Future<void> message([int? index]) async {
    if (saving) return;
    if (index == null && lines.length >= 80) {
      fanMessage(context, 'Limite de 80 mensagens por episódio.');
      return;
    }
    final earlier = lines
        .take(index ?? lines.length)
        .expand((l) => l.options)
        .toSet()
        .toList();
    final value = await showDialog<ChatLine>(
      context: context,
      builder: (_) => _MessageDialog(
        existing: index == null ? null : lines[index],
        conditions: earlier,
      ),
    );
    if (value == null || !mounted) return;
    setState(() {
      if (index == null) {
        lines.add(value);
      } else {
        lines[index] = value;
      }
    });
    scheduleDraft();
  }

  Future<void> save() async {
    if (saving) return;
    if (title.text.trim().length < 3 || lines.length < 2) {
      fanMessage(context, 'Escreva um título e pelo menos duas mensagens.');
      return;
    }
    setState(() => saving = true);
    debounce?.cancel();
    try {
      if (widget.episode == null) {
        await store.addEpisode(widget.story, title.text, lines);
      } else {
        await store.editEpisode(
          widget.story,
          FanEpisode(
            id: widget.episode!.id,
            title: title.text.trim(),
            order: widget.episode!.order,
            lines: List.of(lines),
          ),
        );
      }
      saved = true;
      try {
        await store.saveEditorDraft(widget.story.id, widget.episode?.id, null);
      } catch (_) {
        /* The episode is already committed; never retry creation here. */
      }
      if (mounted) {
        fanMessage(context, 'Episódio salvo.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) fanMessage(context, fanError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> preview() async {
    debounce?.cancel();
    await persistDraft();
    if (!mounted || lines.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderPage(
          story: widget.story,
          previewEpisodes: [
            FanEpisode(
              id: 'preview',
              title: title.text.trim().isEmpty ? 'Prévia' : title.text,
              order: 0,
              lines: List.of(lines),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    debounce?.cancel();
    if (!saved && loaded) {
      // Capture the final draft before disposing the controller.
      store
          .saveEditorDraft(widget.story.id, widget.episode?.id, {
            'title': title.text,
            'lines': lines.map((l) => l.toMap()).toList(),
          })
          .catchError((Object _) {});
    }
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.episode == null ? 'Novo episódio' : 'Editar episódio'),
      actions: [
        TextButton.icon(
          onPressed: lines.isEmpty || saving ? null : preview,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Prévia'),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: ListView(
          padding: fanPagePadding(context),
          children: [
            const FanPageHeader(
              title: 'Dê voz aos personagens.',
              subtitle:
                  'Cada mensagem aparece uma por vez. Adicione escolhas para envolver o leitor.',
            ),
            TextField(
              controller: title,
              enabled: !saving,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Título do episódio',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              draftStatus,
              style: const TextStyle(fontSize: 12, color: FanColors.muted),
            ),
            const SizedBox(height: 26),
            FanSectionHeading(title: '${lines.length}/80 mensagens'),
            if (lines.isEmpty)
              FanEmptyState(
                icon: Icons.chat_outlined,
                title: 'Qual é a primeira mensagem?',
                message:
                    'Pode ser um segredo, um encontro inesperado ou apenas um “oi”.',
                actionLabel: 'Adicionar mensagem',
                onAction: () => message(),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: lines.length,
                onReorder: (oldIndex, newIndex) {
                  if (saving) return;
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    lines.insert(newIndex, lines.removeAt(oldIndex));
                  });
                  scheduleDraft();
                },
                itemBuilder: (context, i) => Padding(
                  key: ValueKey(lines[i].id),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ReorderableDragStartListener(
                                index: i,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.drag_indicator_rounded,
                                    color: FanColors.muted,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${i + 1}. ${lines[i].speaker}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Editar mensagem',
                                onPressed: saving ? null : () => message(i),
                                icon: const Icon(Icons.edit_outlined, size: 20),
                              ),
                              IconButton(
                                tooltip: 'Remover mensagem',
                                onPressed: saving
                                    ? null
                                    : () {
                                        setState(() => lines.removeAt(i));
                                        scheduleDraft();
                                      },
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: FanColors.pink,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lines[i].text,
                            style: const TextStyle(height: 1.7),
                          ),
                          if (lines[i].options.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: lines[i].options
                                  .map(
                                    (o) => FanTag(
                                      o,
                                      icon: Icons.fork_right_rounded,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          if (lines[i].requires != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Se a resposta for: ${lines[i].requires}',
                              style: const TextStyle(
                                color: FanColors.orchid,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: saving ? null : () => message(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar mensagem'),
            ),
            const SizedBox(height: 24),
            FanButton(
              label: 'Salvar episódio',
              loading: saving,
              icon: Icons.check_rounded,
              onPressed: save,
            ),
          ],
        ),
      ),
    ),
  );
}

class _MessageDialog extends StatefulWidget {
  const _MessageDialog({this.existing, required this.conditions});
  final ChatLine? existing;
  final List<String> conditions;
  @override
  State<_MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends State<_MessageDialog> {
  final form = GlobalKey<FormState>();
  final who = TextEditingController(),
      text = TextEditingController(),
      choices = TextEditingController();
  bool interactive = false;
  String condition = '';
  @override
  void initState() {
    super.initState();
    final l = widget.existing;
    if (l != null) {
      who.text = l.speaker;
      text.text = l.text;
      choices.text = l.options.join('\n');
      interactive = l.options.isNotEmpty;
      condition = widget.conditions.contains(l.requires) ? l.requires! : '';
    }
  }

  @override
  void dispose() {
    who.dispose();
    text.dispose();
    choices.dispose();
    super.dispose();
  }

  List<String> get options => interactive
      ? choices.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
      : [];
  void submit() {
    if (!form.currentState!.validate()) return;
    final id = DateTime.now().microsecondsSinceEpoch;
    Navigator.pop(
      context,
      ChatLine(
        id: widget.existing?.id ?? 'm_$id',
        speaker: who.text.trim(),
        text: text.text.trim(),
        choiceId: interactive
            ? widget.existing?.choiceId ?? 'choice_$id'
            : null,
        options: options,
        requires: condition.isEmpty ? null : condition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.existing == null ? 'Uma nova mensagem' : 'Editar mensagem',
    ),
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: who,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Personagem',
                  hintText: 'Nome, Você ou Narrador',
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Informe quem fala.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: text,
                maxLength: 600,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Mensagem'),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Escreva a mensagem.' : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: interactive,
                title: const Text('O leitor escolhe a resposta'),
                onChanged: (v) => setState(() => interactive = v),
              ),
              if (interactive)
                TextFormField(
                  controller: choices,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Uma resposta por linha',
                    helperText: '2 ou 3 opções, até 120 caracteres cada',
                  ),
                  validator: (_) =>
                      options.length < 2 ||
                          options.length > 3 ||
                          options.any((o) => o.length > 120) ||
                          options.toSet().length != options.length
                      ? 'Use de 2 a 3 opções distintas de até 120 caracteres.'
                      : null,
                ),
              if (widget.conditions.isNotEmpty) ...[
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: condition,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mostrar esta mensagem',
                  ),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Sempre')),
                    ...widget.conditions.map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          'Se respondeu: $c',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => condition = v ?? ''),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: submit, child: const Text('Salvar mensagem')),
    ],
  );
}

class ChapterEditorPage extends StatefulWidget {
  const ChapterEditorPage({super.key, required this.story, this.chapter});
  final FanStory story;
  final FanChapter? chapter;
  @override
  State<ChapterEditorPage> createState() => _ChapterEditorPageState();
}

class _ChapterEditorPageState extends State<ChapterEditorPage> {
  final title = TextEditingController();
  final content = TextEditingController();
  late FanStore store;
  bool initialized = false, saving = false, saved = false;
  Timer? debounce;
  String status = 'Rascunho salvo neste dispositivo';
  String get draftId => 'chapter:${widget.chapter?.id ?? 'new'}';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    store = FanScope.of(context);
    final draft = store.editorDraft(widget.story.id, draftId);
    title.text = '${draft?['title'] ?? widget.chapter?.title ?? ''}';
    content.text =
        '${draft?['content'] ?? widget.chapter?.paragraphs.join('\n\n') ?? ''}';
    title.addListener(scheduleDraft);
    content.addListener(scheduleDraft);
  }

  void scheduleDraft() {
    debounce?.cancel();
    if (mounted) setState(() => status = 'Salvando rascunho…');
    debounce = Timer(const Duration(milliseconds: 500), persistDraft);
  }

  Future<void> persistDraft() async {
    try {
      await store.saveEditorDraft(widget.story.id, draftId, {
        'title': title.text,
        'content': content.text,
      });
      if (mounted) setState(() => status = 'Rascunho salvo neste dispositivo');
    } catch (_) {
      if (mounted) {
        setState(() => status = 'Não foi possível salvar o rascunho');
      }
    }
  }

  Future<void> preview() async {
    debounce?.cancel();
    await persistDraft();
    if (!mounted || content.text.trim().isEmpty) return;
    final chapter = FanChapter(
      id: 'preview',
      title: title.text.trim().isEmpty ? 'Prévia' : title.text,
      order: 0,
      paragraphs: content.text
          .split(RegExp(r'\n\s*\n'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList(),
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChapterReaderPage(story: widget.story, previewChapters: [chapter]),
      ),
    );
  }

  Future<void> save() async {
    if (saving) return;
    if (title.text.trim().length < 3 || content.text.trim().length < 100) {
      fanMessage(
        context,
        'Use um título de pelo menos 3 caracteres e texto de pelo menos 100.',
      );
      return;
    }
    setState(() => saving = true);
    debounce?.cancel();
    try {
      if (widget.chapter == null) {
        await store.addChapter(widget.story, title.text, content.text);
      } else {
        await store.editChapter(
          widget.story,
          FanChapter(
            id: widget.chapter!.id,
            title: title.text.trim(),
            order: widget.chapter!.order,
            paragraphs: content.text
                .split(RegExp(r'\n\s*\n'))
                .map((p) => p.trim())
                .where((p) => p.isNotEmpty)
                .toList(),
          ),
        );
      }
      saved = true;
      try {
        await store.saveEditorDraft(widget.story.id, draftId, null);
      } catch (_) {}
      if (mounted) {
        fanMessage(context, 'Capítulo salvo.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) fanMessage(context, fanError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    if (initialized && !saved) {
      store
          .saveEditorDraft(widget.story.id, draftId, {
            'title': title.text,
            'content': content.text,
          })
          .catchError((Object _) {});
    }
    title.dispose();
    content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.chapter == null ? 'Novo capítulo' : 'Editar capítulo'),
      actions: [
        TextButton.icon(
          onPressed: saving || content.text.trim().isEmpty ? null : preview,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Prévia'),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: ListView(
          padding: fanPagePadding(context),
          children: [
            const FanPageHeader(
              title: 'Escreva o próximo universo.',
              subtitle:
                  'Separe os parágrafos com uma linha em branco. Seus leitores podem ajustar fonte e tema.',
            ),
            TextField(
              controller: title,
              enabled: !saving,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Título do capítulo',
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: content,
              enabled: !saving,
              minLines: 12,
              maxLines: 24,
              maxLength: 30000,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                labelText: 'Texto do capítulo',
                alignLabelWithHint: true,
                hintText: 'Era uma noite diferente de todas as outras…',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              status,
              style: const TextStyle(color: FanColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 24),
            FanButton(
              label: 'Salvar capítulo',
              loading: saving,
              onPressed: save,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    ),
  );
}
