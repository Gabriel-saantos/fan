import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/scope.dart';
import 'core/theme.dart';
import 'data/fan_store.dart';
import 'firebase_options.dart';
import 'ui/pages/shell_page.dart';
import 'ui/pages/welcome_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseEnabled = false;
  String? initializationError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseEnabled = true;
  } on StateError {
    // No Firebase configuration: use the persistent local profile.
  } catch (_) {
    initializationError =
        'Não foi possível iniciar a conexão com a nuvem. O aplicativo abriu no modo local.';
  }
  final store = FanStore(firebaseEnabled: firebaseEnabled);
  await store.bootstrap();
  store.cloudError = initializationError;
  var showIntro = true;
  try {
    showIntro =
        !((await SharedPreferences.getInstance()).getBool('fan_intro_seen') ??
            false);
  } catch (_) {
    showIntro = false;
  }
  runApp(FanApp(store: store, showIntro: showIntro));
}

class FanApp extends StatefulWidget {
  const FanApp({super.key, required this.store, this.showIntro = false});
  final FanStore store;
  final bool showIntro;

  @override
  State<FanApp> createState() => _FanAppState();
}

class _FanAppState extends State<FanApp> {
  @override
  void dispose() {
    widget.store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FanScope(
    store: widget.store,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FAN · Histórias que conectam',
      theme: fanTheme(),
      home: widget.showIntro ? const WelcomePage() : const ShellPage(),
    ),
  );
}
