import 'package:flutter_test/flutter_test.dart';
import 'package:fan/data/demo_data.dart';
import 'package:fan/models/fan_models.dart';

void main() {
  test('quatro histórias demo contêm episódios', () {
    expect(demoStories.length, 4);
    for (final story in demoStories) {
      expect(demoEpisodes[story.id], isNotEmpty);
      expect(demoEpisodes[story.id]!.length, story.episodeCount);
    }
  });

  test('mensagem interativa suporta serialização e opções', () {
    const original = ChatLine(id: 'm1', speaker: 'Lia', text: 'Olá',
      choiceId: 'c1', options: ['Sim', 'Não']);
    final restored = ChatLine.fromMap(original.toMap());
    expect(restored.choiceId, 'c1');
    expect(restored.options, ['Sim', 'Não']);
  });

  test('biblioteca mantém progresso ao alternar salvo', () {
    const previous = LibraryState(saved: false, liked: false, episodeIndex: 3);
    final next = previous.copyWith(saved: true);
    expect(next.saved, true);
    expect(next.episodeIndex, 3);
  });
}
