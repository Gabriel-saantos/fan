import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fan/main.dart';
import 'package:fan/core/scope.dart';
import 'package:fan/core/theme.dart';
import 'package:fan/data/demo_data.dart';
import 'package:fan/data/fan_store.dart';
import 'package:fan/models/fan_models.dart';
import 'package:fan/ui/pages/auth_page.dart';
import 'package:fan/ui/pages/reader_page.dart';
import 'package:fan/ui/pages/publish_page.dart';
import 'package:fan/ui/widgets/fan_widgets.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<FanStore> setup() async {
    final s = FanStore(firebaseEnabled: false);
    await s.bootstrap();
    return s;
  }

  for (final size in [const Size(390, 844), const Size(1440, 1000)]) {
    testWidgets('navegação e categoria funcionam em ${size.width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await setup();
      await tester.pumpWidget(FanApp(store: store));
      await tester.pumpAndSettle();
      expect(find.text('Boas histórias começam aqui.'), findsOneWidget);
      final category = find.widgetWithText(FanTag, 'Romance');
      await tester.scrollUntilVisible(
        category,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(category);
      await tester.pumpAndSettle();
      expect(find.text('Encontre seu próximo universo.'), findsOneWidget);
      expect(find.text('1 história'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('perfil local pede apenas nome', (tester) async {
    final store = await setup();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      FanScope(
        store: store,
        child: MaterialApp(theme: fanTheme(), home: const AuthPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('E-mail'), findsNothing);
    expect(find.text('Senha'), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);
  });
  testWidgets('a prévia aguarda a escolha final e não modifica biblioteca', (
    tester,
  ) async {
    final store = await setup();
    await store.enterLocal('Leitor');
    addTearDown(store.dispose);
    await tester.pumpWidget(
      FanScope(
        store: store,
        child: MaterialApp(
          theme: fanTheme(),
          home: ReaderPage(
            story: demoStories.first,
            previewEpisodes: const [
              FanEpisode(
                id: 'preview',
                title: 'Prévia',
                order: 0,
                lines: [
                  ChatLine(
                    id: 'q',
                    speaker: 'Lia',
                    text: 'Você vem?',
                    options: ['Sim', 'Não'],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Concluir história'), findsNothing);
    await tester.tap(find.text('Sim'));
    await tester.pumpAndSettle();
    expect(find.text('Concluir história'), findsOneWidget);
    expect(store.libraryOf(demoStories.first.id).started, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('apresentação cabe em tela pequena e salva conclusão', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await setup();
    await tester.pumpWidget(FanApp(store: store, showIntro: true));
    await tester.pumpAndSettle();
    expect(find.text('Pular'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();
    expect(find.text('Boas histórias começam aqui.'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getBool('fan_intro_seen'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('catálogo de livros abre o leitor de capítulos reais', (
    tester,
  ) async {
    final store = await setup();
    await tester.pumpWidget(FanApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FanTag, 'Capítulos'));
    await tester.pumpAndSettle();
    expect(find.text('2 histórias'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Universos Paralelos'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Universos Paralelos'));
    await tester.pumpAndSettle();
    final read = find.text('Começar a ler');
    await tester.scrollUntilVisible(
      read,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(read);
    await tester.pumpAndSettle();
    expect(find.text('A cidade com duas luas'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  testWidgets('chat mostra digitando, acelera ao toque e pausa', (
    tester,
  ) async {
    final store = await setup();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      FanScope(
        store: store,
        child: MaterialApp(
          theme: fanTheme(),
          home: ReaderPage(story: demoStories.first),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 620));
    expect(find.byType(TypingBubble), findsOneWidget);
    await tester.tap(find.text('Mostrar mensagem agora'));
    await tester.pump();
    expect(
      find.text('Gente... alguém sabe por que fui adicionada aqui? 😅'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Pausar leitura automática'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(
      find.text('Eu ia perguntar exatamente a mesma coisa.'),
      findsNothing,
    );
    expect(find.byType(TypingBubble), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('editor grava capítulo nativo e remove rascunho', (tester) async {
    final store = await setup();
    addTearDown(store.dispose);
    await store.enterLocal('Autor');
    final book = await store.createStory(
      title: 'Livro de teste',
      description: 'Uma narrativa longa para testar o editor.',
      category: 'Fantasia',
      contentRating: 'Livre',
      coverAsset: coverAssets[1],
      coverUrl: '',
      format: StoryFormat.chapter,
    );
    await tester.pumpWidget(
      FanScope(
        store: store,
        child: MaterialApp(
          theme: fanTheme(),
          home: ChapterEditorPage(story: book),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Uma nova aventura');
    await tester.enterText(
      find.byType(TextField).last,
      List.filled(
        3,
        'As estrelas iluminavam a cidade enquanto a aventura começava.',
      ).join('\n\n'),
    );
    final button = find.text('Salvar capítulo');
    await tester.scrollUntilVisible(
      button,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    final chapters = await store.loadChapters(book.id);
    expect(chapters.single.title, 'Uma nova aventura');
    expect(chapters.single.paragraphs.length, 3);
    expect(store.editorDraft(book.id, 'chapter:new'), isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
