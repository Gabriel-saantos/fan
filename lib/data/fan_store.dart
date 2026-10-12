import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/fan_models.dart';
import 'demo_data.dart';

class FanStore extends ChangeNotifier {
  FanStore({required this.firebaseEnabled});

  final bool firebaseEnabled;
  final List<FanStory> _public = [];
  final List<FanStory> _owned = [];
  final Map<String, LibraryState> _library = {};
  final Map<String, List<FanEpisode>> _localEpisodes = {};
  final Set<String> _following = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _librarySubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _followSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ownedSubscription;

  bool _demoAuthenticated = false;
  String _demoName = 'Leitor FAN';
  String _bio = 'Criando meus próprios universos ✨';
  bool isLoading = true;

  User? get user => firebaseEnabled ? FirebaseAuth.instance.currentUser : null;
  bool get signedIn => firebaseEnabled ? user != null : _demoAuthenticated;
  String get uid => firebaseEnabled ? (user?.uid ?? '') : 'offline_demo';
  String get displayName => firebaseEnabled
      ? (user?.displayName?.trim().isNotEmpty == true ? user!.displayName! : (user?.email?.split('@').first ?? 'Leitor FAN'))
      : _demoName;
  String get email => firebaseEnabled ? (user?.email ?? '') : 'Modo demonstração';
  String get bio => _bio;
  bool get demoMode => !firebaseEnabled;
  bool get hasCloud => firebaseEnabled;

  List<FanStory> get stories {
    final remoteIds = _public.map((e) => e.id).toSet();
    return [..._public, ...demoStories.where((s) => !remoteIds.contains(s.id))];
  }
  List<FanStory> get myStories => List.unmodifiable(_owned);
  List<FanStory> get savedStories => stories.where((s) => libraryOf(s.id).saved).toList();
  List<FanStory> get readingStories => stories.where((s) => libraryOf(s.id).episodeIndex > 0).toList();
  LibraryState libraryOf(String id) => _library[id] ?? const LibraryState();
  bool follows(String authorId) => _following.contains(authorId);

  Future<void> bootstrap() async {
    if (!firebaseEnabled) {
      isLoading = false;
      notifyListeners();
      return;
    }
    _subscriptions.add(FirebaseFirestore.instance.collection('stories')
      .where('published', isEqualTo: true).limit(100).snapshots().listen((snapshot) {
        _public..clear()..addAll(snapshot.docs.map((d) => FanStory.fromMap(d.id, d.data())));
        isLoading = false;
        notifyListeners();
      }, onError: (_) { isLoading = false; notifyListeners(); }));

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((u) async {
      await _librarySubscription?.cancel();
      await _followSubscription?.cancel();
      await _ownedSubscription?.cancel();
      _library.clear(); _following.clear(); _owned.clear();
      if (u != null) {
        final users = FirebaseFirestore.instance.collection('users');
        try {
          final doc = await users.doc(u.uid).get();
          if (doc.exists) {
            _bio = (doc.data()?['bio'] ?? 'Criando meus próprios universos ✨').toString();
          } else {
            await users.doc(u.uid).set({
              'displayName': u.displayName ?? (u.email?.split('@').first ?? 'Leitor FAN'),
              'bio': _bio, 'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (_) { /* Rules or offline: keep session usable. */ }
        _librarySubscription = users.doc(u.uid).collection('library').snapshots().listen((snapshot) {
          _library.clear();
          for (final d in snapshot.docs) {
            _library[d.id] = LibraryState.fromMap(d.data());
          }
          notifyListeners();
        }, onError: (_) {});
        _followSubscription = users.doc(u.uid).collection('following').snapshots().listen((snapshot) {
          _following..clear()..addAll(snapshot.docs.map((d) => d.id));
          notifyListeners();
        }, onError: (_) {});
        _ownedSubscription = FirebaseFirestore.instance.collection('stories')
          .where('authorId', isEqualTo: u.uid).snapshots().listen((snapshot) {
            _owned..clear()..addAll(snapshot.docs.map((d) => FanStory.fromMap(d.id, d.data())));
            notifyListeners();
          }, onError: (_) {});
      }
      notifyListeners();
    });
    isLoading = false;
    notifyListeners();
  }

  Future<void> logIn(String email, String password) async {
    if (!firebaseEnabled) {
      _demoAuthenticated = true;
      _demoName = email.trim().split('@').first.isEmpty ? 'Leitor FAN' : email.trim().split('@').first;
      notifyListeners();
      return;
    }
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> register(String name, String email, String password) async {
    if (!firebaseEnabled) {
      _demoAuthenticated = true;
      _demoName = name.trim();
      notifyListeners();
      return;
    }
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(), password: password,
    );
    await cred.user?.updateDisplayName(name.trim());
    await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
      'displayName': name.trim(), 'bio': _bio,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    notifyListeners();
  }

  Future<void> logOut() async {
    if (firebaseEnabled) {
      await FirebaseAuth.instance.signOut();
    } else {
      _demoAuthenticated = false;
      _owned.clear();
      _library.clear();
      _following.clear();
    }
    notifyListeners();
  }

  Future<void> resetPassword(String address) async {
    if (!firebaseEnabled) throw StateError('Recuperação disponível após conectar o Firebase.');
    await FirebaseAuth.instance.sendPasswordResetEmail(email: address.trim());
  }

  Future<void> editProfile(String name, String newBio) async {
    if (!signedIn) throw StateError('Entre em sua conta.');
    _bio = newBio.trim();
    if (firebaseEnabled) {
      await user!.updateDisplayName(name.trim());
      await FirebaseFirestore.instance.collection('users').doc(uid)
        .set({'displayName': name.trim(), 'bio': _bio}, SetOptions(merge: true));
    } else {
      _demoName = name.trim();
    }
    notifyListeners();
  }

  Future<void> updateLibrary(String storyId, {bool? saved, bool? liked, int? episodeIndex}) async {
    if (!signedIn) throw StateError('Entre em sua conta para salvar seu progresso.');
    final old = libraryOf(storyId);
    final next = old.copyWith(saved: saved, liked: liked,
      episodeIndex: episodeIndex != null && episodeIndex > old.episodeIndex ? episodeIndex : null);
    _library[storyId] = next;
    notifyListeners();
    if (firebaseEnabled) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid)
          .collection('library').doc(storyId).set({
            'saved': next.saved, 'liked': next.liked, 'episodeIndex': next.episodeIndex,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      } catch (_) {
        _library[storyId] = old;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> toggleFollow(String authorId) async {
    if (!signedIn) throw StateError('Entre em sua conta para seguir autores.');
    if (authorId == uid) throw StateError('Você não pode seguir a si mesmo.');
    if (authorId == 'fan_demo' && !firebaseEnabled) {
      if (!_following.add(authorId)) _following.remove(authorId);
      notifyListeners();
      return;
    }
    final already = _following.contains(authorId);
    if (already) { _following.remove(authorId); } else { _following.add(authorId); }
    notifyListeners();
    if (firebaseEnabled) {
      final ref = FirebaseFirestore.instance.collection('users').doc(uid).collection('following').doc(authorId);
      try {
        if (already) { await ref.delete(); }
        else { await ref.set({'createdAt': FieldValue.serverTimestamp()}); }
      } catch (_) {
        if (already) { _following.add(authorId); } else { _following.remove(authorId); }
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<List<FanEpisode>> loadEpisodes(String storyId) async {
    if (storyId.startsWith('demo_')) return demoEpisodes[storyId] ?? [];
    if (!firebaseEnabled) return _localEpisodes[storyId] ?? [];
    final docs = await FirebaseFirestore.instance.collection('stories').doc(storyId)
        .collection('episodes').orderBy('order').get();
    return docs.docs.map((e) => FanEpisode.fromMap(e.id, e.data())).toList();
  }

  Future<String> uploadCover(Uint8List bytes) async {
    if (!firebaseEnabled) return '';
    if (!signedIn) throw StateError('Faça login antes de enviar uma capa.');
    if (bytes.length > 5 * 1024 * 1024) throw StateError('Imagem deve ter no máximo 5 MB.');
    final path = 'covers/$uid/${DateTime.now().microsecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<FanStory> createStory({
    required String title, required String description, required String category,
    required String contentRating, required String coverAsset, required String coverUrl,
  }) async {
    if (!signedIn) throw StateError('Faça login para criar histórias.');
    final data = {
      'title': title.trim(), 'description': description.trim(), 'category': category,
      'authorId': uid, 'authorName': displayName, 'coverAsset': coverAsset,
      'coverUrl': coverUrl, 'contentRating': contentRating,
      'published': false, 'episodeCount': 0,
      'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
    };
    if (firebaseEnabled) {
      final ref = await FirebaseFirestore.instance.collection('stories').add(data);
      return FanStory.fromMap(ref.id, data);
    }
    final story = FanStory(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}', title: title.trim(),
      description: description.trim(), category: category, authorId: uid,
      authorName: displayName, coverAsset: coverAsset, coverUrl: '',
      contentRating: contentRating, published: false, isDemo: true,
    );
    _owned.insert(0, story);
    _localEpisodes[story.id] = [];
    notifyListeners();
    return story;
  }

  Future<void> addEpisode(FanStory story, String title, List<ChatLine> lines) async {
    if (!signedIn || story.authorId != uid) throw StateError('Apenas o autor pode editar.');
    if (lines.length < 2) throw StateError('Adicione pelo menos duas mensagens.');
    if (lines.length > 80) throw StateError('Limite de 80 mensagens por episódio.');
    if (story.episodeCount >= 50) throw StateError('Limite de 50 episódios por história.');
    final nextOrder = (await loadEpisodes(story.id)).length;
    final episode = FanEpisode(id: 'e${nextOrder + 1}', title: title.trim(), order: nextOrder, lines: lines);
    if (firebaseEnabled) {
      final ref = FirebaseFirestore.instance.collection('stories').doc(story.id);
      await ref.collection('episodes').add({
        ...episode.toMap(), 'createdAt': FieldValue.serverTimestamp(),
      });
      await ref.update({'episodeCount': FieldValue.increment(1), 'updatedAt': FieldValue.serverTimestamp()});
    } else {
      (_localEpisodes[story.id] ??= []).add(episode);
      final i = _owned.indexWhere((e) => e.id == story.id);
      if (i != -1) _owned[i] = _owned[i].copyWith(episodeCount: nextOrder + 1);
    }
    notifyListeners();
  }

  Future<void> publishStory(FanStory story) async {
    if (!signedIn || story.authorId != uid) throw StateError('Apenas o autor pode publicar.');
    final episodes = await loadEpisodes(story.id);
    if (episodes.isEmpty) throw StateError('Crie pelo menos um episódio antes de publicar.');
    if (firebaseEnabled) {
      await FirebaseFirestore.instance.collection('stories').doc(story.id)
          .update({'published': true, 'updatedAt': FieldValue.serverTimestamp()});
    } else {
      final i = _owned.indexWhere((e) => e.id == story.id);
      if (i != -1) {
        _owned[i] = _owned[i].copyWith(published: true);
        _public.insert(0, _owned[i]);
      }
    }
    notifyListeners();
  }

  Future<void> reportStory(String storyId, String reason) async {
    if (!signedIn) throw StateError('Entre em sua conta para denunciar.');
    if (storyId.startsWith('demo_') || !firebaseEnabled) return;
    await FirebaseFirestore.instance.collection('reports').add({
      'storyId': storyId, 'reporterId': uid,
      'reason': reason, 'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    for (final s in _subscriptions) { s.cancel(); }
    _authSubscription?.cancel();
    _librarySubscription?.cancel();
    _followSubscription?.cancel();
    _ownedSubscription?.cancel();
    super.dispose();
  }
}
