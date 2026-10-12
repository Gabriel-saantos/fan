import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fan/core/scope.dart';
import 'package:fan/core/theme.dart';
import 'package:fan/data/demo_data.dart';
import 'package:fan/data/fan_store.dart';
import 'package:fan/models/fan_models.dart';
import 'package:fan/ui/pages/chapter_reader_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('FanChapter aceita parágrafos e conteúdo em texto', () {
    final chapter = FanChapter.fromMap('c1', {'title': 'Começo', 'order': 0,
      'paragraphs': [' Primeiro parágrafo. ', '', 'Segundo parágrafo.']});
    expect(chapter.paragraphs, ['Primeiro parágrafo.', 'Segundo parágrafo.']);
    final text = FanChapter.fromMap('c2', {'content': 'Primeiro.\n\nSegundo.'});
    expect(text.paragraphs, ['Primeiro.', 'Segundo.']);
  });
  test('transcrição mantém opções e condições explícitas', () {
    const ep = FanEpisode(id: 'e1', title: 'Conversa', order: 0, lines: [
      ChatLine(id: 'm1', speaker: 'Lia', text: 'Você vem?', options: ['Sim', 'Não']),
      ChatLine(id: 'm2', speaker: 'Lia', text: 'Até logo.', requires: 'Sim'),
    ]);
    final chapter = FanChapter.fromEpisode(ep);
    expect(chapter.paragraphs.first, contains('Sim / Não'));
    expect(chapter.paragraphs.last, contains('Se a resposta for “Sim”'));
  });
  test('posição do capítulo não aumenta a contagem de concluídos', () async {
    final store = FanStore(firebaseEnabled: false); await store.bootstrap();
    addTearDown(store.dispose); await store.enterLocal('Leitor');
    final List<FanChapter> chapters = await store.loadChapters('demo_entre');
    expect(chapters.length, 3);
    await store.saveChapterReading('demo_entre', chapterIndex: 0, chapterProgress: .45);
    expect(store.libraryOf('demo_entre').episodeIndex, 0);
    final restored = FanStore(firebaseEnabled: false); await restored.bootstrap(); addTearDown(restored.dispose);
    expect(restored.libraryOf('demo_entre').chapterProgress, .45);
    await restored.saveChapterReading('demo_entre', chapterIndex: 1, chapterProgress: 0, completedEpisodes: 1);
    expect(restored.libraryOf('demo_entre').chapterIndex, 1);
    expect(restored.libraryOf('demo_entre').episodeIndex, 1);
  });
  testWidgets('leitor em texto abre e avança para o próximo capítulo', (tester) async {
    final store = FanStore(firebaseEnabled: false); await store.bootstrap(); addTearDown(store.dispose);
    await store.enterLocal('Leitor');
    await tester.pumpWidget(FanScope(store: store,
      child: MaterialApp(theme: fanTheme(), home: ChapterReaderPage(story: demoStories.first))));
    await tester.pumpAndSettle();
    expect(find.text('O grupo errado'), findsOneWidget);
    await tester.tap(find.text('Próximo capítulo')); await tester.pumpAndSettle();
    expect(find.text('Três pontos'), findsOneWidget);
    expect(store.libraryOf('demo_entre').episodeIndex, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink()); await tester.pumpAndSettle();
  });
}
