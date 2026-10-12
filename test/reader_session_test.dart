import 'package:flutter_test/flutter_test.dart';
import 'package:fan/models/fan_models.dart';
import 'package:fan/models/reader_session.dart';

FanEpisode episode(List<ChatLine> lines) =>
    FanEpisode(id: 'e1', title: 'Uma conversa', order: 0, lines: lines);
const question = ChatLine(
  id: 'q',
  speaker: 'Lia',
  text: 'Você vem?',
  choiceId: 'choice',
  options: ['Sim', 'Não'],
);

void main() {
  test('a última mensagem exige resposta antes de concluir', () {
    final session = ReaderSession(episode([question]));
    expect(session.finished, isFalse);
    expect(session.advance(), isFalse);
    session.choose('inválida');
    expect(session.finished, isFalse);
    session.choose('Sim');
    expect(session.finished, isTrue);
  });
  test(
    'escolha revela a ramificação correta sem ações para mensagens ocultas',
    () {
      final session = ReaderSession(
        episode([
          question,
          const ChatLine(
            id: 'yes',
            speaker: 'Lia',
            text: 'Até logo!',
            requires: 'Sim',
          ),
          const ChatLine(
            id: 'no',
            speaker: 'Lia',
            text: 'Tudo bem.',
            requires: 'Não',
          ),
          const ChatLine(id: 'end', speaker: 'Narrador', text: 'Fim.'),
        ]),
      );
      session.choose('Não');
      session.advance();
      expect(session.revealed.map((l) => l.id), ['q', 'no']);
      session.advance();
      expect(session.finished, isTrue);
      expect(session.revealed.map((l) => l.id), ['q', 'no', 'end']);
    },
  );
  test('retomada restaura posição e escolhas', () {
    final ep = episode([
      question,
      const ChatLine(id: 'end', speaker: 'Lia', text: 'Até amanhã.'),
    ]);
    final session = ReaderSession(
      ep,
      visibleCount: 1,
      answers: {'choice': 'Sim'},
    );
    expect(session.cursor, 1);
    expect(session.pendingChoice, isNull);
    session.advance();
    expect(session.finished, isTrue);
  });
  test('resposta antiga removida pelo autor deve ser escolhida de novo', () {
    final session = ReaderSession(
      episode([question]),
      visibleCount: 900,
      answers: {'choice': 'Talvez'},
    );
    expect(session.cursor, 1);
    expect(session.answers, isEmpty);
    expect(session.finished, isFalse);
  });
  test('ramificações ocultas finais não impedem concluir', () {
    final session = ReaderSession(
      episode([
        question,
        const ChatLine(
          id: 'yes',
          speaker: 'Lia',
          text: 'Esperando você.',
          requires: 'Sim',
        ),
      ]),
    );
    session.choose('Não');
    expect(session.finished, isTrue);
    expect(session.revealed.length, 1);
  });
}
