const storyCategories = ['Romance', 'Fantasia', 'Mistério', 'Drama', 'Terror', 'Comédia'];
const contentRatings = ['Livre', '10+', '12+', '14+', '16+', '18+'];
const coverAssets = [
  'assets/covers/entre_mensagens.webp',
  'assets/covers/universos_paralelos.webp',
  'assets/covers/depois_da_meia_noite.webp',
  'assets/covers/cartas_que_ficaram.webp',
];

class FanStory {
  final String id, title, description, category, authorId, authorName;
  final String coverAsset, coverUrl, contentRating;
  final int episodeCount;
  final bool published, isDemo;
  const FanStory({required this.id, required this.title, required this.description,
    required this.category, required this.authorId, required this.authorName,
    required this.coverAsset, this.coverUrl = '', this.contentRating = 'Livre',
    this.episodeCount = 0, this.published = true, this.isDemo = false});

  factory FanStory.fromMap(String id, Map<String, dynamic> json) => FanStory(
    id: id, title: '${json['title'] ?? ''}', description: '${json['description'] ?? ''}',
    category: '${json['category'] ?? 'Drama'}', authorId: '${json['authorId'] ?? ''}',
    authorName: '${json['authorName'] ?? 'Autor FAN'}',
    coverAsset: '${json['coverAsset'] ?? coverAssets.first}', coverUrl: '${json['coverUrl'] ?? ''}',
    contentRating: '${json['contentRating'] ?? 'Livre'}',
    episodeCount: (json['episodeCount'] as num?)?.toInt() ?? 0,
    published: json['published'] == true, isDemo: json['isDemo'] == true);

  Map<String, dynamic> toMap() => {'title': title, 'description': description,
    'category': category, 'authorId': authorId, 'authorName': authorName,
    'coverAsset': coverAsset, 'coverUrl': coverUrl, 'contentRating': contentRating,
    'episodeCount': episodeCount, 'published': published};

  FanStory copyWith({String? title, String? description, String? category,
    String? contentRating, String? coverAsset, String? coverUrl,
    int? episodeCount, bool? published}) => FanStory(id: id,
    title: title ?? this.title, description: description ?? this.description,
    category: category ?? this.category, contentRating: contentRating ?? this.contentRating,
    coverAsset: coverAsset ?? this.coverAsset, coverUrl: coverUrl ?? this.coverUrl,
    episodeCount: episodeCount ?? this.episodeCount, published: published ?? this.published,
    authorId: authorId, authorName: authorName, isDemo: isDemo);
}

class ChatLine {
  final String id, speaker, text;
  final String? choiceId, requires;
  final List<String> options;
  const ChatLine({required this.id, required this.speaker, required this.text,
    this.choiceId, this.options = const [], this.requires});
  String get answerKey => choiceId ?? id;
  factory ChatLine.fromMap(Map<String, dynamic> json) => ChatLine(
    id: '${json['id'] ?? ''}', speaker: '${json['speaker'] ?? 'Narrador'}',
    text: '${json['text'] ?? ''}', choiceId: json['choiceId']?.toString(),
    options: (json['options'] as List? ?? []).map((e) => '$e').toList(),
    requires: json['requires']?.toString());
  Map<String, dynamic> toMap() => {'id': id, 'speaker': speaker, 'text': text,
    if (choiceId != null) 'choiceId': choiceId,
    if (options.isNotEmpty) 'options': options, if (requires != null) 'requires': requires};
}

class FanEpisode {
  final String id, title;
  final int order;
  final List<ChatLine> lines;
  const FanEpisode({required this.id, required this.title, required this.order, required this.lines});
  factory FanEpisode.fromMap(String id, Map<String, dynamic> json) => FanEpisode(
    id: id, title: '${json['title'] ?? 'Episódio'}', order: (json['order'] as num?)?.toInt() ?? 0,
    lines: (json['lines'] as List? ?? []).whereType<Map>()
      .map((e) => ChatLine.fromMap(Map<String, dynamic>.from(e))).toList());
  Map<String, dynamic> toMap() => {'title': title, 'order': order,
    'lines': lines.map((l) => l.toMap()).toList()};
}

class LibraryState {
  final bool saved, liked, started, completed;
  /// Number of completed episodes. Kept compatible with the original schema.
  final int episodeIndex;
  final String currentEpisodeId;
  final int visibleCount;
  final Map<String, String> answers;
  const LibraryState({this.saved = false, this.liked = false, this.started = false,
    this.completed = false, this.episodeIndex = 0, this.currentEpisodeId = '',
    this.visibleCount = 0, this.answers = const {}});
  LibraryState copyWith({bool? saved, bool? liked, bool? started, bool? completed,
    int? episodeIndex, String? currentEpisodeId, int? visibleCount,
    Map<String, String>? answers}) => LibraryState(saved: saved ?? this.saved,
    liked: liked ?? this.liked, started: started ?? this.started,
    completed: completed ?? this.completed, episodeIndex: episodeIndex ?? this.episodeIndex,
    currentEpisodeId: currentEpisodeId ?? this.currentEpisodeId,
    visibleCount: visibleCount ?? this.visibleCount, answers: answers ?? this.answers);
  factory LibraryState.fromMap(Map<String, dynamic> json) => LibraryState(
    saved: json['saved'] == true, liked: json['liked'] == true,
    started: json['started'] == true || ((json['episodeIndex'] as num?) ?? 0) > 0,
    completed: json['completed'] == true, episodeIndex: (json['episodeIndex'] as num?)?.toInt() ?? 0,
    currentEpisodeId: '${json['currentEpisodeId'] ?? ''}',
    visibleCount: (json['visibleCount'] as num?)?.toInt() ?? 0,
    answers: (json['answers'] as Map? ?? {}).map((k, v) => MapEntry('$k', '$v')));
  Map<String, dynamic> toMap() => {'saved': saved, 'liked': liked, 'started': started,
    'completed': completed, 'episodeIndex': episodeIndex,
    'currentEpisodeId': currentEpisodeId, 'visibleCount': visibleCount, 'answers': answers};
}
