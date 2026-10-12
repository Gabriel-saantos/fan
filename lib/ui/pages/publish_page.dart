import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/scope.dart';
import '../../core/theme.dart';
import '../../models/fan_models.dart';
import '../widgets/fan_widgets.dart';
import 'auth_page.dart';
import 'details_page.dart';

class PublishPage extends StatelessWidget {
  const PublishPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = FanScope.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 23, 20, 25), children: [
      const Text('Estúdio FAN', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1)),
      const SizedBox(height: 8),
      const Text('Crie histórias que merecem ser vividas.',
        style: TextStyle(fontSize: 12, color: FanColors.muted)),
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF302045), Color(0xFF4A2762)]),
        borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.auto_stories_rounded, color: FanColors.pink, size: 30),
          const SizedBox(height: 14),
          const Text('Seu universo começa com\numa mensagem.', style: TextStyle(
            fontWeight: FontWeight.w900, fontSize: 20, height: 1.3)),
          const SizedBox(height: 10),
          const Text('Escreva conversas, crie personagens e publique seus episódios para a comunidade.',
            style: TextStyle(fontSize: 11, height: 1.7, color: FanColors.muted)),
          const SizedBox(height: 20),
          FanButton(label: 'Criar nova história', icon: Icons.add_rounded, onPressed: () async {
            if (await requireFanLogin(context) && context.mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateStoryPage()));
            }
          }),
        ])),
      const SizedBox(height: 26),
      const FanSectionHeading(title: 'Minhas histórias'),
      if (!store.signedIn)
        const Padding(padding: EdgeInsets.symmetric(vertical: 22),
          child: Text('Entre para criar e publicar suas histórias.',
            style: TextStyle(color: FanColors.muted, fontSize: 12)))
      else if (store.myStories.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(vertical: 22),
          child: Text('Seu estúdio está vazio. Que tal começar?',
            style: TextStyle(color: FanColors.muted, fontSize: 12)))
      else ...store.myStories.map((story) => FanStoryRow(
        story: story,
        subtitle: story.published ? 'PUBLICADA · ${story.episodeCount} episódios' : 'RASCUNHO · ${story.episodeCount} episódios',
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ManageStoryPage(storyId: story.id))),
      )),
    ]);
  }
}

class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key});
  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  final keyForm = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  String category = 'Romance';
  String rating = 'Livre';
  String asset = 'assets/covers/entre_mensagens.webp';
  Uint8List? imageData;
  bool saving = false;
  static const assets = [
    'assets/covers/entre_mensagens.webp',
    'assets/covers/universos_paralelos.webp',
    'assets/covers/depois_da_meia_noite.webp',
    'assets/covers/cartas_que_ficaram.webp',
  ];

  @override
  void dispose() { title.dispose(); description.dispose(); super.dispose(); }

  Future<void> pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery,
        maxWidth: 1100, imageQuality: 80);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) fanMessage(context, 'Escolha uma imagem de até 5 MB.');
        return;
      }
      if (mounted) setState(() => imageData = bytes);
    } catch (e) { if (mounted) fanMessage(context, 'Não foi possível selecionar: $e'); }
  }

  Future<void> create() async {
    if (!keyForm.currentState!.validate() || saving) return;
    setState(() => saving = true);
    try {
      final store = FanScope.of(context);
      String url = '';
      if (imageData != null) url = await store.uploadCover(imageData!);
      final story = await store.createStory(
        title: title.text, description: description.text,
        category: category, contentRating: rating,
        coverAsset: asset, coverUrl: url,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => ManageStoryPage(storyId: story.id)));
    } catch (e) {
      if (mounted) fanMessage(context, 'Não foi possível criar a história: $e');
    } finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Criar história', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680),
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 26), children: [
        const Text('Dê vida à sua ideia ✨', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Comece com os detalhes. Depois você vai escrever as mensagens.',
          style: TextStyle(color: FanColors.muted, fontSize: 11.5)),
        const SizedBox(height: 20),
        InkWell(onTap: pickImage, child: Center(child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(children: [
            SizedBox(width: 150, height: 195, child: imageData != null
              ? Image.memory(imageData!, fit: BoxFit.cover)
              : Image.asset(asset, fit: BoxFit.cover)),
            Positioned.fill(child: Container(color: const Color(0x78000000),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 28),
                SizedBox(height: 7),
                Text('Escolher imagem', style: TextStyle(fontSize: 10, color: Colors.white)),
              ]))),
          ]),
        ))),
        const SizedBox(height: 9),
        const Text('Ou escolha uma capa ilustrada', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: FanColors.muted)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: assets.map((a) => GestureDetector(
          onTap: () => setState(() { asset = a; imageData = null; }),
          child: Container(margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(11),
              border: Border.all(color: a == asset && imageData == null
                ? FanColors.orchid : FanColors.line, width: 2)),
            child: ClipRRect(borderRadius: BorderRadius.circular(8),
              child: Image.asset(a, width: 48, height: 65, fit: BoxFit.cover))),
        )).toList()),
        const SizedBox(height: 24),
        Form(key: keyForm, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _FieldLabel('Título da história'),
          TextFormField(controller: title, maxLength: 70,
            decoration: const InputDecoration(hintText: 'Ex.: Nosso último verão'),
            validator: (value) => (value?.trim().length ?? 0) < 3 ? 'Digite um título de pelo menos 3 letras.' : null),
          const SizedBox(height: 12),
          const _FieldLabel('Sinopse'),
          TextFormField(controller: description, maxLength: 800, maxLines: 4,
            decoration: const InputDecoration(hintText: 'Sobre o que é sua história?'),
            validator: (value) => (value?.trim().length ?? 0) < 15 ? 'Escreva uma sinopse de pelo menos 15 letras.' : null),
          const SizedBox(height: 13),
          const _FieldLabel('Categoria'),
          DropdownButtonFormField<String>(initialValue: category,
            dropdownColor: FanColors.surface2,
            items: ['Romance', 'Fantasia', 'Mistério', 'Drama', 'Terror', 'Comédia']
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (e) => setState(() => category = e ?? category)),
          const SizedBox(height: 17),
          const _FieldLabel('Classificação indicativa'),
          DropdownButtonFormField<String>(initialValue: rating,
            dropdownColor: FanColors.surface2,
            items: ['Livre', '10+', '12+', '14+', '16+', '18+']
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (e) => setState(() => rating = e ?? rating)),
          const SizedBox(height: 27),
          FanButton(label: 'Salvar e escrever episódios', loading: saving,
            onPressed: create, icon: Icons.arrow_forward_rounded),
        ])),
      ]),
    )),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 9),
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)));
}

class ManageStoryPage extends StatefulWidget {
  const ManageStoryPage({super.key, required this.storyId});
  final String storyId;
  @override
  State<ManageStoryPage> createState() => _ManageStoryPageState();
}

class _ManageStoryPageState extends State<ManageStoryPage> {
  late Future<List<FanEpisode>> future;
  bool _initialLoad = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoad) { _initialLoad = true; refresh(); }
  }
  void refresh() { future = FanScope.of(context).loadEpisodes(widget.storyId); }

  @override
  Widget build(BuildContext context) {
    final store = FanScope.of(context);
    final matches = store.myStories.where((s) => s.id == widget.storyId).toList();
    final story = matches.isEmpty ? null : matches.first;
    return Scaffold(appBar: AppBar(title: const Text('Gerenciar história')),
      body: story == null
        ? const Center(child: CircularProgressIndicator())
        : Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 28), children: [
            FanStoryRow(story: story, subtitle: story.published ? 'Publicada' : 'Rascunho',
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => DetailsPage(story: story)))),
            const SizedBox(height: 20),
            FanButton(label: 'Adicionar episódio', icon: Icons.add_rounded,
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EpisodeEditorPage(story: story)));
                if (mounted) setState(refresh);
              }),
            const SizedBox(height: 12),
            if (!story.published) OutlinedButton.icon(
              onPressed: () async {
                try {
                  await store.publishStory(story);
                  if (context.mounted) fanMessage(context, 'História publicada! 🎉');
                } catch (e) { if (context.mounted) fanMessage(context, '$e'); }
              }, icon: const Icon(Icons.public_rounded),
              label: const Text('Publicar história'),
              style: OutlinedButton.styleFrom(foregroundColor: FanColors.orchid,
                side: const BorderSide(color: FanColors.line),
                padding: const EdgeInsets.symmetric(vertical: 15))),
            const SizedBox(height: 18),
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
              color: FanColors.surface2, borderRadius: BorderRadius.circular(14)),
              child: const Text('Publicação: adicione pelo menos um episódio. Histórias publicadas ficam visíveis aos leitores. Respeite os direitos autorais e a classificação indicativa.',
                style: TextStyle(fontSize: 10.5, height: 1.6, color: FanColors.muted))),
            const SizedBox(height: 25),
            const FanSectionHeading(title: 'Episódios escritos'),
            FutureBuilder<List<FanEpisode>>(future: future, builder: (context, snapshot) {
              if (snapshot.hasError) return Text('Erro ao carregar episódios: ${snapshot.error}');
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.isEmpty) return const Text('Ainda sem episódios.',
                style: TextStyle(fontSize: 12, color: FanColors.muted));
              return Column(children: snapshot.data!.map((ep) => ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded, color: FanColors.orchid),
                title: Text(ep.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                subtitle: Text('${ep.lines.length} mensagens',
                  style: const TextStyle(color: FanColors.muted, fontSize: 10)),
              )).toList());
            }),
          ]),
        )));
  }
}

class EpisodeEditorPage extends StatefulWidget {
  const EpisodeEditorPage({super.key, required this.story});
  final FanStory story;
  @override
  State<EpisodeEditorPage> createState() => _EpisodeEditorPageState();
}

class _EpisodeEditorPageState extends State<EpisodeEditorPage> {
  final title = TextEditingController();
  final List<ChatLine> lines = [];
  bool saving = false;
  @override
  void dispose() { title.dispose(); super.dispose(); }

  Future<void> addLine() async {
    if (lines.length >= 80) { fanMessage(context, 'Máximo de 80 mensagens por episódio.'); return; }
    final value = await showDialog<ChatLine>(context: context,
      builder: (_) => _MessageDialog(number: lines.length + 1));
    if (value != null) setState(() => lines.add(value));
  }

  Future<void> save() async {
    if (title.text.trim().length < 3) { fanMessage(context, 'Informe um título para o episódio.'); return; }
    if (lines.length < 2) { fanMessage(context, 'Adicione pelo menos duas mensagens.'); return; }
    setState(() => saving = true);
    try {
      await FanScope.of(context).addEpisode(widget.story, title.text, lines);
      if (mounted) { fanMessage(context, 'Episódio salvo!'); Navigator.pop(context); }
    } catch (e) { if (mounted) fanMessage(context, 'Erro ao salvar episódio: $e'); }
    finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Novo episódio')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700),
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 20, 18, 30), children: [
        const Text('Escreva a conversa', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Cada mensagem surge na tela do leitor, uma por vez.',
          style: TextStyle(fontSize: 11.5, color: FanColors.muted)),
        const SizedBox(height: 20),
        TextField(controller: title, maxLength: 80,
          decoration: const InputDecoration(labelText: 'Título do episódio', hintText: 'Ex.: A primeira mensagem')),
        const SizedBox(height: 18),
        Row(children: [
          Text('Mensagens (${lines.length}/80)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const Spacer(), TextButton.icon(onPressed: addLine,
            icon: const Icon(Icons.add_rounded, size: 19), label: const Text('Adicionar')),
        ]),
        const SizedBox(height: 13),
        if (lines.isEmpty) Container(padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: FanColors.surface, borderRadius: BorderRadius.circular(18)),
          child: const Text('A conversa ainda está vazia. Adicione as mensagens dos personagens.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.6, color: FanColors.muted)))
        else ...List.generate(lines.length, (i) => Card(child: ListTile(
          leading: CircleAvatar(backgroundColor: FanColors.surface2,
            child: Text('${i + 1}', style: const TextStyle(color: FanColors.orchid, fontSize: 11))),
          title: Text(lines[i].speaker, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          subtitle: Text('${lines[i].text}${lines[i].options.isNotEmpty ? '\nEscolhas: ${lines[i].options.join(' / ')}' : ''}',
            maxLines: 4, style: const TextStyle(color: FanColors.muted, fontSize: 11)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (i > 0) IconButton(icon: const Icon(Icons.arrow_upward_rounded, size: 17), onPressed: () => setState(() {
              final item = lines.removeAt(i); lines.insert(i - 1, item);
            })),
            IconButton(icon: const Icon(Icons.delete_outline, size: 19, color: FanColors.pink),
              onPressed: () => setState(() => lines.removeAt(i))),
          ]),
        ))),
        const SizedBox(height: 25),
        FanButton(label: 'Salvar episódio', loading: saving, icon: Icons.check_circle_outline_rounded,
          onPressed: save),
      ]),
    )),
  );
}

class _MessageDialog extends StatefulWidget {
  const _MessageDialog({required this.number});
  final int number;
  @override
  State<_MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends State<_MessageDialog> {
  final who = TextEditingController();
  final text = TextEditingController();
  final choices = TextEditingController();
  bool interactive = false;
  @override
  void dispose() { who.dispose(); text.dispose(); choices.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    insetPadding: const EdgeInsets.all(20),
    title: Text('Mensagem ${widget.number}', style: const TextStyle(fontSize: 17)),
    content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: who, maxLength: 40, decoration: const InputDecoration(
        labelText: 'Personagem', hintText: 'Ex.: Lívia, Kael, Você')),
      const SizedBox(height: 10),
      TextField(controller: text, maxLength: 600, minLines: 2, maxLines: 4,
        decoration: const InputDecoration(labelText: 'Mensagem', hintText: 'O que o personagem diz?')),
      SwitchListTile(contentPadding: EdgeInsets.zero, value: interactive,
        onChanged: (v) => setState(() => interactive = v),
        title: const Text('Leitor escolhe uma resposta', style: TextStyle(fontSize: 11.5))),
      if (interactive) TextField(controller: choices, maxLines: 3,
        decoration: const InputDecoration(labelText: 'Uma opção por linha',
          hintText: 'Sim, quero!\nAinda não sei...')),
    ]))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      TextButton(onPressed: () {
        final options = interactive
          ? choices.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).take(3).toList()
          : <String>[];
        if (who.text.trim().isEmpty || text.text.trim().isEmpty ||
          (interactive && options.length < 2)) {
          fanMessage(context, 'Preencha personagem, mensagem e ao menos duas opções.'); return;
        }
        Navigator.pop(context, ChatLine(
          id: 'm${widget.number}_${DateTime.now().microsecondsSinceEpoch}',
          speaker: who.text.trim(), text: text.text.trim(),
          choiceId: interactive ? 'choice_${widget.number}_${DateTime.now().microsecondsSinceEpoch}' : null,
          options: options,
        ));
      }, child: const Text('Adicionar')),
    ],
  );
}
