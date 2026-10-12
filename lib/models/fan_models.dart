class FanStory {
  final String id;
  final String title;
  final String description;
  final String category;
  final String authorId;
  final String authorName;
  final String coverAsset;
  final String coverUrl;
  final String contentRating;
  final int episodeCount;
  final bool published;
  final bool isDemo;

  const FanStory({
    required this.id, required this.title, required this.description,
    required this.category, required this.authorId, required this.authorName,
    required this.coverAsset, this.coverUrl = '', this.contentRating = 'Livre',
    this.episodeCount = 0, this.published = true, this.isDemo = false,
  });

  factory FanStory.fromMap(String id, Map<String, dynamic> json) => FanStory(
    id: id,
    title: (json['title'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    category: (json['category'] ?? 'Drama').toString(),
    authorId: (json['authorId'] ?? '').toString(),
    authorName: (json['authorName'] ?? 'Autor FAN').toString(),
    coverAsset: (json['coverAsset'] ?? 'assets/covers/entre_mensagens.webp').toString(),
    coverUrl: (json['coverUrl'] ?? '').toString(),
    contentRating: (json['contentRating'] ?? 'Livre').toString(),
    episodeCount: (json['episodeCount'] is num) ? (json['episodeCount'] as num).toInt() : 0,
    published: json['published'] == true,
    isDemo: false,
  );

  FanStory copyWith({int? episodeCount, bool? published, String? coverUrl}) => FanStory(
    id: id, title: title, description: description, category: category,
    authorId: authorId, authorName: authorName, coverAsset: coverAsset,
    coverUrl: coverUrl ?? this.coverUrl, contentRating: contentRating,
    episodeCount: episodeCount ?? this.episodeCount,
    published: published ?? this.published, isDemo: isDemo,
  );
}

class ChatLine {
  final String id;
  final String speaker;
  final String text;
  final String? choiceId;
  final List<String> options;
  final String? requires;

  const ChatLine({
    required this.id, required this.speaker, required this.text,
    this.choiceId, this.options = const [], this.requires,
  });

  factory ChatLine.fromMap(Map<String, dynamic> json) => ChatLine(
    id: (json['id'] ?? '').toString(),
    speaker: (json['speaker'] ?? 'Narrador').toString(),
    text: (json['text'] ?? '').toString(),
    choiceId: json['choiceId']?.toString(),
    options: (json['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    requires: json['requires']?.toString(),
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'speaker': speaker, 'text': text,
    if (choiceId != null) 'choiceId': choiceId,
    if (options.isNotEmpty) 'options': options,
    if (requires != null) 'requires': requires,
  };
}

class FanEpisode {
  final String id;
  final String title;
  final int order;
  final List<ChatLine> lines;

  const FanEpisode({required this.id, required this.title, required this.order, required this.lines});

  factory FanEpisode.fromMap(String id, Map<String, dynamic> json) => FanEpisode(
    id: id, title: (json['title'] ?? 'Episódio').toString(),
    order: (json['order'] is num) ? (json['order'] as num).toInt() : 0,
    lines: (json['lines'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => ChatLine.fromMap(Map<String, dynamic>.from(e))).toList(),
  );

  Map<String, dynamic> toMap() => {
    'title': title, 'order': order,
    'lines': lines.map((l) => l.toMap()).toList(),
  };
}

class LibraryState {
  final bool saved;
  final bool liked;
  final int episodeIndex;
  const LibraryState({this.saved = false, this.liked = false, this.episodeIndex = 0});
  LibraryState copyWith({bool? saved, bool? liked, int? episodeIndex}) => LibraryState(
    saved: saved ?? this.saved, liked: liked ?? this.liked,
    episodeIndex: episodeIndex ?? this.episodeIndex,
  );
  factory LibraryState.fromMap(Map<String, dynamic> json) => LibraryState(
    saved: json['saved'] == true, liked: json['liked'] == true,
    episodeIndex: (json['episodeIndex'] is num) ? (json['episodeIndex'] as num).toInt() : 0,
  );
}
