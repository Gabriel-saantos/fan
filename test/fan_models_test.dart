import 'package:flutter_test/flutter_test.dart';
import 'package:fan/data/demo_data.dart';
import 'package:fan/models/fan_models.dart';

void main() {
  test('histórias demo têm conteúdo no formato correto', () {
    expect(demoStories.length, 4);
    for (final story in demoStories) {
      if (story.format == StoryFormat.chat) {
        expect(demoEpisodes[story.id], isNotEmpty);
        expect(demoEpisodes[story.id]!.length, story.episodeCount);
      } else {
        expect(demoChapters[story.id], isNotEmpty);
        expect(demoChapters[story.id]!.length, story.episodeCount);
      }
    }
  });

  test('histórias antigas sem formato continuam como chat', () {
    final story = FanStory.fromMap('older', {
      'title': 'Antiga',
      'description': 'Descrição longa para testar',
      'authorId': 'x',
      'published': true,
    });
    expect(story.format, StoryFormat.chat);
    expect(StoryFormat.parse('chapter'), StoryFormat.chapter);
    expect(StoryFormat.parse('desconhecido'), StoryFormat.chat);
  });

  test('mensagem interativa suporta serialização e opções', () {
    const original = ChatLine(
      id: 'm1',
      speaker: 'Lia',
      text: 'Olá',
      choiceId: 'c1',
      options: ['Sim', 'Não'],
      requires: 'Sim',
    );
    final restored = ChatLine.fromMap(original.toMap());
    expect(restored.choiceId, 'c1');
    expect(restored.options, ['Sim', 'Não']);
    expect(restored.requires, 'Sim');
  });

  test('capítulo preserva parágrafos e título ao serializar', () {
    const original = FanChapter(
      id: 'c1',
      order: 0,
      title: 'O início',
      paragraphs: ['Primeiro parágrafo.', 'Segundo parágrafo.'],
    );
    final restored = FanChapter.fromMap('c1', original.toMap());
    expect(restored.title, 'O início');
    expect(restored.paragraphs.length, 2);
    expect(restored.paragraphs.last, 'Segundo parágrafo.');
  });

  test('biblioteca guarda progresso e porcentagem de capítulos', () {
    const previous = LibraryState(
      saved: false,
      liked: false,
      episodeIndex: 3,
      chapterProgress: 0.35,
    );
    final next = previous.copyWith(saved: true);
    expect(next.saved, true);
    expect(next.episodeIndex, 3);
    expect(next.chapterProgress, 0.35);
  });

  test('progresso de capítulo não excede os limites', () {
    final progress = LibraryState.fromMap({
      'episodeIndex': 2,
      'chapterProgress': 12,
    });
    expect(progress.chapterProgress, 1);
    expect(progress.chapterIndex, 2);
    expect(progress.started, isTrue);
    expect(
      LibraryState.fromMap({
        'episodeIndex': 50,
        'chapterProgress': 0,
      }).chapterIndex,
      49,
    );
  });
}
