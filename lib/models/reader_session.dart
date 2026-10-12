import 'fan_models.dart';

/// A cursor over an episode; hidden branches never consume a reader action.
class ReaderSession {
  ReaderSession(this.episode, {int visibleCount = 0, Map<String, String> answers = const {}})
      : cursor = visibleCount.clamp(0, episode.lines.length).toInt(),
        answers = Map.of(answers) {
    // Discard stale/invalid responses after an author edits the episode.
    this.answers.removeWhere((key, value) => !episode.lines.any(
      (line) => line.answerKey == key && line.options.contains(value)));
    _skipHidden();
    if (cursor == 0) advance();
  }
  final FanEpisode episode;
  int cursor;
  final Map<String, String> answers;
  bool _allowed(ChatLine line) => line.requires == null || answers.values.contains(line.requires);
  List<ChatLine> get revealed => episode.lines.take(cursor).where(_allowed).toList();
  ChatLine? get pendingChoice {
    for (final line in revealed) {
      if (line.options.isNotEmpty && !answers.containsKey(line.answerKey)) return line;
    }
    return null;
  }
  bool get finished => cursor >= episode.lines.length && pendingChoice == null;
  double get progress => episode.lines.isEmpty ? 1 : cursor / episode.lines.length;
  void _skipHidden() {
    if (pendingChoice != null) return;
    while (cursor < episode.lines.length && !_allowed(episode.lines[cursor])) { cursor++; }
  }
  bool advance() {
    if (pendingChoice != null || finished) return false;
    _skipHidden();
    if (cursor < episode.lines.length) cursor++;
    _skipHidden();
    return true;
  }
  void choose(String value) {
    final line = pendingChoice;
    if (line == null || !line.options.contains(value)) return;
    answers[line.answerKey] = value;
    _skipHidden();
  }
}
