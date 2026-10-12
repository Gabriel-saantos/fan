import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fan_models.dart';
import 'demo_data.dart';

class FanStore extends ChangeNotifier {
  FanStore({required this.firebaseEnabled});
  final bool firebaseEnabled;
  final List<FanStory> _public = [], _owned = [];
  final Map<String, LibraryState> _library = {};
  final Map<String, List<FanEpisode>> _localEpisodes = {};
  final Set<String> _following = {};
  final Map<String, Map<String, dynamic>> _drafts = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<StreamSubscription<dynamic>> _userSubscriptions = [];
  SharedPreferences? _preferences;
  bool _localProfile = false, _disposed = false;
  int _authGeneration = 0;
  String _name = 'Leitor FAN', _bio = 'Histórias também são um lugar para chamar de casa.';
  String? cloudError, localError;
  bool isLoading = true;
  double readerFontSize = 16;
  bool reduceMotion = false;
  Future<void> _writeQueue = Future.value();

  User? get user => firebaseEnabled ? FirebaseAuth.instance.currentUser : null;
  bool get signedIn => firebaseEnabled ? user != null : _localProfile;
  String get uid => firebaseEnabled ? (user?.uid ?? '') : 'offline_demo';
  String get displayName => firebaseEnabled
    ? (user?.displayName ?? user?.email?.split('@').first ?? 'Leitor FAN') : _name;
  String get email => firebaseEnabled ? (user?.email ?? '') : 'Perfil local neste dispositivo';
  String get bio => _bio;
  bool get demoMode => !firebaseEnabled;
  bool get hasCloud => firebaseEnabled;
  List<FanStory> get stories {
    final map = <String, FanStory>{for (final s in demoStories) s.id: s,
      for (final s in _public) s.id: s,
      for (final s in _owned.where((s) => s.published)) s.id: s};
    return List.unmodifiable(map.values);
  }
  FanStory? storyById(String id) {
    for (final s in [..._owned, ...stories]) { if (s.id == id) return s; }
    return null;
  }
  List<FanStory> get myStories => List.unmodifiable(_owned);
  List<FanStory> get savedStories => stories.where((s) => libraryOf(s.id).saved).toList();
  List<FanStory> get readingStories => stories.where((s) {
    final l = libraryOf(s.id); return l.started && !l.completed;
  }).toList();
  List<FanStory> get completedStories => stories.where((s) => libraryOf(s.id).completed).toList();
  int get followingCount => _following.length;
  LibraryState libraryOf(String id) => _library[id] ?? const LibraryState();
  bool follows(String id) => _following.contains(id);
  void _notify() { if (!_disposed) notifyListeners(); }

  Future<void> bootstrap() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      readerFontSize = (_preferences!.getDouble('fan.readerFontSize') ?? 16).clamp(14, 22).toDouble();
      reduceMotion = _preferences!.getBool('fan.reduceMotion') ?? false;
      final drafts = _preferences!.getString('fan.drafts');
      if (drafts != null) {
        final map = jsonDecode(drafts) as Map<String, dynamic>;
        for (final e in map.entries) { _drafts[e.key] = Map<String, dynamic>.from(e.value as Map); }
      }
      if (!firebaseEnabled) _restoreLocal();
    } catch (_) { localError = 'Não foi possível restaurar os dados locais. Você pode continuar nesta sessão.'; }
    if (firebaseEnabled) {
      _subscriptions.add(FirebaseFirestore.instance.collection('stories')
        .where('published', isEqualTo: true).limit(100).snapshots().listen((snapshot) {
          _public..clear()..addAll(snapshot.docs.map((d) => FanStory.fromMap(d.id, d.data())));
          isLoading = false; cloudError = null; _notify();
        }, onError: (_) {
          isLoading = false; cloudError = 'Sem conexão com o catálogo. As histórias de exemplo continuam disponíveis.'; _notify();
        }));
      _subscriptions.add(FirebaseAuth.instance.authStateChanges().listen(_bindUser));
    }
    isLoading = false; _notify();
  }

  void _restoreLocal() {
    final raw = _preferences?.getString('fan.local.v2');
    if (raw == null) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _localProfile = data['signedIn'] == true; _name = '${data['name'] ?? _name}'; _bio = '${data['bio'] ?? _bio}';
    _owned.addAll((data['stories'] as List? ?? []).map((v) {
      final map = Map<String, dynamic>.from(v as Map);
      return FanStory.fromMap('${map['id']}', map);
    }));
    for (final e in (data['library'] as Map? ?? {}).entries) {
      _library['${e.key}'] = LibraryState.fromMap(Map<String, dynamic>.from(e.value as Map));
    }
    for (final e in (data['episodes'] as Map? ?? {}).entries) {
      _localEpisodes['${e.key}'] = (e.value as List).map((v) {
        final map = Map<String, dynamic>.from(v as Map);
        return FanEpisode.fromMap('${map['id']}', map);
      }).toList();
    }
    _following.addAll((data['following'] as List? ?? []).map((v) => '$v'));
  }

  Future<void> _persistLocal() {
    final snapshot = jsonEncode({'signedIn': _localProfile, 'name': _name, 'bio': _bio,
      'stories': _owned.map((s) => {'id': s.id, ...s.toMap(), 'isDemo': true}).toList(),
      'library': _library.map((k, v) => MapEntry(k, v.toMap())),
      'episodes': _localEpisodes.map((k, v) => MapEntry(k,
        v.map((e) => {'id': e.id, ...e.toMap()}).toList())), 'following': _following.toList()});
    final operation = _writeQueue.then((_) async {
      if (_preferences == null || !await _preferences!.setString('fan.local.v2', snapshot)) {
        throw StateError('Não foi possível salvar neste dispositivo.');
      }
    });
    _writeQueue = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _bindUser(User? u) async {
    final generation = ++_authGeneration;
    final previous = List<StreamSubscription<dynamic>>.of(_userSubscriptions);
    _userSubscriptions.clear();
    await Future.wait(previous.map((s) => s.cancel()));
    if (generation != _authGeneration || _disposed) return;
    _library.clear(); _following.clear(); _owned.clear();
    _bio = 'Histórias também são um lugar para chamar de casa.';
    if (u == null || _disposed) { _notify(); return; }
    final users = FirebaseFirestore.instance.collection('users').doc(u.uid);
    try {
      final doc = await users.get();
      if (generation != _authGeneration || _disposed) return;
      if (doc.exists) { _bio = '${doc.data()?['bio'] ?? _bio}'; }
      else { await users.set({'displayName': displayName, 'bio': _bio,
        'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true)); }
    } catch (_) { cloudError = 'Não foi possível carregar seu perfil na nuvem.'; }
    if (generation != _authGeneration || _disposed) return;
    void error(Object _) {
      if (generation != _authGeneration || _disposed) return;
      cloudError = 'Não foi possível sincronizar seus dados. Verifique a conexão e tente novamente.'; _notify(); }
    _userSubscriptions.add(users.collection('library').snapshots().listen((s) {
      if (generation != _authGeneration || _disposed) return;
      _library..clear()..addEntries(s.docs.map((d) => MapEntry(d.id, LibraryState.fromMap(d.data())))); _notify();
    }, onError: error));
    _userSubscriptions.add(users.collection('following').snapshots().listen((s) {
      if (generation != _authGeneration || _disposed) return;
      _following..clear()..addAll(s.docs.map((d) => d.id)); _notify();
    }, onError: error));
    _userSubscriptions.add(FirebaseFirestore.instance.collection('stories')
      .where('authorId', isEqualTo: u.uid).snapshots().listen((s) {
        if (generation != _authGeneration || _disposed) return;
        _owned..clear()..addAll(s.docs.map((d) => FanStory.fromMap(d.id, d.data()))); _notify();
      }, onError: error));
    _notify();
  }

  Future<void> enterLocal(String name) async {
    if (firebaseEnabled) throw StateError('Use sua conta para entrar.');
    if (name.trim().length < 2 || name.trim().length > 40) throw StateError('Use um nome de 2 a 40 caracteres.');
    final previousName = _name, previousProfile = _localProfile;
    _name = name.trim(); _localProfile = true;
    try { await _persistLocal(); }
    catch (_) { _name = previousName; _localProfile = previousProfile; rethrow; }
    _notify();
  }
  Future<void> logIn(String email, String password) async {
    if (!firebaseEnabled) { await enterLocal(email.split('@').first); return; }
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.trim(), password: password);
  }
  Future<void> register(String name, String email, String password) async {
    if (!firebaseEnabled) { await enterLocal(name); return; }
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.trim(), password: password);
    await cred.user!.updateDisplayName(name.trim());
    await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
      'displayName': name.trim(), 'bio': _bio, 'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    _notify();
  }
  Future<void> logOut() async {
    if (firebaseEnabled) { await FirebaseAuth.instance.signOut(); }
    else { _localProfile = false; await _persistLocal(); }
    _notify();
  }
  Future<void> resetPassword(String address) async {
    if (!firebaseEnabled) throw StateError('O perfil local não utiliza senha.');
    await FirebaseAuth.instance.sendPasswordResetEmail(email: address.trim());
  }
  Future<void> editProfile(String name, String newBio) async {
    _requireLogin();
    if (name.trim().length < 2 || name.trim().length > 40 || newBio.trim().length > 160) {
      throw StateError('Nome deve ter 2 a 40 caracteres e biografia até 160.');
    }
    if (firebaseEnabled) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'displayName': name.trim(), 'bio': newBio.trim()}, SetOptions(merge: true));
      await user!.updateDisplayName(name.trim());
    }
    _name = name.trim(); _bio = newBio.trim();
    if (!firebaseEnabled) await _persistLocal();
    _notify();
  }

  void _requireLogin() { if (!signedIn) throw StateError('Entre para continuar.'); }
  void _requireAuthor(FanStory story) {
    _requireLogin(); if (story.authorId != uid) throw StateError('Apenas o autor pode editar esta história.');
  }
  Future<void> _saveLibrary(String storyId, LibraryState next) async {
    _requireLogin();
    // Commit state after successful persistence, avoiding concurrent optimistic rollbacks.
    if (firebaseEnabled) {
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('library').doc(storyId)
        .set({...next.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
      _library[storyId] = next;
    } else {
      final previous = _library[storyId];
      _library[storyId] = next;
      try { await _persistLocal(); }
      catch (_) {
        if (previous == null) { _library.remove(storyId); } else { _library[storyId] = previous; }
        rethrow;
      }
    }
    _notify();
  }
  Future<void> updateLibrary(String storyId, {bool? saved, bool? liked, int? episodeIndex}) async {
    await _saveLibrary(storyId, libraryOf(storyId).copyWith(saved: saved, liked: liked,
      started: episodeIndex != null ? true : null, episodeIndex: episodeIndex));
  }
  Future<void> saveReading(String storyId, String episodeId, int visibleCount,
    Map<String, String> answers, {int? completedEpisodes, bool? completed}) async {
    final old = libraryOf(storyId);
    final previousCount = old.completed && completed == false ? 0 : old.episodeIndex;
    await _saveLibrary(storyId, old.copyWith(started: true, currentEpisodeId: episodeId,
      visibleCount: visibleCount, answers: Map.of(answers),
      episodeIndex: completedEpisodes == null ? previousCount :
        (completedEpisodes > previousCount ? completedEpisodes : previousCount), completed: completed));
  }
  Future<void> toggleFollow(String authorId) async {
    _requireLogin(); if (authorId == uid) throw StateError('Você já é o autor desta história.');
    final followed = _following.contains(authorId);
    if (firebaseEnabled) {
      final ref = FirebaseFirestore.instance.collection('users').doc(uid).collection('following').doc(authorId);
      if (followed) { await ref.delete(); }
      else { await ref.set({'createdAt': FieldValue.serverTimestamp()}); }
    }
    if (followed) { _following.remove(authorId); } else { _following.add(authorId); }
    if (!firebaseEnabled) await _persistLocal(); _notify();
  }

  Future<List<FanEpisode>> loadEpisodes(String storyId) async {
    // In cloud mode prefer seeded/edited content; fall back to bundled samples only when absent.
    if (!firebaseEnabled) return List.of(_localEpisodes[storyId] ?? demoEpisodes[storyId] ?? []);
    if (storyById(storyId)?.isDemo == true) return List.of(demoEpisodes[storyId] ?? []);
    final docs = await FirebaseFirestore.instance.collection('stories').doc(storyId)
      .collection('episodes').orderBy('order').get();
    if (docs.docs.isEmpty && demoEpisodes.containsKey(storyId)) return List.of(demoEpisodes[storyId]!);
    return docs.docs.map((e) => FanEpisode.fromMap(e.id, e.data())).toList();
  }

  Future<String> uploadCover(Uint8List bytes) async {
    _requireLogin();
    if (bytes.length >= 5 * 1024 * 1024) throw StateError('Escolha uma imagem menor que 5 MB.');
    final jpeg = bytes.length > 2 && bytes[0] == 0xff && bytes[1] == 0xd8;
    final png = bytes.length > 8 && bytes[0] == 0x89 && bytes[1] == 0x50;
    final webp = bytes.length > 12 && String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF'
      && String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
    if (!jpeg && !png && !webp) throw StateError('Use uma imagem JPEG, PNG ou WebP.');
    if (!firebaseEnabled && bytes.length > 512 * 1024) {
      throw StateError('No modo local, use uma capa de até 512 KB para preservar o espaço do dispositivo.');
    }
    final type = jpeg ? 'jpeg' : png ? 'png' : 'webp';
    if (!firebaseEnabled) return 'data:image/$type;base64,${base64Encode(bytes)}';
    final ref = FirebaseStorage.instance.ref('covers/$uid/${DateTime.now().microsecondsSinceEpoch}.$type');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/$type'));
    return ref.getDownloadURL();
  }
  void _validateStory(FanStory s) {
    if (s.title.trim().length < 3 || s.title.length > 70 || s.description.trim().length < 15 ||
      s.description.length > 800 || !storyCategories.contains(s.category) ||
      !contentRatings.contains(s.contentRating) || !coverAssets.contains(s.coverAsset)) {
      throw StateError('Revise o título, a sinopse, a capa e a classificação da história.');
    }
  }
  Future<FanStory> createStory({required String title, required String description,
    required String category, required String contentRating, required String coverAsset,
    required String coverUrl}) async {
    _requireLogin();
    var story = FanStory(id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim(), description: description.trim(), category: category,
      contentRating: contentRating, coverAsset: coverAsset, coverUrl: coverUrl,
      authorId: uid, authorName: displayName, published: false, isDemo: !firebaseEnabled);
    _validateStory(story);
    if (firebaseEnabled) {
      final ref = await FirebaseFirestore.instance.collection('stories').add({...story.toMap(),
        'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
      story = FanStory.fromMap(ref.id, story.toMap());
    }
    _owned.removeWhere((s) => s.id == story.id); _owned.insert(0, story);
    if (!firebaseEnabled) {
      _localEpisodes[story.id] = [];
      try { await _persistLocal(); }
      catch (_) { _owned.removeWhere((s) => s.id == story.id); _localEpisodes.remove(story.id); rethrow; }
    }
    _notify(); return story;
  }
  Future<void> editStory(FanStory story) async {
    _requireAuthor(story); _validateStory(story);
    if (firebaseEnabled) {
      await FirebaseFirestore.instance.collection('stories').doc(story.id)
        .update({...story.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
    }
    final i = _owned.indexWhere((s) => s.id == story.id);
    final previous = i >= 0 ? _owned[i] : null;
    if (i >= 0) _owned[i] = story;
    if (!firebaseEnabled) {
      try { await _persistLocal(); }
      catch (_) { if (i >= 0 && previous != null) _owned[i] = previous; rethrow; }
    }
    _notify();
  }
  void _validateEpisode(String title, List<ChatLine> lines) {
    if (title.trim().length < 3 || title.trim().length > 80 || lines.length < 2 || lines.length > 80) {
      throw StateError('Use um título de 3 a 80 caracteres e de 2 a 80 mensagens.');
    }
    final ids = <String>{}, choiceKeys = <String>{}, earlierOptions = <String>{};
    for (final l in lines) {
      if (l.id.isEmpty || !ids.add(l.id) || l.speaker.trim().isEmpty || l.speaker.length > 40 ||
        l.text.trim().isEmpty || l.text.length > 600 || l.options.length > 3 ||
        (l.options.isNotEmpty && (l.options.length < 2 || l.options.any((o) => o.trim().isEmpty || o.length > 120)
          || l.options.toSet().length != l.options.length || !choiceKeys.add(l.answerKey))) ||
        (l.requires != null && !earlierOptions.contains(l.requires))) {
        throw StateError('Revise mensagens, opções duplicadas e condições após reordenar.');
      }
      earlierOptions.addAll(l.options);
    }
  }
  Future<void> addEpisode(FanStory story, String title, List<ChatLine> lines) async {
    _requireAuthor(story); _validateEpisode(title, lines);
    if (firebaseEnabled) {
      final db = FirebaseFirestore.instance, ref = FirebaseFirestore.instance.collection('stories').doc(story.id);
      final episodeRef = ref.collection('episodes').doc();
      await db.runTransaction((tx) async {
        final parent = await tx.get(ref);
        final count = (parent.data()?['episodeCount'] as num?)?.toInt() ?? 0;
        if (count >= 50) throw StateError('Limite de 50 episódios por história.');
        tx.set(episodeRef, {...FanEpisode(id: episodeRef.id, title: title.trim(), order: count, lines: lines).toMap(),
          'createdAt': FieldValue.serverTimestamp()});
        tx.update(ref, {'episodeCount': count + 1, 'updatedAt': FieldValue.serverTimestamp()});
      });
    } else {
      final episodes = _localEpisodes[story.id] ??= [];
      if (episodes.length >= 50) throw StateError('Limite de 50 episódios por história.');
      episodes.add(FanEpisode(id: 'e_${DateTime.now().microsecondsSinceEpoch}',
        title: title.trim(), order: episodes.length, lines: List.of(lines)));
      final i = _owned.indexWhere((s) => s.id == story.id);
      final previous = _owned[i];
      _owned[i] = previous.copyWith(episodeCount: episodes.length);
      try { await _persistLocal(); }
      catch (_) { episodes.removeLast(); _owned[i] = previous; rethrow; }
    }
    _notify();
  }
  Future<void> editEpisode(FanStory story, FanEpisode episode) async {
    _requireAuthor(story); _validateEpisode(episode.title, episode.lines);
    if (firebaseEnabled) {
      await FirebaseFirestore.instance.collection('stories').doc(story.id).collection('episodes')
        .doc(episode.id).update(episode.toMap());
    } else {
      final episodes = _localEpisodes[story.id] ?? [];
      final i = episodes.indexWhere((e) => e.id == episode.id);
      if (i < 0) throw StateError('Episódio não encontrado.');
      final previous = episodes[i]; episodes[i] = episode;
      try { await _persistLocal(); }
      catch (_) { episodes[i] = previous; rethrow; }
    }
    _notify();
  }
  Future<void> publishStory(FanStory story, {bool publish = true}) async {
    _requireAuthor(story);
    if (publish && (await loadEpisodes(story.id)).isEmpty) throw StateError('Adicione um episódio antes de publicar.');
    await editStory(story.copyWith(published: publish));
  }
  Future<void> reportStory(String storyId, String reason) async {
    _requireLogin();
    if (!firebaseEnabled || storyById(storyId)?.isDemo == true) {
      throw StateError('As histórias locais não são enviadas à moderação.');
    }
    await FirebaseFirestore.instance.collection('reports').add({'storyId': storyId,
      'reporterId': uid, 'reason': reason, 'status': 'open', 'createdAt': FieldValue.serverTimestamp()});
  }
  Future<void> setReadingPreferences({double? fontSize, bool? reducedMotion}) async {
    readerFontSize = (fontSize ?? readerFontSize).clamp(14, 22).toDouble();
    reduceMotion = reducedMotion ?? reduceMotion;
    await _preferences?.setDouble('fan.readerFontSize', readerFontSize);
    await _preferences?.setBool('fan.reduceMotion', reduceMotion); _notify();
  }
  String _draftKey(String storyId, String? episodeId) => '$uid/$storyId/${episodeId ?? 'new'}';
  Map<String, dynamic>? editorDraft(String storyId, String? episodeId) => _drafts[_draftKey(storyId, episodeId)];
  Future<void> saveEditorDraft(String storyId, String? episodeId, Map<String, dynamic>? data) async {
    final key = _draftKey(storyId, episodeId);
    if (data == null) { _drafts.remove(key); } else { _drafts[key] = data; }
    if (_preferences == null || !await _preferences!.setString('fan.drafts', jsonEncode(_drafts))) {
      throw StateError('Não foi possível salvar o rascunho neste dispositivo.');
    }
  }
  Future<void> clearLocalData() async {
    if (firebaseEnabled) throw StateError('Esta opção é apenas para o perfil local.');
    _localProfile = false; _name = 'Leitor FAN'; _bio = '';
    _owned.clear(); _public.clear(); _library.clear(); _following.clear(); _localEpisodes.clear(); _drafts.clear();
    await _persistLocal(); await _preferences?.remove('fan.drafts'); _notify();
  }
  @override
  void dispose() {
    _disposed = true; _authGeneration++;
    for (final s in [..._subscriptions, ..._userSubscriptions]) { s.cancel(); }
    super.dispose();
  }
}
