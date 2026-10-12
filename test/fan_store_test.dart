import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fan/data/fan_store.dart';
import 'package:fan/models/fan_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<FanStore> store() async {
    final s = FanStore(firebaseEnabled: false);
    await s.bootstrap();
    addTearDown(s.dispose);
    return s;
  }

  Future<FanStory> story(FanStore s) => s.createStory(
    title: 'Uma nova história',
    description: 'Uma conversa que muda dois destinos para sempre.',
    category: 'Romance',
    contentRating: 'Livre',
    coverAsset: coverAssets.first,
    coverUrl: '',
  );
  const lines = [
    ChatLine(id: 'm1', speaker: 'Lia', text: 'Olá.'),
    ChatLine(id: 'm2', speaker: 'Theo', text: 'Oi!'),
  ];

  test(
    'perfil, favoritos e posição por mensagem sobrevivem à reinicialização',
    () async {
      final first = await store();
      await first.enterLocal('Gabriel');
      await first.updateLibrary('demo_entre', saved: true, liked: true);
      await first.saveReading('demo_entre', 'e1', 7, {
        'resposta1': 'Talvez um pouquinho 😳',
      });
      final restored = await store();
      expect(restored.signedIn, isTrue);
      expect(restored.displayName, 'Gabriel');
      final state = restored.libraryOf('demo_entre');
      expect(state.saved && state.liked, isTrue);
      expect(state.visibleCount, 7);
      expect(state.currentEpisodeId, 'e1');
      expect(state.answers['resposta1'], 'Talvez um pouquinho 😳');
      expect(restored.readingStories.map((s) => s.id), contains('demo_entre'));
    },
  );
  test('estúdio cria, edita, publica e retira história persistida', () async {
    final first = await store();
    await first.enterLocal('Autor FAN');
    final s = await story(first);
    await expectLater(first.publishStory(s), throwsStateError);
    await first.addEpisode(s, 'O encontro', lines);
    final ep = (await first.loadEpisodes(s.id)).single;
    await first.editEpisode(
      s,
      FanEpisode(
        id: ep.id,
        title: 'O reencontro',
        order: ep.order,
        lines: lines,
      ),
    );
    await first.publishStory(first.storyById(s.id)!);
    expect(first.stories.any((v) => v.id == s.id), isTrue);
    final restored = await store();
    expect(restored.myStories.single.episodeCount, 1);
    expect((await restored.loadEpisodes(s.id)).single.title, 'O reencontro');
    await restored.publishStory(restored.myStories.single, publish: false);
    expect(restored.stories.any((v) => v.id == s.id), isFalse);
  });
  test('sair preserva trabalho local e apagar limpa todos os dados', () async {
    final s = await store();
    await s.enterLocal('Autor');
    await story(s);
    await s.logOut();
    expect(s.signedIn, isFalse);
    expect(s.myStories.length, 1);
    await s.enterLocal('Autor');
    expect(s.myStories.length, 1);
    await s.clearLocalData();
    final restored = await store();
    expect(restored.myStories, isEmpty);
    expect(restored.signedIn, isFalse);
  });
  test('leitura concluída sai de lendo e entra em concluídas', () async {
    final s = await store();
    await s.enterLocal('Leitor');
    await s.saveReading(
      'demo_entre',
      'e3',
      5,
      {},
      completedEpisodes: 3,
      completed: true,
    );
    expect(s.readingStories, isEmpty);
    expect(s.completedStories.single.id, 'demo_entre');
  });
  test(
    'validação impede opções duplicadas e ramificações antes da escolha',
    () async {
      final s = await store();
      await s.enterLocal('Autor');
      final draft = await story(s);
      await expectLater(
        s.addEpisode(draft, 'Episódio', [
          const ChatLine(
            id: 'm1',
            speaker: 'Lia',
            text: 'Oi!',
            options: ['Sim', 'Sim'],
          ),
          lines.last,
        ]),
        throwsStateError,
      );
      await expectLater(
        s.addEpisode(draft, 'Episódio', [
          const ChatLine(
            id: 'm1',
            speaker: 'Lia',
            text: 'Oi!',
            requires: 'Sim',
          ),
          lines.last,
        ]),
        throwsStateError,
      );
    },
  );
  test('rascunho do editor é restaurado e removido após salvar', () async {
    final s = await store();
    await s.enterLocal('Autor');
    await s.saveEditorDraft('story', null, {
      'title': 'Rascunho',
      'lines': [lines.first.toMap()],
    });
    final restored = await store();
    expect(restored.editorDraft('story', null)?['title'], 'Rascunho');
    await restored.saveEditorDraft('story', null, null);
    final clean = await store();
    expect(clean.editorDraft('story', null), isNull);
  });
  test('relato local não simula envio à moderação', () async {
    final s = await store();
    await s.enterLocal('Leitor');
    await expectLater(s.reportStory('demo_entre', 'Plágio'), throwsStateError);
  });
  test(
    'livro local cria, edita, publica e restaura capítulos nativos',
    () async {
      final s = await store();
      await s.enterLocal('Autor');
      final book = await s.createStory(
        title: 'Meu livro',
        description: 'Uma aventura que começa numa noite estrelada.',
        category: 'Fantasia',
        contentRating: 'Livre',
        coverAsset: coverAssets[1],
        coverUrl: '',
        format: StoryFormat.chapter,
      );
      await expectLater(s.publishStory(book), throwsStateError);
      final body = List.filled(
        3,
        'As estrelas iluminavam a cidade enquanto uma nova aventura começava.',
      ).join('\n\n');
      await s.addChapter(book, 'O primeiro encontro', body);
      final chapter = (await s.loadChapters(book.id)).single;
      await s.editChapter(
        book,
        FanChapter(
          id: chapter.id,
          title: 'Um novo começo',
          order: chapter.order,
          paragraphs: chapter.paragraphs,
        ),
      );
      await s.publishStory(s.storyById(book.id)!);
      final restored = await store();
      expect(restored.myStories.single.format, StoryFormat.chapter);
      expect(
        (await restored.loadChapters(book.id)).single.title,
        'Um novo começo',
      );
      expect(
        (await restored.loadChapters(book.id)).single.paragraphs.length,
        3,
      );
      expect(restored.myStories.single.published, isTrue);
    },
  );
  test('formatos diferentes não permitem conteúdo trocado', () async {
    final s = await store();
    await s.enterLocal('Autor');
    final chat = await story(s);
    await expectLater(
      s.addChapter(chat, 'Um capítulo', List.filled(150, 'a').join()),
      throwsStateError,
    );
    await expectLater(s.loadEpisodes('demo_universos'), throwsStateError);
    await expectLater(s.loadChapters('demo_entre'), throwsStateError);
  });
  test('preferências de fonte e tema sobrevivem ao reinício', () async {
    final s = await store();
    await s.setReadingPreferences(
      fontSize: 20,
      theme: 'sepia',
      reducedMotion: true,
    );
    final restored = await store();
    expect(restored.readerFontSize, 20);
    expect(restored.readerTheme, 'sepia');
    expect(restored.reduceMotion, isTrue);
  });
}
