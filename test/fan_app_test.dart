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
import 'package:fan/ui/widgets/fan_widgets.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<FanStore> setup() async { final s = FanStore(firebaseEnabled: false); await s.bootstrap(); return s; }
  for (final size in [const Size(390, 844), const Size(1440, 1000)]) {
    testWidgets('navegação e categoria funcionam em ${size.width.toInt()}px', (tester) async {
      tester.view.physicalSize = size; tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      final store = await setup(); await tester.pumpWidget(FanApp(store: store)); await tester.pumpAndSettle();
      expect(find.text('Boas histórias começam aqui.'), findsOneWidget);
      final category = find.widgetWithText(FanTag, 'Romance').first;
      await tester.ensureVisible(category); await tester.tap(category); await tester.pumpAndSettle();
      expect(find.text('Encontre seu próximo universo.'), findsOneWidget);
      expect(find.text('1 história'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('perfil local pede apenas nome', (tester) async {
    final store = await setup(); addTearDown(store.dispose);
    await tester.pumpWidget(FanScope(store: store, child: MaterialApp(theme: fanTheme(), home: const AuthPage())));
    await tester.pumpAndSettle();
    expect(find.text('E-mail'), findsNothing); expect(find.text('Senha'), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);
  });
  testWidgets('a prévia aguarda a escolha final e não modifica biblioteca', (tester) async {
    final store = await setup(); await store.enterLocal('Leitor'); addTearDown(store.dispose);
    await tester.pumpWidget(FanScope(store: store, child: MaterialApp(theme: fanTheme(),
      home: ReaderPage(story: demoStories.first, previewEpisodes: const [FanEpisode(id: 'preview',
        title: 'Prévia', order: 0, lines: [ChatLine(id: 'q', speaker: 'Lia', text: 'Você vem?', options: ['Sim', 'Não'])])]))));
    await tester.pumpAndSettle();
    expect(find.text('Concluir história'), findsNothing);
    await tester.tap(find.text('Sim')); await tester.pumpAndSettle();
    expect(find.text('Concluir história'), findsOneWidget);
    expect(store.libraryOf(demoStories.first.id).started, isFalse);
    expect(tester.takeException(), isNull);
  });
}
