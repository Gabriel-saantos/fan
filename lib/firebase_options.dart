import 'package:firebase_core/firebase_core.dart';

/// Optional public Firebase client configuration. Never pass an Admin/private key.
/// FlutterFire can also regenerate this file for a selected project.
class DefaultFirebaseOptions {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _bucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static FirebaseOptions get currentPlatform {
    if (_apiKey.isEmpty ||
        _appId.isEmpty ||
        _projectId.isEmpty ||
        _senderId.isEmpty) {
      throw StateError('Firebase não configurado.');
    }
    return const FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _senderId,
      projectId: _projectId,
      authDomain: _authDomain,
      storageBucket: _bucket,
    );
  }
}
